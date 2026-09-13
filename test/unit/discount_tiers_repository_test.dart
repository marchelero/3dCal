// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/features/settings/data/discount_tiers_repository.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';

/// Tests de `DiscountTiersRepository` (feature A — Hito 1).
///
/// Verifica el contrato del repository sobre la tabla `discount_tiers`:
/// - `upsert` inserta un escalón nuevo y actualiza uno existente (mismo id),
///   re-secuenciando los slots automáticamente.
/// - `delete` borra y deja los slots contiguos (0..n-1).
/// - la lista sale ordenada por `min_qty` ascendente (auto-sort al guardar).
/// - `watchAll` emite reactivamente ante cambios.
///
/// **TDD**: este test se escribió ANTES del repository. La primera ejecución
/// debe fallar (RED) — `DiscountTiersRepository` no existe. Tras implementar,
/// debe pasar (GREEN).
void main() {
  late AppDatabase db;
  late DiscountTiersRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DiscountTiersRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------- helpers ----------

  DiscountTier tier(int minQty, int percent) =>
      DiscountTier.create(minQty: minQty, percent: Decimal.fromInt(percent));

  Iterable<int> minQtys(List<DiscountTier> tiers) =>
      tiers.map((t) => t.minQty);

  /// Inserta un escalón nuevo vía el repository y devuelve la entidad.
  Future<DiscountTier> insertTier(int minQty, int percent) async {
    final t = tier(minQty, percent);
    await repo.upsert(t);
    return t;
  }

  // ---------- insert ----------

  group('upsert (insert)', () {
    test('inserta un escalón y queda ordenado con slot 0', () async {
      final tier = DiscountTier.create(
        minQty: 10,
        percent: Decimal.parse('7.5'),
      );

      await repo.upsert(tier);

      final all = await repo.listAll();
      expect(all, hasLength(1));
      expect(all.first.id, tier.id);
      expect(all.first.minQty, 10);
      expect(all.first.percent, Decimal.parse('7.5'));
      expect(all.first.sortOrder, 0);
    });

    test('inserta varios y re-secuencia slots por min_qty ascendente', () async {
      final t25 = await insertTier(25, 15);
      final t10 = await insertTier(10, 10);
      final t5 = await insertTier(5, 5);

      final all = await repo.listAll();
      expect(all, hasLength(3));
      expect(minQtys(all), [5, 10, 25]);
      expect(all[0].id, t5.id);
      expect(all[1].id, t10.id);
      expect(all[2].id, t25.id);
      expect(
        all.map((t) => t.sortOrder),
        [0, 1, 2],
        reason: 'Los slots deben quedar contiguos y en orden de min_qty.',
      );
    });

    test('DiscountTier.create genera ids UUID v4 únicos', () {
      final a = tier(10, 10);
      final b = tier(10, 10);
      expect(a.id, isNot(b.id));

      final uuidRe = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidRe.hasMatch(a.id), isTrue, reason: 'id debe ser UUID v4.');
      expect(uuidRe.hasMatch(b.id), isTrue);
    });
  });

  // ---------- update ----------

  group('upsert (update)', () {
    test('actualiza min_qty y percent preservando el id', () async {
      final original = tier(10, 10);
      await repo.upsert(original);

      final updated = original.copyWith(minQty: 25, percent: Decimal.fromInt(20));
      await repo.upsert(updated);

      final all = await repo.listAll();
      expect(all, hasLength(1), reason: 'Mismo id → update, no insert.');
      expect(all.first.id, original.id);
      expect(all.first.minQty, 25);
      expect(all.first.percent, Decimal.fromInt(20));
    });

    test('editar min_qty reubica el escalón (auto-sort al guardar)', () async {
      final t10 = await insertTier(10, 10);
      await insertTier(25, 15);

      await repo.upsert(t10.copyWith(minQty: 30, percent: Decimal.fromInt(12)));

      final all = await repo.listAll();
      expect(minQtys(all), [25, 30]);
      expect(all[1].id, t10.id);
      expect(all.map((t) => t.sortOrder), [0, 1]);
    });
  });

  // ---------- delete ----------

  group('delete', () {
    test('elimina el escalón indicado y re-secuencia los restantes', () async {
      final a = await insertTier(5, 5);
      final b = await insertTier(10, 10);
      final c = await insertTier(25, 15);

      await repo.delete(a.id);

      final all = await repo.listAll();
      expect(all, hasLength(2));
      expect(minQtys(all), [10, 25]);
      expect(
        all.first.id,
        b.id,
        reason: 'Tras borrar el 5, el 10 queda de primer slot.',
      );
      expect(all.map((t) => t.sortOrder), [0, 1]);
      expect(c.id, isNot(all.first.id));
    });

    test('eliminar un id inexistente es no-op', () async {
      await insertTier(10, 10);
      await repo.delete('no-existe');

      final all = await repo.listAll();
      expect(all, hasLength(1));
    });

    test('borrar todo deja la tabla vacía', () async {
      final a = tier(5, 5);
      final b = tier(10, 10);
      await repo.upsert(a);
      await repo.upsert(b);

      await repo.delete(a.id);
      await repo.delete(b.id);

      expect(await repo.listAll(), isEmpty);
    });
  });

  // ---------- orden ----------

  group('orden', () {
    test('listAll ordena por min_qty ascendente aunque el insert sea inverso',
        () async {
      await insertTier(25, 15);
      await insertTier(10, 10);
      await insertTier(5, 5);
      await insertTier(50, 20);

      final all = await repo.listAll();
      expect(minQtys(all), [5, 10, 25, 50]);
      expect(all.map((t) => t.percent), [
        Decimal.fromInt(5),
        Decimal.fromInt(10),
        Decimal.fromInt(15),
        Decimal.fromInt(20),
      ]);
    });
  });

  // ---------- stream ----------

  group('watchAll', () {
    test('emite la lista inicial y los cambios tras upsert/delete', () async {
      final t10 = tier(10, 10);
      await repo.upsert(t10);

      // Assign future FIRST, luego trigger, luego await (patrón del repo).
      final future = expectLater(
        repo.watchAll(),
        emitsInOrder([
          predicate<List<DiscountTier>>((rows) =>
              rows.length == 1 && rows.first.id == t10.id),
          predicate<List<DiscountTier>>(
            (rows) =>
                _hasOrderedMinQtys(rows, [10, 25]),
          ),
          predicate<List<DiscountTier>>(
            (rows) => rows.length == 1 && rows.first.minQty == 25,
          ),
        ]),
      );

      await repo.upsert(tier(25, 15));
      await repo.delete(t10.id);
      await future;
    });

    test('emite listado vacío en una DB sin escalones', () async {
      await expectLater(repo.watchAll(), emits(isEmpty));
    });
  });
}

/// True si `rows` tiene exactamente `expected` como min_qty (en orden) y cada
/// escalón está en su slot (`sortOrder == posición`).
bool _hasOrderedMinQtys(List<DiscountTier> rows, List<int> expected) {
  final actual = rows.map((t) => t.minQty).toList();
  if (actual.length != expected.length) return false;
  for (var i = 0; i < expected.length; i++) {
    if (actual[i] != expected[i]) return false;
  }
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].sortOrder != i) return false;
  }
  return true;
}
