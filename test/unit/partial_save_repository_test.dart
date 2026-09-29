// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart' show Variable, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';

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
      expect(row.read<String>('piece_name'), '');
    });

    test('bucket existente → update (no duplicado)', () async {
      final ts = DateTime(2026, 9, 28, 12, 5);
      final id1 = await repo.savePartial(
        _partial(createdAt: ts, pieceName: 'Vaso'),
      );
      final id2 = await repo.savePartial(
        _partial(createdAt: ts, pieceName: 'Vaso actualizado'),
      );

      expect(id2, equals(id1), reason: 'Debe reusar la misma fila (upsert)');
      final row = await db.customSelect(
        'SELECT * FROM calculations WHERE id = ?',
        variables: [Variable.withInt(id1)],
      ).getSingle();
      expect(row.read<String>('piece_name'), 'Vaso actualizado');

      final count = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM calculations',
      ).getSingle();
      expect(count.read<int>('cnt'), 1, reason: 'Solo 1 fila, no duplicada');
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
}
