// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';

/// Fuente ÚNICA del total efectivo de un lote desde valores UNITARIOS
/// persistidos (historial, detalle, CSV, dashboard, imagen y PDF).
///
/// **Por que existe**: el snapshot `totalPriceSnapshot` guarda el precio
/// unitario SIN el descuento mayorista (el escalón se persiste aparte en
/// `batch_discount_amount`). Antes cada consumidor hacía `unit × qty` y
/// mostraba un total inflado respecto de la calculadora en vivo y del PDF,
/// que sí restan el escalón (HIGH-01/HIGH-02 de la auditoría 2026-10-04).
///
/// **Contrato** (idéntico a `BatchLotComposer.compose` en su caso sin
/// re-balanceo de servicios):
/// - `lotTotal = max(unitTotal × N − batchDiscount, minimumCharge × N)`
/// - `batchDiscount(pct) = pct × (base + failure + markup) × N / 100`
///   (misma base de escalón que el composer: `subtotalImpression`).
/// - `N < 1` se fija en 1 (misma clamp que `CalculationListItem`).
///
/// Con `batch = 0` y `minimumCharge = 0` (la gran mayoría del historial)
/// el resultado es `unitTotal × N` — backwards compatible.
class LotTotals {
  const LotTotals._();

  static final Decimal _pct = Decimal.fromInt(100);

  /// Descuento mayorista del lote: `pct × (base + failure + markup) × N / 100`.
  ///
  /// [base], [failure] y [markup] son los costos UNITARIOS snapshot.
  /// Retorna 0 si [pct] <= 0.
  static Decimal batchAmount({
    required Decimal base,
    required Decimal failure,
    required Decimal markup,
    required Decimal pct,
    required int quantity,
  }) {
    if (pct <= Decimal.zero) return Decimal.zero;
    final n = Decimal.fromInt(quantity < 1 ? 1 : quantity);
    final subtotalImpression = (base + failure + markup) * n;
    return (subtotalImpression * pct / _pct)
        .toDecimal(scaleOnInfinitePrecision: 6);
  }

  /// Total efectivo del lote: `max(unitTotal × N − batch, minimumCharge × N)`.
  static Decimal total({
    required Decimal unitTotal,
    required int quantity,
    Decimal? batchDiscount,
    Decimal? minimumCharge,
  }) {
    final batch = batchDiscount ?? Decimal.zero;
    final mc = minimumCharge ?? Decimal.zero;
    final n = Decimal.fromInt(quantity < 1 ? 1 : quantity);
    final afterDiscount = unitTotal * n - batch;
    final floor = mc * n;
    return afterDiscount > floor ? afterDiscount : floor;
  }

  /// Parsea el monto de escalón persistido (`String?` en drift). Null/invalido
  /// se trata como 0: las filas pre-escalón nunca tuvieron descuento.
  static Decimal parseBatchAmount(String? raw) {
    final v = Decimal.tryParse(raw ?? '');
    return (v != null && v > Decimal.zero) ? v : Decimal.zero;
  }
}
