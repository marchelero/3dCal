// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';

import '../../../features/settings/domain/discount_tier.dart';
import 'entities/calculation_output.dart';

/// Resultado de componer un lote.
final class BatchLotResult {
  const BatchLotResult({
    required this.subtotalImpression,
    required this.batchDiscountAmount,
    required this.manualDiscountAmount,
    required this.lotTotal,
    required this.unitPrice,
    this.appliedTier,
  });

  /// `(baseCost + failureCost + markupCost) × N` — base de `desc_cantidad`.
  /// Es el "subtotal de impresion" del PRD; en hitos 2/3 sumara insumos y
  /// servicios (punto de extension). `0` cuando no aplica escalon.
  final Decimal subtotalImpression;

  /// Monto del descuento mayorista aplicado: `pct × subtotalImpression`.
  /// `0` cuando no aplica escalon.
  final Decimal batchDiscountAmount;

  /// Monto del descuento manual escalado: `manualPct × (totalFinal × N)`.
  final Decimal manualDiscountAmount;

  /// Total del lote: `max(totalFinal × N − desc_cantidad − desc_manual,
  /// minimumCharge × N)`.
  final Decimal lotTotal;

  /// Precio unitario resultante: `lotTotal ÷ N`.
  final Decimal unitPrice;

  /// Escalon aplicado, o `null` si no hubo descuento mayorista.
  final DiscountTier? appliedTier;
}

/// Compositor de lote (feature A — Hito 1). **Puro, todo en [Decimal].**
///
/// Consume el OUTPUT del motor unitario ([CalculationOutput]) — el motor
/// **no se toca** — y compone el lote aplicando el descuento mayorista.
///
/// **Reglas (decisión D2 del plan)**:
/// - `subtotal_impresion = (baseCost + failureCost + markupCost) × N`
/// - `desc_cantidad = tierPercent × subtotal_impresion` (solo si el escalón
///   aplica; si no, `0`).
/// - `desc_manual = manualPct × (output.totalFinal × N)` — la base es el
///   total de hoy (incluye ganancia), comportamiento actual escalado.
/// - `total = max(totalFinal × N − desc_cantidad − desc_manual,
///   minimumCharge × N)`.
/// - `unitario = total ÷ N`.
///
/// **Regla del 95 %**: con `tier = null` (o N = 1) el resultado es IDÉNTICO
/// al math actual escalado: `lotTotal = max(totalFinal × N − desc_manual,
/// minimumCharge × N)`, es decir `output.totalPrice × N` cuando el engine
/// ya aplicó el mismo `manualPct` (mismo descuento manual que ve el engine).
///
/// **Punto de extensión (hitos 2/3)**: [additionalCost] (insumos/servicios)
/// es opcional y nullable. En hito 1 NO participa de las fórmulas (additive);
/// los hitos 2/3 lo sumarán a `subtotal_impresion` sin romper el contrato.
///
/// **Precision**: las divisiones usan `toDecimal(scaleOnInfinitePrecision: 6)`
/// (patrón de `CalculationEngine.amortizationPerHour`) para no lanzar con
/// decimales de precisión infinita.
class BatchLotComposer {
  const BatchLotComposer._();

  static final Decimal _pct = Decimal.fromInt(100);

  /// Compone [quantity] unidades del [output] con el escalón [tier] (si
  /// aplica) y [manualDiscountPct] (% manual, misma base que el engine).
  ///
  /// [quantity] se fija en ≥ 1; [tier] solo aplica si es válido y
  /// `tier.minQty <= quantity` (si no, se ignora → 0 % mayorista).
  static BatchLotResult compose({
    required CalculationOutput output,
    required int quantity,
    required Decimal minimumCharge,
    DiscountTier? tier,
    Decimal? manualDiscountPct,
    Decimal? additionalCost,
  }) {
    final n = Decimal.fromInt(quantity < 1 ? 1 : quantity);
    final appliedTier =
        tier != null && tier.isValid && tier.minQty <= quantity ? tier : null;

    final subtotalImpression =
        appliedTier == null
            ? Decimal.zero
            : (output.baseCost + output.failureCost + output.markupCost) * n;

    final batchDiscountAmount = appliedTier == null
        ? Decimal.zero
        : _pctOf(subtotalImpression, appliedTier.percent);

    final totalFinalScaled = output.totalFinal * n;
    final manual = manualDiscountPct ?? Decimal.zero;
    final manualDiscountAmount = manual > Decimal.zero
        ? _pctOf(totalFinalScaled, manual)
        : Decimal.zero;

    final totalAfterDiscounts =
        totalFinalScaled - batchDiscountAmount - manualDiscountAmount;
    final floor = minimumCharge * n;
    final lotTotal = totalAfterDiscounts > floor
        ? totalAfterDiscounts
        : floor;
    final unitPrice = _div(lotTotal, n);

    return BatchLotResult(
      subtotalImpression: subtotalImpression,
      batchDiscountAmount: batchDiscountAmount,
      manualDiscountAmount: manualDiscountAmount,
      lotTotal: lotTotal,
      unitPrice: unitPrice,
      appliedTier: appliedTier,
    );
  }

  /// `amount × pct / 100`, redondeo defensivo ante precisión infinita.
  static Decimal _pctOf(Decimal amount, Decimal pct) =>
      (amount * pct / _pct).toDecimal(scaleOnInfinitePrecision: 6);

  /// División con escala defensiva: `a / b`.
  static Decimal _div(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: 6);
}
