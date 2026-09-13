import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/discount_tiers_notifier.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('DiscountTiersNotifier', () {
    test('estado inicial es lista vacía', () async {
      final state = await container.read(discountTiersNotifierProvider.future);
      expect(state, isEmpty);
    });

    test('upsert agrega un escalón', () async {
      final notifier = container.read(discountTiersNotifierProvider.notifier);
      final tier = DiscountTier.create(
        minQty: 10,
        percent: Decimal.parse('10'),
      );
      await notifier.upsert(tier);

      // Esperar el rebuild tras invalidateSelf
      final tiers = await container.read(discountTiersNotifierProvider.future);
      expect(tiers, hasLength(1));
      expect(tiers.first.minQty, 10);
    });

    test('upsert actualiza un escalón existente', () async {
      final notifier = container.read(discountTiersNotifierProvider.notifier);
      final tier = DiscountTier.create(
        minQty: 10,
        percent: Decimal.parse('10'),
      );
      await notifier.upsert(tier);

      final updated = tier.copyWith(
        minQty: 25,
        percent: Decimal.parse('15'),
      );
      await notifier.upsert(updated);

      final tiers = await container.read(discountTiersNotifierProvider.future);
      expect(tiers, hasLength(1));
      expect(tiers.first.minQty, 25);
    });

    test('delete elimina un escalón', () async {
      final notifier = container.read(discountTiersNotifierProvider.notifier);
      final tier = DiscountTier.create(
        minQty: 10,
        percent: Decimal.parse('10'),
      );
      await notifier.upsert(tier);
      await notifier.delete(tier.id);

      final tiers = await container.read(discountTiersNotifierProvider.future);
      expect(tiers, isEmpty);
    });

    test('lista sale ordenada por min_qty ascendente', () async {
      final notifier = container.read(discountTiersNotifierProvider.notifier);
      await notifier.upsert(
        DiscountTier.create(minQty: 25, percent: Decimal.parse('15')),
      );
      await notifier.upsert(
        DiscountTier.create(minQty: 10, percent: Decimal.parse('10')),
      );
      await notifier.upsert(
        DiscountTier.create(minQty: 5, percent: Decimal.parse('5')),
      );

      final tiers = await container.read(discountTiersNotifierProvider.future);
      expect(tiers.map((t) => t.minQty), [5, 10, 25]);
    });
  });
}
