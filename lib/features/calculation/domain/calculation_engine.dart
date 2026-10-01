import 'package:decimal/decimal.dart';

import '../../../core/export/pdf_rate_audit.dart';
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
/// Formula completa (v17 — incluye los 3 campos de servicio con modo % / fijo):
///
/// ```
/// materialCost   = Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i])
/// electricCost   = printerWatts * totalHours * kwhRate / 1000
/// amortCost      = amortizationPerHour * totalHours
/// coreBase       = materialCost + electricCost + amortCost
/// modelingCost   = resolveService(modelingMode, coreBase, modelingPct,
///                   modelingFixed, hours, laborRate)
/// postProcCost   = resolveService(postprocMode, coreBase, postprocPct,
///                   postprocFixed, materialCost, postProcessRate)
/// extrasCost     = resolveExtras(extraCostMode, coreBase, extraCostPct,
///                   extraCostFixed)
/// baseCost       = coreBase + modelingCost + postProcCost + extrasCost
/// failureCost    = baseCost * failureRate / 100
/// markupCost     = materialCost * markupOnMaterials / 100
/// totalBeforeProfit = baseCost + failureCost + markupCost
/// profitAmount   = totalBeforeProfit * profitBase / 100
/// totalFinal     = totalBeforeProfit + profitAmount
/// discountAmount = totalFinal * discountPercentage / 100
/// totalPrice     = max(totalFinal - discountAmount, minimumCharge)
/// ```
///
/// `resolveService` por campo:
/// - `auto` (modelado / postprocesado): replica la formula legacy.
///     - modelado: `hours * laborRate`.
///     - postprocesado: `materialCost * postProcessRate / 100`.
/// - `pct`: `coreBase * pct / 100`.
/// - `fixed`: monto literal del campo.
/// - cualquier otro (incluido `off`): 0.
///
/// **Equivalencia legacy**: con `modelingMode=auto`, `postprocMode=auto`,
/// `extraCostMode=off`, y los campos pct/fixed en 0, el calculo produce
/// los MISMOS numeros que la formula pre-v17 (con la excepcion de
/// `amortCost` que ahora SI esta en `baseCost` para alinear con
/// `computeFromSnapshot` — fix incidental del bug live vs snapshot).
///
/// **Reglas de borde**:
/// - Si no hay materiales, `materialCost = 0`.
/// - Si `discountPercentage = 0`, `discountAmount = 0`.
/// - Si descuento > 100%, `totalPrice` quedaria negativo (caso borde, se
///   preserva para que la UI lo maneje).
/// - Todos los parametros con default 0 no afectan el calculo.
/// - `minimumCharge > 0`: piso del precio final (despues del descuento).
///
/// **Precision**: todo en `Decimal`. Prohibido `double` en este archivo.
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

  /// Amortizacion fija por hora de la impresora.
///
/// `costo / vida_util_horas`, escala interna 6. Retorna `null` si la vida
/// util es <= 0 o el costo no es positivo.
///
/// v17: ahora SI entra en `coreBase` y por lo tanto en el costo de la
/// cotizacion (antes solo se usaba para metricas). El cambio alinea el
/// calculo live con `computeFromSnapshot` (que ya lo incluia en
/// `baseCost`) y evita la inconsistencia entre live y historial.
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

    // Amortizacion de impresora (costo por hora * horas). v17: ahora SI
    // entra en `coreBase` para alinear con `computeFromSnapshot`. Antes el
    // live ignoraba este termino en `baseCost` (mostraba 0 en la UI aunque
    // `computeFromSnapshot` lo incluia), lo que producia dos totales
    // distintos entre live e historial para la misma cotizacion.
    final amortCost =
        input.amortizationPerHour != null && input.totalHours > Decimal.zero
        ? (input.amortizationPerHour! * input.totalHours)
        : Decimal.zero;

    // coreBase = costo automatico (no decision del usuario). Es la base
    // sobre la que se calculan los 3 servicios en modo `pct`.
    final coreBase = materialCost + electricCost + amortCost;

    // === 3 campos de servicio con modo % / fijo ===
    //
    // Modelo (legacy equivalence): cada uno de los 2 que existian
    // pre-v17 (modelado, postprocesado) tiene un modo `auto` que reproduce
    // la formula legacy exactamente cuando `pct`/`fixed` estan en 0. El
    // campo nuevo (extras) arranca en `off` y no aporta nada. Asi, las
    // cotizaciones nuevas arrancan identicas a como se calculaban antes
    // de v17.
    final modelingCost = _resolveService(
      mode: input.modelingMode,
      coreBase: coreBase,
      pct: input.modelingPct,
      fixed: input.modelingFixed,
      legacyAmount: input.totalHours * input.laborRate,
    );
    final postProcCost = _resolveService(
      mode: input.postprocMode,
      coreBase: coreBase,
      pct: input.postprocPct,
      fixed: input.postprocFixed,
      // Legacy: postProcess era `materialCost * postProcessRate / 100`
      // SOLO si `postProcessRate > 0`. Replicamos para equivalencia exacta.
      legacyAmount: input.postProcessRate > Decimal.zero
          ? (materialCost * input.postProcessRate / _pct).toDecimal()
          : Decimal.zero,
    );
    final extrasCost = _resolveService(
      mode: input.extraCostMode,
      coreBase: coreBase,
      pct: input.extraCostPct,
      fixed: input.extraCostFixed,
      // No hay legacy para extras: el caller debe pasar `off` (o un
      // legacyAmount en 0, que es lo que hace este default).
      legacyAmount: Decimal.zero,
    );

    // Base: coreBase + los 3 servicios. Falla / markup / profit / descuento
    // se aplican sobre este total, IGUAL que antes.
    final baseCost = coreBase + modelingCost + postProcCost + extrasCost;

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
      amortizationCost: amortCost,
      laborCost: modelingCost,
      postProcessCost: postProcCost,
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
      // v17: extras en su propio slot (no se reusan campos existentes para
      // evitar acoplamiento con UI/reportes legacy). El reporte interno
      // lee directo este campo.
      extrasCost: extrasCost,
    );
  }

  /// Resuelve el monto de un campo de servicio segun su modo.
  ///
  /// - `pct`: `coreBase * pct / 100`.
  /// - `fixed`: monto literal.
  /// - `auto`: replica la formula legacy (pasada por el caller en
  ///   [legacyAmount]). Si el caller no conoce el legacy, pasa 0.
  /// - cualquier otro modo (incluido `off`): 0.
  ///
  /// Privado: la politica vive en [CalculationInput.modelingMode] etc.
  static Decimal _resolveService({
    required ServiceCostMode mode,
    required Decimal coreBase,
    required Decimal pct,
    required Decimal fixed,
    required Decimal legacyAmount,
  }) {
    if (mode.isPct) {
      if (pct <= Decimal.zero) return Decimal.zero;
      return (coreBase * pct / Decimal.fromInt(100)).toDecimal();
    }
    if (mode.isFixed) {
      return fixed < Decimal.zero ? Decimal.zero : fixed;
    }
    if (mode.isAuto) {
      return legacyAmount < Decimal.zero ? Decimal.zero : legacyAmount;
    }
    // off o cualquier modo desconocido: no se cobra.
    return Decimal.zero;
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

    // Resolver snapshots con fallback a settings actuales. Delegado a
    // [resolveRates] para que el reporte PDF pueda imprimir las MISMAS tasas
    // que uso este calculo (sin duplicar la politica snapshot -> fallback).
    final rates = resolveRates(
      kwhRateSnapshot: kwhRateSnapshot,
      laborRateSnapshot: laborRateSnapshot,
      postProcessRateSnapshot: postProcessRateSnapshot,
      failureRateSnapshot: failureRateSnapshot,
      markupOnMaterialsSnapshot: markupOnMaterialsSnapshot,
      profitBaseSnapshot: profitBaseSnapshot,
      fallbackKwhRate: fallbackKwhRate,
      fallbackLaborRate: fallbackLaborRate,
      fallbackPostProcessRate: fallbackPostProcessRate,
      fallbackFailureRate: fallbackFailureRate,
      fallbackMarkupOnMaterials: fallbackMarkupOnMaterials,
      fallbackProfitBase: fallbackProfitBase,
      fallbackPrinterWatts: fallbackPrinterWatts,
      printerWattsSnapshot: printerWattsSnapshot,
      amortizationCostSnapshot: amortizationCostSnapshot,
    );
    final kwhRate = rates.kwhRate;
    final watts = rates.printerWatts;
    final laborRate = rates.laborRate;
    final postProcessRate = rates.postProcessRate;
    final failureRate = rates.failureRate;
    final markupOnMaterials = rates.markupOnMaterials;
    final profitBase = rates.profitBase;

    // Electricidad
    final electricCost = hours > Decimal.zero && watts > 0
        ? (Decimal.fromInt(watts) * hours * kwhRate / kWhDivisor).toDecimal()
        : Decimal.zero;

    // Amortizacion desde snapshot
    final amortCost = rates.amortizationCost;

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

  /// Resuelve las tasas de una cotizacion aplicando la politica
  /// **snapshot -> fallback a Settings**.
  ///
  /// Politica (identica a la que aplicaba inline en [computeFromSnapshot] antes
  /// de este refactor):
  /// - snapshot > 0 gana (hay valor guardado con la cotizacion);
  /// - snapshot == 0 (dato legacy o no configurado) cae al valor actual de
  ///   Settings.
  ///
  /// Se expone publicamente para que el reporte PDF imprima la tabla de
  /// parametros con las **mismas** tasas que uso el calculo. Si el PDF
  /// resolviera sus propias tasas, la tabla podria contradecir al desglose.
  ///
  /// **No escala por [quantity]**: los montos que dependen de la cantidad se
  /// escalan en [computeFromSnapshot].
  static ResolvedRates resolveRates({
    required double kwhRateSnapshot,
    required double laborRateSnapshot,
    required double postProcessRateSnapshot,
    required double failureRateSnapshot,
    required double markupOnMaterialsSnapshot,
    required double profitBaseSnapshot,
    required Decimal fallbackKwhRate,
    required Decimal fallbackLaborRate,
    required Decimal fallbackPostProcessRate,
    required Decimal fallbackFailureRate,
    required Decimal fallbackMarkupOnMaterials,
    required Decimal fallbackProfitBase,
    required int fallbackPrinterWatts,
    double amortizationCostSnapshot = 0,
    double printerWattsSnapshot = 0,
  }) {
    return ResolvedRates(
      kwhRate: kwhRateSnapshot > 0
          ? Decimal.parse(kwhRateSnapshot.toStringAsFixed(2))
          : fallbackKwhRate,
      printerWatts: printerWattsSnapshot > 0
          ? printerWattsSnapshot.toInt()
          : fallbackPrinterWatts,
      laborRate: laborRateSnapshot > 0
          ? Decimal.parse(laborRateSnapshot.toStringAsFixed(2))
          : fallbackLaborRate,
      postProcessRate: postProcessRateSnapshot > 0
          ? Decimal.parse(postProcessRateSnapshot.toStringAsFixed(2))
          : fallbackPostProcessRate,
      failureRate: failureRateSnapshot > 0
          ? Decimal.parse(failureRateSnapshot.toStringAsFixed(2))
          : fallbackFailureRate,
      markupOnMaterials: markupOnMaterialsSnapshot > 0
          ? Decimal.parse(markupOnMaterialsSnapshot.toStringAsFixed(2))
          : fallbackMarkupOnMaterials,
      profitBase: profitBaseSnapshot > 0
          ? Decimal.parse(profitBaseSnapshot.toStringAsFixed(2))
          : fallbackProfitBase,
      amortizationCost: amortizationCostSnapshot > 0
          ? Decimal.parse(amortizationCostSnapshot.toStringAsFixed(2))
          : Decimal.zero,
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
