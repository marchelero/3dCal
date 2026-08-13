// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, no_leading_underscores_for_local_identifiers
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/app.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/router/app_router.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';
import 'package:tresdcal/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/pages/paywall_page.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/shared/widgets/numeric_input_field.dart';

/// Widget tests del wiring de navegacion de los gates → `/paywall`
/// (T6 del plan free/pro Play Store prep, T14-T17 del plan de monetizacion).
///
/// **Scope**: desde cada uno de los 5 call sites de gates, el tap en el
/// gate (o su SnackBar action "Go Pro") navega a [PaywallPage] usando el
/// router REAL (`appRouter` via [TresdcalApp]) — NO a `_RouterErrorPage`
/// (que es lo que pasaba cuando la ruta `/paywall` no estaba registrada).
///
/// **Call sites cubiertos**:
/// 1. `calculator_page.dart:359` — history cap: save #11 en free → SnackBar
///    "Go Pro" → `/paywall`.
/// 2. `calculations_list_page.dart:195` — CSV export gate → SnackBar
///    "Go Pro" → `/paywall`.
/// 3. `dashboard_page.dart:263` — Pro teaser FilledButton → `/paywall`.
/// 4. `settings_page.dart:744` — companyName field gate → SnackBar
///    "Go Pro" → `/paywall`.
/// 5. `settings_page.dart:845` — logo pick gate → SnackBar "Go Pro" →
///    `/paywall`.
///
/// **Fakes**: `_FakeEntitlementRepository` + `_FakePaymentService`
/// (in-memory). `isProProvider` real via notifier (cache SP vacio →
/// [EntitlementFree]). El override `dashboardIsProProvider →
/// isProProvider` replica el wiring de `main.dart` para que el router
/// vea el mismo estado que prod.

class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;
  int saveCalls = 0;
  int clearCalls = 0;

  void seedActive(Entitlement? e) => _active = e;

  @override
  Future<Entitlement?> getActive() async => _active;

  @override
  Future<int> save(EntitlementsCompanion entry) async {
    saveCalls++;
    return 1;
  }

  @override
  Future<int> clear() async {
    clearCalls++;
    return 0;
  }

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}

class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  PaymentResult purchaseResult = const PaymentCancelled();
  RestoreResult restoreResult = const RestoreEmpty();

  void seedPurchase(PaymentResult r) => purchaseResult = r;
  void seedRestore(RestoreResult r) => restoreResult = r;

  @override
  Future<void> configure() async {
    configureCalls++;
  }

  @override
  Future<PaymentResult> purchase({required String productId}) async {
    purchaseCalls++;
    return purchaseResult;
  }

  @override
  Future<RestoreResult> restore() async {
    restoreCalls++;
    return restoreResult;
  }

  @override
  Stream<PaymentResult> get purchaseStream => const Stream.empty();

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

/// Viewport alto (800x1600) para que los botones cerca del fondo
/// (paywall Unlock, dashboard Go Pro, SnackBar actions) entren en
/// pantalla sin scrollear. Default 800x600 no alcanza.
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
  late _FakeEntitlementRepository repo;
  late _FakePaymentService payment;

  setUp(() {
    EsBO.setImpl(const EsImpl());
    // Reset del router global (es singleton, persiste entre tests del file).
    appRouter.go('/');
  });

  /// Inserta 1 cotizacion via repo real (para que dashboard/history no
  /// esten en empty state y el gate del dashboard se renderice).
  Future<void> _seedOneCalculation(ProviderContainer container) async {
    final calcRepo = container.read(calculationRepositoryProvider);
    await calcRepo.create(
      CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA Test',
            weightGrams: Decimal.parse('100'),
            pricePerBobbin: Decimal.parse('120'),
            gramsPerBobbin: Decimal.parse('1000'),
          ),
        ],
        totalHours: Decimal.parse('5'),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.parse('12'),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.parse('12'),
        ),
        pieceName: 'Test piece',
        clientName: 'Test client',
      ),
    );
  }

  /// Inserta [count] cotizaciones (para el history cap: [kFreeHistoryCap]).
  Future<void> _seedCalculations(ProviderContainer container, int count) async {
    final calcRepo = container.read(calculationRepositoryProvider);
    for (var i = 0; i < count; i++) {
      await calcRepo.create(
        CalculationDraft(
          materials: [
            MaterialInput(
              label: 'PLA',
              weightGrams: Decimal.parse('100'),
              pricePerBobbin: Decimal.parse('120'),
              gramsPerBobbin: Decimal.parse('1000'),
            ),
          ],
          totalHours: Decimal.parse('5'),
          discountPercentage: Decimal.zero,
          output: CalculationOutput.simple(
            materialCost: Decimal.parse('12'),
            discountAmount: Decimal.zero,
            totalPrice: Decimal.parse('36'),
          ),
          pieceName: 'Seed #$i',
        ),
      );
    }
  }

  /// Helper: monta [TresdcalApp] (router REAL) con DB in-memory + fakes.
  /// [dashboardIsProProvider] override a isProProvider replica main.dart.
  ///
  /// El seeding se hace ANTES de `pumpWidget`: los providers se crean con
  /// datos ya en DB (evita cache de empty state en dashboardStatsProvider /
  /// calculationsNotifierProvider).
  Future<ProviderContainer> _pumpApp(
    WidgetTester tester, {
    int seedCalculations = 0,
    bool seedOne = false,
    bool seedPro = false,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _FakeEntitlementRepository();
    payment = _FakePaymentService();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        entitlementRepositoryProvider.overrideWithValue(repo),
        paymentServiceProvider.overrideWithValue(payment),
        dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider)),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await db.close();
    });
    if (seedPro) {
      repo.seedActive(
        Entitlement(
          id: 1,
          source: kSourceLifetimePurchase,
          productId: kProProductId,
          purchasedAt: DateTime.utc(2026, 1, 1),
          validatedAt: DateTime.utc(2026, 1, 1),
          isActive: true,
        ),
      );
    } else if (seedOne) {
      await _seedOneCalculation(container);
    } else if (seedCalculations > 0) {
      await _seedCalculations(container, seedCalculations);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Assert post-tap: [PaywallPage] montada en el arbol.
  ///
  /// En go_router 14.x, `push` renderiza la pagina pero NO actualiza
  /// `routerDelegate.currentConfiguration.uri` (queda con la locacion de
  /// base) — por eso la asercion es por widget, no por uri. Implica que NO
  /// estamos en `_RouterErrorPage` (lo que renderizaba el errorBuilder
  /// cuando la ruta no existia).
  Future<void> _expectPaywall(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(
      find.byType(PaywallPage),
      findsOneWidget,
      reason: 'El gate debe navegar a PaywallPage (ruta real, no error).',
    );
  }

  group('Gates → /paywall (router real, no _RouterErrorPage)', () {
    testWidgets('deep link web no expone paywall; mobile conserva la ruta', (
      tester,
    ) async {
      await _pumpApp(tester);

      appRouter.go('/paywall');
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(find.byType(PaywallPage), findsNothing);
        expect(
          appRouter.routerDelegate.currentConfiguration.uri.toString(),
          '/settings',
        );
      } else {
        expect(find.byType(PaywallPage), findsOneWidget);
      }
    });

    testWidgets(
      'Calculator: history cap save #11 → SnackBar Go Pro → PaywallPage',
      (tester) async {
        _useTallViewport(tester);
        await _pumpApp(tester, seedCalculations: kFreeHistoryCap);
        expect(await db.select(db.calculations).get(), hasLength(10));

        // push() devuelve un Future que resuelve al POP — no se awaita.
        unawaited(appRouter.push('/calculator'));
        await tester.pumpAndSettle();

        // Llenar el form express (Peso / Horas / Precio bobina).
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

        // Abrir el result sheet (bottom bar se vuelve valida).
        await tester.tap(find.byType(ResultBottomBar));
        await tester.pumpAndSettle();

        // Tap en "Guardar cotización" (save a DB) del sheet.
        await tester.tap(find.byTooltip('Guardar cotización'));
        await tester.pumpAndSettle();

        // Confirmar el dialog de save.
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        // Free + 10 existentes → cap: SnackBar con CTA Go Pro.
        final goPro = find.text(EsBO.calculatorGoProAction);
        expect(
          goPro,
          findsOneWidget,
          reason: 'History cap en free debe ofrecer "Go Pro".',
        );
        await tester.ensureVisible(goPro);
        await tester.tap(goPro);

        await _expectPaywall(tester);
      },
    );

    testWidgets('Historial: CSV export gate → SnackBar Go Pro → PaywallPage', (
      tester,
    ) async {
      _useTallViewport(tester);
      await _pumpApp(tester, seedOne: true);

      appRouter.go('/history');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
      // pumpAndSettle: deja que la snackbar termine de animar antes de
      // tocar su action (tap durante el slide es absorbido).
      await tester.pumpAndSettle();

      final goPro = find.byType(SnackBarAction);
      expect(
        goPro,
        findsOneWidget,
        reason: 'CSV gate en free debe ofrecer "Go Pro".',
      );
      expect(
        find.descendant(of: goPro, matching: find.text(EsBO.csvGoProAction)),
        findsOneWidget,
      );
      await tester.ensureVisible(goPro);
      await tester.tap(goPro);

      await _expectPaywall(tester);
    });

    testWidgets('Dashboard: Pro teaser button → PaywallPage', (tester) async {
      _useTallViewport(tester);
      await _pumpApp(tester, seedOne: true);

      appRouter.go('/dashboard');
      await tester.pumpAndSettle();

      final goPro = find.widgetWithText(
        FilledButton,
        EsBO.dashboardGoProAction,
      );
      expect(
        goPro,
        findsOneWidget,
        reason: 'Free: el teaser del dashboard debe tener boton Go Pro.',
      );
      await tester.ensureVisible(goPro);
      await tester.tap(goPro);

      await _expectPaywall(tester);
    });

    testWidgets(
      'Settings: companyName field gate → SnackBar Go Pro → PaywallPage',
      (tester) async {
        _useTallViewport(tester);
        await _pumpApp(tester);

        appRouter.go('/settings');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextField, '3dCalc'));
        // pumpAndSettle: deja que la snackbar termine de animar antes de
        // tocar su action (tap durante el slide es absorbido).
        await tester.pumpAndSettle();

        final goPro = find.byType(SnackBarAction);
        expect(
          goPro,
          findsOneWidget,
          reason: 'companyName gate en free debe ofrecer "Go Pro".',
        );
        expect(
          find.descendant(
            of: goPro,
            matching: find.text(EsBO.settingsGoProAction),
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(goPro);
        await tester.tap(goPro);

        await _expectPaywall(tester);
      },
    );

    testWidgets('Settings: logo pick gate → SnackBar Go Pro → PaywallPage', (
      tester,
    ) async {
      _useTallViewport(tester);
      await _pumpApp(tester);

      appRouter.go('/settings');
      await tester.pumpAndSettle();

      await tester.tap(find.text(EsBO.settingsCompanyLogoPick));
      await tester.pumpAndSettle();

      final goPro = find.byType(SnackBarAction);
      expect(
        goPro,
        findsOneWidget,
        reason: 'Logo pick gate en free debe ofrecer "Go Pro".',
      );
      expect(
        find.descendant(
          of: goPro,
          matching: find.text(EsBO.settingsGoProAction),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(goPro);
      await tester.tap(goPro);

      await _expectPaywall(tester);
    });

    testWidgets(
      'Calculator: advanced mode gate (free) → SnackBar Go Pro → PaywallPage',
      (tester) async {
        _useTallViewport(tester);
        final container = await _pumpApp(tester);

        unawaited(appRouter.push('/calculator'));
        await tester.pumpAndSettle();

        // Default: express. El form advanced (multi-material) NO existe.
        expect(find.text('Agregar material'), findsNothing);

        // El gate ahora lee el estado del notifier: sin esto, el tap caeria
        // en la ventana de loading (cold start) y haria swallow (no gatea).
        await container.read(entitlementNotifierProvider.future);
        await tester.pumpAndSettle();

        // Free: tocar "Avanzado" NO debe cambiar el modo → SnackBar gate.
        await tester.tap(find.text(EsBO.calcModeAdvanced));
        await tester.pumpAndSettle();

        expect(
          find.text(EsBO.calculatorAdvancedLockedBody),
          findsOneWidget,
          reason: 'Free: gate del modo advanced debe mostrar el body locked.',
        );
        final goPro = find.byType(SnackBarAction);
        expect(
          goPro,
          findsOneWidget,
          reason: 'Advanced gate en free debe ofrecer "Go Pro".',
        );
        expect(
          find.descendant(
            of: goPro,
            matching: find.text(EsBO.calculatorGoProAction),
          ),
          findsOneWidget,
        );
        // El modo NO cambio: el form advanced sigue sin montarse.
        expect(
          find.text('Agregar material'),
          findsNothing,
          reason: 'Free: el modo advanced NO debe activarse.',
        );

        await tester.ensureVisible(goPro);
        await tester.tap(goPro);

        await _expectPaywall(tester);
      },
    );

    testWidgets('Calculator: advanced mode gate (pro) → el modo SI cambia', (
      tester,
    ) async {
      _useTallViewport(tester);
      final container = await _pumpApp(tester, seedPro: true);

      unawaited(appRouter.push('/calculator'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar material'), findsNothing);

      // El calculator NO lee isProProvider durante build — forzamos que
      // el entitlementNotifier complete su boot (lee DB → Pro) antes del
      // tap, para que el gate vea el estado real.
      await container.read(entitlementNotifierProvider.future);
      await tester.pumpAndSettle();

      await tester.tap(find.text(EsBO.calcModeAdvanced));
      await tester.pumpAndSettle();

      // Pro: gate NO dispara (sin SnackBar locked) y el form advanced
      // (multi-material, con boton "Agregar material") se monta.
      expect(find.text(EsBO.calculatorAdvancedLockedBody), findsNothing);
      expect(find.text('Agregar material'), findsOneWidget);
    });
  });
}
