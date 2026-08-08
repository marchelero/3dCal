// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';

/// Tests de `EntitlementRepository` (T3 del plan de monetizacion).
///
/// Verifica el contrato del repository sobre la tabla `entitlements`:
/// - `save` enforce la invariante "1 fila activa" desactivando la previa
///   antes de insertar la nueva (cuando el caller quiere estar activo).
/// - `getActive` retorna la unica fila activa o null.
/// - `clear` marca todas las inactivas SIN borrar (auditoria).
/// - `watchActive` emite reactivamente cuando cambia el estado.
///
/// **TDD**: este test se escribio ANTES del repository. La primera
/// ejecucion debe fallar (RED) — `EntitlementRepository` no existe.
/// Tras implementar, debe pasar (GREEN).
void main() {
  late AppDatabase db;
  late EntitlementRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftEntitlementRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------- helpers ----------

  /// Companion minimo: source + productId + purchasedAt required.
  /// Resto: defaults de Drift (isActive absent → DB default = true).
  EntitlementsCompanion entry({
    String source = 'play_store',
    String productId = 'tresdcal_pro_lifetime',
    DateTime? purchasedAt,
    DateTime? validatedAt,
    DateTime? expiresAt,
    String? receiptData,
    Value<bool>? isActive,
  }) {
    return EntitlementsCompanion.insert(
      source: source,
      productId: productId,
      purchasedAt: purchasedAt ?? DateTime.utc(2026, 7, 22),
      validatedAt: validatedAt == null ? const Value.absent() : Value(validatedAt),
      expiresAt: expiresAt == null ? const Value.absent() : Value(expiresAt),
      receiptData: receiptData == null ? const Value.absent() : Value(receiptData),
      isActive: isActive ?? const Value.absent(),
    );
  }

  // ---------- save ----------

  group('save', () {
    test('inserta nueva fila, retorna id > 0, fila queda activa', () async {
      final id = await repo.save(entry(productId: 'A'));
      expect(id, greaterThan(0));

      final active = await repo.getActive();
      expect(active, isNotNull);
      expect(active!.id, id);
      expect(active.productId, 'A');
      expect(active.isActive, isTrue);
    });

    test('segunda vez desactiva la primera y activa la nueva (invariant: '
        'solo 1 activa)', () async {
      final id1 = await repo.save(entry(productId: 'A'));
      final id2 = await repo.save(entry(productId: 'B'));

      expect(id1, isNot(id2));

      final active = await repo.getActive();
      expect(active, isNotNull);
      expect(active!.id, id2);
      expect(active.productId, 'B');

      // La primera fila sigue existiendo pero como inactiva.
      final firstRow = await (db.select(db.entitlements)
            ..where((e) => e.id.equals(id1)))
          .getSingle();
      expect(firstRow.isActive, isFalse,
          reason: 'La fila previa debe quedar isActive=false al reemplazarla.');

      // Solo 1 fila activa en la DB.
      final allActive = await (db.select(db.entitlements)
            ..where((e) => e.isActive.equals(true)))
          .get();
      expect(allActive, hasLength(1));
    });

    test('isActive=true explicito: misma logica que absent (deactiva previa)',
        () async {
      await repo.save(entry(productId: 'A'));
      final id2 = await repo.save(
        entry(productId: 'B', isActive: const Value(true)),
      );

      final active = await repo.getActive();
      expect(active!.id, id2);
      expect(active.productId, 'B');
    });

    test('isActive=false explicito: inserta como inactiva, NO toca la activa '
        'existente', () async {
      final idActive = await repo.save(entry(productId: 'A'));
      final idHistorical = await repo.save(
        entry(productId: 'H', isActive: const Value(false)),
      );

      // La activa sigue siendo A.
      final active = await repo.getActive();
      expect(active!.id, idActive);
      expect(active.productId, 'A');

      // La historica esta inactiva.
      final historical = await (db.select(db.entitlements)
            ..where((e) => e.id.equals(idHistorical)))
          .getSingle();
      expect(historical.isActive, isFalse);
      expect(historical.productId, 'H');

      // Sigue habiendo 1 sola activa.
      final allActive = await (db.select(db.entitlements)
            ..where((e) => e.isActive.equals(true)))
          .get();
      expect(allActive, hasLength(1));
    });

    test('persiste columnas opcionales (validatedAt, expiresAt, receiptData)',
        () async {
      final purchased = DateTime.utc(2026, 1, 15);
      final validated = DateTime.utc(2026, 7, 22);
      final expires = DateTime.utc(2027, 1, 15);

      final id = await repo.save(entry(
        purchasedAt: purchased,
        validatedAt: validated,
        expiresAt: expires,
        receiptData: 'base64blob',
      ));

      final row = await (db.select(db.entitlements)
            ..where((e) => e.id.equals(id)))
          .getSingle();
      expect(row.purchasedAt.toUtc(), purchased);
      expect(row.validatedAt!.toUtc(), validated);
      expect(row.expiresAt!.toUtc(), expires);
      expect(row.receiptData, 'base64blob');
    });

  });

  // ---------- getActive ----------

  group('getActive', () {
    test('retorna null si la DB esta vacia', () async {
      final active = await repo.getActive();
      expect(active, isNull);
    });

    test('retorna la fila con isActive=true si hay', () async {
      final id = await repo.save(entry(productId: 'A'));
      final active = await repo.getActive();
      expect(active, isNotNull);
      expect(active!.id, id);
      expect(active.isActive, isTrue);
    });

    test('retorna null si todas las filas estan inactivas', () async {
      await repo.save(entry(productId: 'A', isActive: const Value(false)));
      await repo.save(entry(productId: 'B', isActive: const Value(false)));

      final active = await repo.getActive();
      expect(active, isNull);
    });

    test('retorna exactamente 1 fila aunque haya varias inactivas', () async {
      await repo.save(entry(productId: 'A'));
      // Inserts historicos manuales (no deberia haber mas de 1 activa):
      await repo.save(entry(productId: 'H1', isActive: const Value(false)));
      await repo.save(entry(productId: 'H2', isActive: const Value(false)));

      final active = await repo.getActive();
      expect(active, isNotNull);
      expect(active!.productId, 'A');
    });
  });

  // ---------- clear ----------

  group('clear', () {
    test('marca todas las filas como inactivas (count active = 0)', () async {
      await repo.save(entry(productId: 'A'));
      await repo.save(entry(productId: 'B', isActive: const Value(false)));

      final affected = await repo.clear();
      expect(affected, greaterThan(0));

      final active = await repo.getActive();
      expect(active, isNull);
    });

    test('NO borra filas — mantiene historial (auditoria)', () async {
      await repo.save(entry(productId: 'A'));
      await repo.save(entry(productId: 'B'));

      final totalBefore = await db.select(db.entitlements).get();
      expect(totalBefore, hasLength(2));

      await repo.clear();

      final totalAfter = await db.select(db.entitlements).get();
      expect(totalAfter, hasLength(2),
          reason: 'clear() debe preservar las filas — solo cambia isActive.');
      expect(totalAfter.every((r) => r.isActive == false), isTrue);
    });

    test('retorna el count de filas afectadas', () async {
      await repo.save(entry(productId: 'A'));
      await repo.save(entry(productId: 'B', isActive: const Value(false)));
      await repo.save(entry(productId: 'C', isActive: const Value(false)));

      final affected = await repo.clear();
      expect(affected, 3);
    });

    test('retorna 0 si la DB ya estaba vacia', () async {
      final affected = await repo.clear();
      expect(affected, 0);
    });
  });

  // ---------- watchActive ----------

  group('watchActive', () {
    test('emite null al suscribirse si DB vacia', () async {
      await expectLater(repo.watchActive(), emits(null));
    });

    test('emite la fila activa al suscribirse', () async {
      final id = await repo.save(entry(productId: 'A'));

      await expectLater(
        repo.watchActive(),
        emits(predicate<Entitlement>((e) => e.id == id && e.productId == 'A')),
      );
    });

    test('emite null cuando clear() desactiva la activa', () async {
      await repo.save(entry(productId: 'A'));

      // Importante: NO `await expectLater(...)` antes del trigger — eso
      // bloquearia el test y clear() nunca se llamaria. Pattern: assign
      // future, trigger, await future.
      final future = expectLater(
        repo.watchActive(),
        emitsInOrder([
          predicate<Entitlement>((e) => e.productId == 'A'),
          null,
        ]),
      );
      await repo.clear();
      await future;
    });

    test('emite nueva fila cuando save() reemplaza la activa', () async {
      final id1 = await repo.save(entry(productId: 'A'));
      final id2Future = expectLater(
        repo.watchActive(),
        emitsInOrder([
          predicate<Entitlement>((e) => e.id == id1 && e.productId == 'A'),
          predicate<Entitlement>((e) => e.id != id1 && e.productId == 'B'),
        ]),
      );
      await repo.save(entry(productId: 'B'));
      await id2Future;
    });
  });

  // ---------- invariantes cross-metodo ----------

  group('invariantes cross-metodo', () {
    test('save → clear → save: segunda save reactiva correctamente', () async {
      await repo.save(entry(productId: 'A'));
      await repo.clear();

      // Despues de clear, no hay activa. Save nuevo debe ser la activa.
      final id2 = await repo.save(entry(productId: 'B'));
      final active = await repo.getActive();
      expect(active!.id, id2);
      expect(active.productId, 'B');

      // La fila vieja (A) sigue existiendo como inactiva.
      final oldRow = await (db.select(db.entitlements)
            ..where((e) => e.productId.equals('A')))
          .getSingle();
      expect(oldRow.isActive, isFalse);
    });

    test('multiples saves con mismas opciones solo generan 1 activa', () async {
      await repo.save(entry(productId: 'A'));
      await repo.save(entry(productId: 'B'));
      await repo.save(entry(productId: 'C'));

      final allActive = await (db.select(db.entitlements)
            ..where((e) => e.isActive.equals(true)))
          .get();
      expect(allActive, hasLength(1));
      expect(allActive.first.productId, 'C');
    });
  });
}
