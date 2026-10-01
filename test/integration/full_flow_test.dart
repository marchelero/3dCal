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
import 'package:tresdcal/features/calculation/presentation/widgets/calculator_wizard.dart';
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
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    prefs = await SharedPreferences.getInstance();
    // Reset GoRouter state (es global, persiste entre tests en el mismo file).
    appRouter.go('/');
  });

  /// Fuerza viewport mobile (width < 600) para que AppScaffold use
  /// NavigationBar (bottom nav) en vez de NavigationRail. Default test
  /// window es 800x600 → cae en tablet layout. Height generoso (1500) para
  /// que la NavigationBar completa (height 65 + icon + label) entre sin clip.
  void useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Avanza el reloj fake para que corran los debounces del CalculatorPage
  /// (draft 500ms + auto-save de parcial 1.5s) y luego deja todo quieto.
  ///
  /// `pumpAndSettle` solo adelanta el reloj mientras hay frames agendados: si
  /// no queda ninguno, deja vivos los `Timer` de debounce y el binding aborta
  /// el test con `'!timersPending'`. Por eso avanzamos el reloj a mano.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  /// Desmonta la app a mano y adelanta el reloj un tick.
  ///
  /// Al destruirse el `ProviderScope`, drift cierra sus `QueryStream` con un
  /// `Timer(Duration.zero)` (`StreamQueryStore.markAsClosed`). Ese timer nace
  /// DENTRO del frame de teardown del binding, asi que el reloj fake nunca
  /// avanza despues y el assert `'!timersPending'` revienta el test. Desmontar
  /// nosotros + un `pump(Duration.zero)` deja que el timer dispare.
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
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
    await settle(tester);

    expect(find.byType(HomePage), findsOneWidget);
    // Los labels aparecen tambien en la NavigationBar, asi que usamos
    // findsAtLeastNWidgets(1) en vez de findsOneWidget.
    expect(find.text('Nueva cotización'), findsAtLeastNWidgets(1));
    expect(find.text('Historial'), findsAtLeastNWidgets(1));
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
    await disposeApp(tester);
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
    await settle(tester);

    await tester.tap(find.text('Nueva cotización'));
    await settle(tester);

    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(find.widgetWithText(NumericInputField, 'Peso'), findsOneWidget);
    // El wizard es un scroll CONTINUO (no paginado): los 3 pasos viven en el
    // mismo arbol, asi que los campos del paso 2 ya existen aunque el step bar
    // marque "Pieza". Lo que si debe estar en el arbol es el step bar.
    expect(find.byType(CalcWizardStepBar), findsOneWidget);
    expect(find.text('Impresión'), findsWidgets);
    expect(find.widgetWithText(NumericInputField, 'Horas'), findsOneWidget);
    await disposeApp(tester);
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
      await settle(tester);

      await tester.tap(find.text('Nueva cotización'));
      await settle(tester);

      // El wizard es scroll continuo: los campos de los 3 pasos estan en el
      // arbol. ensureVisible por si alguno quedo bajo el fold.
      Future<void> fill(String label, String value) async {
        final f = find.widgetWithText(NumericInputField, label);
        await tester.ensureVisible(f);
        await settle(tester);
        await tester.enterText(f, value);
        await settle(tester);
      }

      await fill('Peso', '100');
      await fill('Precio bobina', '120');
      await fill('Horas', '5');
      // Gramos / bobina ya no se muestra — default 1000 internamente.

      expect(find.textContaining(r'$ '), findsWidgets);

      await disposeApp(tester);
    },
  );

  testWidgets('Tab switch: Inicio → Dashboard via NavigationBar (AC-8.1)', (
    tester,
  ) async {
    useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await settle(tester);

    // Tap tab Dashboard (indice 3 en AppScaffold._destinations: 0 Inicio,
    // 1 Historial, 2 Impresoras, 3 Dashboard, 4 Ajustes).
    //
    // Tap por NavigationDestination.at(3) en vez de por texto "Dashboard"
    // porque el label se renderiza fuera del area visible del bottom nav
    // (NavigationBar con height custom hace overflow del label).
    await tester.tap(find.byType(NavigationDestination).at(3));
    await settle(tester);

    // DashboardPage se renderiza (puede mostrar empty state o stats).
    expect(find.byType(DashboardPage), findsOneWidget);
    await disposeApp(tester);
  });
  testWidgets('Tab switch: Inicio → Historial via NavigationBar (AC-7.1)', (
    tester,
  ) async {
    useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await settle(tester);

    // Tab Historial (indice 1 en AppScaffold._destinations).
    await tester.tap(find.byType(NavigationDestination).at(1));
    await settle(tester);

    expect(find.byType(CalculationsListPage), findsOneWidget);
    await disposeApp(tester);
  });
  testWidgets('Dashboard vacio: muestra EmptyView con CTA (AC-8.4)', (
    tester,
  ) async {
    useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await settle(tester);

    // Tab Dashboard (indice 3).
    await tester.tap(find.byType(NavigationDestination).at(3));
    await settle(tester);

    // Empty state: el ProfitBarChart NO debe renderizar (no hay datos).
    expect(find.byType(ProfitBarChart), findsNothing);
    // CTA visible.
    expect(find.text('Ir a Inicio'), findsOneWidget);
    await disposeApp(tester);
  });
}
