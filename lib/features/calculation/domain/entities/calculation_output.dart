// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';

/// Resultado del calculo de cotizacion. Inmutable.
///
/// Formula completa:
///   materialCost = Σ(weight * pricePerBobbin / gramsPerBobbin)
///   electricCost = printerWatts * totalHours * kwhRate / 1000
///   amortizationCost = 0 (F5: la amortizacion de la impresora queda
///     FUERA del costo y de los reportes; express y avanzado no la usan)
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
  CalculationOutput({
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
    this.totalOriginal,
    Decimal? amortizationCost,
    Decimal? extrasCost,
  }) : amortizationCost = amortizationCost ?? Decimal.zero,
       extrasCost = extrasCost ?? Decimal.zero;

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
      extrasCost: Decimal.zero,
    );
  }

  /// Suma de costos de materiales (BOB).
  final Decimal materialCost;

  /// Costo de energia electrica (BOB).
  final Decimal electricCost;

  /// Amortizacion de la impresora (BOB). F5.
  ///
  /// Siempre `Decimal.zero`: no entra en el costo de la cotizacion ni en
  /// los reportes. El campo se conserva por compatibilidad (schema,
  /// serializacion y filas viejas).
  final Decimal amortizationCost;

  /// Costo de mano de obra (BOB).
  final Decimal laborCost;

  /// Costo de post-procesado (BOB).
  final Decimal postProcessCost;

  /// Costo base = materialCost + electricCost
  /// + laborCost + postProcessCost (+ extras).
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

  /// Total sin descuento, UNITARIO (el engine no conoce quantity).
  /// Usado por el template de imagen: se multiplica por la cantidad ahi
  /// para mostrar "Sin descuento: $X" correcto con cantidad > 1.
  final Decimal? totalOriginal;

  /// v17: costo de "Extras" (argollas, pegamento, etc.).
  ///
  /// Modo `off` (default) → 0. Modo `pct` → `coreBase * pct / 100`. Modo
  /// `fixed` → monto literal. Aparece como linea propia en el desglose del
  /// reporte interno. En el resumen client-facing solo se muestra si > 0.
  final Decimal extrasCost;

  @override
  bool operator ==(Object other) =>
      other is CalculationOutput &&
      materialCost == other.materialCost &&
      electricCost == other.electricCost &&
      amortizationCost == other.amortizationCost &&
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
      totalPrice == other.totalPrice &&
      totalOriginal == other.totalOriginal &&
      extrasCost == other.extrasCost;

  @override
  int get hashCode => Object.hash(
    materialCost,
    electricCost,
    amortizationCost,
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
    totalOriginal,
    extrasCost,
  );

  @override
  String toString() =>
      'CalculationOutput('
      'materialCost: $materialCost, '
      'electricCost: $electricCost, '
      'amortizationCost: $amortizationCost, '
      'laborCost: $laborCost, '
      'postProcessCost: $postProcessCost, '
      'extrasCost: $extrasCost, '
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
