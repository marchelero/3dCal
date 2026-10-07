/// Servicio de backup/restore para la base de datos completa.
///
/// **Export**: lee todas las tablas (filamentos, impresoras, cotizaciones,
/// materiales, settings), serializa a JSON y comparte via `share_plus`.
///
/// **Import**: lee un archivo JSON via `file_picker`, valida, borra la data
/// actual y restaura todo desde el backup.
///
/// **NO exporta**: entitlements (RevenueCat) — son estado vinculado a la
/// cuenta del store, no datos locales del usuario.
///
/// **Estrategia de import**: REPLACE — borra todo antes de insertar.
/// Se muestra confirmacion al usuario antes de proceder.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:share_plus/share_plus.dart';

import '../../l10n/es_bo.dart';
import '../database/app_database.dart';
import 'backup_models.dart';

/// Extension de archivo para backups.
const String kBackupExtension = '3dcal';

/// Códigos de error de importación de backup (LOW-14).
///
/// El servicio devuelve SIEMPRE un código ASCII estable (nunca un mensaje
/// en español) para que la UI lo traduzca con el locale activo (EsBO en
/// `settings_page`). El detalle diagnóstico (tamaños, versiones, filas
/// inválidas) va a `debugPrint` y jamás se muestra al usuario.
abstract final class BackupErrorCodes {
  /// El archivo supera `kBackupMaxFileBytes`.
  static const sizeTooLarge = 'size_too_large';

  /// JSON malformado o estructura que no es un backup.
  static const invalidFile = 'invalid_file';

  /// No se pudo leer el archivo (I/O).
  static const readFailed = 'read_failed';

  /// `BackupData.validate()` rechazó filas/columnas (detalle en log).
  static const invalidData = 'invalid_data';

  /// El backup es de un schema más nuevo que la app.
  static const futureVersion = 'future_version';

  /// La transacción de restore falló (rollback total; datos intactos).
  static const restoreFailed = 'restore_failed';
}

/// Nombre base del archivo de backup.
String _backupFileName() {
  final now = DateTime.now().toUtc();
  final stamp = now.toIso8601String().replaceAll(RegExp(r'[:\-]'), '');
  return '3dcal_backup_$stamp.$kBackupExtension';
}

/// Servicio de backup/restore.
class BackupService {
  /// Crea un servicio de backup/restore para la base de datos dada.
  const BackupService(this._db);

  final AppDatabase _db;

  // ─────────────────────────────────────────────
  // EXPORT
  // ─────────────────────────────────────────────

  /// Exporta toda la data a un archivo JSON y lo comparte.
  ///
  /// Retorna el nombre del archivo generado.
  /// Lanza la excepcion si falla (para mostrar el error real al usuario).
  Future<String> export() async {
    final data = await _collectAllData();
    final json = jsonEncode(data.toJson());
    final fileName = _backupFileName();

    // XFile.fromData funciona en TODAS las plataformas (web, movil, desktop)
    // sin depender de dart:io ni escribir a disco temporal.
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(json),
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        text: EsBO.settingsBackupTitle,
      ),
    );

    return fileName;
  }

  /// Recolecta toda la data de la base de datos.
  Future<BackupData> _collectAllData() async {
    final filaments = await _db.select(_db.filaments).get();
    final printers = await _db.select(_db.printers).get();
    final calculations = await _db.select(_db.calculations).get();
    final materials = await _db.select(_db.calculationMaterials).get();
    final settings = await _db.select(_db.settingsTable).get();
    // v12: escalones de descuento por cantidad (los crea el usuario en
    // Ajustes). Sin esto se perderian en cada restore.
    final tiers = await _db.select(_db.discountTiersTable).get();

    return BackupData(
      version: kBackupFormatVersion,
      schemaVersion: _db.schemaVersion,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      appName: kBackupAppName,
      filaments: filaments.map<Map<String, dynamic>>(_rowToMap).toList(),
      printers: printers.map<Map<String, dynamic>>(_rowToMap).toList(),
      calculations: calculations.map<Map<String, dynamic>>(_rowToMap).toList(),
      calculationMaterials: materials
          .map<Map<String, dynamic>>(_rowToMap)
          .toList(),
      settings: settings.map<Map<String, dynamic>>(_rowToMap).toList(),
      discountTiers: tiers.map<Map<String, dynamic>>(_rowToMap).toList(),
    );
  }

  /// Reolecta toda la data sin compartirla (para tests).
  ///
  /// [export] usa [_collectAllData] + share; este wrapper expone el mismo
  /// snapshot como [BackupData] para poder verificar el contenido del
  /// archivo exportado sin pasar por el share sheet del sistema.
  @visibleForTesting
  Future<BackupData> collectAllDataForTest() async => _collectAllData();

  /// Convierte una fila de drift a Map.
  ///
  /// Las clases generadas por drift exponen `toJson()` (NO `toMap()`).
  /// Normalizamos DateTime porque algunas versiones/serializadores de Drift
  /// lo producen como milisegundos Unix y el formato público del backup es
  /// ISO-8601.
  Map<String, dynamic> _rowToMap(Object row) {
    final json = Map<String, dynamic>.from(
      (row as dynamic).toJson() as Map<String, dynamic>,
    );
    for (final key in const ['createdAt', 'updatedAt']) {
      final value = json[key];
      if (value is num && value.isFinite && value % 1 == 0) {
        json[key] = DateTime.fromMillisecondsSinceEpoch(
          value.toInt(),
          isUtc: true,
        ).toIso8601String();
      } else if (value is DateTime) {
        json[key] = value.toUtc().toIso8601String();
      }
    }
    return json;
  }

  // ─────────────────────────────────────────────
  // IMPORT
  // ─────────────────────────────────────────────

  /// Valida que un archivo seleccionado no supere el tamaño máximo del
  /// backup, ANTES de cargarlo a memoria.
  ///
  /// Retorna null si es valido, o [BackupErrorCodes.sizeTooLarge] si el
  /// archivo es demasiado grande. Revisa el tamaño reportado por el picker
  /// y, cuando hay path, el tamaño real en disco.
  static String? validateFileSize(PlatformFile file) {
    final size = file.lengthSync();
    if (size != null && size > kBackupMaxFileBytes) {
      debugPrint('[Backup] picker size $size B > $kBackupMaxFileBytes B');
      return BackupErrorCodes.sizeTooLarge;
    }
    final path = file.path;
    if (path != null) {
      try {
        if (File(path).lengthSync() > kBackupMaxFileBytes) {
          debugPrint('[Backup] disk size > $kBackupMaxFileBytes B');
          return BackupErrorCodes.sizeTooLarge;
        }
      } on FileSystemException {
        // No se puede stat el archivo; se dejara pasar y la lectura fallara
        // con un mensaje generico en el paso siguiente.
      }
    }
    return null;
  }

  /// Permite al usuario seleccionar un archivo de backup y lo restaura.
  ///
  /// Retorna null si el usuario cancelo, un código de
  /// [BackupErrorCodes] si fallo, o string vacio si fue exitoso.
  Future<String?> import() async {
    try {
      // Seleccionar archivo (lista vacia = usuario cancelo)
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [kBackupExtension, 'json'],
      );
      if (files.isEmpty) {
        return null; // Usuario cancelo
      }

      // En web no hay `path` (se lee con readAsBytes); en movil/desktop se
      // lee por path sin cargar el archivo entero a memoria.
      final file = files.single;

      // Limite de tamaño ANTES de cargar a memoria (archivos gigantes o
      // corruptos no deben agotar la RAM del dispositivo).
      final sizeError = validateFileSize(file);
      if (sizeError != null) {
        return sizeError;
      }

      final String content;
      final path = file.path;
      if (path != null) {
        final f = File(path);
        if (f.lengthSync() > kBackupMaxFileBytes) {
          debugPrint('[Backup] path size > $kBackupMaxFileBytes B');
          return BackupErrorCodes.sizeTooLarge;
        }
        content = await f.readAsString();
      } else {
        final bytes = await file.readAsBytes();
        if (bytes.lengthInBytes > kBackupMaxFileBytes) {
          debugPrint('[Backup] bytes size > $kBackupMaxFileBytes B');
          return BackupErrorCodes.sizeTooLarge;
        }
        content = utf8.decode(bytes);
      }

      return await restoreFromJson(content);
    } on FormatException {
      return BackupErrorCodes.invalidFile;
    } catch (e) {
      debugPrint('[Backup] import fallo: $e');
      return BackupErrorCodes.readFailed;
    }
  }

  /// Restaura datos desde un string JSON.
  ///
  /// Retorna null si el usuario cancelo (validacion fallo), un código de
  /// [BackupErrorCodes] si fallo, o string vacio si fue exitoso. La UI
  /// traduce los códigos con el locale activo (LOW-14).
  ///
  /// **Seguridad**: el restore corre dentro de una transaccion Drift: si
  /// cualquier insert falla a mitad de camino, TODA la operacion se revierte
  /// (rollback) y los datos actuales quedan intactos. Nunca queda un estado
  /// intermedio.
  Future<String?> restoreFromJson(String jsonContent) async {
    try {
      // Limite de tamaño sobre el contenido ya deserializado.
      if (jsonContent.length > kBackupMaxFileBytes) {
        debugPrint(
          '[Backup] content length ${jsonContent.length} > '
          '$kBackupMaxFileBytes B',
        );
        return BackupErrorCodes.sizeTooLarge;
      }

      final Object? raw;
      try {
        raw = jsonDecode(jsonContent);
      } on FormatException {
        return BackupErrorCodes.invalidFile;
      }
      if (raw is! Map<String, dynamic>) {
        return BackupErrorCodes.invalidFile;
      }
      final backup = BackupData.fromJson(raw);

      // Validar estructura, tipos, duplicados y referencias.
      final error = backup.validate();
      if (error != null) {
        // LOW-14: el detalle en español es solo diagnóstico (log); la UI
        // muestra un mensaje localizado a partir de este código.
        debugPrint('[Backup] validate rechazó: $error');
        return BackupErrorCodes.invalidData;
      }

      // Rechazar backups de un schema FUTURO (no sabemos migrar hacia atras).
      // Backups de schema anterior son aceptables: la app migra hacia adelante.
      if (backup.schemaVersion > _db.schemaVersion) {
        debugPrint(
          '[Backup] schema futuro: ${backup.schemaVersion} > '
          '${_db.schemaVersion}',
        );
        return BackupErrorCodes.futureVersion;
      }

      // Restaurar en transaccion (atomica: fallo parcial => rollback total)
      await _db.transaction(() async {
        await _clearAllData();
        await _insertFilaments(backup.filaments);
        await _insertPrinters(backup.printers);
        await _insertCalculations(backup.calculations);
        await _insertCalculationMaterials(backup.calculationMaterials);
        await _insertDiscountTiers(backup.discountTiers);
        await _insertSettings(backup.settings);
      });

      return ''; // Exito
    } catch (e) {
      debugPrint('[Backup] restoreFromJson fallo: $e');
      return BackupErrorCodes.restoreFailed;
    }
  }

  /// Borra toda la data actual (excepto entitlements).
  Future<void> _clearAllData() async {
    await _db.delete(_db.calculationMaterials).go();
    await _db.delete(_db.calculations).go();
    await _db.delete(_db.filaments).go();
    await _db.delete(_db.printers).go();
    await _db.delete(_db.settingsTable).go();
    await _db.delete(_db.discountTiersTable).go();
  }

  /// Inserta filamentos desde el backup.
  Future<void> _insertFilaments(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db
          .into(_db.filaments)
          .insert(
            FilamentsCompanion(
              id: Value(row['id'] as int),
              name: Value(row['name'] as String),
              brand: Value(row['brand'] as String?),
              pricePerBobbin: Value((row['pricePerBobbin'] as num).toDouble()),
              gramsPerBobbin: Value((row['gramsPerBobbin'] as num).toDouble()),
              isDefault: Value(row['isDefault'] as bool),
              color: Value(row['color'] as String?),
              createdAt: Value(_parseDateTime(row['createdAt'])),
            ),
          );
    }
  }

  /// Inserta impresoras desde el backup.
  Future<void> _insertPrinters(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db
          .into(_db.printers)
          .insert(
            PrintersCompanion(
              id: Value(row['id'] as int),
              brand: Value(row['brand'] as String?),
              name: Value(row['name'] as String),
              averageWatts: Value(row['averageWatts'] as int),
              purchaseCost: Value((row['purchaseCost'] as num?)?.toDouble()),
              usefulLifeHours: Value(row['usefulLifeHours'] as int?),
              isDefault: Value(row['isDefault'] as bool),
              // v13 (currentHours).
              currentHours: Value(row['currentHours'] as int?),
              createdAt: Value(_parseDateTime(row['createdAt'])),
            ),
          );
    }
  }

  /// Inserta cotizaciones desde el backup.
  Future<void> _insertCalculations(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db
          .into(_db.calculations)
          .insert(
            CalculationsCompanion(
              id: Value(row['id'] as int),
              createdAt: Value(_parseDateTime(row['createdAt'])),
              pieceName: Value(row['pieceName'] as String?),
              clientName: Value(row['clientName'] as String?),
              notes: Value(row['notes'] as String?),
              conditions: Value(row['conditions'] as String?),
              printerId: Value(row['printerId'] as int?),
              printerNameSnapshot: Value(row['printerNameSnapshot'] as String?),
              printerWattsSnapshot: Value(
                (row['printerWattsSnapshot'] as num).toDouble(),
              ),
              totalHours: Value((row['totalHours'] as num).toDouble()),
              // MED-07: opcional en backups previos a schema 4 → default 0
              // (misma semántica que el default de columna).
              printMinutes: Value(row['printMinutes'] as int? ?? 0),
              discountPercentage: Value(
                (row['discountPercentage'] as num).toDouble(),
              ),
              kwhRateSnapshot: Value(
                (row['kwhRateSnapshot'] as num).toDouble(),
              ),
              profitBaseSnapshot: Value(
                (row['profitBaseSnapshot'] as num).toDouble(),
              ),
              isSold: Value(row['isSold'] as bool),
              isTemplate: Value(row['isTemplate'] as bool? ?? false),
              // v14 (isPartial) y v16 (isAdvanced). Backups anteriores a esas
              // versiones no traen las keys: los defaults conservan el
              // comportamiento viejo (no-parcial, modo inferido).
              isPartial: Value(row['isPartial'] as bool? ?? false),
              isAdvanced: Value(row['isAdvanced'] as bool? ?? false),
              quantity: Value((row['quantity'] as num?)?.toInt() ?? 1),
              materialCostSnapshot: Value(
                (row['materialCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              electricCostSnapshot: Value(
                (row['electricCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              amortizationCostSnapshot: Value(
                (row['amortizationCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              laborCostSnapshot: Value(
                (row['laborCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              postProcessCostSnapshot: Value(
                (row['postProcessCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              baseCostSnapshot: Value(
                (row['baseCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              failureCostSnapshot: Value(
                (row['failureCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              markupCostSnapshot: Value(
                (row['markupCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              profitAmountSnapshot: Value(
                (row['profitAmountSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              minimumChargeAppliedSnapshot: Value(
                (row['minimumChargeAppliedSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              effectiveTotalSnapshot: Value(
                (row['effectiveTotalSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              totalPriceSnapshot: Value(
                (row['totalPriceSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              laborRateSnapshot: Value(
                (row['laborRateSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              postProcessRateSnapshot: Value(
                (row['postProcessRateSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              failureRateSnapshot: Value(
                (row['failureRateSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              minimumChargeSnapshot: Value(
                (row['minimumChargeSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              markupOnMaterialsSnapshot: Value(
                (row['markupOnMaterialsSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              // v12 (descuento mayorista).
              batchDiscountPercent: Value(
                row['batchDiscountPercent'] as String?,
              ),
              batchDiscountAmount: Value(row['batchDiscountAmount'] as String?),
              pieceImageBlob: Value(_decodePieceImage(row)),
              // v17: los 3 costos de servicio. Un backup viejo no trae las
              // keys -> caen a los defaults de COLUMNAS ('auto'/'auto'/'off'),
              // que reproducen la fórmula legacy (cobro según horas/material).
              // MED-06: antes caían a 'fixed' y el motor pasaba a cobrar 0
              // por modelado/postproceso, desalineando el desglose del PDF.
              modelingMode: Value(row['modelingMode'] as String? ?? 'auto'),
              modelingValue: Value(
                (row['modelingValue'] as num?)?.toDouble() ?? 0,
              ),
              postprocMode: Value(row['postprocMode'] as String? ?? 'auto'),
              postprocValue: Value(
                (row['postprocValue'] as num?)?.toDouble() ?? 0,
              ),
              extraMode: Value(row['extraMode'] as String? ?? 'off'),
              extraValue: Value((row['extraValue'] as num?)?.toDouble() ?? 0),
              extraLabel: Value(row['extraLabel'] as String? ?? ''),
            ),
          );
    }
  }

  /// Decodifica la foto de la pieza (F2) desde el backup.
  ///
  /// El export serializa `pieceImageBlob` como base64 String (via `toJson()`
  /// de drift). Backups viejos sin la key, o sin foto, llegan como `null`.
  /// Base64 corrupto → [FormatException] → el catch de [restoreFromJson]
  /// hace rollback transaccional y la DB actual queda intacta.
  Uint8List? _decodePieceImage(Map<String, dynamic> row) {
    final raw = row['pieceImageBlob'];
    if (raw == null) return null;
    if (raw is! String) {
      throw const FormatException(
        'pieceImageBlob invalido (no es base64 String)',
      );
    }
    try {
      return base64Decode(raw);
    } on FormatException {
      throw FormatException('pieceImageBlob invalido (base64 corrupto)');
    }
  }

  /// Inserta materiales de cotizaciones desde el backup.
  Future<void> _insertCalculationMaterials(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      await _db
          .into(_db.calculationMaterials)
          .insert(
            CalculationMaterialsCompanion(
              id: Value(row['id'] as int),
              calculationId: Value(row['calculationId'] as int),
              filamentId: Value(row['filamentId'] as int?),
              label: Value(row['label'] as String),
              weightGrams: Value((row['weightGrams'] as num).toDouble()),
              pricePerBobbinSnapshot: Value(
                (row['pricePerBobbinSnapshot'] as num).toDouble(),
              ),
              gramsPerBobbinSnapshot: Value(
                (row['gramsPerBobbinSnapshot'] as num).toDouble(),
              ),
              // v15 (tiempo propio por material). Backups anteriores no
              // traen las keys → NULL = usa el tiempo global.
              useOwnTime: Value(row['useOwnTime'] as bool?),
              materialHours: Value((row['materialHours'] as num?)?.toDouble()),
              materialMinutes: Value(
                (row['materialMinutes'] as num?)?.toDouble(),
              ),
            ),
          );
    }
  }

  /// Inserta escalones de descuento por cantidad desde el backup (v12).
  ///
  /// Coleccion vacia en backups previos a v12 → no inserta nada y la app
  /// queda sin escalones, que es el estado previo a esa feature.
  Future<void> _insertDiscountTiers(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db
          .into(_db.discountTiersTable)
          .insert(
            DiscountTiersTableCompanion.insert(
              id: row['id'] as String,
              minQty: row['minQty'] as int,
              // `percent` se conserva como TEXT decimal (no se castea a
              // double: perderia precision en el round-trip JSON).
              percent: row['percent'] as String,
              sortOrder: row['sortOrder'] as int,
            ),
          );
    }
  }

  /// Inserta settings desde el backup.
  Future<void> _insertSettings(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db
          .into(_db.settingsTable)
          .insert(
            SettingsTableCompanion(
              key: Value(row['key'] as String),
              value: Value(row['value'] as String),
              updatedAt: Value(_parseDateTime(row['updatedAt'])),
            ),
          );
    }
  }

  /// Parsea ISO-8601 o milisegundos Unix de backups antiguos.
  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      return DateTime.parse(value).toUtc();
    }
    if (value is num && value.isFinite && value % 1 == 0) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    throw const FormatException('Fecha de backup invalida');
  }
}
