// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculations_list_page.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests del gate "Exportar CSV" (T16 del plan de monetizacion).
///
/// **Scope**:
/// - **Free**: tap en "Exportar CSV" muestra SnackBar con
///   [EsBO.csvExportLockedBody] + action [EsBO.csvGoProAction].
///   El action navega a `/paywall`. El export NO ocurre (no se invoca
///   `Share.shareXFiles`).
/// - **Pro**: tap en "Exportar CSV" NO muestra el gate SnackBar. Procede
///   al export (que en el test fallara con MissingPluginException — el
///   aserto relevante es "no se mostro el SnackBar de gate").
/// - **l10n**: las 2 keys nuevas existen en es_bo y en_us.
///
/// **Mocking**: `_FakeEntitlementRepository` + `_FakePaymentService`
/// (in-memory, sin SDK nativo). El `isProProvider` real se evalua
/// contra los fakes via el [entitlementNotifierProvider] real — asi
/// se ejercita la cadena completa (cache SP → repo → notifier →
/// isProProvider → gate).

class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;
  int saveCalls = 0;
  int clearCalls = 0;

  // ignore: use_setters_to_change_properties
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

  // ignore: close_sinks
  final StreamController<PaymentResult> _purchaseStream =
      StreamController<PaymentResult>.broadcast();

  // ignore: use_setters_to_change_properties
  void seedPurchase(PaymentResult r) => purchaseResult = r;
  // ignore: use_setters_to_change_properties
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
  Stream<PaymentResult> get purchaseStream => _purchaseStream.stream;

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Future<bool?> isProActiveOnStore() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

/// Stub para destinos de navegacion (solo necesitamos el titulo para
/// verificar que la navegacion llego a la ruta correcta).
class _ScaffoldWithText extends StatelessWidget {
  const _ScaffoldWithText({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}

/// Helper: inserta una cotizacion "dummy" via el [CalculationRepository]
/// real (contra DB in-memory). Asi el page no se renderiza en empty state
/// y el export button es visible.
Future<void> _seedOneCalculation(ProviderContainer container) async {
  final repo = container.read(calculationRepositoryProvider);
  await repo.create(
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

/// Helper: monta [CalculationsListPage] en estado FREE con un GoRouter
/// minimal (incluye `/paywall` para verificar la navegacion del SnackBar
/// action). Inserta 1 cotizacion dummy para que la lista no este vacia.
Future<({ProviderContainer container, AppDatabase db})> _pumpPageFree(
  WidgetTester tester, {
  int seedCount = 1,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = _FakeEntitlementRepository();
  final payment = _FakePaymentService();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementRepositoryProvider.overrideWithValue(repo),
      paymentServiceProvider.overrideWithValue(payment),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(() async {
    await db.close();
  });

  for (var i = 0; i < seedCount; i++) {
    await _seedOneCalculation(container);
  }

  final router = _buildRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, db: db);
}

/// Helper: monta [CalculationsListPage] en estado PRO (via cache SP
/// pre-poblada, sin tocar DB). Igual GoRouter que [_pumpPageFree].
Future<({ProviderContainer container, AppDatabase db})> _pumpPagePro(
  WidgetTester tester,
) async {
  final validated = DateTime.now().toUtc();
  SharedPreferences.setMockInitialValues(<String, Object>{
    kIsProKey: true,
    kEntitlementSourceKey: kSourceLifetimePurchase,
    kEntitlementValidatedAtKey: validated.toIso8601String(),
  });
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = _FakeEntitlementRepository();
  final payment = _FakePaymentService();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementRepositoryProvider.overrideWithValue(repo),
      paymentServiceProvider.overrideWithValue(payment),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(() async {
    await db.close();
  });

  // Forzar la resolucion del [EntitlementNotifier] ANTES de pumpWidget.
  // Si no, el primer pump corre con AsyncValue.loading y `isProProvider`
  // lee valueOrNull=null → isPro=false → el gate se dispara
  // incorrectamente en Pro.
  await container.read(entitlementNotifierProvider.future);

  await _seedOneCalculation(container);

  final router = _buildRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, db: db);
}

/// GoRouter minimal con la lista + el destino /paywall. Se reutiliza
/// entre los pumps Free y Pro.
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (_, _) => const CalculationsListPage(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, _) => const _ScaffoldWithText(title: 'Paywall stub'),
      ),
    ],
  );
}

void main() {
  setUp(() {
    EsBO.setImpl(const EsImpl());
  });

  // ─────────────────────────────────────────────────────────────
  // l10n (las 2 keys nuevas del gate)
  // ─────────────────────────────────────────────────────────────

  group('CSV gate l10n (T16)', () {
    test('EsBO.csvExportLockedBody esta definido y no vacio', () {
      expect(EsBO.csvExportLockedBody, isNotEmpty);
    });

    test('EsBO.csvGoProAction esta definido y no vacio', () {
      expect(EsBO.csvGoProAction, isNotEmpty);
    });

    test('EnImpl expone las 2 keys del CSV gate con texto no vacio', () {
      EsBO.setImpl(const EnImpl());
      expect(EsBO.csvExportLockedBody, isNotEmpty);
      expect(EsBO.csvGoProAction, isNotEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Gate behavior (Free + tap CSV)
  // ─────────────────────────────────────────────────────────────

  group('CalculationsListPage — CSV export gate en Free', () {
    testWidgets('duplicar al alcanzar el cap muestra el gate de historial', (
      tester,
    ) async {
      await _pumpPageFree(tester, seedCount: kFreeHistoryCap);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.calcDuplicateAction).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(EsBO.historyCapReachedBody), findsOneWidget);
      expect(find.text(EsBO.calculatorGoProAction), findsOneWidget);
    });

    testWidgets('muestra el IconButton "Exportar CSV" en la AppBar', (
      tester,
    ) async {
      await _pumpPageFree(tester);
      expect(
        find.byTooltip(EsBO.csvExportTooltipLocked),
        findsOneWidget,
        reason: 'Free: el boton de export CSV (tooltip locked) en la AppBar.',
      );
    });

    testWidgets(
      'tap en "Exportar CSV" muestra SnackBar con body + action "Go Pro"',
      (tester) async {
        await _pumpPageFree(tester);

        await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
        await tester.pump(); // Schedule SnackBar.
        await tester.pump(const Duration(milliseconds: 100)); // Anima SnackBar.

        // El SnackBar del gate debe estar visible.
        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason: 'Free debe ver SnackBar del gate.',
        );
        // Body del gate.
        expect(
          find.text(EsBO.csvExportLockedBody),
          findsOneWidget,
          reason: 'Body del SnackBar debe ser csvExportLockedBody.',
        );
        // Action label.
        expect(
          find.text(EsBO.csvGoProAction),
          findsOneWidget,
          reason: 'Action del SnackBar debe ser csvGoProAction.',
        );
      },
    );

    testWidgets(
      'NO muestra el SnackBar de "no hay cotizaciones" cuando hay datos',
      (tester) async {
        // La lista tiene 1 cotizacion seeded → el codigo del export debe
        // entrar al gate (no al branch de lista vacia).
        await _pumpPageFree(tester);

        await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // El texto del branch "lista vacia" no debe aparecer.
        expect(
          find.text('No hay cotizaciones para exportar'),
          findsNothing,
          reason:
              'Lista no vacia: el gate debe dispararse, no el branch empty.',
        );
        // El body del gate SI debe aparecer.
        expect(find.text(EsBO.csvExportLockedBody), findsOneWidget);
      },
    );

    testWidgets('tap en action "Go Pro" navega a /paywall', (tester) async {
      await _pumpPageFree(tester);

      await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // El action "Go Pro" del SnackBar debe estar visible.
      final goProAction = find.text(EsBO.csvGoProAction);
      expect(goProAction, findsOneWidget);

      // Tap en el action. Usamos ensureVisible por si quedo fuera del
      // viewport en viewports chicos.
      await tester.ensureVisible(goProAction);
      await tester.tap(goProAction);
      await tester.pumpAndSettle();

      // La pagina paywall (stub) debe estar visible.
      expect(
        find.text('Paywall stub'),
        findsOneWidget,
        reason: 'Action "Go Pro" debe navegar a /paywall.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Gate behavior (Pro + tap CSV) — export debe proceder, no gate
  // ─────────────────────────────────────────────────────────────

  group('CalculationsListPage — CSV export en Pro', () {
    testWidgets('tap en "Exportar CSV" NO muestra SnackBar del gate', (
      tester,
    ) async {
      final res = await _pumpPagePro(tester);

      // Sanity check: isProProvider debe ser true antes del tap. El
      // `_pumpPagePro` fuerza la resolucion del notifier via
      // `container.read(future)`, asi que esto es un guard redundante
      // para que un cambio futuro no haga el test silenciosamente
      // invalido.
      expect(
        res.container.read(isProProvider),
        isTrue,
        reason: 'Pro setup: el notifier debe haber resuelto a Pro.',
      );

      await tester.tap(find.byTooltip('Exportar CSV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // El body del gate NO debe aparecer.
      expect(
        find.text(EsBO.csvExportLockedBody),
        findsNothing,
        reason: 'Pro: el gate no debe dispararse.',
      );
      // El action "Go Pro" tampoco.
      expect(
        find.text(EsBO.csvGoProAction),
        findsNothing,
        reason: 'Pro: no debe ofrecer "Go Pro" en el export.',
      );
      // Y no debe aparecer el branch de lista vacia tampoco.
      expect(
        find.text('No hay cotizaciones para exportar'),
        findsNothing,
        reason: 'Lista no vacia: no debe disparar branch empty.',
      );
      // El share va a throw MissingPluginException (no hay platform
      // channel en test), pero eso no rompe el assert: lo que importa
      // es que el gate NO se disparo.
    });
  });
}
