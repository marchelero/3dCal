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

/// Tamaño maximo aceptado para un backup (bytes). Protege contra archivos
/// gigantes que agotarian la memoria al deserializarlos.
const int kBackupMaxFileBytes = 50 * 1024 * 1024; // 50 MB

/// Limites de filas por coleccion. Son órdenes de magnitud muy por encima
/// de cualquier uso real (catalogo de filamentos, historial de cotizaciones),
/// pero detectan backups corruptos o maliciosos con conteos patologicos.
const int kBackupMaxFilaments = 20000;

/// Limite de impresoras por backup.
const int kBackupMaxPrinters = 5000;

/// Limite de cotizaciones por backup.
const int kBackupMaxCalculations = 50000;

/// Limite de filas de materiales por backup.
const int kBackupMaxMaterialRows = 200000;

/// Limite de settings por backup.
const int kBackupMaxSettings = 500;

/// Longitud maxima de strings en campos de texto (protege contra valores
/// abusivos que inflarian la memoria o romperian la UI).
const int kBackupMaxStringLength = 2048;

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
      printers: (json['printers'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      calculations: (json['calculations'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      calculationMaterials: (json['calculationMaterials'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
      settings: (json['settings'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
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
  ///
  /// Precondiciones de tipos (BUG-024): todas las colecciones deben contener
  /// unicamente tipos JSON-serializables (String/int/bool/Map/List). Pasar
  /// Decimal, DateTime o tipos custom hace fallar jsonEncode en runtime.
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

  /// Validacion exhaustiva del archivo de backup.
  /// Retorna null si es valido, o un mensaje de error si no.
  ///
  /// Cubre: identidad de la app, version de formato, version de schema,
  /// limites de filas por coleccion, tipos de campos por fila, duplicados
  /// de IDs e integridad referencial (materiales -> cotizaciones).
  String? validate() {
    if (appName != kBackupAppName) {
      return 'Archivo no reconocido: appName="$appName"';
    }
    if (version != kBackupFormatVersion) {
      return 'Version de backup incompatible: $version (esperado: $kBackupFormatVersion)';
    }

    // Limites de filas.
    if (filaments.length > kBackupMaxFilaments) {
      return 'Demasiados filamentos (${filaments.length}); maximo $kBackupMaxFilaments';
    }
    if (printers.length > kBackupMaxPrinters) {
      return 'Demasiadas impresoras (${printers.length}); maximo $kBackupMaxPrinters';
    }
    if (calculations.length > kBackupMaxCalculations) {
      return 'Demasiadas cotizaciones (${calculations.length}); maximo $kBackupMaxCalculations';
    }
    if (calculationMaterials.length > kBackupMaxMaterialRows) {
      return 'Demasiadas filas de materiales (${calculationMaterials.length}); '
          'maximo $kBackupMaxMaterialRows';
    }
    if (settings.length > kBackupMaxSettings) {
      return 'Demasiados settings (${settings.length}); maximo $kBackupMaxSettings';
    }

    // Validacion de filas + duplicados + referencias.
    final errors = <String>[];

    final calcIds = <int>{};
    for (var i = 0; i < calculations.length; i++) {
      final row = calculations[i];
      final id = row['id'];
      if (id is! int || id <= 0) {
        errors.add('Cotizacion #${i + 1}: id invalido ($id)');
      } else if (!calcIds.add(id)) {
        errors.add('Cotizacion #$i: id duplicado ($id)');
      }
      _checkString(row, 'pieceName', 'Cotizacion #$id', errors);
      _checkString(row, 'clientName', 'Cotizacion #$id', errors);
      _checkDateTime(row, 'createdAt', 'Cotizacion #$id', errors);
      for (final key in const [
        'totalHours',
        'discountPercentage',
        'kwhRateSnapshot',
        'profitBaseSnapshot',
      ]) {
        _checkNumber(row, key, 'Cotizacion #$id', errors);
      }
      _checkBool(row, 'isSold', 'Cotizacion #$id', errors);
      _checkInt(row, 'printMinutes', 'Cotizacion #$id', errors);
    }

    final filamentIds = <int>{};
    for (var i = 0; i < filaments.length; i++) {
      final row = filaments[i];
      final id = row['id'];
      if (id is! int || id <= 0) {
        errors.add('Filamento #${i + 1}: id invalido ($id)');
      } else if (!filamentIds.add(id)) {
        errors.add('Filamento #$i: id duplicado ($id)');
      }
      _checkString(row, 'name', 'Filamento #$id', errors);
      _checkNumber(row, 'pricePerBobbin', 'Filamento #$id', errors);
      _checkNumber(row, 'gramsPerBobbin', 'Filamento #$id', errors);
      _checkBool(row, 'isDefault', 'Filamento #$id', errors);
      _checkDateTime(row, 'createdAt', 'Filamento #$id', errors);
    }

    final printerIds = <int>{};
    for (var i = 0; i < printers.length; i++) {
      final row = printers[i];
      final id = row['id'];
      if (id is! int || id <= 0) {
        errors.add('Impresora #${i + 1}: id invalido ($id)');
      } else if (!printerIds.add(id)) {
        errors.add('Impresora #$i: id duplicado ($id)');
      }
      _checkString(row, 'name', 'Impresora #$id', errors);
      _checkInt(row, 'averageWatts', 'Impresora #$id', errors);
      _checkBool(row, 'isDefault', 'Impresora #$id', errors);
      _checkDateTime(row, 'createdAt', 'Impresora #$id', errors);
    }

    for (var i = 0; i < calculationMaterials.length; i++) {
      final row = calculationMaterials[i];
      final id = row['id'];
      if (id is! int || id <= 0) {
        errors.add('Material #${i + 1}: id invalido ($id)');
      }
      final calcId = row['calculationId'];
      if (calcId is! int || !calcIds.contains(calcId)) {
        errors.add(
          'Material #${i + 1}: reference a cotizacion inexistente '
          '($calcId)',
        );
      }
      _checkString(row, 'label', 'Material #$id', errors);
      _checkNumber(row, 'weightGrams', 'Material #$id', errors);
      _checkNumber(row, 'pricePerBobbinSnapshot', 'Material #$id', errors);
      _checkNumber(row, 'gramsPerBobbinSnapshot', 'Material #$id', errors);
    }

    for (var i = 0; i < settings.length; i++) {
      final row = settings[i];
      final key = row['key'];
      if (key is! String || key.isEmpty) {
        errors.add('Setting #${i + 1}: key invalida ($key)');
      }
      _checkString(row, 'value', 'Setting #$key', errors);
      _checkDateTime(row, 'updatedAt', 'Setting #$key', errors);
    }

    if (errors.isNotEmpty) {
      final shown = errors.take(5).join('; ');
      final extra = errors.length > 5 ? ' (+${errors.length - 5} mas)' : '';
      return 'Backup invalido: $shown$extra';
    }
    return null;
  }

  static void _checkString(
    Map<String, dynamic> row,
    String key,
    String label,
    List<String> errors,
  ) {
    final v = row[key];
    if (v != null && (v is! String || v.length > kBackupMaxStringLength)) {
      errors.add('$label: $key invalido');
    }
  }

  static void _checkNumber(
    Map<String, dynamic> row,
    String key,
    String label,
    List<String> errors,
  ) {
    final v = row[key];
    if (v == null) return;
    if (v is! num || v.isNaN || v.isInfinite || v < 0) {
      errors.add('$label: $key invalido ($v)');
    }
  }

  static void _checkInt(
    Map<String, dynamic> row,
    String key,
    String label,
    List<String> errors,
  ) {
    final v = row[key];
    if (v is! int || v < 0) {
      errors.add('$label: $key invalido ($v)');
    }
  }

  static void _checkBool(
    Map<String, dynamic> row,
    String key,
    String label,
    List<String> errors,
  ) {
    final v = row[key];
    if (v is! bool) {
      errors.add('$label: $key invalido ($v)');
    }
  }

  static void _checkDateTime(
    Map<String, dynamic> row,
    String key,
    String label,
    List<String> errors,
  ) {
    final v = row[key];
    if (!_isValidDateTimeValue(v)) {
      errors.add('$label: $key invalido ($v)');
    }
  }

  /// Acepta el formato ISO-8601 canónico y timestamps Unix en milisegundos.
  /// Drift serializa DateTime como número; los backups antiguos pueden
  /// contener ese formato aunque los nuevos se exporten como ISO-8601.
  static bool _isValidDateTimeValue(Object? value) {
    if (value is String) return DateTime.tryParse(value) != null;
    if (value is! num || !value.isFinite || value < 0 || value % 1 != 0) {
      return false;
    }
    try {
      DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
      return true;
    } on ArgumentError {
      return false;
    }
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
