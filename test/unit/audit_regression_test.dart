// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/storage/calculation_draft.dart' as session;
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/calculation_engine.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_input.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/domain/lot_totals.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';
import 'package:tresdcal/features/settings/data/settings_repository.dart';

Decimal d(String v) => Decimal.parse(v);

/// Regresión de la auditoría 2026-10-04 (docs de revisión externa).
/// Cubre los contratos nuevos que cierran HIGH-01/02/03, MED-05/06/07/08:
/// - [LotTotals]: única fuente del total efectivo del lote.
/// - `CalculationEngine.computeFromSnapshot`: piso de minimumCharge +
///   equivalencia live↔snapshot con tasas idénticas.
/// - `CalculationListItem.effectiveTotal`: menos lote + piso.
/// - `CalculationRepository.create`: persiste tasas/printer reales y el
///   dashboard SQL (totalQuoted) coincide con el getter.
/// - `session.CalculationDraft`: roundtrip de `quantity` + tolerancia legacy.
///
/// Ronda 2 (2026-10-05, prefijo R2-):
/// - `R2-MED-04`: los borradores cuentan en TODAS las métricas del
///   dashboard (decisión F4) pero NO consumen el cap Free.
/// - `R2-MED-05`: `stateToPartialDto` persiste el escalón mayorista.
void main() {
  group('LotTotals (HIGH-01)', () {
    test('sin lote ni piso = unit x N (compatibilidad)', () {
      expect(
        LotTotals.total(unitTotal: d('90'), quantity: 10),
        d('900'),
      );
    });

    test('escenario de la auditoría: 100 x 10 - lote 100 = 900 -> 800 neto',
        () {
      expect(
        LotTotals.total(
          unitTotal: d('100.00'),
          quantity: 10,
          batchDiscount: d('100.00'),
        ),
        d('900'),
        reason: 'unit*qty - batch = 1000 - 100',
      );
    });

    test('piso minimumCharge*N gana sobre (unit*N - batch)', () {
      expect(
        LotTotals.total(
          unitTotal: d('40'),
          quantity: 2,
          batchDiscount: d('10'),
          minimumCharge: d('50'),
        ),
        d('100'),
        reason: 'max(80-10, 50*2) = 100 (floor post-lote, como el composer)',
      );
    });

    test('quantity < 1 se fija en 1', () {
      expect(
        LotTotals.total(unitTotal: d('10'), quantity: 0, batchDiscount: d('5')),
        d('5'),
      );
    });

    test('batchAmount = pct x (base+failure+markup) x N / 100', () {
      expect(
        LotTotals.batchAmount(
          base: d('60'),
          failure: d('20'),
          markup: d('20'),
          pct: d('10'),
          quantity: 10,
        ),
        d('100'),
      );
    });

    test('parseBatchAmount tolerante', () {
      expect(LotTotals.parseBatchAmount(null), Decimal.zero);
      expect(LotTotals.parseBatchAmount('garbage'), Decimal.zero);
      expect(LotTotals.parseBatchAmount('-5'), Decimal.zero);
      expect(LotTotals.parseBatchAmount('100.0'), d('100'));
    });
  });

  group('computeFromSnapshot + minimumCharge (HIGH-03A)', () {
    CalculationOutput liveUnit({required String minimumCharge}) {
      return CalculationEngine.compute(
        CalculationInput(
          materials: [
            MaterialInput(
              label: 'PLA',
              weightGrams: d('100'),
              pricePerBobbin: d('1000'),
              gramsPerBobbin: d('1000'),
            ),
          ],
          totalHours: Decimal.zero,
          discountPercentage: Decimal.zero,
          printerWatts: 0,
          kwhRate: Decimal.zero,
          profitBase: Decimal.zero,
          laborRate: Decimal.zero,
          postProcessRate: Decimal.zero,
          failureRate: Decimal.zero,
          markupOnMaterials: Decimal.zero,
          minimumCharge: d(minimumCharge),
        ),
      );
    }

    CalculationOutput? snapshotUnit({
      String minimumChargeSnapshot = '0',
      String? fallbackMinimumCharge,
    }) {
      return CalculationEngine.computeFromSnapshot(
        materials: const <MaterialSnapshot>[],
        materialCostSnapshot: 100,
        totalHours: 0,
        printerWattsSnapshot: 0,
        kwhRateSnapshot: 0,
        laborRateSnapshot: 0,
        postProcessRateSnapshot: 0,
        failureRateSnapshot: 0,
        markupOnMaterialsSnapshot: 0,
        profitBaseSnapshot: 0,
        discountPercentage: 0,
        fallbackKwhRate: Decimal.zero,
        fallbackLaborRate: Decimal.zero,
        fallbackPostProcessRate: Decimal.zero,
        fallbackFailureRate: Decimal.zero,
        fallbackMarkupOnMaterials: Decimal.zero,
        fallbackProfitBase: Decimal.zero,
        fallbackPrinterWatts: 0,
        minimumChargeSnapshot: double.parse(minimumChargeSnapshot),
        fallbackMinimumCharge: fallbackMinimumCharge == null
            ? null
            : d(fallbackMinimumCharge),
      );
    }

    test('sin piso: totalPrice = totalFinal - descuento (igual que antes)', () {
      expect(snapshotUnit()!.totalPrice, d('100'));
    });

    test('piso por snapshot: 100 < 150 -> 150', () {
      expect(
        snapshotUnit(minimumChargeSnapshot: '150')!.totalPrice,
        d('150'),
      );
    });

    test('filas legacy (snapshot 0) usan el fallback de Settings', () {
      expect(
        snapshotUnit(fallbackMinimumCharge: '120')!.totalPrice,
        d('120'),
      );
    });

    test('live vs snapshot con minimumCharge > 0 dan el MISMO total', () {
      final live = liveUnit(minimumCharge: '150');
      final snap = snapshotUnit(minimumChargeSnapshot: '150');
      expect(snap!.totalPrice, live.totalPrice);
    });
  });

  group('CalculationListItem.effectiveTotal (HIGH-01)', () {
    CalculationListItem item({
      double unit = 100,
      int quantity = 10,
      String? batch,
      double minCharge = 0,
    }) {
      return CalculationListItem(
        id: 1,
        createdAt: DateTime(2026, 10),
        quantity: quantity,
        totalHours: 1,
        discountPercentage: 0,
        isSold: false,
        isPartial: false,
        materialCostSnapshot: unit,
        electricCostSnapshot: 0,
        profitAmountSnapshot: 0,
        totalPriceSnapshot: unit,
        hasImage: false,
        batchDiscountAmount: batch,
        minimumChargeSnapshot: minCharge,
      );
    }

    test('descuenta el lote persistido', () {
      expect(item(batch: '100.0').effectiveTotal, d('900'));
    });

    test('sin lote = unit x N (legacy intacto)', () {
      expect(item().effectiveTotal, d('1000'));
    });

    test('respeta el piso minimumCharge x N', () {
      expect(
        item(unit: 40, quantity: 2, minCharge: 50).effectiveTotal,
        d('100'),
      );
    });
  });

  group('repo: snapshot real + paridad SQL/getter (HIGH-01/03B/MED-06)', () {
    late AppDatabase db;
    late CalculationRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = CalculationRepository(db);
    });
    tearDown(() async => db.close());

    Future<int> createWithLot({
      required int quantity,
      Decimal? batchAmount,
      Decimal? minimumCharge,
    }) {
      final materials = [
        MaterialInput(
          label: 'PLA',
          weightGrams: d('100'),
          pricePerBobbin: d('1000'),
          gramsPerBobbin: d('1000'),
        ),
      ];
      final input = CalculationInput(
        materials: materials,
        totalHours: Decimal.zero,
        discountPercentage: Decimal.zero,
        printerWatts: 120,
        kwhRate: d('0.75'),
        profitBase: Decimal.zero,
        laborRate: d('15'),
        postProcessRate: Decimal.zero,
        failureRate: Decimal.zero,
        markupOnMaterials: Decimal.zero,
        minimumCharge: minimumCharge ?? Decimal.zero,
      );
      final output = CalculationEngine.compute(input);
      return repo.create(
        CalculationDraft(
          materials: materials,
          totalHours: input.totalHours,
          discountPercentage: input.discountPercentage,
          output: output,
          quantity: quantity,
          pieceName: 'Lote',
          batchDiscountPercent: batchAmount == null ? null : d('10'),
          batchDiscountAmount: batchAmount,
          // F2: las tasas REALES ahora viajan en el draft.
          kwhRate: input.kwhRate,
          profitBase: input.profitBase,
          laborRate: input.laborRate,
          postProcessRate: input.postProcessRate,
          failureRate: input.failureRate,
          markupOnMaterials: input.markupOnMaterials,
          minimumCharge: input.minimumCharge,
          printerId: 7,
          printerName: 'Ender-3',
          printerWatts: input.printerWatts,
        ),
      );
    }

    test('persiste tasas y printer reales (antes: 0/null)', () async {
      final id = await createWithLot(quantity: 1);
      final row = await repo.getById(id);
      expect(row!.kwhRateSnapshot, 0.75);
      expect(row.laborRateSnapshot, 15.0);
      expect(row.printerWattsSnapshot, 120.0);
      expect(row.printerId, 7);
      expect(row.printerNameSnapshot, 'Ender-3');
    });

    test('getter == SQL del dashboard con lote (10 u, batch 100)', () async {
      // unit = 100 (material) → 1000 − 100 lote = 900.
      final id = await createWithLot(quantity: 10, batchAmount: d('100'));
      final expected = (await repo.listItems())
          .firstWhere((c) => c.id == id)
          .effectiveTotal;
      expect(expected, d('900'));
      final total = await repo.totalQuoted();
      expect(total, d('900'), reason: 'SQL = MAX(unit*q − batch, mc*q)');
    });

    test('piso de minimumCharge también en SQL (mc 150, unit 100)', () async {
      final id = await createWithLot(
        quantity: 2,
        batchAmount: d('50'),
        minimumCharge: d('150'),
      );
      final getter = (await repo.listItems())
          .firstWhere((c) => c.id == id)
          .effectiveTotal;
      // max(100*2 − 50, 150*2) = 300.
      expect(getter, d('300'));
      expect(await repo.totalQuoted(), d('300'));
    });

    test('minimumChargeAppliedSnapshot marca 1 cuando el piso subió el precio',
        () async {
      final id = await createWithLot(quantity: 1, minimumCharge: d('150'));
      final row = await repo.getById(id);
      expect(row!.minimumChargeAppliedSnapshot, 1);
      final plain = await createWithLot(quantity: 1);
      expect((await repo.getById(plain))!.minimumChargeAppliedSnapshot, 0);
    });

    test('HIGH-02: duplicate arrastra el escalón mayorista', () async {
      // unit 100 × 10 − lote 100 = 900 por fila.
      final id = await createWithLot(quantity: 10, batchAmount: d('100'));
      final copyId = await repo.duplicate(id);

      final copy = (await repo.listItems()).firstWhere((c) => c.id == copyId);
      expect(copy.batchDiscountPercent, isNotNull);
      expect(copy.batchDiscountAmount, isNotNull);
      // Sin el fix la copia pierde el escalón y suma 1000 en vez de 900.
      expect(copy.effectiveTotal, d('900'));
      expect(await repo.totalQuoted(), d('1800'), reason: '900 + 900');
    });

    test('HIGH-03: fila legacy (snapshot 0) usa Settings en getter Y SQL',
        () async {
      // Fila pre-F2: minimumChargeSnapshot = 0.
      final id = await createWithLot(quantity: 2);
      expect((await repo.getById(id))!.minimumChargeSnapshot, 0);

      // Sin cargo mínimo configurado: 100 × 2 = 200 en ambas rutas.
      expect(
        (await repo.listItems()).firstWhere((c) => c.id == id).effectiveTotal,
        d('200'),
      );
      expect(await repo.totalQuoted(), d('200'));

      // El usuario configura el cargo mínimo DESPUÉS: el detalle/PDF ya
      // aplicaban el fallback; ahora getter y SQL hacen lo mismo.
      await SettingsRepository(db).setMinimumCharge(d('150'));

      final item = (await repo.listItems()).firstWhere((c) => c.id == id);
      expect(item.effectiveTotal, d('300'), reason: 'getter: max(200, 150×2)');
      expect(
        await repo.totalQuoted(),
        d('300'),
        reason: 'SQL: MISMO fallback a la tabla settings',
      );
    });

    /// Borrador (`is_partial = 1`) mínimo válido — mismo shape que
    /// `_partial` de partial_save_repository_test.
    CalculationsCompanion draft({
      String client = 'Cliente Draft',
      double total = 50,
      bool sold = false,
    }) {
      return CalculationsCompanion(
        createdAt: Value(DateTime(2026, 10, 4, 12, 0)),
        pieceName: const Value('Borrador'),
        clientName: Value(client),
        printerWattsSnapshot: const Value(0),
        totalHours: const Value(2),
        printMinutes: const Value(30),
        discountPercentage: const Value(0),
        kwhRateSnapshot: const Value(0),
        profitBaseSnapshot: const Value(0),
        quantity: const Value(1),
        isSold: Value(sold),
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
        effectiveTotalSnapshot: Value(total),
        totalPriceSnapshot: Value(total),
        laborRateSnapshot: const Value(0),
        postProcessRateSnapshot: const Value(0),
        failureRateSnapshot: const Value(0),
        minimumChargeSnapshot: const Value(0),
        markupOnMaterialsSnapshot: const Value(0),
      );
    }

    test('R2-MED-04: cap Free sin borradores, dashboard con borradores',
        () async {
      await createWithLot(quantity: 1); // real: unit 100 → 100 BOB
      await repo.savePartial(draft()); // borrador: 50 BOB

      expect(await repo.countAll(), 1, reason: 'Free: el borrador no consume');
      expect(
        await repo.countAllIncludingDrafts(),
        2,
        reason: 'dashboard: el borrador SÍ cuenta (decisión F4)',
      );
      // La SUM del dashboard ya sumaba borradores (no filtraba is_partial).
      expect(await repo.totalQuoted(), d('150'), reason: '100 real + 50 borr.');
    });

    test('R2-MED-04: countSold cuenta borradores vendidos', () async {
      await repo.savePartial(draft(sold: true));
      expect(
        await repo.countSold(),
        1,
        reason: 'numerador (totalSold) y denominador: mismo universo',
      );
    });

    test('R2-MED-04: topClients ya no excluye borradores', () async {
      await createWithLot(quantity: 1); // sin cliente → no aparece en top
      await repo.savePartial(draft(client: 'Cliente Draft'));
      final labels = (await repo.topClients()).map((c) => c.label);
      expect(labels, contains('Cliente Draft'));
    });
  });

  group('draft de sesión: quantity (MED-07)', () {
    test('roundtrip preserva la cantidad', () {
      final draft = session.CalculationDraft(weight: '120', quantity: 12);
      final restored = session.CalculationDraft.tryDecode(draft.encode())!;
      expect(restored.quantity, 12);
    });

    test('draft legacy sin "quantity" cae a 1 sin romper decode', () {
      final legacy = jsonEncode({
        'weight': '120',
        'printHours': '2',
      });
      final restored = session.CalculationDraft.tryDecode(legacy)!;
      expect(restored.quantity, 1);
      expect(restored.weight, '120');
    });

    test('quantity corrupta ("0", negativa, string basura) degrada a 1', () {
      for (final raw in ['0', '-3', '"x"', 'null']) {
        final restored = session.CalculationDraft.tryDecode(
          '{"quantity":$raw}',
        )!;
        expect(restored.quantity, 1, reason: 'caso $raw');
      }
    });
  });

  group('stateToPartialDto: escalón mayorista (R2-MED-05)', () {
    CalculatorState baseState({
      Decimal? batchPercent,
      Decimal? batchAmount,
    }) {
      return CalculatorState(
        mode: CalculatorMode.express,
        printHours: '',
        printMinutes: '',
        discountPct: '0',
        weight: '0',
        filamentPrice: '0',
        filamentGrams: '0',
        label: '',
        materials: const [],
        output: null,
        quantity: 10,
        batchAppliedPercent: batchPercent,
        batchDiscountAmount: batchAmount,
      );
    }

    test('persiste percent y amount en el Companion', () {
      final dto = CalculatorNotifier.stateToPartialDto(
        baseState(batchPercent: d('10'), batchAmount: d('95')),
      );

      expect(dto.batchDiscountPercent.present, isTrue);
      expect(dto.batchDiscountPercent.value, '10');
      expect(dto.batchDiscountAmount.value, '95');
    });

    test('sin escalón: percent null explícito y amount "0"', () {
      final dto = CalculatorNotifier.stateToPartialDto(baseState());

      // Un null explícito != ausente: sin esto el autosave de un borrador
      // con escalón previo dejaba el percent viejo en la fila (upsert).
      expect(dto.batchDiscountPercent.present, isTrue);
      expect(dto.batchDiscountPercent.value, isNull);
      expect(dto.batchDiscountAmount.value, '0');
    });
  });
}
