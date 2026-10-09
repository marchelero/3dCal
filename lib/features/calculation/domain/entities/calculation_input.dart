// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';

import 'material_input.dart';

/// Modo de cobro de un campo de servicio (v17).
///
/// - [serviceCostAuto] (solo modelado / postprocesado): replica la formula
///   legacy pre-v17 (`hours * rate` para modelado,
///   `materialCost * rate / 100` para postprocesado).
/// - [serviceCostOff] (solo extras): no se cobra nada.
/// - [serviceCostPct]: el campo se calcula como porcentaje sobre `coreBase`
///   (material + electric).
/// - [serviceCostFixed]: el campo se cobra como monto fijo en moneda local.
class ServiceCostMode {
  const ServiceCostMode._(this.value);

  final String value;

  static const ServiceCostMode auto = ServiceCostMode._('auto');
  static const ServiceCostMode off = ServiceCostMode._('off');
  static const ServiceCostMode pct = ServiceCostMode._('pct');
  static const ServiceCostMode fixed = ServiceCostMode._('fixed');

  bool get isPct => this == pct;
  bool get isFixed => this == fixed;
  bool get isAuto => this == auto;
  bool get isOff => this == off;
  bool get isActive => isPct || isFixed;

  static ServiceCostMode parse(String? raw) {
    switch (raw) {
      case 'pct':
        return pct;
      case 'fixed':
        return fixed;
      case 'off':
        return off;
      default:
        return auto;
    }
  }

  /// Comparacion por `value` (string). La igualdad por referencia sigue
  /// funcionando para los singletons de arriba (auto/off/pct/fixed son
  /// la misma instancia siempre).
  @override
  bool operator ==(Object other) =>
      other is ServiceCostMode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Inputs para el motor de calculo. Inmutable.
///
/// Reglas de validacion:
/// - [materials] puede estar vacio (costo material = 0).
/// - [totalHours] >= 0.
/// - [discountPercentage] >= 0.
/// - Los parametros de settings (laborRate, postProcessRate, etc.) se pasan
///   desde el notifier y tienen defaults a 0 (sin efecto).
///
/// Formula completa (v17):
///   coreBase = material + electric
///   (F5 amortizacion EXCLUIDA del costo: no afecta el total ni los
///    reportes; purchaseCost/usefulLifeHours son solo datos de catalogo)
///   modelado = resolveService(modelingMode, coreBase, modelingRate,
///               modelingFixedAmount, hours, laborRate)
///   postProc = resolveService(postprocMode, coreBase, postprocRate,
///               postprocFixedAmount, materialCost, postProcessRate)
///   extras   = resolveExtras(extraCostMode, coreBase, extraCostAmount)
///   baseCost = coreBase + modelado + postProc + extras
///   failureCost = baseCost * failureRate / 100
///   markupCost  = materialCost * markupOnMaterials / 100
///   totalBeforeProfit = baseCost + failureCost + markupCost
///   profitAmount = totalBeforeProfit * profitBase / 100
///   totalFinal = totalBeforeProfit + profitAmount
///   discountAmount = totalFinal * discountPercentage / 100
///   totalPrice = max(totalFinal - discountAmount, minimumCharge)
class CalculationInput {
  CalculationInput({
    required this.materials,
    required this.totalHours,
    required this.discountPercentage,
    this.printerWatts = 0,
    required this.kwhRate,
    required this.profitBase,
    required this.laborRate,
    required this.postProcessRate,
    required this.failureRate,
    required this.markupOnMaterials,
    this.amortizationPerHour,
    Decimal? minimumCharge,
    // === v17: overrides per-cotizacion de los 3 campos de servicio ===
    // Default `auto` para modelado y postprocesado replica la formula
    // legacy; `off` para extras significa "no se cobra nada". Tests
    // existentes que no pasan estos parametros siguen produciendo el mismo
    // calculo (los campos en `pct`/`fixed` con valor 0 no aportan).
    this.modelingMode = ServiceCostMode.auto,
    Decimal? modelingPct,
    Decimal? modelingFixed,
    this.postprocMode = ServiceCostMode.auto,
    Decimal? postprocPct,
    Decimal? postprocFixed,
    this.extraCostMode = ServiceCostMode.off,
    Decimal? extraCostPct,
    Decimal? extraCostFixed,
  }) : minimumCharge = minimumCharge ?? Decimal.zero,
       modelingPct = modelingPct ?? Decimal.zero,
       modelingFixed = modelingFixed ?? Decimal.zero,
       postprocPct = postprocPct ?? Decimal.zero,
       postprocFixed = postprocFixed ?? Decimal.zero,
       extraCostPct = extraCostPct ?? Decimal.zero,
       extraCostFixed = extraCostFixed ?? Decimal.zero;

  /// Lista de materiales (puede ser vacia).
  final List<MaterialInput> materials;

  /// Tiempo total de impresion (horas).
  final Decimal totalHours;

  /// Descuento comercial (%). 0 permitido.
  final Decimal discountPercentage;

  /// Watts promedio de la impresora.
  final int printerWatts;

  /// Tarifa electrica (BOB/kWh).
  final Decimal kwhRate;

  /// Ganancia base (%).
  final Decimal profitBase;

  /// Tarifa de mano de obra (BOB/hora).
  final Decimal laborRate;

  /// Tasa de post-procesado (% del costo de materiales).
  final Decimal postProcessRate;

  /// Tasa de falla (% del costo base).
  final Decimal failureRate;

  /// Markup por desperdicio (% del costo de materiales).
  final Decimal markupOnMaterials;

  /// Amortizacion de la impresora (BOB/hora). Null = sin linea
  /// (impresora sin costo/vida util configurados).
  final Decimal? amortizationPerHour;

  /// Cargo minimo por cotizacion (BOB). Piso del precio FINAL: si
  /// `totalFinal - discountAmount` queda por debajo, sube a [minimumCharge].
  /// `Decimal.zero` (default) = sin efecto.
  final Decimal minimumCharge;

  // === v17: 3 campos de servicio con modo % / fijo ===

  /// Modo del campo "Modelado y diseño". Default [ServiceCostMode.auto]
  /// reproduce la formula legacy (`hours * laborRate`).
  final ServiceCostMode modelingMode;

  /// Porcentaje (sobre `coreBase`) cuando [modelingMode] es `pct`.
  final Decimal modelingPct;

  /// Monto fijo cuando [modelingMode] es `fixed`.
  final Decimal modelingFixed;

  /// Modo del campo "Postprocesado". Default [ServiceCostMode.auto]
  /// reproduce la formula legacy (`materialCost * postProcessRate / 100`).
  final ServiceCostMode postprocMode;

  /// Porcentaje (sobre `coreBase`) cuando [postprocMode] es `pct`.
  final Decimal postprocPct;

  /// Monto fijo cuando [postprocMode] es `fixed`.
  final Decimal postprocFixed;

  /// Modo del campo "Extras" (argollas, pegamento, etc.). Default
  /// [ServiceCostMode.off] = no se cobra nada.
  final ServiceCostMode extraCostMode;

  /// Porcentaje (sobre `coreBase`) cuando [extraCostMode] es `pct`.
  final Decimal extraCostPct;

  /// Monto fijo cuando [extraCostMode] es `fixed`.
  final Decimal extraCostFixed;
}
