// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';

/// Fuente ÚNICA de los cálculos de descuento del dominio (T1-3).
///
/// **Por que existe**: la fórmula del descuento manual y la base
/// `manualPct × (totalFinal × N)` estaban re-derivadas en al menos 4 lugares
/// (PDF, imagen de cotización, detalle y composer). Antes, un cambio de regla
/// obligaba a tocar todos los call sites con riesgo de divergir en el último
/// dígito. Acá viven las dos operaciones atómicas:
///
/// - [scaled]: descuento manual de un lote a partir del descuento UNITARIO
///   ya calculado por el motor (`output.discountAmount`).
/// - [pctOf]: aplica un porcentaje sobre un monto (`amount × pct / 100`).
///
/// **Contrato** (idéntico al del composer/engine, no cambia montos):
/// - `scaled = unitDiscountAmount × N` (N < 1 → 1).
/// - `pctOf = amount × pct / 100` con redondeo defensivo (escala 6).
///
/// Con `unitDiscountAmount = pctOf(totalFinal, pct)` se cumple
/// `scaled(...) == pctOf(totalFinal × N, pct)` (`/100` es exacto en decimal).
class ManualDiscount {
  const ManualDiscount._();

  static final Decimal _pct = Decimal.fromInt(100);

  /// Aplica [pct] sobre [amount]: `amount × pct / 100`.
  ///
  /// Usa `toDecimal(scaleOnInfinitePrecision: 6)` (patrón de
  /// `CalculationEngine`/`BatchLotComposer`) para no lanzar con precisiones
  /// infinitas. Con `pct <= 0` retorna `0`.
  static Decimal pctOf(Decimal amount, Decimal pct) {
    if (pct <= Decimal.zero) return Decimal.zero;
    return (amount * pct / _pct).toDecimal(scaleOnInfinitePrecision: 6);
  }

  /// Descuento manual escalado a un lote de [quantity] unidades desde el
  /// descuento UNITARIO del motor ([unitDiscountAmount]).
  ///
  /// `N < 1` se fija en 1 (misma clamp que `LotTotals`/`BatchLotComposer`).
  /// Retorna `0` si [unitDiscountAmount] <= 0.
  static Decimal scaled({
    required Decimal unitDiscountAmount,
    required int quantity,
  }) {
    if (unitDiscountAmount <= Decimal.zero) return Decimal.zero;
    return unitDiscountAmount * Decimal.fromInt(quantity < 1 ? 1 : quantity);
  }
}
