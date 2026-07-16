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
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculations_list_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/home_page.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/decimal_input_field.dart';
import 'package:tresdcal/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:tresdcal/features/dashboard/presentation/widgets/profit_bar_chart.dart';

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
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    // Reset GoRouter state (es global, persiste entre tests en el mismo file).
    appRouter.go('/');
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Home renderiza 3 botones principales (AC-1 baseline)',
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

    expect(find.byType(HomePage), findsOneWidget);
    // Los labels aparecen tambien en la NavigationBar, asi que usamos
    // findsAtLeastNWidgets(1) en vez de findsOneWidget.
    expect(find.text('Nueva cotizacion'), findsAtLeastNWidgets(1));
    expect(find.text('Historial'), findsAtLeastNWidgets(1));
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
  });

  testWidgets('Tap Nueva → CalculatorPage con form completo (AC-1)',
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

    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(find.widgetWithText(DecimalInputField, 'Peso'), findsOneWidget);
    expect(find.widgetWithText(DecimalInputField, 'Horas'), findsOneWidget);
  });

  testWidgets('Form completo: input 4 campos → output BOB visible (AC-1, AC-2)',
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
        find.widgetWithText(DecimalInputField, 'Peso'), '100');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(DecimalInputField, 'Horas'), '5');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(DecimalInputField, 'Precio bobina'), '120');
    await tester.pumpAndSettle();
    // Gramos / bobina ya no se muestra — default 1000 internamente.

    expect(find.textContaining('Bs.'), findsWidgets);
  });

  testWidgets('Tab switch: Inicio → Dashboard via NavigationBar (AC-8.1)',
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

    // Tap tab "Dashboard" en la NavigationBar (scoped para no chocar
    // con el boton de Home que tiene el mismo texto).
    final navBar = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Dashboard')),
    );
    await tester.pumpAndSettle();

    // DashboardPage se renderiza (puede mostrar empty state o stats).
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('Tab switch: Inicio → Historial via NavigationBar (AC-7.1)',
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

    final navBar = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Historial')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CalculationsListPage), findsOneWidget);
  });

  testWidgets('Dashboard vacio: muestra EmptyView con CTA (AC-8.4)',
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

    final navBar = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Dashboard')),
    );
    await tester.pumpAndSettle();

    // Empty state: el ProfitBarChart NO debe renderizar (no hay datos).
    expect(find.byType(ProfitBarChart), findsNothing);
    // CTA visible.
    expect(find.text('Ir a Home'), findsOneWidget);
  });
}
