import 'package:decimal/decimal.dart';

import 'entities/calculation_input.dart';
import 'entities/calculation_output.dart';
import 'entities/material_input.dart';

/// Motor de calculo de cotizaciones. **Pure Dart, sin dependencias de Flutter**.
///
/// Formula completa (F1):
///
///   materialCost       = Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i])
///   electricCost       = printerWatts * totalHours * kwhRate / 1000
///   laborCost          = totalHours * laborRate
///   postProcessCost    = materialCost * postProcessRate / 100
///   baseCost           = materialCost + electricCost + laborCost + postProcessCost
///   failureCost        = baseCost * failureRate / 100
///   costWithFailure    = baseCost + failureCost
///   markupCost         = materialCost * markupOnMaterials / 100
///   totalBeforeProfit  = costWithFailure + markupCost
///   profitAmount       = totalBeforeProfit * profitBase / 100
///   totalFinal         = totalBeforeProfit + profitAmount
///   discountAmount     = totalFinal * discountPercentage / 100
///   totalPrice         = totalFinal - discountAmount
///
/// **Reglas de borde**:
/// - Si no hay materiales, `materialCost = 0`.
/// - Si `discountPercentage = 0`, `discountAmount = 0`.
/// - Si descuento > 100%, `totalPrice` quedaria negativo (caso borde, se
///   preserva para que la UI lo maneje).
/// - Todos los parametros con default 0 no afectan el calculo.
///
/// **Precision**: todo en `Decimal`. Prohibido `double` en este archivo.
class CalculationEngine {
  const CalculationEngine._();

  /// Divisor para pasar de % a fraccion.
  static final Decimal _pct = Decimal.fromInt(100);

  /// Calcula la salida financiera para los [input] dados.
  static CalculationOutput compute(CalculationInput input) {
    final materialCost = _sumMaterialCost(input.materials);

    // Electricidad
    final electricCost = input.printerWatts > 0 && input.totalHours > Decimal.zero
        ? (Decimal.fromInt(input.printerWatts) *
                input.totalHours *
                input.kwhRate /
                Decimal.fromInt(1000))
            .toDecimal()
        : Decimal.zero;

    // Mano de obra
    final laborCost = input.totalHours * input.laborRate;

    // Post-procesado (% del costo de materiales)
    final postProcessCost = input.postProcessRate > Decimal.zero
        ? (materialCost * input.postProcessRate / _pct).toDecimal()
        : Decimal.zero;

    // Base
    final baseCost = materialCost + electricCost + laborCost + postProcessCost;

    // Tasa de falla (% del base)
    final failureCost = input.failureRate > Decimal.zero
        ? (baseCost * input.failureRate / _pct).toDecimal()
        : Decimal.zero;
    final costWithFailure = baseCost + failureCost;

    // Markup sobre materiales
    final markupCost = input.markupOnMaterials > Decimal.zero
        ? (materialCost * input.markupOnMaterials / _pct).toDecimal()
        : Decimal.zero;
    final totalBeforeProfit = costWithFailure + markupCost;

    // Ganancia
    final profitAmount = input.profitBase > Decimal.zero
        ? (totalBeforeProfit * input.profitBase / _pct).toDecimal()
        : Decimal.zero;
    final totalFinal = totalBeforeProfit + profitAmount;

    // Descuento
    final discountAmount = input.discountPercentage > Decimal.zero
        ? (totalFinal * input.discountPercentage / _pct).toDecimal()
        : Decimal.zero;
    final totalPrice = totalFinal - discountAmount;

    return CalculationOutput(
      materialCost: materialCost,
      electricCost: electricCost,
      laborCost: laborCost,
      postProcessCost: postProcessCost,
      baseCost: baseCost,
      failureCost: failureCost,
      costWithFailure: costWithFailure,
      markupCost: markupCost,
      totalBeforeProfit: totalBeforeProfit,
      profitAmount: profitAmount,
      totalFinal: totalFinal,
      discountAmount: discountAmount,
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
}
