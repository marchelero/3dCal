// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/app.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/router/app_router.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculations_list_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/home_page.dart';
import 'package:tresdcal/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:tresdcal/features/dashboard/presentation/widgets/profit_bar_chart.dart';
import 'package:tresdcal/shared/widgets/numeric_input_field.dart';

/// Integration test smoke (plan §9C reducido).
///
/// Cubre el happy path completo:
/// 1. Home se renderiza con 3 botones (Nueva / Historial / Dashboard).
/// 2. Tap "Nueva cotizacion" abre Calculator.
/// 3. Llenar form → output BOB visible.
/// 4. Volver a Home via NavigationBar tab.
/// 5. Tap "Dashboard" abre DashboardPage (puede estar empty al inicio).
/// 6. Tap "Historial" abre CalculationsListPage (puede estar empty al inicio).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });
    prefs = await SharedPreferences.getInstance();
    // Reset GoRouter state (es global, persiste entre tests en el mismo file).
    appRouter.go('/');
  });

  /// Fuerza viewport mobile (width < 600) para que AppScaffold use
  /// NavigationBar (bottom nav) en vez de NavigationRail. Default test
  /// window es 800x600 → cae en tablet layout. Height generoso (1500) para
  /// que la NavigationBar completa (height 65 + icon + label) entre sin clip.
  void _useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  tearDown(() async {
    await db.close();
  });

  testWidgets('Home renderiza 3 botones principales (AC-1 baseline)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    // Los labels aparecen tambien en la NavigationBar, asi que usamos
    // findsAtLeastNWidgets(1) en vez de findsOneWidget.
    expect(find.text('Nueva cotizacion'), findsAtLeastNWidgets(1));
    expect(find.text('Historial'), findsAtLeastNWidgets(1));
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
  });

  testWidgets('Tap Nueva → CalculatorPage con form completo (AC-1)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva cotizacion'));
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(
        find.widgetWithText(NumericInputField, 'Peso'),
        findsOneWidget);
    expect(find.widgetWithText(NumericInputField, 'Horas'), findsOneWidget);
  });

  testWidgets(
    'Form completo: input 4 campos → output BOB visible (AC-1, AC-2)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const TresdcalApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva cotizacion'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(NumericInputField, 'Peso'),
        '100',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(NumericInputField, 'Horas'),
        '5',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(NumericInputField, 'Precio bobina'),
        '120',
      );
      await tester.pumpAndSettle();
      // Gramos / bobina ya no se muestra — default 1000 internamente.

      expect(find.textContaining(r'$ '), findsWidgets);
    },
  );

  testWidgets('Tab switch: Inicio → Dashboard via NavigationBar (AC-8.1)', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap tab Dashboard (indice 2 en AppScaffold._destinations).
    // Tap por NavigationDestination.at(2) en vez de por texto "Dashboard"
    // porque el label se renderiza fuera del area visible del bottom nav
    // (NavigationBar con height custom hace overflow del label).
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();

    // DashboardPage se renderiza (puede mostrar empty state o stats).
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('Tab switch: Inicio → Historial via NavigationBar (AC-7.1)', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tab Historial (indice 1 en AppScaffold._destinations).
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();

    expect(find.byType(CalculationsListPage), findsOneWidget);
  });

  testWidgets('Dashboard vacio: muestra EmptyView con CTA (AC-8.4)', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tab Dashboard (indice 2).
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();

    // Empty state: el ProfitBarChart NO debe renderizar (no hay datos).
    expect(find.byType(ProfitBarChart), findsNothing);
    // CTA visible.
    expect(find.text('Ir a Home'), findsOneWidget);
  });
}
