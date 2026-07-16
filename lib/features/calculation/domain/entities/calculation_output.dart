import 'package:decimal/decimal.dart';

/// Resultado del calculo de cotizacion. Inmutable.
///
/// Formula:
///   materialCost = Σ(weight * pricePerBobbin / gramsPerBobbin)
///   discountAmount = materialCost * (discountPercentage / 100)
///   totalPrice = materialCost - discountAmount
class CalculationOutput {
  const CalculationOutput({
    required this.materialCost,
    required this.discountAmount,
    required this.totalPrice,
  });

  /// Suma de costos de materiales (BOB).
  final Decimal materialCost;

  /// Monto de descuento (BOB).
  final Decimal discountAmount;

  /// Precio total final (BOB) = materialCost - discountAmount.
  final Decimal totalPrice;

  @override
  bool operator ==(Object other) =>
      other is CalculationOutput &&
      materialCost == other.materialCost &&
      discountAmount == other.discountAmount &&
      totalPrice == other.totalPrice;

  @override
  int get hashCode => Object.hash(materialCost, discountAmount, totalPrice);

  @override
  String toString() =>
      'CalculationOutput(materialCost: $materialCost, '
      'discountAmount: $discountAmount, totalPrice: $totalPrice)';
}
