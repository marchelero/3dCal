// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Variable, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';

/// Unit tests para los metodos de guardado parcial en [CalculationRepository]:
/// - savePartial (insert + update/upsert)
/// - deletePartial
/// - findLatestPartialForMinute
void main() {
  late AppDatabase db;
  late CalculationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CalculationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  CalculationsCompanion _partial({
    DateTime? createdAt,
    String? pieceName,
    int? quantity,
  }) {
    return CalculationsCompanion(
      createdAt: Value(createdAt ?? DateTime(2026, 9, 28, 12, 0)),
      pieceName: Value(pieceName ?? ''),
      clientName: const Value(''),
      notes: const Value.absent(),
      conditions: const Value.absent(),
      printerId: const Value.absent(),
      printerNameSnapshot: const Value.absent(),
      printerWattsSnapshot: const Value(0),
      totalHours: const Value(2.0),
      printMinutes: const Value(30),
      discountPercentage: const Value(0),
      kwhRateSnapshot: const Value(0),
      profitBaseSnapshot: const Value(0),
      quantity: Value(quantity ?? 1),
      isSold: const Value(false),
      isTemplate: const Value(false),
      isPartial: const Value(true),
      materialCostSnapshot: const Value(10),
      electricCostSnapshot: const Value(0),
      amortizationCostSnapshot: const Value(0),
      laborCostSnapshot: const Value(0),
      postProcessCostSnapshot: const Value(0),
      baseCostSnapshot: const Value(10),
      failureCostSnapshot: const Value(0),
      markupCostSnapshot: const Value(0),
      profitAmountSnapshot: const Value(0),
      minimumChargeAppliedSnapshot: const Value(0),
      effectiveTotalSnapshot: const Value(10),
      totalPriceSnapshot: const Value(10),
      laborRateSnapshot: const Value(0),
      postProcessRateSnapshot: const Value(0),
      failureRateSnapshot: const Value(0),
      minimumChargeSnapshot: const Value(0),
      markupOnMaterialsSnapshot: const Value(0),
      pieceImageBlob: const Value.absent(),
      batchDiscountPercent: const Value.absent(),
      batchDiscountAmount: const Value.absent(),
    );
  }

  group('savePartial', () {
    test('bucket nuevo → insert (devuelve id nuevo)', () async {
      final ts = DateTime(2026, 9, 28, 12, 0);
      final id = await repo.savePartial(_partial(createdAt: ts));

      expect(id, greaterThan(0));
      final row = await db.customSelect(
        'SELECT * FROM calculations WHERE id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      expect(row.read<int>('is_partial'), 1);
      // El helper del test pasa pieceName='' explicito; el dto de produccion
      // lo deja ausente (columna default). Cubrimos el caso del helper.
      expect(row.read<String?>('piece_name'), anyOf(isNull, isEmpty));
    });

    test('sin existingId inserta fila nueva (identidad por id, no por minuto)',
        () async {
      final ts = DateTime(2026, 9, 28, 12, 5);
      final id1 = await repo.savePartial(
        _partial(createdAt: ts, pieceName: 'Vaso'),
      );
      final id2 = await repo.savePartial(
        _partial(createdAt: ts, pieceName: 'Vaso 2'),
      );

      expect(id2, isNot(equals(id1)), reason: 'sin existingId = insert nuevo');
      final count = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM calculations',
      ).getSingle();
      expect(count.read<int>('cnt'), 2);
    });

    test('existingId → update (no duplicado, conserva createdAt)', () async {
      final ts = DateTime(2026, 9, 28, 12, 5);
      final id1 = await repo.savePartial(
        _partial(createdAt: ts, pieceName: 'Vaso'),
      );
      final id2 = await repo.savePartial(
        _partial(createdAt: ts.add(const Duration(minutes: 3)), pieceName: 'Vaso actualizado'),
        existingId: id1,
      );

      expect(id2, equals(id1), reason: 'Debe reusar la misma fila (upsert)');
      final row = await db.customSelect(
        'SELECT * FROM calculations WHERE id = ?',
        variables: [Variable.withInt(id1)],
      ).getSingle();
      expect(row.read<String?>('piece_name'), 'Vaso actualizado');
      expect(
        row.read<DateTime>('created_at'),
        ts,
        reason: 'el upsert no debe tocar createdAt',
      );

      final count = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM calculations',
      ).getSingle();
      expect(count.read<int>('cnt'), 1, reason: 'Solo 1 fila, no duplicada');
    });

    test('existingId conserva pieceName/clientName si el patch los trae ausentes', () async {
      final ts = DateTime(2026, 9, 28, 12, 10);
      final id = await repo.savePartial(
        _partial(createdAt: ts, pieceName: 'Taza'),
      );
      // Patch tipico del autosave: nombres absentes, totales nuevos.
      await repo.savePartial(
        CalculationsCompanion(
          createdAt: Value(ts),
          pieceName: const Value.absent(),
          clientName: const Value.absent(),
          totalPriceSnapshot: const Value(99),
          effectiveTotalSnapshot: const Value(99),
          isPartial: const Value(true),
        ),
        existingId: id,
      );
      final row = await db.customSelect(
        'SELECT * FROM calculations WHERE id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      expect(row.read<String?>('piece_name'), 'Taza');
      expect(row.read<double>('total_price_snapshot'), 99);
    });
  });

  group('deletePartial', () {
    test('elimina un parcial por id', () async {
      final ts = DateTime(2026, 9, 28, 13, 0);
      final id = await repo.savePartial(_partial(createdAt: ts));
      await repo.deletePartial(id);

      final row = await db.customSelect(
        'SELECT * FROM calculations WHERE id = ?',
        variables: [Variable.withInt(id)],
      ).getSingleOrNull();
      expect(row, isNull);
    });
  });

  group('savePartial: materiales (regresion)', () {
    DraftMaterialInput mat(String label, double w) => DraftMaterialInput(
      label: label,
      weightGrams: w,
      pricePerBobbin: 150,
      gramsPerBobbin: 1000,
    );

    test('persiste los materiales del parcial (no se perdian al reusar)', () async {
      final ts = DateTime(2026, 9, 28, 16, 0);
      final id = await repo.savePartial(
        _partial(createdAt: ts),
        materials: [mat('PLA', 120), mat('ABS', 80)],
      );

      final mats = await repo.materialsOf(id);
      expect(mats.length, 2);
      expect(mats.map((m) => m.label).toSet(), {'PLA', 'ABS'});
    });

    test('upsert con existingId reemplaza (no duplica) materiales', () async {
      final ts = DateTime(2026, 9, 28, 16, 30);
      final id1 = await repo.savePartial(
        _partial(createdAt: ts),
        materials: [mat('PLA', 120), mat('ABS', 80)],
      );
      final id2 = await repo.savePartial(
        _partial(createdAt: ts),
        materials: [mat('PLA', 100)],
        existingId: id1,
      );
      expect(id2, equals(id1));

      final mats = await repo.materialsOf(id1);
      expect(mats.length, 1, reason: 'La lista vieja debe desaparecer');
      expect(mats.single.label, 'PLA');
    });

    test('borrar el parcial borra tambien sus materiales', () async {
      final ts = DateTime(2026, 9, 28, 17, 0);
      final id = await repo.savePartial(
        _partial(createdAt: ts),
        materials: [mat('PLA', 120)],
      );
      expect((await repo.materialsOf(id)).length, 1);

      await repo.deletePartial(id);

      final orphans = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM calculation_materials WHERE calculation_id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      expect(orphans.read<int>('cnt'), 0, reason: 'Sin filas huerfanas');
    });

    test('express (sin materiales) no rompe', () async {
      final id = await repo.savePartial(
        _partial(createdAt: DateTime(2026, 9, 28, 18, 0)),
      );
      expect(await repo.materialsOf(id), isEmpty);
    });

    test('persiste el desglose de tiempo propio por material (v15)', () async {
      final id = await repo.savePartial(
        _partial(createdAt: DateTime(2026, 9, 28, 19, 0)),
        materials: [
          DraftMaterialInput(
            label: 'PLA',
            weightGrams: 120,
            pricePerBobbin: 150,
            gramsPerBobbin: 1000,
            useOwnTime: true,
            materialHours: 2,
            materialMinutes: 30,
          ),
          // Sin tiempo propio: se persiste como false (= tiempo global).
          const DraftMaterialInput(
            label: 'ABS',
            weightGrams: 80,
            pricePerBobbin: 160,
            gramsPerBobbin: 1000,
          ),
        ],
      );

      final byLabel = {for (final m in await repo.materialsOf(id)) m.label: m};
      final pla = byLabel['PLA']!;
      expect(pla.useOwnTime, isTrue);
      expect(pla.materialHours, 2.0);
      expect(pla.materialMinutes, 30.0);

      final abs = byLabel['ABS']!;
      expect(abs.useOwnTime, isFalse, reason: 'usaba el tiempo global');
      expect(abs.materialHours, isNull);
    });

    test('el upsert con existingId actualiza el desglose viejo en vez de duplicarlo', () async {
      final ts = DateTime(2026, 9, 28, 20, 0);
      final id1 = await repo.savePartial(
        _partial(createdAt: ts),
        materials: [mat('PLA', 120)],
      );
      final id2 = await repo.savePartial(
        _partial(createdAt: ts),
        materials: [
          DraftMaterialInput(
            label: 'PLA',
            weightGrams: 120,
            pricePerBobbin: 150,
            gramsPerBobbin: 1000,
            useOwnTime: true,
            materialHours: 1,
            materialMinutes: 15,
          ),
        ],
        existingId: id1,
      );
      expect(id2, equals(id1));

      final mats = await repo.materialsOf(id1);
      expect(mats, hasLength(1));
      expect(mats.single.useOwnTime, isTrue);
      expect(mats.single.materialMinutes, 15.0);
    });
  });

  group('borradores (partial): visibles en historial, fuera del cap', () {
    /// Crear un borrador via savePartial.
    Future<int> seedDraft(int minute) =>
        repo.savePartial(_partial(createdAt: DateTime(2026, 10, 3, 12, minute)));

    test('countAll excluye borradores (no consumen el cap free)', () async {
      await seedDraft(0);
      await seedDraft(1);
      await seedDraft(2);
      expect(await repo.countAll(), 0, reason: 'borradores no cuentan');
    });

    test('listItems SI muestra borradores (retomables desde historial)',
        () async {
      await seedDraft(0);
      await seedDraft(1);
      final items = await repo.listItems();
      expect(items, hasLength(2));
      expect(items.every((i) => i.isPartial), isTrue);
    });

    test('con el cap lleno de borradores, un save real SI entra', () async {
      // 10 borradores (el cap free) + un save real.
      for (var i = 0; i < 10; i++) {
        await seedDraft(i);
      }
      final draft = CalculationDraft(
        materials: const [],
        totalHours: Decimal.fromInt(2),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.fromInt(12),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.fromInt(12),
        ),
        clientName: 'Cliente',
      );
      final id = await repo.createIfWithinLimit(draft, limit: kFreeHistoryCap);
      expect(id, isNotNull, reason: 'los borradores no deben llenar el cap');
      // Historial: 10 borradores + 1 real.
      expect(await repo.listItems(), hasLength(11));
    });
  });

  group('findLatestPartialForMinute', () {
    test('filtra correctamente por timestamp truncado', () async {
      final bucket = DateTime(2026, 9, 28, 14, 0);
      final ts1 = DateTime(2026, 9, 28, 14, 0, 10);
      final ts2 = DateTime(2026, 9, 28, 14, 0, 50);
      final tsOutside = DateTime(2026, 9, 28, 14, 2, 0);

      await repo.savePartial(_partial(createdAt: ts1, pieceName: 'Primero'));
      await repo.savePartial(_partial(createdAt: ts2, pieceName: 'Segundo'));
      await repo.savePartial(
        _partial(createdAt: tsOutside, pieceName: 'Fuera'),
      );

      final latest = await repo.findLatestPartialForMinute(bucket);
      expect(latest, isNotNull);
      expect(latest!.pieceName, 'Segundo', reason: 'El mas reciente del bucket');
    });

    test('retorna null si no hay parciales en el bucket', () async {
      final bucket = DateTime(2026, 9, 28, 15, 0);
      final latest = await repo.findLatestPartialForMinute(bucket);
      expect(latest, isNull);
    });
  });

  group('watchLatestPartial', () {
    test('emite null cuando no hay parciales', () async {
      await expectLater(repo.watchLatestPartial(), emitsInOrder([null]));
    });

    test('re-emite al insertar un parcial (sin invalidate manual)', () async {
      // Pattern: asignar el future del matcher, disparar el trigger, await.
      // El stream emite el estado actual (null) y luego el nuevo parcial.
      final future = expectLater(
        repo.watchLatestPartial(),
        emitsInOrder([
          null,
          predicate<Calculation>((c) => c.pieceName == 'Uno'),
        ]),
      );
      await repo.savePartial(_partial(pieceName: 'Uno'));
      await future;
    });

    test('re-emite al actualizar un parcial por id (autosave)', () async {
      final id = await repo.savePartial(_partial(pieceName: 'Viejo'));
      await repo.savePartial(_partial(pieceName: 'Otro', createdAt: DateTime(2026, 9, 28, 13, 0)));
      final existing = await repo.getById(id);

      final future = expectLater(
        repo.watchLatestPartial(),
        emitsThrough(
          predicate<Calculation>((c) => c.id == id && c.pieceName == 'Editado'),
        ),
      );
      await repo.updatePartial(
        id,
        existing!.toCompanion(true).copyWith(pieceName: const Value('Editado')),
      );
      await future;
    });

    test('re-emite al borrar el parcial mas reciente', () async {
      await repo.savePartial(_partial(pieceName: 'Primero'));
      final id = await repo.savePartial(
        _partial(pieceName: 'Segundo', createdAt: DateTime(2026, 9, 28, 11, 0)),
      );

      final future = expectLater(
        repo.watchLatestPartial(),
        emitsThrough(
          predicate<Calculation>((c) => c.pieceName == 'Primero'),
        ),
      );
      await repo.deletePartial(id);
      await future;
    });
  });
}
