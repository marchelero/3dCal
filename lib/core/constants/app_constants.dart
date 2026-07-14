/// Constantes globales de la aplicacion tresdcal.
///
/// Single source of truth para valores que se usan en multiples lugares.
library;

/// Organizacion del paquete (declarada en pubspec.yaml `name`).
const String kPackageName = 'bo.3dcal.tresdcal';

/// Codigo de moneda por defecto. BOB unico MVP.
const String kCurrencyCode = 'BOB';

/// Simbolo visible: "Bs." segun convencion boliviana.
const String kCurrencySymbol = 'Bs.';

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
}
