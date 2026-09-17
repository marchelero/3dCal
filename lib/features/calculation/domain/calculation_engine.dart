import 'package:decimal/decimal.dart';

import 'entities/calculation_input.dart';
import 'entities/calculation_output.dart';
import 'entities/material_input.dart';

/// Datos de un material guardado en DB (snapshot).
///
/// Usado por [CalculationEngine.computeFromSnapshot] para reconstruir el
/// costo por material desde los datos persistidos.
class MaterialSnapshot {
  const MaterialSnapshot({
    required this.weightGrams,
    required this.pricePerBobbinSnapshot,
    required this.gramsPerBobbinSnapshot,
  });

  final double weightGrams;
  final double pricePerBobbinSnapshot;
  final double gramsPerBobbinSnapshot;
}

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

  /// Reconstruye [CalculationOutput] desde datos guardados en DB (snapshots)
  /// + settings actuales como fallback.
  ///
  /// ** single source of truth **: reemplaza la logica duplicada que existia
  /// en `calculation_detail_page.dart._recomputeOutput()`. Si cambia la
  /// formula, se cambia aca y ambas rutas (live + historial) se actualizan.
  ///
  /// [materials]: lista de materiales guardados (con snapshots de precio/gramos).
  /// [materialCostSnapshot]: costo material guardado en la fila de la calculo.
  /// [totalHours]: horas de impresion guardadas.
  /// [printerWattsSnapshot], [kwhRateSnapshot], etc.: snapshots de la calculo.
  /// [fallbackKwhRate], [fallbackLaborRate], etc.: settings actuales (fallback
  ///   cuando el snapshot es 0/legacy).
  /// [fallbackPrinterWatts]: watts de la impresora activa actual.
  /// [quantity]: multiplica todos los montos (default 1 = unitario).
  ///
  /// Retorna null si no hay datos suficientes para computar.
  static CalculationOutput? computeFromSnapshot({
    required List<MaterialSnapshot> materials,
    required double materialCostSnapshot,
    required double totalHours,
    required double printerWattsSnapshot,
    required double kwhRateSnapshot,
    required double laborRateSnapshot,
    required double postProcessRateSnapshot,
    required double failureRateSnapshot,
    required double markupOnMaterialsSnapshot,
    required double profitBaseSnapshot,
    required double discountPercentage,
    double amortizationCostSnapshot = 0,
    required Decimal fallbackKwhRate,
    required Decimal fallbackLaborRate,
    required Decimal fallbackPostProcessRate,
    required Decimal fallbackFailureRate,
    required Decimal fallbackMarkupOnMaterials,
    required Decimal fallbackProfitBase,
    required int fallbackPrinterWatts,
    int quantity = 1,
  }) {
    if (materials.isEmpty && materialCostSnapshot <= 0) return null;
    final qty = quantity < 1 ? 1 : quantity;
    final qtyD = Decimal.fromInt(qty);
    final pctDivisor = Decimal.fromInt(100);
    final kWhDivisor = Decimal.fromInt(1000);

    // Material cost desde snapshots
    final materialCost = Decimal.parse(materialCostSnapshot.toStringAsFixed(2));
    final hours = Decimal.parse(totalHours.toStringAsFixed(2));

    // Resolver snapshots con fallback a settings actuales
    final kwhRate = kwhRateSnapshot > 0
        ? Decimal.parse(kwhRateSnapshot.toStringAsFixed(2))
        : fallbackKwhRate;
    final watts = printerWattsSnapshot > 0
        ? printerWattsSnapshot.toInt()
        : fallbackPrinterWatts;
    final laborRate = laborRateSnapshot > 0
        ? Decimal.parse(laborRateSnapshot.toStringAsFixed(2))
        : fallbackLaborRate;
    final postProcessRate = postProcessRateSnapshot > 0
        ? Decimal.parse(postProcessRateSnapshot.toStringAsFixed(2))
        : fallbackPostProcessRate;
    final failureRate = failureRateSnapshot > 0
        ? Decimal.parse(failureRateSnapshot.toStringAsFixed(2))
        : fallbackFailureRate;
    final markupOnMaterials = markupOnMaterialsSnapshot > 0
        ? Decimal.parse(markupOnMaterialsSnapshot.toStringAsFixed(2))
        : fallbackMarkupOnMaterials;
    final profitBase = profitBaseSnapshot > 0
        ? Decimal.parse(profitBaseSnapshot.toStringAsFixed(2))
        : fallbackProfitBase;

    // Electricidad
    final electricCost = hours > Decimal.zero && watts > 0
        ? (Decimal.fromInt(watts) * hours * kwhRate / kWhDivisor).toDecimal()
        : Decimal.zero;

    // Amortizacion desde snapshot
    final amortCost = amortizationCostSnapshot > 0
        ? Decimal.parse(amortizationCostSnapshot.toStringAsFixed(2))
        : Decimal.zero;

    // Mano de obra
    final laborCost = hours * laborRate;

    // Post-procesado
    final postProcessCost = postProcessRate > Decimal.zero
        ? (materialCost * postProcessRate / pctDivisor).toDecimal()
        : Decimal.zero;

    // Base
    final baseCost =
        materialCost + electricCost + amortCost + laborCost + postProcessCost;

    // Tasa de falla
    final failureCost = failureRate > Decimal.zero
        ? (baseCost * failureRate / pctDivisor).toDecimal()
        : Decimal.zero;
    final costWithFailure = baseCost + failureCost;

    // Markup
    final markupCost = markupOnMaterials > Decimal.zero
        ? (materialCost * markupOnMaterials / pctDivisor).toDecimal()
        : Decimal.zero;
    final totalBeforeProfit = costWithFailure + markupCost;

    // Ganancia
    final profitAmount = profitBase > Decimal.zero
        ? (totalBeforeProfit * profitBase / pctDivisor).toDecimal()
        : Decimal.zero;
    final totalFinal = totalBeforeProfit + profitAmount;

    // Descuento
    final discountPct = discountPercentage > 0
        ? Decimal.parse(discountPercentage.toStringAsFixed(2))
        : Decimal.zero;
    final discountOnTotalFinal = discountPct > Decimal.zero
        ? (totalFinal * discountPct / pctDivisor).toDecimal()
        : Decimal.zero;
    final totalPrice = totalFinal - discountOnTotalFinal;

    return CalculationOutput(
      materialCost: materialCost * qtyD,
      electricCost: electricCost * qtyD,
      amortizationCost: amortCost * qtyD,
      laborCost: laborCost * qtyD,
      postProcessCost: postProcessCost * qtyD,
      baseCost: baseCost * qtyD,
      failureCost: failureCost * qtyD,
      costWithFailure: costWithFailure * qtyD,
      markupCost: markupCost * qtyD,
      totalBeforeProfit: totalBeforeProfit * qtyD,
      profitAmount: profitAmount * qtyD,
      totalFinal: totalFinal * qtyD,
      discountAmount: discountOnTotalFinal * qtyD,
      totalPrice: totalPrice * qtyD,
      totalOriginal: totalFinal * qtyD,
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
