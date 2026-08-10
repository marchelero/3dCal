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
import 'package:share_plus/share_plus.dart';

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
        text: 'Backup 3dCal',
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
      calculations:
          calculations.map<Map<String, dynamic>>(_rowToMap).toList(),
      calculationMaterials:
          materials.map<Map<String, dynamic>>(_rowToMap).toList(),
      settings: settings.map<Map<String, dynamic>>(_rowToMap).toList(),
    );
  }

  /// Convierte una fila de drift a Map.
  ///
  /// Las clases generadas por drift exponen `toJson()` (NO `toMap()`), que
  /// serializa DateTime a ISO8601 y usa claves camelCase iguales a los
  /// nombres de campo Dart — las mismas que esperan los metodos `_insert*`.
  Map<String, dynamic> _rowToMap(Object row) {
    return (row as dynamic).toJson() as Map<String, dynamic>;
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
      final String content;
      if (bytes != null) {
        content = utf8.decode(bytes);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return 'No se pudo leer el archivo seleccionado';
      }

      return restoreFromJson(content);
    } catch (e) {
      return 'Error al importar: $e';
    }
  }

  /// Restaura datos desde un string JSON.
  ///
  /// Retorna null si el usuario cancelo (validacion fallo), o un mensaje
  /// de error. Retorna string vacio si fue exitoso.
  Future<String?> restoreFromJson(String jsonContent) async {
    try {
      final parsed = jsonDecode(jsonContent) as Map<String, dynamic>;
      final backup = BackupData.fromJson(parsed);

      // Validar
      final error = backup.validate();
      if (error != null) {
        return error;
      }

      // Restaurar en transaccion
      await _db.transaction(() async {
        await _clearAllData();
        await _insertFilaments(backup.filaments);
        await _insertPrinters(backup.printers);
        await _insertCalculations(backup.calculations);
        await _insertCalculationMaterials(backup.calculationMaterials);
        await _insertSettings(backup.settings);
      });

      return ''; // Exito
    } on FormatException catch (e) {
      return 'Archivo de backup invalido: $e';
    } catch (e) {
      return 'Error al restaurar: $e';
    }
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
      await _db.into(_db.filaments).insert(
            FilamentsCompanion(
              id: Value(row['id'] as int),
              name: Value(row['name'] as String),
              brand: Value(row['brand'] as String?),
              pricePerBobbin: Value((row['pricePerBobbin'] as num).toDouble()),
              gramsPerBobbin: Value(
                  (row['gramsPerBobbin'] as num).toDouble()),
              isDefault: Value(row['isDefault'] as bool),
              createdAt: Value(_parseDateTime(row['createdAt'])),
            ),
          );
    }
  }

  /// Inserta impresoras desde el backup.
  Future<void> _insertPrinters(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db.into(_db.printers).insert(
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
      await _db.into(_db.calculations).insert(
            CalculationsCompanion(
              id: Value(row['id'] as int),
              createdAt: Value(_parseDateTime(row['createdAt'])),
              pieceName: Value(row['pieceName'] as String?),
              clientName: Value(row['clientName'] as String?),
              printerId: Value(row['printerId'] as int?),
              printerNameSnapshot: Value(row['printerNameSnapshot'] as String?),
              printerWattsSnapshot: Value(
                  (row['printerWattsSnapshot'] as num).toDouble()),
              totalHours: Value((row['totalHours'] as num).toDouble()),
              printMinutes: Value(row['printMinutes'] as int),
              discountPercentage: Value(
                  (row['discountPercentage'] as num).toDouble()),
              kwhRateSnapshot: Value(
                  (row['kwhRateSnapshot'] as num).toDouble()),
              profitBaseSnapshot: Value(
                  (row['profitBaseSnapshot'] as num).toDouble()),
              isSold: Value(row['isSold'] as bool),
              materialCostSnapshot: Value(
                  (row['materialCostSnapshot'] as num?)?.toDouble() ?? 0),
              electricCostSnapshot: Value(
                  (row['electricCostSnapshot'] as num?)?.toDouble() ?? 0),
              laborCostSnapshot: Value(
                  (row['laborCostSnapshot'] as num?)?.toDouble() ?? 0),
              postProcessCostSnapshot: Value(
                  (row['postProcessCostSnapshot'] as num?)?.toDouble() ?? 0),
              baseCostSnapshot: Value(
                  (row['baseCostSnapshot'] as num?)?.toDouble() ?? 0),
              failureCostSnapshot: Value(
                  (row['failureCostSnapshot'] as num?)?.toDouble() ?? 0),
              markupCostSnapshot: Value(
                  (row['markupCostSnapshot'] as num?)?.toDouble() ?? 0),
              profitAmountSnapshot: Value(
                  (row['profitAmountSnapshot'] as num?)?.toDouble() ?? 0),
              minimumChargeAppliedSnapshot: Value(
                  (row['minimumChargeAppliedSnapshot'] as num?)?.toDouble() ??
                      0),
              effectiveTotalSnapshot: Value(
                  (row['effectiveTotalSnapshot'] as num?)?.toDouble() ?? 0),
              totalPriceSnapshot: Value(
                  (row['totalPriceSnapshot'] as num?)?.toDouble() ?? 0),
              laborRateSnapshot: Value(
                  (row['laborRateSnapshot'] as num?)?.toDouble() ?? 0),
              postProcessRateSnapshot: Value(
                  (row['postProcessRateSnapshot'] as num?)?.toDouble() ?? 0),
              failureRateSnapshot: Value(
                  (row['failureRateSnapshot'] as num?)?.toDouble() ?? 0),
              minimumChargeSnapshot: Value(
                  (row['minimumChargeSnapshot'] as num?)?.toDouble() ?? 0),
              markupOnMaterialsSnapshot: Value(
                  (row['markupOnMaterialsSnapshot'] as num?)?.toDouble() ??
                      0),
            ),
          );
    }
  }

  /// Inserta materiales de cotizaciones desde el backup.
  Future<void> _insertCalculationMaterials(
      List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db.into(_db.calculationMaterials).insert(
            CalculationMaterialsCompanion(
              id: Value(row['id'] as int),
              calculationId: Value(row['calculationId'] as int),
              filamentId: Value(row['filamentId'] as int?),
              label: Value(row['label'] as String),
              weightGrams: Value((row['weightGrams'] as num).toDouble()),
              pricePerBobbinSnapshot: Value(
                  (row['pricePerBobbinSnapshot'] as num).toDouble()),
              gramsPerBobbinSnapshot: Value(
                  (row['gramsPerBobbinSnapshot'] as num).toDouble()),
            ),
          );
    }
  }

  /// Inserta settings desde el backup.
  Future<void> _insertSettings(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _db.into(_db.settingsTable).insert(
            SettingsTableCompanion(
              key: Value(row['key'] as String),
              value: Value(row['value'] as String),
              updatedAt: Value(_parseDateTime(row['updatedAt'])),
            ),
          );
    }
  }

  /// Parsea un string DateTime o retorna la fecha actual como fallback.
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        return DateTime.now().toUtc();
      }
    }
    return DateTime.now().toUtc();
  }
}
