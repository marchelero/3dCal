import 'package:decimal/decimal.dart';

/// Resultado del calculo de cotizacion. Inmutable.
class CalculationOutput {
  /// Construye el resultado. Todos los campos requeridos para garantizar
  /// consistencia con el motor de calculo.
  const CalculationOutput({
    required this.materialCost,
    required this.electricCost,
    required this.baseCost,
    required this.effectiveProfitPercentage,
    required this.profitAmount,
    required this.totalPrice,
  });

  /// Suma de costos de materiales (BOB).
  final Decimal materialCost;

  /// Costo electrico (BOB).
  final Decimal electricCost;

  /// Costo base total = materialCost + electricCost (BOB).
  final Decimal baseCost;

  /// Ganancia efectiva aplicada (%). Puede ser negativa si descuento > 50% con
  /// profitBase < 100%. NO clampeado aca: el caller decide si clampar.
  final Decimal effectiveProfitPercentage;

  /// Monto de ganancia (BOB). Clampeado a 0 si effectiveProfit < 0.
  final Decimal profitAmount;

  /// Precio total final sugerido (BOB) = baseCost + profitAmount.
  final Decimal totalPrice;

  @override
  bool operator ==(Object other) =>
      other is CalculationOutput &&
      materialCost == other.materialCost &&
      electricCost == other.electricCost &&
      baseCost == other.baseCost &&
      effectiveProfitPercentage == other.effectiveProfitPercentage &&
      profitAmount == other.profitAmount &&
      totalPrice == other.totalPrice;

  @override
  int get hashCode => Object.hash(
        materialCost,
        electricCost,
        baseCost,
        effectiveProfitPercentage,
        profitAmount,
        totalPrice,
      );

  @override
  String toString() =>
      'CalculationOutput(baseCost: $baseCost, profitAmount: $profitAmount, '
      'totalPrice: $totalPrice, effProfit: $effectiveProfitPercentage%)';
}
