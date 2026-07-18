/// Constantes globales de la aplicacion tresdcal.
///
/// Single source of truth para valores que se usan en multiples lugares.
library;

/// Organizacion del paquete (declarada en pubspec.yaml `name`).
const String kPackageName = 'bo.3dcal.tresdcal';

/// Codigo de moneda por defecto. USD default.
const String kCurrencyCode = 'USD';

/// Simbolo visible: "$" segun convencion.
const String kCurrencySymbol = r'$';

/// Separador de miles: "." (formato es_BO).
const String kThousandsSeparator = '.';

/// Separador decimal: "," (formato es_BO).
const String kDecimalSeparator = ',';

/// Ganancia base global por defecto (200%).
/// Cada 1% de descuento comercial reduce este margen en 2 puntos.
const double kDefaultProfitBasePercentage = 200;

/// Tarifa electrica por defecto en BOB/kWh.
/// Rango residencial Bolivia: 0.60 - 0.80 BOB/kWh.
const double kDefaultKwhRate = 0.7;

/// Tarifa de mano de obra por defecto (BOB/hora).
/// Costo de operador/tecnico por hora de impresion.
const double kDefaultLaborRate = 0;

/// Tasa de post-procesado por defecto (% del costo de materiales).
const double kDefaultPostProcessRate = 0;

/// Tasa de falla por defecto (% del costo base).
const double kDefaultFailureRate = 0;

/// Cargo minimo por defecto (BOB).
const double kDefaultMinimumCharge = 0;

/// Markup por desperdicio por defecto (% del costo de materiales).
const double kDefaultMarkupOnMaterials = 0;

/// Limite maximo de materiales simultaneos en una cotizacion.
/// Defensive limit (no es limitacion del motor).
const int kMaxMaterialsPerCalculation = 10;

/// Limite maximo de descuento permitido (50%).
/// Por encima de esto la penalizacion 2x vaciaria la ganancia.
const int kMaxDiscountPercentage = 50;

/// Precision decimal para formateo final (2 lugares).
const int kCurrencyDecimalPlaces = 2;

/// Nombre del almacen de settings persistidos.
const String kSettingsStoreName = 'tresdcal_settings';

/// Claves de settings (key-value store).
class SettingsKeys {
  const SettingsKeys._();

  /// Ganancia base global (% como double).
  static const String profitBasePercentage = 'profit_base_percentage';

  /// Tarifa electrica (BOB/kWh como double).
  static const String kwhRate = 'kwh_rate';

  /// Nombre de la empresa/negocio (string).
  static const String companyName = 'company_name';

  /// Logo de la empresa en base64 (string). Null si no configurado.
  static const String companyLogo = 'company_logo';

  // === F1: Mano de obra + Post-procesado ===

  /// Tarifa de mano de obra (BOB/hora como double).
  static const String laborRate = 'labor_rate';

  /// Tasa de post-procesado (% del costo de materiales como double).
  static const String postProcessRate = 'post_process_rate';

  /// Tasa de falla (% del costo base como double).
  static const String failureRate = 'failure_rate';

  /// Cargo minimo por cotizacion (BOB como double).
  static const String minimumCharge = 'minimum_charge';

  /// Markup por desperdicio de materiales (% del costo de materiales como double).
  static const String markupOnMaterials = 'markup_on_materials';

  // === F4: Moneda ===

  /// Codigo ISO 4217 de la moneda activa: USD, BOB, EUR...
  static const String currencyCode = 'currency_code';
}
