import 'package:decimal/decimal.dart';

import 'entities/calculation_input.dart';
import 'entities/calculation_output.dart';
import 'entities/material_input.dart';

/// Motor de calculo de cotizaciones. **Pure Dart, sin dependencias de Flutter**.
///
/// Implementa las formulas del PRD seccion 7:
///
///   materialCost  = Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i])
///   electricCost  = totalHours * (printerWatts / 1000) * kwhRate
///   baseCost      = materialCost + electricCost
///   effProfit     = profitBasePercentage - (discountPercentage * 2)
///   profitAmount  = baseCost * (effProfit / 100), clampeado a >= 0
///   totalPrice    = baseCost + profitAmount
///
/// **Reglas de borde**:
/// - Si `effProfit < 0`, `profitAmount` se clampea a 0 (no se vende a perdida).
///   El valor de `effProfit` se preserva en el output para que la UI muestre
///   la advertencia.
/// - Si no hay materiales, `materialCost = 0`.
/// - Si `printerWatts = 0`, `electricCost = 0`.
///
/// **Precision**: todo en `Decimal`. Prohibido `double` en este archivo.
class CalculationEngine {
  const CalculationEngine._();

  /// Penalizacion: cada 1% de descuento resta 2% al profit base.
  static final Decimal _discountPenaltyMultiplier = Decimal.fromInt(2);

  /// Divisor para convertir Watts a kW.
  static final Decimal _wattsToKw = Decimal.fromInt(1000);

  /// Divisor para pasar de % a fraccion.
  static final Decimal _percentToFraction = Decimal.fromInt(100);

  /// Calcula la salida financiera para los [input] dados.
  static CalculationOutput compute(CalculationInput input) {
    final materialCost = _sumMaterialCost(input.materials);
    final electricCost = _computeElectricCost(
      totalHours: input.totalHours,
      printerWatts: input.printerWatts,
      kwhRate: input.kwhRate,
    );
    final baseCost = materialCost + electricCost;

    final effectiveProfit = _computeEffectiveProfit(
      profitBase: input.profitBasePercentage,
      discount: input.discountPercentage,
    );

    // Clamp profit a 0 si effProfit < 0 (no se vende a perdida).
    final profitAmount = effectiveProfit < Decimal.zero
        ? Decimal.zero
        : baseCost * (effectiveProfit / _percentToFraction).toDecimal();

    final totalPrice = baseCost + profitAmount;

    return CalculationOutput(
      materialCost: materialCost,
      electricCost: electricCost,
      baseCost: baseCost,
      effectiveProfitPercentage: effectiveProfit,
      profitAmount: profitAmount,
      totalPrice: totalPrice,
    );
  }

  /// Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i]).
  static Decimal _sumMaterialCost(List<MaterialInput> materials) {
    var total = Decimal.zero;
    for (final m in materials) {
      total += m.weightGrams * m.pricePerGram;
    }
    return total;
  }

  /// totalHours * (printerWatts / 1000) * kwhRate.
  static Decimal _computeElectricCost({
    required Decimal totalHours,
    required Decimal printerWatts,
    required Decimal kwhRate,
  }) {
    if (printerWatts <= Decimal.zero || totalHours <= Decimal.zero) {
      return Decimal.zero;
    }
    final kw = (printerWatts / _wattsToKw).toDecimal();
    return totalHours * kw * kwhRate;
  }

  /// profitBase - (discount * 2).
  ///
  /// **No clampeado**: el caller (compute) clampea profitAmount a 0 si este
  /// valor es negativo, pero el valor original se preserva en el output.
  static Decimal _computeEffectiveProfit({
    required Decimal profitBase,
    required Decimal discount,
  }) {
    final penalty = discount * _discountPenaltyMultiplier;
    return profitBase - penalty;
  }
}
