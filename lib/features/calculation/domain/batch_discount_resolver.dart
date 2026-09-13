// ignore_for_file: public_member_api_docs
import '../../../features/settings/domain/discount_tier.dart';

/// Resolver de escalones de descuento por cantidad (feature A — Hito 1).
///
/// Funcion pura: dado un `quantity` y una lista de `DiscountTier`, aplica
/// el escalon con la mayor `min_qty <= quantity`. Si `quantity` queda por
/// debajo del primer escalon (o no hay escalones, o `quantity <= 1`) no hay
/// descuento: retorna `null` (0 % sin linea — el flujo actual no se toca).
///
/// **Contrato de validacion** (documentado):
/// - Los escalones invalidos (`min_qty < 2` o `percent` fuera de 0–100) se
///   DESCARTAN silenciosamente. Un dato corrupto (draft/backup legacy) nunca
///   dispara una linea de descuento.
/// - Si hay multiples escalones con el mismo `min_qty` (empate), gana el de
///   menor `sort_order` (desempate deterministico). Con `sort_order` igual,
///   queda el primero en el orden de la lista.
/// - `quantity < 2` retorna `null` siempre: la cantidad 1 es el flujo actual.
class BatchDiscountResolver {
  const BatchDiscountResolver._();

  /// Aplica el escalon con la mayor `min_qty <= [quantity]`.
  /// Retorna `null` cuando no aplica ningun escalon.
  static DiscountTier? resolve({
    required int quantity,
    required List<DiscountTier> tiers,
  }) {
    if (quantity < 2) return null;
    DiscountTier? best;
    for (final tier in tiers) {
      if (!tier.isValid) continue;
      if (tier.minQty > quantity) continue;
      if (best == null) {
        best = tier;
        continue;
      }
      if (tier.minQty > best.minQty) {
        best = tier;
        continue;
      }
      if (tier.minQty == best.minQty && tier.sortOrder < best.sortOrder) {
        best = tier;
        continue;
      }
    }
    return best;
  }
}
