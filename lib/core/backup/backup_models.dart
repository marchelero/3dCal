/// Modelos de datos para backup/restore.
///
/// Estructura del archivo JSON exportado:
/// ```json
/// {
///   "version": 1,
///   "schemaVersion": 5,
///   "exportedAt": "2026-08-10T12:00:00Z",
///   "appName": "3dCal",
///   "filaments": [...],
///   "printers": [...],
///   "calculations": [...],
///   "calculationMaterials": [...],
///   "settings": [...]
/// }
/// ```
///
/// **Nota**: los entitlements (RevenueCat) NO se exportan — son estado
/// vinculado a la cuenta del store, no a los datos locales del usuario.
library;

/// Version actual del formato de backup. Incrementar si cambia la estructura.
const int kBackupFormatVersion = 1;

/// Nombre esperado en el archivo de backup para validacion.
const String kBackupAppName = '3dCal';

/// Datos completos de un backup.
class BackupData {
  /// Crea un objeto BackupData con todos los campos requeridos.
  const BackupData({
    required this.version,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appName,
    required this.filaments,
    required this.printers,
    required this.calculations,
    required this.calculationMaterials,
    required this.settings,
  });

  /// Deserializa desde JSON. Lanza [FormatException] si falta un campo
  /// requerido o el formato es invalido.
  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int,
      schemaVersion: json['schemaVersion'] as int,
      exportedAt: json['exportedAt'] as String,
      appName: json['appName'] as String,
      filaments: (json['filaments'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      printers:
          (json['printers'] as List<dynamic>).cast<Map<String, dynamic>>(),
      calculations: (json['calculations'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      calculationMaterials: (json['calculationMaterials'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      settings:
          (json['settings'] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }

  /// Version del formato de backup.
  final int version;

  /// Schema version de drift al momento del export.
  final int schemaVersion;

  /// Fecha de export en ISO 8601 UTC.
  final String exportedAt;

  /// Nombre de la app (validacion de integridad).
  final String appName;

  /// Filamentos del catalogo.
  final List<Map<String, dynamic>> filaments;

  /// Impresoras del catalogo.
  final List<Map<String, dynamic>> printers;

  /// Cotizaciones (padre).
  final List<Map<String, dynamic>> calculations;

  /// Materiales de cada cotizacion (hijo).
  final List<Map<String, dynamic>> calculationMaterials;

  /// Settings globales (key-value).
  final List<Map<String, dynamic>> settings;

  /// Serializa a JSON para escritura a archivo.
  Map<String, dynamic> toJson() => {
        'version': version,
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt,
        'appName': appName,
        'filaments': filaments,
        'printers': printers,
        'calculations': calculations,
        'calculationMaterials': calculationMaterials,
        'settings': settings,
      };

  /// Validacion basica del archivo de backup.
  /// Retorna null si es valido, o un mensaje de error si no.
  String? validate() {
    if (appName != kBackupAppName) {
      return 'Archivo no reconocido: appName="$appName"';
    }
    if (version != kBackupFormatVersion) {
      return 'Version de backup incompatible: $version (esperado: $kBackupFormatVersion)';
    }
    return null;
  }

  /// Conteo resumido para el dialog de confirmacion.
  BackupSummary get summary => BackupSummary(
        filamentCount: filaments.length,
        printerCount: printers.length,
        calculationCount: calculations.length,
        materialRowCount: calculationMaterials.length,
        settingCount: settings.length,
      );
}

/// Resumen de cantidades en un backup.
class BackupSummary {
  /// Crea un resumen con los conteos de cada tipo de dato.
  const BackupSummary({
    required this.filamentCount,
    required this.printerCount,
    required this.calculationCount,
    required this.materialRowCount,
    required this.settingCount,
  });

  /// Cantidad de filamentos en el backup.
  final int filamentCount;

  /// Cantidad de impresoras en el backup.
  final int printerCount;

  /// Cantidad de cotizaciones en el backup.
  final int calculationCount;

  /// Cantidad de filas de materiales en el backup.
  final int materialRowCount;

  /// Cantidad de settings en el backup.
  final int settingCount;

  /// Describe el resumen en formato legible.
  String describe() {
    final parts = <String>[];
    if (filamentCount > 0) parts.add('$filamentCount filamentos');
    if (printerCount > 0) parts.add('$printerCount impresoras');
    if (calculationCount > 0) parts.add('$calculationCount cotizaciones');
    if (parts.isEmpty) return 'Sin datos';
    return parts.join(', ');
  }
}
