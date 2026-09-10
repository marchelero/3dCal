import 'package:decimal/decimal.dart';

import 'entities/calculation_input.dart';
import 'entities/calculation_output.dart';
import 'entities/material_input.dart';

/// Motor de calculo de cotizaciones. **Pure Dart, sin dependencias de Flutter**.
///
/// Formula completa (F1 + F5 amortizacion):
///
///   materialCost       = Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i])
///   electricCost       = printerWatts * totalHours * kwhRate / 1000
///   amortizationCost   = amortizationPerHour * totalHours
///   laborCost          = totalHours * laborRate
///   postProcessCost    = materialCost * postProcessRate / 100
///   baseCost           = materialCost + electricCost + amortizationCost + laborCost + postProcessCost
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
/// - `amortizationPerHour` null → sin linea (impresora sin costo/vida util).
/// - `minimumCharge > 0`: piso del precio final (despues del descuento).
///   Si el precio queda por debajo, sube a `minimumCharge`. Con
///   `minimumCharge = 0` no hay efecto.
///
/// **Precision**: todo en `Decimal`. Prohibido `double` en este archivo.
class CalculationEngine {
  const CalculationEngine._();

  /// Divisor para pasar de % a fraccion.
  static final Decimal _pct = Decimal.fromInt(100);

  /// Amortizacion fija por hora de la impresora (F5).
  ///
  /// `costo / vida_util_horas`, escala interna 6. Retorna `null` si la vida
  /// util es <= 0 o el costo no es positivo (linea ausente, sin division
  /// por cero). El display redondea a 2 decimales en la UI.
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

    // Amortizacion de la impresora (F5): costo fijo por hora.
    // `Decimal * Decimal` ya da Decimal; solo la division del helper
    // necesita escala explicita (scaleOnInfinitePrecision: 6).
    final amortizationCost =
        input.amortizationPerHour != null && input.totalHours > Decimal.zero
        ? input.amortizationPerHour! * input.totalHours
        : Decimal.zero;

    // Mano de obra
    final laborCost = input.totalHours * input.laborRate;

    // Post-procesado (% del costo de materiales)
    final postProcessCost = input.postProcessRate > Decimal.zero
        ? (materialCost * input.postProcessRate / _pct).toDecimal()
        : Decimal.zero;

    // Base
    final baseCost =
        materialCost +
        electricCost +
        amortizationCost +
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
      amortizationCost: amortizationCost,
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
