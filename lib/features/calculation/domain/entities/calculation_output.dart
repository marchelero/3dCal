import 'package:decimal/decimal.dart';

/// Resultado del calculo de cotizacion. Inmutable.
///
/// Formula completa:
///   materialCost = Σ(weight * pricePerBobbin / gramsPerBobbin)
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
class CalculationOutput {
  const CalculationOutput({
    required this.materialCost,
    required this.electricCost,
    required this.laborCost,
    required this.postProcessCost,
    required this.baseCost,
    required this.failureCost,
    required this.costWithFailure,
    required this.markupCost,
    required this.totalBeforeProfit,
    required this.profitAmount,
    required this.totalFinal,
    required this.discountAmount,
    required this.totalPrice,
  });

  /// Suma de costos de materiales (BOB).
  final Decimal materialCost;

  /// Costo de energia electrica (BOB).
  final Decimal electricCost;

  /// Costo de mano de obra (BOB).
  final Decimal laborCost;

  /// Costo de post-procesado (BOB).
  final Decimal postProcessCost;

  /// Costo base = materialCost + electricCost + laborCost + postProcessCost.
  final Decimal baseCost;

  /// Costo por tasa de falla (BOB).
  final Decimal failureCost;

  /// Costo base con falla = baseCost + failureCost.
  final Decimal costWithFailure;

  /// Markup por desperdicio de materiales (BOB).
  final Decimal markupCost;

  /// Total antes de ganancia = costWithFailure + markupCost.
  final Decimal totalBeforeProfit;

  /// Monto de ganancia (BOB).
  final Decimal profitAmount;

  /// Total final = totalBeforeProfit + profitAmount (antes de descuento).
  final Decimal totalFinal;

  /// Monto de descuento (BOB).
  final Decimal discountAmount;

  /// Precio total final (BOB) = totalFinal - discountAmount.
  final Decimal totalPrice;

  /// Crea un output simplificado cuando no hay parametros de settings
  /// (todos los extras en 0). Equivalente a la formula MVP.
  factory CalculationOutput.simple({
    required Decimal materialCost,
    required Decimal discountAmount,
    required Decimal totalPrice,
  }) {
    return CalculationOutput(
      materialCost: materialCost,
      electricCost: Decimal.zero,
      laborCost: Decimal.zero,
      postProcessCost: Decimal.zero,
      baseCost: materialCost,
      failureCost: Decimal.zero,
      costWithFailure: materialCost,
      markupCost: Decimal.zero,
      totalBeforeProfit: materialCost,
      profitAmount: Decimal.zero,
      totalFinal: materialCost,
      discountAmount: discountAmount,
      totalPrice: totalPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CalculationOutput &&
      materialCost == other.materialCost &&
      electricCost == other.electricCost &&
      laborCost == other.laborCost &&
      postProcessCost == other.postProcessCost &&
      baseCost == other.baseCost &&
      failureCost == other.failureCost &&
      costWithFailure == other.costWithFailure &&
      markupCost == other.markupCost &&
      totalBeforeProfit == other.totalBeforeProfit &&
      profitAmount == other.profitAmount &&
      totalFinal == other.totalFinal &&
      discountAmount == other.discountAmount &&
      totalPrice == other.totalPrice;

  @override
  int get hashCode => Object.hash(
        materialCost,
        electricCost,
        laborCost,
        postProcessCost,
        baseCost,
        failureCost,
        costWithFailure,
        markupCost,
        totalBeforeProfit,
        profitAmount,
        totalFinal,
        discountAmount,
        totalPrice,
      );

  @override
  String toString() =>
      'CalculationOutput('
      'materialCost: $materialCost, '
      'electricCost: $electricCost, '
      'laborCost: $laborCost, '
      'postProcessCost: $postProcessCost, '
      'baseCost: $baseCost, '
      'failureCost: $failureCost, '
      'costWithFailure: $costWithFailure, '
      'markupCost: $markupCost, '
      'totalBeforeProfit: $totalBeforeProfit, '
      'profitAmount: $profitAmount, '
      'totalFinal: $totalFinal, '
      'discountAmount: $discountAmount, '
      'totalPrice: $totalPrice)';
}
