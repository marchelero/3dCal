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

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:share_plus/share_plus.dart';

import '../../l10n/es_bo.dart';
import '../database/app_database.dart';
import 'backup_models.dart';

/// Extension de archivo para backups.
const String kBackupExtension = '3dcal';

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
    );
  }

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

  /// Permite al usuario seleccionar un archivo de backup y lo restaura.
  ///
  /// Retorna null si el usuario cancelo, o un mensaje de error si fallo.
  /// Retorna string vacio si fue exitoso.
  Future<String?> import() async {
    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [kBackupExtension, 'json'],
      );
      if (result == null || result.files.isEmpty) {
        return null; // Usuario cancelo
      }

      // En web `path` es null: el contenido viene en `bytes`.
      // En movil/desktop `bytes` suele ser null y se lee por path.
      final file = result.files.single;
      final bytes = file.bytes;

      // Limite de tamaño ANTES de cargar a memoria (archivos gigantes o
      // corruptos no deben agotar la RAM del dispositivo).
      final size = file.size;
      if (size > kBackupMaxFileBytes) {
        return 'El archivo de backup supera el tamaño permitido '
            '(${_formatBytes(kBackupMaxFileBytes)}).';
      }

      final String content;
      if (bytes != null) {
        if (bytes.lengthInBytes > kBackupMaxFileBytes) {
          return 'El archivo de backup supera el tamaño permitido.';
        }
        content = utf8.decode(bytes);
      } else if (file.path != null) {
        final f = File(file.path!);
        if (f.lengthSync() > kBackupMaxFileBytes) {
          return 'El archivo de backup supera el tamaño permitido.';
        }
        content = await f.readAsString();
      } else {
        return 'No se pudo leer el archivo seleccionado';
      }

      return restoreFromJson(content);
    } on FormatException {
      return 'El archivo seleccionado no es un backup valido.';
    } catch (e) {
      debugPrint('[Backup] import fallo: $e');
      return 'No se pudo leer el archivo seleccionado.';
    }
  }

  /// Restaura datos desde un string JSON.
  ///
  /// Retorna null si el usuario cancelo (validacion fallo), o un mensaje
  /// de error. Retorna string vacio si fue exitoso.
  ///
  /// **Seguridad**: el restore corre dentro de una transaccion Drift: si
  /// cualquier insert falla a mitad de camino, TODA la operacion se revierte
  /// (rollback) y los datos actuales quedan intactos. Nunca queda un estado
  /// intermedio.
  Future<String?> restoreFromJson(String jsonContent) async {
    try {
      // Limite de tamaño sobre el contenido ya deserializado.
      if (jsonContent.length > kBackupMaxFileBytes) {
        return 'El archivo de backup supera el tamaño permitido '
            '(${_formatBytes(kBackupMaxFileBytes)}).';
      }

      final Object? raw;
      try {
        raw = jsonDecode(jsonContent);
      } on FormatException {
        return 'El archivo seleccionado no es un backup valido.';
      }
      if (raw is! Map<String, dynamic>) {
        return 'El archivo seleccionado no es un backup valido.';
      }
      final backup = BackupData.fromJson(raw);

      // Validar estructura, tipos, duplicados y referencias.
      final error = backup.validate();
      if (error != null) {
        return error;
      }

      // Rechazar backups de un schema FUTURO (no sabemos migrar hacia atras).
      // Backups de schema anterior son aceptables: la app migra hacia adelante.
      if (backup.schemaVersion > _db.schemaVersion) {
        return 'Backup de version futura incompatible (schema '
            '${backup.schemaVersion}; la app soporta hasta '
            '${_db.schemaVersion}). Actualiza la app e intenta de nuevo.';
      }

      // Restaurar en transaccion (atomica: fallo parcial => rollback total)
      await _db.transaction(() async {
        await _clearAllData();
        await _insertFilaments(backup.filaments);
        await _insertPrinters(backup.printers);
        await _insertCalculations(backup.calculations);
        await _insertCalculationMaterials(backup.calculationMaterials);
        await _insertSettings(backup.settings);
      });

      return ''; // Exito
    } catch (e) {
      debugPrint('[Backup] restoreFromJson fallo: $e');
      return 'No se pudo restaurar el backup. Tus datos actuales no '
          'fueron modificados.';
    }
  }

  /// Formatea bytes a una unidad legible (KB/MB).
  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  /// Borra toda la data actual (excepto entitlements).
  Future<void> _clearAllData() async {
    await _db.delete(_db.calculationMaterials).go();
    await _db.delete(_db.calculations).go();
    await _db.delete(_db.filaments).go();
    await _db.delete(_db.printers).go();
    await _db.delete(_db.settingsTable).go();
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
              isDefault: Value(row['isDefault'] as bool),
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
              printMinutes: Value(row['printMinutes'] as int),
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
              isTemplate: Value(row['isTemplate'] == 1),
              materialCostSnapshot: Value(
                (row['materialCostSnapshot'] as num?)?.toDouble() ?? 0,
              ),
              electricCostSnapshot: Value(
                (row['electricCostSnapshot'] as num?)?.toDouble() ?? 0,
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
            ),
          );
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
