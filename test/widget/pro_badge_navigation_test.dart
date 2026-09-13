// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, no_leading_underscores_for_local_identifiers
//
// F1 — Navigation de los badges ProBadge → `/paywall`.
//
// **Scope**: el tap en un [ProBadge] (componente compartido, usado en los
// 5 call sites) navega a la [PaywallPage] con el router REAL ([TresdcalApp] +
// `appRouter`). Cubre:
// - AC-102: free → navega; pro (o entitlement loading) → NO navega.
// - AC-103: los badges anidados dentro de otra InkWell (header "Costos de la pieza",
//   pill de modo) disparan UNA sola navegacion — sin doble PaywallPage.
// - El badge del result sheet (custom onTap) cierra el sheet antes de
//   navegar.
//
// **Fakes**: `_FakeEntitlementRepository` + `_FakePaymentService` (copiados
// de paywall_navigation_test). `isProProvider` real via el notifier.
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';
import 'package:tresdcal/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/pages/paywall_page.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/shared/widgets/numeric_input_field.dart';
import 'package:tresdcal/shared/widgets/pro_badge.dart';
import 'package:tresdcal/shared/widgets/section_header.dart';

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

Entitlement _proEntitlement() => Entitlement(
  id: 1,
  source: kSourceLifetimePurchase,
  productId: kProProductId,
  purchasedAt: DateTime.utc(2026, 1, 1),
  validatedAt: DateTime.utc(2026, 1, 1),
  isActive: true,
);

/// Viewport alto para botones cerca del fondo (paywall / sheet).
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EsBO.setImpl(const EsImpl());
    // Reset del router global (es singleton, persiste entre tests del file).
    appRouter.go('/');
  });

  /// Ack del tap del badge ProBadge: espera la PaywallPage montada.
  Future<void> expectPaywall(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(
      find.byType(PaywallPage),
      findsOneWidget,
      reason: 'El badge debe navegar a PaywallPage (una sola vez).',
    );
  }

  /// Espera (con timeout) hasta que [finder] matchee 1+ widgets. Intercala
  /// `runAsync` (deja completar futures/IO reales del test env) con `pump`
  /// para no depender de `pumpAndSettle` cuando hay animaciones continuas
  /// (spinner de carga del detalle).
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('timeout esperando $finder');
  }

  group('ProBadge — default handler (AC-102)', () {
    /// Harness minimo: ProBadge en '/' + ruta '/paywall' (stub). Sin
    /// pages reales — aislar el componente.
    Future<ProviderContainer> pumpMinimal(
      WidgetTester tester, {
      bool seedPro = false,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeEntitlementRepository();
      if (seedPro) repo.seedActive(_proEntitlement());
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(_FakePaymentService()),
        ],
      );
      addTearDown(container.dispose);

      // Pre-boot del entitlement: el handler del badge no navega durante
      // el loading (AC-102) — para poder probarlo el tier debe estar
      // resuelto ANTES del tap.
      await container.read(entitlementNotifierProvider.future);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => const Scaffold(body: Center(child: ProBadge())),
          ),
          GoRoute(
            path: '/paywall',
            builder: (c, s) =>
                const Scaffold(body: Center(child: Text('PAYWALL-STUB'))),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('free: tap en el badge → /paywall', (tester) async {
      await pumpMinimal(tester);

      await tester.tap(find.byType(ProBadge));
      await tester.pumpAndSettle();

      expect(find.text('PAYWALL-STUB'), findsOneWidget);
    });

    testWidgets('pro: tap en el badge → NO navega', (tester) async {
      await pumpMinimal(tester, seedPro: true);

      await tester.tap(find.byType(ProBadge));
      await tester.pumpAndSettle();

      expect(find.text('PAYWALL-STUB'), findsNothing);
      expect(find.byType(ProBadge), findsOneWidget);
    });
  });

  group('Gates de badge → /paywall (router real)', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late _FakeEntitlementRepository repo;

    /// Inserta 1 cotizacion y devuelve su id.
    Future<int> seedOneCalculation(ProviderContainer container) async {
      final calcRepo = container.read(calculationRepositoryProvider);
      return calcRepo.create(
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

    /// Monta [TresdcalApp] con DB in-memory + fakes (mismas overrides que
    /// paywall_navigation_test para que dashboard/router vean el estado).
    /// [seed] inserta datos ANTES de montar el widget tree (el notifier de
    /// cálculos arranca con la DB ya poblada; sino queda con lista vacía).
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      bool seedPro = false,
      Future<void> Function(ProviderContainer container)? seed,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
      });
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = _FakeEntitlementRepository();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(_FakePaymentService()),
          dashboardIsProProvider.overrideWith(
            (ref) => ref.watch(isProProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() async {
        await db.close();
      });
      if (seedPro) repo.seedActive(_proEntitlement());
      await seed?.call(container);
      // Pre-boot del entitlement (AC-102: durante loading el badge no
      // navega) — resuelto antes de interactuar con el badge.
      await container.read(entitlementNotifierProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TresdcalApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('Calculator: badge del header "Costos de la pieza" → PaywallPage (AC-103)', (
      tester,
    ) async {
      _useTallViewport(tester);
      await pumpApp(tester);

      unawaited(appRouter.push('/calculator'));
      await tester.pumpAndSettle();

      // El badge del header "Costos de la pieza" (dentro del onTap del SectionHeader:
      // el InkWell externo del header NO debe disparar su propio push).
      final otrosBadge = find.descendant(
        of: find.byType(SectionHeader),
        matching: find.byType(ProBadge),
      );
      expect(otrosBadge, findsOneWidget);
      await tester.tap(otrosBadge);

      // UNA sola PaywallPage (sin doble navegacion del InkWell externo).
      await expectPaywall(tester);
    });

    testWidgets(
      'Calculator: badge del pill "Avanzado" → PaywallPage (AC-103)',
      (tester) async {
        _useTallViewport(tester);
        await pumpApp(tester);

        unawaited(appRouter.push('/calculator'));
        await tester.pumpAndSettle();

        // El pill "Avanzado" (locked en free) contiene su propio ProBadge,
        // FUERA del SectionHeader de "Costos de la pieza". La calculator tiene 2 badges:
        // el del header (dentro de SectionHeader) + el del pill.
        final scaffoldBadges = find.descendant(
          of: find.byType(CalculatorPage),
          matching: find.byType(ProBadge),
        );
        expect(
          scaffoldBadges,
          findsNWidgets(2),
          reason: 'badges en free: header "Costos de la pieza" + pill Avanzado (AC-103)',
        );
        final pillBadge = find.byWidget(
          scaffoldBadges.evaluate().last.widget as ProBadge,
        );
        await tester.tap(pillBadge);

        await expectPaywall(tester);
      },
    );

    testWidgets(
      'Calculator result sheet: badge de Cantidad → cierra el sheet y navega',
      (tester) async {
        _useTallViewport(tester);
        await pumpApp(tester);

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

        final sheetBadge = find.descendant(
          of: find.byType(ResultSheetContent),
          matching: find.byType(ProBadge),
        );
        expect(sheetBadge, findsOneWidget);
        await tester.tap(sheetBadge);

        await tester.pumpAndSettle();

        // El onTap custom cierra el sheet antes de navegar.
        expect(find.byType(ResultSheetContent), findsNothing);
        await expectPaywall(tester);
      },
    );

    testWidgets('Detail page: badge del resumen → PaywallPage', (tester) async {
      _useTallViewport(tester);
      late int calcId;
      await pumpApp(
        tester,
        seed: (c) async {
          calcId = await seedOneCalculation(c);
        },
      );

      appRouter.go('/history/$calcId');
      // La page del detalle muestra un spinner mientras navega/loads;
      // bounded pump (sin pumpAndSettle) hasta que aparezca el badge.
      await pumpUntilFound(tester, find.byType(ProBadge));

      final badge = find.byType(ProBadge);
      expect(badge, findsOneWidget);
      await tester.ensureVisible(badge);
      await tester.tap(badge);

      await expectPaywall(tester);
    });

    testWidgets('Settings: badge del branding → PaywallPage', (tester) async {
      _useTallViewport(tester);
      await pumpApp(tester);

      appRouter.go('/settings');
      await tester.pumpAndSettle();

      final badge = find.byType(ProBadge);
      expect(badge, findsOneWidget);
      await tester.ensureVisible(badge);
      await tester.pumpAndSettle();
      await tester.tap(badge);

      await expectPaywall(tester);
    });
  });
}
