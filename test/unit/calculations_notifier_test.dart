// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/notifiers/calculations_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/notifiers/history_sort.dart';

/// Unit tests del pipeline de filtros del historial avanzado
/// (PRD 2026-09-11). Cubren:
/// - search matchea labels de materiales (no solo piece/client).
/// - dateRange filtra por `createdAt.toLocal()` (inclusivo en bornes).
/// - clientFilter exacto case-insensitive.
/// - sort por precio efectivo (unitario x cantidad) y clientes A-Z.
/// - combinacion AND de search + sold + date + client.
/// - resumen: conteo + total efectivo del set filtrado.
/// - la nueva query `materialLabelsByCalcId` del repo.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CalculationsNotifier notifier;
  late CalculationRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    notifier = container.read(calculationsNotifierProvider.notifier);
    repo = container.read(calculationRepositoryProvider);
    await container.read(calculationsNotifierProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Inserta una cotizacion con control total de campos.
  Future<int> seedCalculation(
    AppDatabase db, {
    required String piece,
    String? client,
    String material = 'PLA',
    Decimal? price,
    int quantity = 1,
    DateTime? createdAtUtc,
    bool sold = false,
    List<String>? materials,
  }) {
    final finalPrice = price ?? Decimal.parse('10');
    return repo
        .create(
          CalculationDraft(
            materials: [
              for (final label in (materials ?? [material]))
                MaterialInput(
                  label: label,
                  weightGrams: Decimal.parse('100'),
                  pricePerBobbin: Decimal.parse('120'),
                  gramsPerBobbin: Decimal.parse('1000'),
                ),
            ],
            totalHours: Decimal.parse('2'),
            discountPercentage: Decimal.zero,
            output: CalculationOutput.simple(
              materialCost: Decimal.parse('10'),
              discountAmount: Decimal.zero,
              totalPrice: finalPrice,
            ),
            pieceName: piece,
            clientName: client,
            quantity: quantity,
          ),
        )
        .then((id) async {
          if (createdAtUtc != null) {
            await (db.update(db.calculations)..where((c) => c.id.equals(id)))
                .write(CalculationsCompanion(createdAt: Value(createdAtUtc)));
          }
          if (sold) {
            await (db.update(db.calculations)..where((c) => c.id.equals(id)))
                .write(CalculationsCompanion(isSold: const Value(true)));
          }
          return id;
        });
  }

  List<String> pieces() => [
    for (final c
        in container.read(calculationsNotifierProvider).value ??
            <CalculationListItem>[])
      c.pieceName ?? '',
  ];

  group('CalculationsNotifier.search', () {
    test(
      'matchea por label de material aunque no este en piece/client',
      () async {
        await seedCalculation(
          db,
          piece: 'Pieza sin pista',
          client: 'Cliente X',
          material: 'PLA+',
        );
        await seedCalculation(
          db,
          piece: 'Otra pieza',
          client: 'Otro cliente',
          material: 'PETG',
        );
        await notifier.refresh();

        notifier.search('pla+');

        expect(pieces(), ['Pieza sin pista']);
      },
    );

    test('search vacio restaura la lista completa', () async {
      // Tokens unicos: el cliente compartido contiene 'a', por eso se busca
      // un texto que solo existe en la pieza A.
      await seedCalculation(db, piece: 'pzaalpha');
      await seedCalculation(db, piece: 'pzabeta');
      await notifier.refresh();

      notifier.search('alpha');
      expect(pieces(), ['pzaalpha']);

      notifier.search('');
      expect(pieces(), hasLength(2));
    });
  });

  group('CalculationsNotifier.dateRange', () {
    test('filtra por createdAt.toLocal() (rolling 7d)', () async {
      final now = DateTime.now();
      await seedCalculation(db, piece: 'Reciente');
      await seedCalculation(
        db,
        piece: 'Vieja',
        createdAtUtc: now.toUtc().subtract(const Duration(days: 10)),
      );
      await notifier.refresh();

      notifier.setDateRange(
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      );

      expect(pieces(), ['Reciente']);
    });

    test('inclusivo en ambos bornes (start y end incluidos)', () async {
      // drift guarda DateTime con precision de 1 segundo: los bornes deben
      // ser segundos enteros para que el seed toUtc() mapee 1:1 al leerlos.
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      final end = start.add(const Duration(days: 2));
      await seedCalculation(db, piece: 'EnStart', createdAtUtc: start.toUtc());
      await seedCalculation(db, piece: 'EnEnd', createdAtUtc: end.toUtc());
      await seedCalculation(
        db,
        piece: 'Fuera',
        createdAtUtc: end.toUtc().subtract(const Duration(days: 30)),
      );
      await notifier.refresh();

      notifier.setDateRange(DateTimeRange(start: start, end: end));

      expect(pieces(), ['EnEnd', 'EnStart']);
    });

    test('setDateRange(null) limpia el rango', () async {
      final now = DateTime.now();
      await seedCalculation(db, piece: 'A');
      await seedCalculation(
        db,
        piece: 'Vieja',
        createdAtUtc: now.toUtc().subtract(const Duration(days: 10)),
      );
      await notifier.refresh();

      notifier.setDateRange(
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      );
      expect(pieces(), ['A']);

      notifier.setDateRange(null);
      expect(pieces(), hasLength(2));
    });
  });

  group('CalculationsNotifier.clientFilter', () {
    test('matchea exacto case-insensitive (no substring)', () async {
      await seedCalculation(db, piece: 'A', client: 'Juan Perez');
      await seedCalculation(db, piece: 'B', client: 'JUAN PEREZ');
      await seedCalculation(db, piece: 'C', client: 'Maria');
      await notifier.refresh();

      notifier.setClientFilter('juan perez');
      expect(pieces(), hasLength(2));

      // Exact match: 'juan' no matchea 'Juan Perez'.
      notifier.setClientFilter('juan');
      expect(pieces(), isEmpty);
    });

    test('setClientFilter(null) restaura todos', () async {
      await seedCalculation(db, piece: 'A', client: 'Solo');
      await seedCalculation(db, piece: 'B', client: 'Otro');
      await notifier.refresh();

      notifier.setClientFilter('Solo');
      expect(pieces(), ['A']);

      notifier.setClientFilter(null);
      expect(pieces(), hasLength(2));
    });
  });

  group('CalculationsNotifier.sort', () {
    test('default = fecha reciente (comportamiento actual intacto)', () async {
      final now = DateTime.now();
      await seedCalculation(
        db,
        piece: 'A',
        createdAtUtc: now.toUtc().subtract(const Duration(days: 3)),
      );
      await seedCalculation(
        db,
        piece: 'B',
        createdAtUtc: now.toUtc().subtract(const Duration(days: 2)),
      );
      await seedCalculation(
        db,
        piece: 'C',
        createdAtUtc: now.toUtc().subtract(const Duration(days: 1)),
      );
      await notifier.refresh();

      expect(pieces(), ['C', 'B', 'A']);

      notifier.setSort(HistorySort.dateOldest);
      expect(pieces(), ['A', 'B', 'C']);
    });

    test(
      'priceHigh/priceLow usan el total efectivo (unitario x cantidad)',
      () async {
        // A = 100 x1 = 100 ; B = 60 x3 = 180 ; C = 50 x1 = 50.
        await seedCalculation(
          db,
          piece: 'A',
          price: Decimal.parse('100'),
          quantity: 1,
        );
        await seedCalculation(
          db,
          piece: 'B',
          price: Decimal.parse('60'),
          quantity: 3,
        );
        await seedCalculation(
          db,
          piece: 'C',
          price: Decimal.parse('50'),
          quantity: 1,
        );
        await notifier.refresh();

        notifier.setSort(HistorySort.priceHigh);
        expect(pieces(), ['B', 'A', 'C']);

        notifier.setSort(HistorySort.priceLow);
        expect(pieces(), ['C', 'A', 'B']);
      },
    );

    test(
      'quantity < 1 se trata como 1 (mismo patron que _effectiveTotal)',
      () async {
        await seedCalculation(
          db,
          piece: 'A',
          price: Decimal.parse('100'),
          quantity: 0,
        );
        await seedCalculation(
          db,
          piece: 'B',
          price: Decimal.parse('200'),
          quantity: 1,
        );
        await notifier.refresh();

        notifier.setSort(HistorySort.priceHigh);
        expect(pieces(), ['B', 'A']);
      },
    );

    test('clientAz ordena por nombre de cliente case-insensitive', () async {
      await seedCalculation(db, piece: 'A', client: 'zeta');
      await seedCalculation(db, piece: 'B', client: 'Maria');
      await seedCalculation(db, piece: 'C', client: 'JUAN');
      await notifier.refresh();

      notifier.setSort(HistorySort.clientAz);
      expect(pieces(), ['C', 'B', 'A']);
    });
  });

  group('CalculationsNotifier.combinacion', () {
    test('search + sold + date + client con AND', () async {
      final now = DateTime.now();
      // Unico que cumple los 4 filtros: Juan, vendida, hoy, con PLA+.
      await seedCalculation(
        db,
        piece: 'JuanHoy',
        client: 'Juan',
        material: 'PLA+',
        sold: true,
      );
      await seedCalculation(
        db,
        piece: 'NoMaterial',
        client: 'Juan',
        material: 'PETG',
        sold: true,
      );
      await seedCalculation(
        db,
        piece: 'NoCliente',
        client: 'Maria',
        material: 'PLA+',
        sold: true,
      );
      await seedCalculation(
        db,
        piece: 'NoFecha',
        client: 'Juan',
        material: 'PLA+',
        sold: true,
        createdAtUtc: now.toUtc().subtract(const Duration(days: 10)),
      );
      await notifier.refresh();

      notifier.search('pla+');
      notifier.setSoldFilter(true);
      notifier.setClientFilter('juan');
      notifier.setDateRange(
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      );

      expect(pieces(), ['JuanHoy']);
    });

    test('limpiar UN filtro no resetea los demas', () async {
      final now = DateTime.now();
      await seedCalculation(
        db,
        piece: 'Match',
        client: 'Juan',
        material: 'PLA',
        sold: true,
      );
      await seedCalculation(
        db,
        piece: 'Pendiente',
        client: 'Juan',
        material: 'PLA',
      );
      await notifier.refresh();

      notifier.setSoldFilter(true);
      notifier.setClientFilter('juan');
      notifier.setDateRange(
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      );
      expect(pieces(), ['Match']);

      notifier.setClientFilter(null);
      // Sold + date siguen aplicando: 'Pendiente' queda fuera por soldFilter.
      expect(pieces(), ['Match']);
    });
  });

  group('CalculationsNotifier.resumen', () {
    test(
      'conteo + total efectivo del set filtrado (sort no lo cambia)',
      () async {
        await seedCalculation(
          db,
          piece: 'A',
          price: Decimal.parse('100'),
          quantity: 1,
        );
        await seedCalculation(
          db,
          piece: 'B',
          price: Decimal.parse('60'),
          quantity: 3,
        );
        await seedCalculation(
          db,
          piece: 'C',
          price: Decimal.parse('50'),
          quantity: 1,
        );
        await notifier.refresh();

        notifier.setSort(HistorySort.priceLow);

        final items = container.read(calculationsNotifierProvider).value!;
        final total = items.fold<Decimal>(
          Decimal.zero,
          (acc, c) => acc + effectiveTotal(c),
        );

        expect(items, hasLength(3));
        expect(total, Decimal.parse('330'));
      },
    );

    test(
      'effectiveTotal = unitario x cantidad, clamp quantity<1 a 1',
      () async {
        await seedCalculation(
          db,
          piece: 'Lote',
          price: Decimal.parse('12.50'),
          quantity: 4,
        );
        await seedCalculation(
          db,
          piece: 'Cero',
          price: Decimal.parse('12.50'),
          quantity: 0,
        );
        await notifier.refresh();

        final items = container.read(calculationsNotifierProvider).value!;
        final lote = items.singleWhere((c) => c.pieceName == 'Lote');
        final cero = items.singleWhere((c) => c.pieceName == 'Cero');

        expect(effectiveTotal(lote), Decimal.parse('50.00'));
        expect(effectiveTotal(cero), Decimal.parse('12.50'));
      },
    );
  });

  group('CalculationRepository.materialLabelsByCalcId', () {
    test('mapea id -> label y excluye plantillas', () async {
      final a = await seedCalculation(db, piece: 'A', material: 'PLA');
      final b = await seedCalculation(db, piece: 'B', material: 'PETG');
      await repo.createTemplate(
        CalculationDraft(
          materials: [
            MaterialInput(
              label: 'TPU',
              weightGrams: Decimal.parse('100'),
              pricePerBobbin: Decimal.parse('120'),
              gramsPerBobbin: Decimal.parse('1000'),
            ),
          ],
          totalHours: Decimal.parse('2'),
          discountPercentage: Decimal.zero,
          output: CalculationOutput.simple(
            materialCost: Decimal.parse('10'),
            discountAmount: Decimal.zero,
            totalPrice: Decimal.parse('10'),
          ),
          pieceName: 'Plantilla',
          isTemplate: true,
        ),
      );

      final labels = await repo.materialLabelsByCalcId();

      expect(labels[a], 'PLA');
      expect(labels[b], 'PETG');
      expect(labels, hasLength(2));
    });

    test('multi-material: labels unidos con |', () async {
      final id = await seedCalculation(
        db,
        piece: 'Multi',
        materials: ['PLA', 'PLA+'],
      );

      final labels = await repo.materialLabelsByCalcId();

      expect(labels[id]!.split('|').toSet(), {'PLA', 'PLA+'});
    });
  });
}
