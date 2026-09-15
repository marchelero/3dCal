import 'package:decimal/decimal.dart';

import 'entities/calculation_input.dart';
import 'entities/calculation_output.dart';
import 'entities/material_input.dart';

/// Motor de calculo de cotizaciones. **Pure Dart, sin dependencias de Flutter**.
///
/// Formula completa (sin amortizacion en costo):
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
///   totalPrice         = max(totalFinal - discountAmount, minimumCharge)
///
/// **Reglas de borde**:
/// - Si no hay materiales, `materialCost = 0`.
/// - Si `discountPercentage = 0`, `discountAmount = 0`.
/// - Si descuento > 100%, `totalPrice` quedaria negativo (caso borde, se
///   preserva para que la UI lo maneje).
/// - Todos los parametros con default 0 no afectan el calculo.
/// - `minimumCharge > 0`: piso del precio final (despues del descuento).
///   Si el precio queda por debajo, sube a `minimumCharge`. Con
///   `minimumCharge = 0` no hay efecto.
///
/// **Nota**: `amortizationPerHour` existe para estadisticas/depreciacion,
/// pero NO se incluye en el costo de la cotizacion.
///
/// **Precision**: todo en `Decimal`. Prohibido `double` en este archivo.
class CalculationEngine {
  const CalculationEngine._();

  /// Divisor para pasar de % a fraccion.
  static final Decimal _pct = Decimal.fromInt(100);

  /// Amortizacion fija por hora de la impresora (para estadisticas).
  ///
  /// `costo / vida_util_horas`, escala interna 6. Retorna `null` si la vida
  /// util es <= 0 o el costo no es positivo. NO se incluye en el costo
  /// de la cotizacion, solo se usa para metricas de depreciacion.
  static Decimal? amortizationPerHour({
    required Decimal purchaseCost,
    required int usefulLifeHours,
  }) {
    if (usefulLifeHours <= 0 || purchaseCost <= Decimal.zero) return null;
    return (purchaseCost / Decimal.fromInt(usefulLifeHours)).toDecimal(
      scaleOnInfinitePrecision: 6,
    );
  }

  /// Calcula la salida financiera para los [input] dados.
  static CalculationOutput compute(CalculationInput input) {
    final materialCost = _sumMaterialCost(input.materials);

    // Electricidad
    final electricCost =
        input.printerWatts > 0 && input.totalHours > Decimal.zero
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

    // Base (sin amortizacion — la amortizacion es solo para estadisticas)
    final baseCost =
        materialCost +
        electricCost +
        laborCost +
        postProcessCost;

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

    // Cargo minimo: piso del precio FINAL (despues del descuento). Si el
    // precio queda por debajo del piso, sube a minimumCharge. Guard en
    // `minimumCharge > 0` para que el default no altere el caso borde de
    // total negativo por descuento > 100%.
    final totalAfterDiscount = totalFinal - discountAmount;
    final totalPrice =
        input.minimumCharge > Decimal.zero &&
            totalAfterDiscount < input.minimumCharge
        ? input.minimumCharge
        : totalAfterDiscount;

    return CalculationOutput(
      materialCost: materialCost,
      electricCost: electricCost,
      amortizationCost: Decimal.zero, // Solo para estadisticas, no en costo
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
      totalOriginal: totalFinal,
    );
  }

  /// Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i]).
  ///
  /// BUG-009 fix: salta materiales con `gramsPerBobbin <= 0` o
  /// `weightGrams <= 0` para evitar division por cero (NaN/Infinity)
  /// cuando llega un material corrupto desde un draft legacy o un
  /// backup malformado.
  static Decimal _sumMaterialCost(List<MaterialInput> materials) {
    var total = Decimal.zero;
    for (final m in materials) {
      if (m.gramsPerBobbin <= Decimal.zero) continue;
      if (m.weightGrams <= Decimal.zero) continue;
      total += m.weightGrams * m.pricePerGram;
    }
    return total;
  }
}
