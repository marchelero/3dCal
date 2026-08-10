// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, no_leading_underscores_for_local_identifiers
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
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

/// E2E del flujo completo paywall → unlock (T6 del plan free/pro Play
/// Store prep). Extiende `test/integration/purchase_flow_test.dart` (que
/// testea el notifier con DB in-memory) agregando la capa de UI + router.
///
/// **Stack**: [TresdcalApp] (router REAL `appRouter`) + DB in-memory real +
/// [PaymentService] mock via `paymentServiceProvider` + [EntitlementRepository]
/// fake + `dashboardIsProProvider` override a `isProProvider` (replica el
/// wiring de `main.dart`).
///
/// **Paths cubiertos**:
/// - purchase success → gates unlock (dashboard charts visibles, CSV
///   habilitado, history cap levantado).
/// - restore success → unlock (dashboard charts visibles).
/// - cancel → snackbar del gate sigue + sin unlock.
/// - error → sin unlock.
///
/// **Desvio documentado**: el plan menciona "advanced mode visible" como
/// gate de Pro, pero en el codigo actual el modo avanzado del calculator
/// (`CalculatorMode.advanced`) NO es un gate de isPro. El gate Pro del
/// calculator es el **history cap** (save #11); usamos el lift del cap
/// como el "calculator gate unlock" en el test de purchase success.
///
/// **Actualizacion (review F1+F2)**: `CalculatorMode.advanced` YA es un
/// gate de isPro desde T14 (`_switchMode` en calculator_page.dart muestra
/// SnackBar locked en free). El gate del calculator testea aca sigue siendo
/// el history cap (save #11), que cubre el camino E2E con UI.

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
}

/// Viewport alto (800x1600) para que los botones del paywall (Unlock,
/// Restore) y los SnackBar actions entren en pantalla sin scrollear.
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
    // Reset del router global (singleton, persiste entre tests del file).
    appRouter.go('/');
  });

  /// Inserta [count] cotizaciones via repo real.
  Future<void> _seedCalculations(
    ProviderContainer container,
    int count,
  ) async {
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
  ///
  /// El seeding se hace ANTES de `pumpWidget`: los providers
  /// (`dashboardStatsProvider`, `calculationsNotifierProvider`) se crean
  /// por primera vez con datos ya en DB, evitando el cache de empty state.
  Future<ProviderContainer> _pumpApp(
    WidgetTester tester, {
    int seedCalculations = 1,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _FakeEntitlementRepository();
    payment = _FakePaymentService();
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementRepositoryProvider.overrideWithValue(repo),
      paymentServiceProvider.overrideWithValue(payment),
      dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider)),
    ]);
    addTearDown(container.dispose);
    addTearDown(() async {
      await db.close();
    });
    if (seedCalculations > 0) {
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

  /// Llena el form express del calculator (Peso / Horas / Precio bobina).
  Future<void> _fillCalculatorForm(WidgetTester tester) async {
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
  }

  /// Tapa el boton Unlock del paywall (paywall ya montado).
  ///
  /// El label usa `EsBO.paywallPrice` ("\$4,99", coma decimal es-BO), no
  /// el formato de [kProPriceUsd].
  Future<void> _tapUnlock(WidgetTester tester) async {
    final unlock = find.widgetWithText(
      FilledButton,
      EsBO.paywallUnlockButton(EsBO.paywallPrice),
    );
    expect(unlock, findsOneWidget,
        reason: 'Paywall free debe mostrar el boton Unlock.');
    await tester.ensureVisible(unlock);
    await tester.tap(unlock);
    await tester.pumpAndSettle();
  }

  /// Tapa el boton Restore del paywall (paywall ya montado).
  Future<void> _tapRestore(WidgetTester tester) async {
    final restore = find.widgetWithText(
      TextButton,
      EsBO.paywallRestoreButton,
    );
    expect(restore, findsOneWidget,
        reason: 'Paywall free debe mostrar el boton Restore.');
    await tester.ensureVisible(restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();
  }

  /// Abre el paywall y tapa Unlock con el resultado seedado.
  Future<void> _unlockViaPaywall(
    WidgetTester tester, {
    required void Function() seed,
  }) async {
    seed();
    _useTallViewport(tester);
    // push() devuelve un Future que resuelve al POP — no se awaita.
    unawaited(appRouter.push('/paywall'));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    await _tapUnlock(tester);
  }

  group('Purchase success → gates unlock', () {
    testWidgets(
      'dashboard charts, CSV habilitado y history cap levantado',
      (tester) async {
        _useTallViewport(tester);
        // 10 existentes: cap activo en free, save #11 solo para Pro.
        final container = await _pumpApp(tester, seedCalculations: 10);

        // ── Free: dashboard teaser, sin charts ──
        appRouter.go('/dashboard');
        await tester.pumpAndSettle();
        expect(find.text(EsBO.dashboardProTeaserTitle.toUpperCase()), findsOneWidget,
            reason: 'Free: teaser Pro visible en dashboard.');
        expect(
          find.widgetWithText(FilledButton, EsBO.dashboardGoProAction),
          findsOneWidget,
        );
        expect(find.byType(BarChart), findsNothing,
            reason: 'Free: charts ocultos (dashboardIsProProvider=false).');

        // ── Free: CSV gated ──
        appRouter.go('/history');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text(EsBO.csvExportLockedBody), findsOneWidget,
            reason: 'Free: CSV gate con SnackBar.');

        // Oculta la snackbar free: el messenger es root-level y persiste
        // entre paginas. Si queda viva, al volver a /history en modo Pro la
        // asercion veria la snackbar vieja como si el gate siguiera activo.
        // (El auto-dismiss timer de la SnackBar arranca recien cuando termina
        // la animacion de entrada, asi que pump(5s) no es deterministico.)
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .hideCurrentSnackBar();
        await tester.pumpAndSettle();

        // ── Paywall → purchase success ──
        await _unlockViaPaywall(tester, seed: () {
          payment.seedPurchase(PaymentSuccess(
            productId: kProProductId,
            purchasedAt: DateTime.now().toUtc(),
          ));
        });

        // isPro reactivo = true.
        expect(container.read(isProProvider), isTrue,
            reason: 'Purchase success debe activar Pro.');
        expect(payment.purchaseCalls, 1);

        // ── Pro: dashboard charts visibles, teaser gone ──
        appRouter.go('/dashboard');
        await tester.pumpAndSettle();
        expect(find.byType(BarChart), findsOneWidget,
            reason: 'Pro: charts visibles (dashboardIsProProvider wireado).');
        expect(find.text(EsBO.dashboardProTeaserTitle.toUpperCase()), findsNothing,
            reason: 'Pro: teaser ya no se muestra.');

        // ── Pro: CSV habilitado (sin gate) ──
        appRouter.go('/history');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Exportar CSV'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text(EsBO.csvExportLockedBody), findsNothing,
            reason: 'Pro: CSV sin gate.');

        // ── Pro: history cap levantado → save #11 funciona ──
        unawaited(appRouter.push('/calculator'));
        await tester.pumpAndSettle();
        await _fillCalculatorForm(tester);
        await tester.tap(find.byType(ResultBottomBar));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Guardar cotización'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(await db.select(db.calculations).get(), hasLength(11),
            reason: 'Pro: el save #11 no debe chocar con el history cap.');

        // Drena los Future.delayed del stagger del listado de /history
        // (calculations_list_page.dart:483, index*60ms → item 10 = 600ms)
        // que quedan montados en el shell; si no, quedan pendientes al
        // teardown y el binding falla con "A Timer is still pending".
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      },
    );
  });

  group('Restore success → gates unlock', () {
    testWidgets('dashboard charts visibles tras restore activo',
        (tester) async {
      _useTallViewport(tester);
      final container = await _pumpApp(tester);

      // Free baseline: teaser.
      appRouter.go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsNothing);

      // Paywall → restore success.
      payment.seedRestore(RestoreActive(
        productId: kProProductId,
        purchasedAt: DateTime.now().toUtc(),
        validatedAt: DateTime.now().toUtc(),
      ));
      unawaited(appRouter.push('/paywall'));
      await tester.pumpAndSettle();
      await _tapRestore(tester);

      expect(container.read(isProProvider), isTrue,
          reason: 'Restore activo debe activar Pro.');
      expect(payment.restoreCalls, 1);

      // Pro: charts visibles.
      appRouter.go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text(EsBO.dashboardProTeaserTitle.toUpperCase()), findsNothing);
    });
  });

  group('Cancel path → sin unlock', () {
    testWidgets('cancel no cambia estado; CSV sigue gated',
        (tester) async {
      _useTallViewport(tester);
      final container = await _pumpApp(tester);

      await _unlockViaPaywall(tester, seed: () {
        payment.seedPurchase(const PaymentCancelled());
      });

      expect(container.read(isProProvider), isFalse,
          reason: 'Cancel no debe activar Pro.');
      expect(payment.purchaseCalls, 1);

      // Dashboard sigue free.
      appRouter.go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.text(EsBO.dashboardProTeaserTitle.toUpperCase()), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);

      // CSV sigue gated (snackbar del gate persiste al tap).
      appRouter.go('/history');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(EsBO.csvExportLockedBody), findsOneWidget,
          reason: 'Cancel: el gate CSV debe seguir activo.');
    });
  });

  group('Error path → sin unlock', () {
    testWidgets('error de purchase no cambia estado; dashboard sigue free',
        (tester) async {
      _useTallViewport(tester);
      final container = await _pumpApp(tester);

      await _unlockViaPaywall(tester, seed: () {
        payment.seedPurchase(const PaymentError('network'));
      });

      expect(container.read(isProProvider), isFalse,
          reason: 'Error de purchase no debe activar Pro.');
      expect(payment.purchaseCalls, 1);

      appRouter.go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.text(EsBO.dashboardProTeaserTitle.toUpperCase()), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });
  });
}
