// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, no_leading_underscores_for_local_identifiers
import 'dart:async';

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
import 'package:tresdcal/features/calculation/presentation/pages/home_page.dart';
import 'package:tresdcal/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/shared/widgets/numeric_input_field.dart';

/// Widget tests del gear de Ajustes del AppBar del calculator.
///
/// **Scope**: el gear top-right de [CalculatorPage] navega a [SettingsPage]
/// via `context.push('/settings/standalone')` y el back (system pop)
/// restaura el calculator con su estado (draft parcial) intacto.
///
/// **Stack REAL de produccion**: se ejercita tal cual corre la app:
/// `[shell(home), calculator, settings(standalone)]`.
///
/// El bug que se corrige: el gear apuntaba a `context.push('/settings')`, la
/// ruta DENTRO del `StatefulShellRoute`. Push sobre una shell existente
/// re-entra al shell y duplica su pagina en el navigator raiz
/// (pageKey estable = `route.hashCode`): assert Navigator en debug y stack
/// silenciosamente corrupto en release ([shell(home), calc, shell(settings)]
/// con keys `['<shellHash>', calcKey, '<shellHash>']`) — upstream
/// go_router/flutter #185011, no fixeable subiendo la version.
///
/// La ruta `/settings/standalone` (fuera del shell, full-screen push) evita
/// esa duplicacion: SettingsPage se empuja como pagina normal ENCIMA del
/// calculator y el back popea limpio a `[shell(home), calculator]`.
class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;

  void seedActive(Entitlement? e) => _active = e;

  @override
  Future<Entitlement?> getActive() async => _active;

  @override
  Future<int> save(EntitlementsCompanion entry) async => 1;

  @override
  Future<int> clear() async => 0;

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}

class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;

  @override
  Future<void> configure() async {}

  @override
  Future<PaymentResult> purchase({required String productId}) async =>
      const PaymentCancelled();

  @override
  Future<RestoreResult> restore() async => const RestoreEmpty();

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Future<bool?> isProActiveOnStore() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

/// Viewport alto (800x1600) para que el AppBar quepa con todas sus actions.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() {
    EsBO.setImpl(const EsImpl());
    // Reset del router global (es singleton, persiste entre tests del file).
    appRouter.go('/');
  });

  /// Helper: monta [TresdcalApp] (router REAL) con DB in-memory + fakes.
  /// [dashboardIsProProvider] override a isProProvider replica main.dart.
  Future<void> _pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        entitlementRepositoryProvider.overrideWithValue(
          _FakeEntitlementRepository(),
        ),
        paymentServiceProvider.overrideWithValue(_FakePaymentService()),
        dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider)),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  NumericInputField _pesoField(WidgetTester tester) =>
      tester.widget<NumericInputField>(
        find.widgetWithText(NumericInputField, 'Peso'),
      );

  testWidgets('gear → SettingsPage (standalone) y back restaura calculator', (
    tester,
  ) async {
    _useTallViewport(tester);
    await _pumpApp(tester);

    // 1. Home (shell activo) → stack base real.
    appRouter.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    // 2. Abrir el calculator con push → stack [shell(home), calculator].
    unawaited(appRouter.push('/calculator'));
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);

    // El gear existe y su tooltip usa la l10n de settings.
    final gear = find.byTooltip(EsBO.settingsTitle);
    expect(gear, findsOneWidget);

    // 3. Tipear un draft parcial (express: Peso / Horas / Precio bobina).
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

    // 4. Gear → /settings/standalone (push). SettingsPage se empuja ENCIMA
    //    del calculator sin duplicar la shell.
    await tester.tap(gear);
    await tester.pumpAndSettle();

    expect(
      find.byType(SettingsPage),
      findsOneWidget,
      reason: 'Gear debe navegar a SettingsPage.',
    );
    expect(
      find.byType(CalculatorPage),
      findsNothing,
      reason: 'Calculator queda oculto debajo de la ruta push.',
    );

    // Flecha de retorno visible SOLO porque fue empujada api (canPop = true).
    // Prueba implícita de que es la instancia standalone: dentro del tab del
    // shell canPop == false y la flecha NO se renderiza.
    expect(
      find.byTooltip(EsBO.configBack),
      findsOneWidget,
      reason: 'Settings standalone debe mostrar flecha de retorno.',
    );

    // 5. System back → calculator restaurado.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.byType(CalculatorPage),
      findsOneWidget,
      reason: 'Back debe volver al calculator sin duplicar la shell.',
    );
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(HomePage), findsNothing);

    // Draft parcial preservado: controllers intactos tras el pop.
    expect(_pesoField(tester).controller.text, '100');
  });
}
