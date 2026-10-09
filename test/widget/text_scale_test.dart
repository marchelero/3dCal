// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show MediaQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/app.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/router/app_router.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculation_detail_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculations_list_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/home_page.dart';
import 'package:tresdcal/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'package:tresdcal/features/entitlement/presentation/pages/paywall_page.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';

/// T2-4: harness de text-scale 1.5× (a11y alto impacto).
///
/// Monta la app REAL ([TresdcalApp] + router real) con
/// `textScaleFactorTestValue = 1.5` y navega a cada pantalla principal.
/// Un overflow de RenderFlex ("A RenderFlex overflowed...") se reporta como
/// FlutterError en el test binding → `tester.takeException()` lo detecta y
/// el test falla. Cero excepciones = sin clipping a escala grande.
///
/// Alcance deliberado (PRD Tier 2): solo detectar y arreglar los clipping
/// descubiertos; NO rediseñar las pantallas.
void main() {
  late AppDatabase db;

  Future<void> pumpRoute(
    WidgetTester tester,
    String location, {
    Future<void> Function(AppDatabase db)? seed,
  }) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    if (seed != null) await seed(db);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider)),
      ],
    );
    // Orden LIFO: container.dispose antes de db.close (patron de
    // router_guards_test — evita deadlock del stream de drift).
    addTearDown(() async => db.close());
    addTearDown(container.dispose);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // Escala de texto 1.5× (accesibilidad Android/iOS ampliada).
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter.go(location);
    await tester.pumpAndSettle();
  }

  /// Afirma cero excepciones (overflow u otra) tras montar la pantalla.
  void expectNoOverflow(WidgetTester tester, String route) {
    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: 'Overflow/error a text-scale 1.5× en $route: $exception',
    );
  }

  testWidgets('home (/) a 1.5× sin overflow', (tester) async {
    await pumpRoute(tester, '/');
    expect(find.byType(HomePage), findsWidgets);
    // Sanity-check: el harness REALMENTE aplica 1.5× (si no, el resto de
    // asserts de este archivo serian un verde vacio).
    final ctx = tester.element(find.byType(HomePage).first);
    expect(
      MediaQuery.textScalerOf(ctx).scale(14),
      closeTo(21, 0.01),
      reason: '14sp × 1.5 = 21 — la escala no se aplico al harness.',
    );
    expectNoOverflow(tester, '/');
  });

  testWidgets('calculator a 1.5× sin overflow', (tester) async {
    await pumpRoute(tester, '/calculator');
    expect(find.byType(CalculatorPage), findsOneWidget);
    expectNoOverflow(tester, '/calculator');
  });

  testWidgets('settings a 1.5× sin overflow', (tester) async {
    await pumpRoute(tester, '/settings');
    expect(find.byType(SettingsPage), findsOneWidget);
    expectNoOverflow(tester, '/settings');
  });

  testWidgets('history (lista) a 1.5× sin overflow', (tester) async {
    await pumpRoute(tester, '/history');
    expect(find.byType(CalculationsListPage), findsOneWidget);
    expectNoOverflow(tester, '/history');
  });

  testWidgets('paywall a 1.5× sin overflow', (tester) async {
    await pumpRoute(tester, '/paywall');
    expect(find.byType(PaywallPage), findsOneWidget);
    expectNoOverflow(tester, '/paywall');
  });

  testWidgets('detail de cotización (/history/1) a 1.5× sin overflow', (
    tester,
  ) async {
    await pumpRoute(
      tester,
      '/history/1',
      seed: (db) => db.into(db.calculations).insert(
        CalculationsCompanion.insert(
          createdAt: DateTime.now().toUtc(),
          pieceName: const Value('Pieza escala'),
          clientName: const Value('Cliente'),
          printerWattsSnapshot: const Value(120),
          totalHours: 2.5,
          printMinutes: const Value(90),
          discountPercentage: 0,
          kwhRateSnapshot: 0,
          profitBaseSnapshot: 0,
          materialCostSnapshot: 12,
          electricCostSnapshot: 1,
          baseCostSnapshot: 13,
          failureCostSnapshot: const Value(0),
          markupCostSnapshot: const Value(0),
          profitAmountSnapshot: 5,
          minimumChargeAppliedSnapshot: const Value(0),
          effectiveTotalSnapshot: const Value(18),
          totalPriceSnapshot: 18,
          laborRateSnapshot: const Value(0),
          postProcessRateSnapshot: const Value(0),
          failureRateSnapshot: const Value(0),
          minimumChargeSnapshot: const Value(0),
          markupOnMaterialsSnapshot: const Value(0),
        ),
      ),
    );
    expect(find.byType(CalculationDetailPage), findsOneWidget);
    expectNoOverflow(tester, '/history/1 (detail)');
  });
}
