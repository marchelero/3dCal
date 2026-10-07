// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/app.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/router/app_router.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// MED-09 fix (auditoría 2026-10-04): los routes que leen `state.extra`
/// (Calculation/Filament/PrinterProfile) o parsean `:id` lanzaban TypeError
/// dentro del pageBuilder cuando `extra` no viaja (refresh/deep link en web),
/// y `errorBuilder` NO captura excepciones del builder → pantalla blanca.
/// Estos tests simulan el "F5" con `go()` SIN extra y exigen degradación
/// elegante (página útil o _RouterErrorPage visible), sin exception.
void main() {
  late AppDatabase db;

  Future<void> pumpAt(WidgetTester tester, String location) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider)),
      ],
    );
    // container.dispose antes de db.close (orden LIFO de addTearDown —
    // mismo patrón que paywall_navigation_test, evita deadlock del stream).
    addTearDown(() async => db.close());
    addTearDown(container.dispose);
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

  testWidgets('/calculator/edit sin extra no rompe (vuelve al calculator)', (
    tester,
  ) async {
    await pumpAt(tester, '/calculator/edit');
    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(
      find.byType(CalculatorPage),
      findsWidgets,
      reason: 'sin Calculation en extra se degrada a form nuevo',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('/settings/filaments/3 sin extra muestra error page', (
    tester,
  ) async {
    await pumpAt(tester, '/settings/filaments/3');
    expect(tester.takeException(), isNull);
    expect(find.text(EsBO.routeNotFound), findsOneWidget);
  });

  testWidgets('/history/abc (id no numérico) muestra error page', (
    tester,
  ) async {
    await pumpAt(tester, '/history/abc');
    expect(tester.takeException(), isNull);
    expect(find.text(EsBO.routeNotFound), findsOneWidget);
  });
}
