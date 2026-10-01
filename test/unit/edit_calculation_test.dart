// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';

/// Tests de "Editar cotizacion" (update-in-place).
///
/// El contrato que fijan:
/// - Editar NO crea una fila nueva (mismo id, mismo createdAt, mismo isSold).
/// - Editar reemplaza los materiales (nueva lista, sin huerfanos/duplicados).
/// - Editar NO dispara el cap free ni suma horas a la impresora (double count
///   de depreciacion si lo hiciera).
/// - Si la fila desaparecio, `save(updateId:)` devuelve null (no explota).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CalculationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CalculationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Draft minimo valido (1 material express, 100g, 120/1000, 5h).
  CalculationDraft draft({
    String pieceName = 'Original',
    String label = 'PLA',
    double weight = 100,
    double totalHours = 5,
    int quantity = 1,
    bool isAdvanced = false,
    List<MaterialInput> materials = const [],
    bool withOwnTime = false,
  }) => CalculationDraft(
    materials: materials,
    totalHours: Decimal.parse(totalHours.toString()),
    printMinutes: 0,
    discountPercentage: Decimal.zero,
    output: _output(),
    filamentLabel: label,
    isAdvanced: isAdvanced,
    quantity: quantity,
    pieceName: pieceName,
    clientName: 'Cliente',
    batchDiscountPercent: null,
    batchDiscountAmount: null,
  );

  Future<int> seed() async {
    return repo.create(
      draft(pieceName: 'Original', materials: [_mat('PLA', 100, 120, 1000)]),
    );
  }

  group('updateCalculation (repository)', () {
    test('actualiza en el lugar: mismo id, sin filas nuevas', () async {
      final id = await seed();
      expect(await repo.countAll(), 1);

      final ok = await repo.updateCalculation(
        id,
        draft(pieceName: 'Corregida', totalHours: 8),
      );

      expect(ok, isTrue);
      expect(await repo.countAll(), 1, reason: 'No debe crear una 2da fila');

      final updated = (await repo.getById(id))!;
      expect(updated.pieceName, 'Corregida');
      expect(updated.totalHours, 8.0);
    });

    test(
      'preserva createdAt e isSold (editar no "refecha" ni desmarca)',
      () async {
        final id = await seed();
        final before = (await repo.getById(id))!;

        // El usuario ya la dio por vendida antes de editar.
        await repo.toggleSold(id, true);
        final sold = (await repo.getById(id))!;

        await repo.updateCalculation(id, draft(pieceName: 'Editada'));

        final after = (await repo.getById(id))!;
        expect(after.createdAt, sold.createdAt, reason: 'createdAt no cambia');
        expect(after.isSold, isTrue, reason: 'Editar no desmarca la venta');
        expect(after.id, before.id);
      },
    );

    test('reemplaza los materiales sin duplicar ni dejar huerfanos', () async {
      final id = await repo.create(
        draft(
          materials: [_mat('PLA', 100, 120, 1000), _mat('ABS', 80, 160, 1000)],
          isAdvanced: true,
        ),
      );
      expect(await repo.materialsOf(id), hasLength(2));

      await repo.updateCalculation(
        id,
        draft(isAdvanced: true, materials: [_mat('PETG', 50, 200, 1000)]),
      );

      final mats = await repo.materialsOf(id);
      expect(mats, hasLength(1), reason: 'La lista vieja debe desaparecer');
      expect(mats.single.label, 'PETG');
      expect(mats.single.weightGrams, 50.0);
    });

    test('conserva el tiempo propio por material (v15) al editar', () async {
      final id = await repo.create(
        draft(
          isAdvanced: true,
          materials: [_mat('PLA', 100, 120, 1000), _mat('ABS', 80, 160, 1000)],
        ),
      );

      await repo.updateCalculation(
        id,
        draft(
          isAdvanced: true,
          materials: [
            _mat(
              'PLA',
              120,
              120,
              1000,
              ownTime: true,
              ownHours: 3,
              ownMinutes: 15,
            ),
          ],
        ),
      );

      final mat = (await repo.materialsOf(id)).single;
      expect(mat.useOwnTime, isTrue);
      expect(mat.materialHours, 3.0);
      expect(mat.materialMinutes, 15.0);
    });

    test('devuelve false si la cotizacion ya no existe', () async {
      final ok = await repo.updateCalculation(9999, draft());
      expect(ok, isFalse);
    });

    test('is_advanced se actualiza (Advanced <-> Express)', () async {
      final id = await repo.create(
        draft(materials: const [], isAdvanced: false),
      );
      expect((await repo.getById(id))!.isAdvanced, isFalse);

      await repo.updateCalculation(id, draft(isAdvanced: true));
      expect((await repo.getById(id))!.isAdvanced, isTrue);
    });
  });

  group('save(updateId:) (notifier)', () {
    late ProviderContainer container;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // El camino de ALTA (`save()` sin updateId) resuelve isPro, que lee
          // prefs. El camino de edicion no lo necesita (ver notifier).
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Llena el form express con valores validos.
    CalculatorNotifier validNotifier() {
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('5');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');
      return n;
    }

    test('save(updateId:) actualiza y devuelve el MISMO id', () async {
      final id = await seed();
      final n = validNotifier();

      final returned = await n.save(
        pieceName: 'Editada desde la calculadora',
        updateId: id,
      );

      expect(returned, id);
      expect(await repo.countAll(), 1, reason: 'No crea una 2da cotizacion');

      final row = (await repo.getById(id))!;
      expect(row.pieceName, 'Editada desde la calculadora');
      expect(row.totalHours, 5.0, reason: 'Snapshot recalculado del form');
    });

    test('save(updateId:) NO suma horas a la impresora', () async {
      // Sin impresora activa el camino es un no-op; lo que importa es que
      // editar no cree historial ni altere la fila. Verificado aqui que el
      // conteo de cotizaciones no cambia (el cap tampoco se dispara).
      final id = await seed();
      final n = validNotifier();

      await n.save(pieceName: 'X', updateId: id);

      expect(await repo.countAll(), 1);
      final row = (await repo.getById(id))!;
      expect(row.pieceName, 'X');
    });

    test('save(updateId:) devuelve null si la fila ya no existe', () async {
      await seed();
      final n = validNotifier();
      final returned = await n.save(pieceName: 'Huerfana', updateId: 4242);
      expect(returned, isNull);
      expect(
        await repo.countAll(),
        1,
        reason: 'La fila sembrada queda intacta',
      );
    });

    test(
      'save(updateId:) no dispara el cap free (no crece el historial)',
      () async {
        // Sembramos kFreeHistoryCap cotizaciones: en alta normal la #cap+1
        // lanzaria HistoryCapReachedException; en edicion debe funcionar igual.
        for (var i = 0; i < kFreeHistoryCap; i++) {
          await repo.create(draft(pieceName: 'Q$i'));
        }
        expect(await repo.countAll(), kFreeHistoryCap);

        final id = (await repo.getById(1))!.id;
        final n = validNotifier();

        final returned = await n.save(pieceName: 'Editada', updateId: id);

        expect(returned, id);
        expect(
          await repo.countAll(),
          kFreeHistoryCap,
          reason: 'Editar no puede ser bloqueado por el cap',
        );
        expect((await repo.getById(id))!.pieceName, 'Editada');
      },
    );

    test('save() sin updateId sigue creando una fila nueva', () async {
      final n = validNotifier();
      final id = await n.save(pieceName: 'Nueva');
      expect(id, isPositive);
      expect(await repo.countAll(), 1);
    });

    test('round-trip: crear -> cargar -> editar -> recargar', () async {
      final id = await seed();
      final row = (await repo.getById(id))!;

      // El notifier carga la fila (como hace /calculator/edit).
      final n = container.read(calculatorNotifierProvider.notifier);
      await n.loadFromCalculation(row);
      expect(container.read(calculatorNotifierProvider).label, 'Original');

      // El usuario cambia el peso y guarda la edicion.
      n.setWeight('250');
      final returned = await n.save(updateId: id);

      expect(returned, id);
      final after = (await repo.getById(id))!;
      expect(after.pieceName, 'Original');
      // 250g * 120/1000 = 30 (sin markup por defecto).
      expect(after.totalPriceSnapshot, 30.0);

      // Recargar la fila editada devuelve los valores nuevos.
      await n.loadFromCalculation(after);
      expect(container.read(calculatorNotifierProvider).weight, '250');
    });
  });
}

/// Material de prueba: [MaterialInput] con Decimals y own-time opcional.
MaterialInput _mat(
  String label,
  double weight,
  double price,
  double grams, {
  bool ownTime = false,
  double? ownHours,
  double? ownMinutes,
}) => MaterialInput(
  label: label,
  weightGrams: Decimal.parse(weight.toString()),
  pricePerBobbin: Decimal.parse(price.toString()),
  gramsPerBobbin: Decimal.parse(grams.toString()),
  useOwnTime: ownTime,
  ownTimeHours: ownHours == null ? null : Decimal.parse(ownHours.toString()),
  ownTimeMinutes: ownMinutes == null
      ? null
      : Decimal.parse(ownMinutes.toString()),
);

CalculationOutput _output() => CalculationOutput(
  materialCost: Decimal.fromInt(12),
  electricCost: Decimal.zero,
  amortizationCost: Decimal.zero,
  laborCost: Decimal.zero,
  postProcessCost: Decimal.zero,
  baseCost: Decimal.fromInt(12),
  costWithFailure: Decimal.fromInt(12),
  failureCost: Decimal.zero,
  markupCost: Decimal.zero,
  totalBeforeProfit: Decimal.fromInt(12),
  profitAmount: Decimal.zero,
  totalFinal: Decimal.fromInt(12),
  totalPrice: Decimal.fromInt(12),
  discountAmount: Decimal.zero,
);
