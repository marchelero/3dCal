// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/batch_discount_resolver.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';

/// Tests de `BatchDiscountResolver` (feature A — Hito 1).
///
/// Contrato:
/// - Aplica el escalón con la mayor `min_qty <= N`.
/// - N bajo el primer escalón → null (0 %, sin línea).
/// - N <= 1 → null siempre.
/// - Sin escalones → null.
/// - Empate de `min_qty` → gana menor `sort_order`.
/// - Escalones inválidos (min_qty < 2 o % fuera de 0–100) → descartados.
void main() {
  DiscountTier tier(int minQty, int percent, {int sortOrder = 0}) =>
      DiscountTier.create(minQty: minQty, percent: Decimal.fromInt(percent))
          .copyWith(sortOrder: sortOrder);

  test('N=10 con escalón 10→10% → aplica 10%', () {
    final r = BatchDiscountResolver.resolve(
      quantity: 10,
      tiers: [tier(10, 10)],
    );
    expect(r, isNotNull);
    expect(r!.minQty, 10);
    expect(r.percent, Decimal.fromInt(10));
  });

  test('N=1 sin escalón → null (flujo actual intacto)', () {
    final r = BatchDiscountResolver.resolve(
      quantity: 1,
      tiers: [tier(10, 10)],
    );
    expect(r, isNull);
  });

  test('N=1 con escalón en 1 → null (min_qty >= 2 es la regla)', () {
    final r = BatchDiscountResolver.resolve(
      quantity: 1,
      tiers: [tier(2, 5)],
    );
    expect(r, isNull);
  });

  test('escalones [10→10%, 25→15%] con N=26 → aplica 15%', () {
    final tiers = [tier(10, 10), tier(25, 15)];
    for (final t in tiers) {
      expect(t.isValid, isTrue);
    }
    final r = BatchDiscountResolver.resolve(quantity: 26, tiers: tiers);
    expect(r, isNotNull);
    expect(r!.minQty, 25);
    expect(r.percent, Decimal.fromInt(15));
  });

  test('N=9 bajo el primer escalón → null', () {
    final r = BatchDiscountResolver.resolve(
      quantity: 9,
      tiers: [tier(10, 10)],
    );
    expect(r, isNull);
  });

  test('sin escalones → null', () {
    final r = BatchDiscountResolver.resolve(quantity: 10, tiers: const []);
    expect(r, isNull);
  });

  test('empate de min_qty → gana el de menor sort_order', () {
    final tiers = [
      tier(10, 8, sortOrder: 1),
      tier(10, 10, sortOrder: 0),
    ];
    final r = BatchDiscountResolver.resolve(quantity: 10, tiers: tiers);
    expect(r, isNotNull);
    expect(r!.sortOrder, 0, reason: 'Empate: gana el menor sort_order.');
    expect(r.percent, Decimal.fromInt(10));
  });

  test('escalones inválidos se descartan (min_qty < 2 o % fuera de rango)',
      () {
    final invalidQty = DiscountTier.create(
      minQty: 1,
      percent: Decimal.fromInt(10),
    );
    final invalidPct = DiscountTier.create(
      minQty: 10,
      percent: Decimal.fromInt(0),
    );
    final invalidPctOver =
        DiscountTier.create(minQty: 10, percent: Decimal.fromInt(101));

    expect(
      BatchDiscountResolver.resolve(
        quantity: 10,
        tiers: [invalidQty, invalidPct, invalidPctOver],
      ),
      isNull,
      reason: 'Todo escalón inválido debe descartarse silenciosamente.',
    );
  });

  test('N=100 con escalones [10%, 50→20%, 100→25%] → aplica 25%', () {
    final r = BatchDiscountResolver.resolve(
      quantity: 100,
      tiers: [tier(10, 10), tier(50, 20), tier(100, 25)],
    );
    expect(r, isNotNull);
    expect(r!.minQty, 100);
    expect(r.percent, Decimal.fromInt(25));
  });
}
