import 'package:decimal/decimal.dart';

import 'material_input.dart';

/// Inputs para el motor de calculo. Inmutable.
///
/// Reglas de validacion:
/// - [materials] puede estar vacio (costo material = 0).
/// - [totalHours] >= 0.
/// - [discountPercentage] >= 0.
/// - Los parametros de settings (laborRate, postProcessRate, etc.) se pasan
///   desde el notifier y tienen defaults a 0 (sin efecto).
///
/// Formula completa:
///   materialCost = Σ(weightGrams * pricePerBobbin / gramsPerBobbin)
///   electricCost = printerWatts * totalHours * kwhRate / 1000
///   laborCost = totalHours * laborRate
///   postProcessCost = materialCost * postProcessRate / 100
///   baseCost = materialCost + electricCost + laborCost + postProcessCost
///   failureCost = baseCost * failureRate / 100
///   costWithFailure = baseCost + failureCost
///   markupCost = materialCost * markupOnMaterials / 100
///   totalBeforeProfit = costWithFailure + markupCost
///   profitAmount = totalBeforeProfit * profitBase / 100
///   totalFinal = totalBeforeProfit + profitAmount
///   discountAmount = totalFinal * discountPercentage / 100
///   totalPrice = totalFinal - discountAmount
class CalculationInput {
  const CalculationInput({
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
  });

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
}
