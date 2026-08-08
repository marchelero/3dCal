// ignore_for_file: public_member_api_docs, no_leading_underscores_for_local_identifiers
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
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';

/// Holder mutable para tests que necesitan cambiar `isPro` en runtime.
///
/// **Por que existe**: `ProviderContainer.updateOverrides` no permite
/// cambiar el `length` de la lista (mismo overrides, solo updates de
/// valores). Para simular un "upgrade mid-flight", el override de
/// `isProProvider` lee de este holder; mutar el value + `invalidate`
/// dispara el rebuild.
class _MutableIsProHolder {
  _MutableIsProHolder(this.value);
  bool value;
}

/// Integration tests del history cap (T15 del plan de monetizacion).
///
/// **Spec**:
/// - Free user: cap de [kFreeHistoryCap] (10) cotizaciones. Al intentar
///   guardar la #11, `save()` throws [HistoryCapReachedException] y NO
///   inserta la row. Los 10 items existentes quedan intactos.
/// - Pro user: sin cap. Save funciona con cualquier count.
/// - Upgrade mid-flight: free con 10 → upgrade a pro → save #11 OK.
///
/// **Por que exception en vez de sealed result**: la firma actual de
/// `save()` es `Future<int?>` (null = form invalido, int = id). Mantener
/// la firma y usar una typed exception mantiene backwards-compat con los
/// 7 tests existentes de `save()` en `calculator_notifier_test.dart` y
/// permite al caller (UI) tipar el catch y mostrar UX especifica
/// (SnackBar con accion "Go Pro" → /paywall).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  /// Construye un container Riverpod con db + prefs + override de isPro.
  /// Si [isPro] es null, NO se override (default = free via SP vacio).
  ProviderContainer _container({bool? isPro}) {
    final overrides = <Override>[
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ];
    if (isPro != null) {
      overrides.add(isProProvider.overrideWith((ref) => isPro));
    }
    return ProviderContainer(overrides: overrides);
  }

  /// Helper: llena el form del calculator con valores validos y guarda
  /// [count] cotizaciones. Retorna la lista de ids insertados.
  Future<List<int>> _seedCalculations(
    ProviderContainer container,
    int count,
  ) async {
    final repo = container.read(calculationRepositoryProvider);
    final ids = <int>[];
    for (var i = 0; i < count; i++) {
      final draft = CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA',
            weightGrams: Decimal.fromInt(100),
            pricePerBobbin: Decimal.fromInt(120),
            gramsPerBobbin: Decimal.fromInt(1000),
          ),
        ],
        totalHours: Decimal.fromInt(5),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.fromInt(12),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.fromInt(36),
        ),
        pieceName: 'Seed #$i',
      );
      ids.add(await repo.create(draft));
    }
    return ids;
  }

  /// Helper: llena el form del calculator notifier con inputs validos.
  void _fillValid(ProviderContainer container) {
    final n = container.read(calculatorNotifierProvider.notifier);
    n.setWeight('100');
    n.setPrintHours('5');
    n.setFilamentPrice('120');
    n.setFilamentGrams('1000');
  }

  group('History cap (T15) — Free user', () {
    test(
      'countAll < kFreeHistoryCap: save() exitoso, retorna id positivo',
      () async {
        final container = _container();
        addTearDown(container.dispose);

        // 9 existentes → free puede guardar la #10 OK.
        await _seedCalculations(container, kFreeHistoryCap - 1);
        expect(await db.select(db.calculations).get(), hasLength(9));

        _fillValid(container);
        final id = await container
            .read(calculatorNotifierProvider.notifier)
            .save(pieceName: 'T15 Free 10');
        expect(id, isPositive);
        expect(await db.select(db.calculations).get(), hasLength(10));
      },
    );

    test(
      'countAll == kFreeHistoryCap: 11vo save() throws HistoryCapReachedException',
      () async {
        final container = _container();
        addTearDown(container.dispose);

        // 10 existentes.
        await _seedCalculations(container, kFreeHistoryCap);
        final before = await db.select(db.calculations).get();
        expect(before, hasLength(10));

        // Intento guardar la #11 → throw.
        _fillValid(container);
        await expectLater(
          container
              .read(calculatorNotifierProvider.notifier)
              .save(pieceName: 'T15 Free 11'),
          throwsA(isA<HistoryCapReachedException>()),
        );

        // DB intacta: 10 rows, ninguna nueva.
        final after = await db.select(db.calculations).get();
        expect(after, hasLength(10));
        expect(after.map((c) => c.id), equals(before.map((c) => c.id)));
      },
    );

    test(
      'countAll == kFreeHistoryCap: items existentes NO se eliminan al bloquear',
      () async {
        final container = _container();
        addTearDown(container.dispose);

        final seededIds = await _seedCalculations(container, kFreeHistoryCap);
        expect(seededIds, hasLength(10));

        // Intentar el 11vo save debe fallar SIN tocar los existentes.
        _fillValid(container);
        try {
          await container
              .read(calculatorNotifierProvider.notifier)
              .save(pieceName: 'Should fail');
        } on HistoryCapReachedException {
          // Esperado.
        }

        final all = await db.select(db.calculations).get();
        expect(all, hasLength(10));
        // Los 10 ids originales siguen presentes, sin cambios.
        for (final id in seededIds) {
          expect(all.any((c) => c.id == id), isTrue,
              reason: 'Id $id debe seguir presente post-cap.');
        }
      },
    );

    test(
      'propertied: HistoryCapReachedException expone cap + current count',
      () async {
        final container = _container();
        addTearDown(container.dispose);

        await _seedCalculations(container, kFreeHistoryCap);

        _fillValid(container);
        try {
          await container
              .read(calculatorNotifierProvider.notifier)
              .save();
          fail('Deberia haber tirado HistoryCapReachedException');
        } on HistoryCapReachedException catch (e) {
          expect(e.currentCount, kFreeHistoryCap);
          expect(e.cap, kFreeHistoryCap);
        }
      },
    );
  });

  group('History cap (T15) — Pro user', () {
    test(
      'countAll == kFreeHistoryCap: pro puede guardar la #11 sin cap',
      () async {
        final container = _container(isPro: true);
        addTearDown(container.dispose);

        await _seedCalculations(container, kFreeHistoryCap);
        expect(await db.select(db.calculations).get(), hasLength(10));

        _fillValid(container);
        final id = await container
            .read(calculatorNotifierProvider.notifier)
            .save(pieceName: 'T15 Pro 11');
        expect(id, isPositive);
        expect(await db.select(db.calculations).get(), hasLength(11));
      },
    );

    test(
      'pro con countAll = 50: save() funciona (cap efectivamente no aplica)',
      () async {
        final container = _container(isPro: true);
        addTearDown(container.dispose);

        // 50 existentes (simula uso prolongado).
        await _seedCalculations(container, 50);
        expect(await db.select(db.calculations).get(), hasLength(50));

        _fillValid(container);
        final id = await container
            .read(calculatorNotifierProvider.notifier)
            .save(pieceName: 'T15 Pro 51');
        expect(id, isPositive);
        expect(await db.select(db.calculations).get(), hasLength(51));
      },
    );

    test(
      'upgrade mid-flight: free con 10 → upgrade a pro → save #11 OK',
      () async {
        // Usamos un holder mutable para no chocar con la regla de
        // `updateOverrides` (mismo length, solo update de valores).
        final isProHolder = _MutableIsProHolder(false);
        final c = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isProProvider.overrideWith((ref) => isProHolder.value),
        ]);
        addTearDown(c.dispose);

        await _seedCalculations(c, kFreeHistoryCap);

        // Confirm free bloquea primero.
        _fillValid(c);
        await expectLater(
          c.read(calculatorNotifierProvider.notifier).save(),
          throwsA(isA<HistoryCapReachedException>()),
        );

        // Upgrade mid-flight: flip + invalidar para que se relea.
        isProHolder.value = true;
        c.invalidate(isProProvider);

        // Ahora save funciona.
        final id = await c
            .read(calculatorNotifierProvider.notifier)
            .save(pieceName: 'T15 Upgrade 11');
        expect(id, isPositive);
        expect(await db.select(db.calculations).get(), hasLength(11));
      },
    );
  });

  group('History cap (T15) — Edge cases', () {
    test(
      'form invalido con cap libre: save() retorna null (no exception, no insert)',
      () async {
        final container = _container();
        addTearDown(container.dispose);

        // 10 existentes (en el cap), pero form vacio → save retorna null,
        // NO throws. La excepcion solo se dispara si el form es valido
        // Y estamos en el cap.
        await _seedCalculations(container, kFreeHistoryCap);

        final id = await container
            .read(calculatorNotifierProvider.notifier)
            .save();
        expect(id, isNull);
        // 10 rows, sin cambios.
        expect(await db.select(db.calculations).get(), hasLength(10));
      },
    );

    test(
      'free con 0 existentes: 10 saves consecutivos funcionan, el 11vo throw',
      () async {
        final container = _container();
        addTearDown(container.dispose);

        _fillValid(container);
        // 10 saves exitosos.
        for (var i = 0; i < kFreeHistoryCap; i++) {
          final id = await container
              .read(calculatorNotifierProvider.notifier)
              .save(pieceName: 'Seq $i');
          expect(id, isPositive, reason: 'Save #$i deberia tener exito.');
        }
        expect(await db.select(db.calculations).get(), hasLength(10));

        // 11vo throws.
        await expectLater(
          container.read(calculatorNotifierProvider.notifier).save(),
          throwsA(isA<HistoryCapReachedException>()),
        );
      },
    );
  });
}
