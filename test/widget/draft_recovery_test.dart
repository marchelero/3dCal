// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/calculation_draft.dart';
import 'package:tresdcal/core/storage/draft_storage.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/core/utils/image_downscale.dart'
    show downscalePieceImage;
import 'package:tresdcal/features/calculation/data/calculation_repository.dart'
    hide CalculationDraft;
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/home_page.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';
import 'package:tresdcal/l10n/es_bo.dart';

CalculationsCompanion _partialDto(CalculatorState state) =>
    CalculatorNotifier.stateToPartialDto(state).copyWith(
      kwhRateSnapshot: const Value(0),
      profitBaseSnapshot: const Value(0),
    );

/// Tests minimos del draft recovery (PRD NFR-3).
///
/// Cubre:
/// 1. El draft se persiste al cambiar inputs.
/// 2. Un draft pre-existente se restaura al montar CalculatorPage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DraftStorage unit', () {
    test('save + load roundtrip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = DraftStorage(prefs);

      const draft = CalculationDraft(
        weight: '120',
        printHours: '5',
        filamentPrice: '150.00',
      );
      await storage.save(draft);

      final loaded = await storage.load();
      expect(loaded, isNotNull);
      expect(loaded!.weight, '120');
      expect(loaded.printHours, '5');
      expect(loaded.filamentPrice, '150.00');
    });

    test('clear() borra el draft', () async {
      SharedPreferences.setMockInitialValues({'form_draft': '{"weight":"50"}'});
      final prefs = await SharedPreferences.getInstance();
      final storage = DraftStorage(prefs);

      expect(await storage.load(), isNotNull);
      await storage.clear();
      expect(await storage.load(), isNull);
    });

    test('draft legacy sin ID sigue decodificando sin asociacion', () {
      final draft = CalculationDraft.tryDecode(
        '{"weight":"50","printHours":"2"}',
      );

      expect(draft, isNotNull);
      expect(draft!.weight, '50');
      expect(draft.partialId, isNull);
    });
  });

  testWidgets(
    'restart con draft y parcial retoma y convierte la misma fila al guardar',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = CalculationRepository(db);
      final partialId = await repository.savePartial(
        _partialDto(
          CalculatorState.initial().copyWith(
            weight: '100',
            printHours: '1',
            filamentPrice: '120',
            filamentGrams: '1000',
          ),
        ),
      );
      await DraftStorage(prefs).save(
        CalculationDraft(
          partialId: partialId,
          weight: '100',
          printHours: '1',
          filamentPrice: '120',
          filamentGrams: '1000',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          // F2: sin override, `Isolate.run` nunca resuelve en fake-async.
          pieceImageDownscalerProvider.overrideWithValue(
            (bytes) async => downscalePieceImage(bytes),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomePage()),
          GoRoute(
            path: '/calculator',
            builder: (_, _) => const CalculatorPage(),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        container.dispose();
        await db.close();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.homeDraftContinue));
      await tester.pumpAndSettle();

      expect(container.read(currentPartialIdProvider), partialId);
      expect(find.widgetWithText(TextField, '100'), findsOneWidget);

      await tester.ensureVisible(find.text('VER COTIZACIÓN'));
      await tester.tap(find.text('VER COTIZACIÓN'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Guardar cotización'));
      await tester.tap(find.byTooltip('Guardar cotización'));
      await tester.pumpAndSettle();
      expect(find.text(EsBO.calcDialogSaveSubtitle), findsOneWidget);
      final confirmSave = find.text(EsBO.commonSave).last;
      await tester.ensureVisible(confirmSave);
      await tester.tap(confirmSave);
      await tester.pumpAndSettle();
      expect(find.text(EsBO.calcDialogSaveSubtitle), findsNothing);

      final rows = await db.select(db.calculations).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, partialId);
      expect(rows.single.isPartial, isFalse);
      expect(rows.single.clientName, isNull);
      expect(await db.select(db.calculationMaterials).get(), hasLength(1));
    },
  );

  testWidgets('draft legacy no se vincula al parcial ajeno de Drift', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'form_draft':
          '{"weight":"77","printHours":"3","filamentPrice":"200",'
          '"filamentGrams":"1000"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final partialId = await CalculationRepository(
      db,
    ).savePartial(_partialDto(CalculatorState.initial()));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CalculatorPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(calculatorNotifierProvider).weight, '77');
    expect(container.read(currentPartialIdProvider), isNull);
    expect((await db.select(db.calculations).get()).single.id, partialId);
    expect((await db.select(db.calculations).get()).single.isPartial, isTrue);
  });

  testWidgets(
    'CalculatorPage restaura draft al montar — valores pre-cargados aparecen',
    (tester) async {
      // Pre-cargar un draft en SharedPreferences antes de montar la pagina.
      SharedPreferences.setMockInitialValues({
        'form_draft': const CalculationDraft(
          weight: '77',
          printHours: '3',
          discountPct: '10',
          filamentPrice: '200',
          filamentGrams: '1000',
        ).encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: CalculatorPage()),
        ),
      );
      // Esperar post-frame callback + load async.
      await tester.pumpAndSettle();

      // Draft fue restaurado — inputs muestran valores pre-cargados.
      // '77' (peso) esta en el paso 1 visible; '3' (horas) en el paso 2
      // del wizard: montado pero offstage (IndexedStack) → skipOffstage.
      expect(find.widgetWithText(TextField, '77'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, '3', skipOffstage: false),
        findsOneWidget,
      );

      await db.close();
    },
  );
}
