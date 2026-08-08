// ignore_for_file: public_member_api_docs, use_setters_to_change_properties
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/notifiers/entitlement_notifier.dart';
import 'package:tresdcal/features/entitlement/presentation/pages/paywall_page.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests del paywall (T10 del plan de monetizacion).
///
/// **Scope**:
/// - Free state → renderiza titulo, precio, 5 features, boton Unlock, boton Restore.
/// - Pro state → renderiza "Already Pro" + Close, NO muestra Unlock.
/// - Unlock tap → invoca `entitlementNotifier.purchase()` con el productId
///   correcto (verificable via spy del PaymentService fake).
/// - Restore tap → invoca `entitlementNotifier.restore()`.
/// - Loading state → muestra spinner + botones deshabilitados.
/// - Error state → muestra SnackBar con mensaje user-friendly.
///
/// **Mocks**: `_FakePaymentService` + `_FakeRepo` (in-memory, sin SDK nativo).
/// El notifier es REAL (no se mockea) — usa los fakes como deps. Esto
/// valida el wire entre el widget y el notifier real, no solo UI aislada.

class _FakePaymentService implements PaymentService {
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  String? lastPurchaseProductId;
  PaymentResult purchaseResult = const PaymentCancelled();
  RestoreResult restoreResult = const RestoreEmpty();
  // ignore: close_sinks
  final StreamController<PaymentResult> _purchaseStream =
      StreamController<PaymentResult>.broadcast();

  void seedPurchase(PaymentResult r) => purchaseResult = r;
  void seedRestore(RestoreResult r) => restoreResult = r;

  @override
  Future<void> configure() async {
    configureCalls++;
  }

  @override
  Future<PaymentResult> purchase({required String productId}) async {
    purchaseCalls++;
    lastPurchaseProductId = productId;
    return purchaseResult;
  }

  @override
  Future<RestoreResult> restore() async {
    restoreCalls++;
    return restoreResult;
  }

  @override
  Stream<PaymentResult> get purchaseStream => _purchaseStream.stream;
}

class _FakeRepo implements EntitlementRepository {
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<Entitlement?> getActive() async => null;

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

/// Notifier que mantiene el state en `AsyncValue.loading()` para siempre.
/// Se usa para verificar que la UI renderiza el spinner durante un
/// purchase/restore en curso.
class _LoadingNotifier extends EntitlementNotifier {
  @override
  Future<EntitlementState> build() async {
    state = const AsyncValue<EntitlementState>.loading();
    return Completer<EntitlementState>().future;
  }
}

/// Notifier que mantiene el state en `AsyncValue.error(...)` para siempre.
/// Se usa para verificar que la SnackBar se dispara y permanece visible
/// mientras el state es error.
class _ErrorNotifier extends EntitlementNotifier {
  _ErrorNotifier(this._error);

  final Object _error;

  @override
  Future<EntitlementState> build() async {
    state = AsyncValue<EntitlementState>.error(_error, StackTrace.current);
    return Completer<EntitlementState>().future;
  }
}

/// Helper: pump del [PaywallPage] dentro de un ProviderScope con deps
/// fakados. Retorna el container + el payment service para que los tests
/// inspeccionen side effects.
Future<({ProviderContainer container, _FakePaymentService payment})>
    _pumpPaywall(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final payment = _FakePaymentService();
  final repo = _FakeRepo();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    entitlementRepositoryProvider.overrideWithValue(repo),
    paymentServiceProvider.overrideWithValue(payment),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PaywallPage()),
    ),
  );
  // pumpAndSettle para que el build() del notifier complete y emita data.
  await tester.pumpAndSettle();
  return (container: container, payment: payment);
}

Future<({ProviderContainer container, _FakePaymentService payment})>
    _pumpPaywallPro(WidgetTester tester) async {
  final validated = DateTime.now().toUtc();
  SharedPreferences.setMockInitialValues(<String, Object>{
    kIsProKey: true,
    kEntitlementSourceKey: kSourceLifetimePurchase,
    kEntitlementValidatedAtKey: validated.toIso8601String(),
  });
  final prefs = await SharedPreferences.getInstance();
  final payment = _FakePaymentService();
  final repo = _FakeRepo();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    entitlementRepositoryProvider.overrideWithValue(repo),
    paymentServiceProvider.overrideWithValue(payment),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PaywallPage()),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, payment: payment);
}

Future<({ProviderContainer container, _FakePaymentService payment})>
    _pumpPaywallLoading(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final payment = _FakePaymentService();
  final repo = _FakeRepo();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    entitlementRepositoryProvider.overrideWithValue(repo),
    paymentServiceProvider.overrideWithValue(payment),
    entitlementNotifierProvider.overrideWith(_LoadingNotifier.new),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PaywallPage()),
    ),
  );
  // NO pumpAndSettle — el notifier queda en loading. Un pump solo dispara
  // un frame para que el widget vea el AsyncValue.loading.
  await tester.pump();
  return (container: container, payment: payment);
}

/// Set viewport a 800x1600 (mas alto que el default 800x600) para que
/// el boton Unlock (cerca del fondo del SingleChildScrollView) entre
/// en pantalla sin scrollear.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Formatea el precio kProPriceUsd con el separador decimal del proyecto.
/// Matchea lo que la paywall muestra al user.
String _formatPrice() {
  // USD con 2 decimales: "$4.99" (locale-agnostic, no usa intl porque
  // el precio del paywall no se formatea segun el locale del user — la
  // store cobra en USD fijo).
  final dollars = kProPriceUsd.toStringAsFixed(2);
  return '\$$dollars';
}

void main() {
  // Reset entre tests para evitar que el estado del singleton de EsBO
  // (caso hipotetico) contamine otros tests.
  setUp(() {
    EsBO.setImpl(const EnImpl());
  });

  group('PaywallPage — Free state', () {
    testWidgets('renderiza titulo, precio, 5 features, Unlock y Restore',
        (tester) async {
      _useTallViewport(tester);
      await _pumpPaywall(tester);

      // Titulo + subtitulo + precio + boton.
      // El titulo aparece en el body (AppBar solo tiene close icon).
      expect(find.text(EsBO.paywallTitle), findsAtLeast(1));
      expect(find.text(EsBO.paywallSubtitle), findsOneWidget);
      expect(find.text(_formatPrice()), findsOneWidget);
      expect(find.text(EsBO.paywallUnlockButton(_formatPrice())),
          findsOneWidget);
      expect(find.text(EsBO.paywallRestoreButton), findsOneWidget);

      // 5 features.
      final features = EsBO.paywallFeatures;
      expect(features.length, 5);
      for (final f in features) {
        expect(find.text(f), findsOneWidget,
            reason: 'Feature "$f" no encontrada en el paywall.');
      }
    });

    testWidgets('tap en Unlock invoca notifier.purchase con kProProductId',
        (tester) async {
      _useTallViewport(tester);
      final result = await _pumpPaywall(tester);
      final payment = result.payment;

      // Seed: purchase retorna success para que el flow no se queje.
      payment.seedPurchase(PaymentSuccess(
        productId: kProProductId,
        purchasedAt: DateTime.now().toUtc(),
      ));

      final unlockButton = find.widgetWithText(
        FilledButton,
        EsBO.paywallUnlockButton(_formatPrice()),
      );
      expect(unlockButton, findsOneWidget);
      await tester.tap(unlockButton);
      // pumpAndSettle para que el Future del notifier complete.
      await tester.pumpAndSettle();

      expect(payment.purchaseCalls, 1,
          reason: 'Tap en Unlock debe llamar PaymentService.purchase.');
      expect(payment.lastPurchaseProductId, kProProductId,
          reason: 'Purchase debe recibir el productId correcto.');
      // No leak de restore.
      expect(payment.restoreCalls, 0);
    });

    testWidgets('tap en Restore invoca notifier.restore()', (tester) async {
      _useTallViewport(tester);
      final result = await _pumpPaywall(tester);
      final payment = result.payment;

      payment.seedRestore(const RestoreEmpty());

      final restoreButton = find.widgetWithText(
        TextButton,
        EsBO.paywallRestoreButton,
      );
      expect(restoreButton, findsOneWidget);
      await tester.tap(restoreButton);
      await tester.pumpAndSettle();

      expect(payment.restoreCalls, 1,
          reason: 'Tap en Restore debe llamar PaymentService.restore.');
      // No leak de purchase.
      expect(payment.purchaseCalls, 0);
    });
  });

  group('PaywallPage — Pro state', () {
    testWidgets(
      'muestra UI "Already Pro" con boton Close y NO muestra Unlock',
      (tester) async {
        _useTallViewport(tester);
        await _pumpPaywallPro(tester);

        expect(find.text(EsBO.paywallAlreadyPro), findsOneWidget);
        // Boton Close presente (FilledButton con label "Close").
        expect(find.widgetWithText(FilledButton, EsBO.paywallClose),
            findsOneWidget);
        // Unlock ausente (no hay nada que comprar).
        expect(find.text(EsBO.paywallUnlockButton(_formatPrice())),
            findsNothing);
        // Features ausentes (no estamos vendiendo nada).
        final features = EsBO.paywallFeatures;
        for (final f in features) {
          expect(find.text(f), findsNothing,
              reason: 'Feature "$f" no debe estar en Already Pro view.');
        }
        // Subtitulo "Unlock all features" ausente.
        expect(find.text(EsBO.paywallSubtitle), findsNothing);
      },
    );
  });

  group('PaywallPage — Loading state', () {
    testWidgets(
      'muestra CircularProgressIndicator cuando AsyncValue esta loading',
      (tester) async {
        await _pumpPaywallLoading(tester);

        expect(find.byType(CircularProgressIndicator), findsAtLeast(1),
            reason: 'Loading state debe mostrar al menos 1 spinner.');
      },
    );
  });

  group('PaywallPage — Error state', () {
    testWidgets(
      'muestra SnackBar con error message cuando AsyncValue tiene error',
      (tester) async {
        // Override el notifier para emitir un error permanente.
        late ProviderContainer container;
        late _FakePaymentService payment;
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        payment = _FakePaymentService();
        final repo = _FakeRepo();

        final errorNotifier =
            _ErrorNotifier(Exception('boom from notifier'));
        container = ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(payment),
          entitlementNotifierProvider.overrideWith(() => errorNotifier),
        ]);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: PaywallPage()),
          ),
        );
        // pumpAndSettle deja que el listener de ref.listen dispare la
        // SnackBar y que la animacion del SnackBar entre.
        await tester.pumpAndSettle();

        // El SnackBar con el mensaje de error generico debe estar visible.
        expect(find.byType(SnackBar), findsAtLeast(1),
            reason: 'Error debe disparar SnackBar.');
        // El mensaje exacto viene del paywall — debe contener la key l10n.
        expect(find.textContaining(EsBO.paywallErrorGeneric), findsAtLeast(1));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────
  // T20 — Close button coverage. Los botones de cerrar (X en AppBar +
  // FilledButton en "Already Pro" view) tienen un `if (context.canPop())
  // { context.pop(); }` defensivo. Para ejercitar el `context.pop()` real
  // (no la rama `canPop() == false`), necesitamos un GoRouter con un
  // stack que tenga al paywall pusheado encima de otra ruta.
  // ─────────────────────────────────────────────────────────────

  group('PaywallPage — Close button (T20 coverage)', () {
    /// Pump helper con GoRouter y una ruta previa "/home" para que el
    /// paywall pueda hacer `context.pop()`.
    Future<GoRouter> _pumpPaywallWithStack(WidgetTester tester) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final payment = _FakePaymentService();
      final repo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entitlementRepositoryProvider.overrideWithValue(repo),
        paymentServiceProvider.overrideWithValue(payment),
      ]);
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('HOME_T20')),
            ),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, _) => const PaywallPage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      // Push paywall encima de home.
      router.push('/paywall');
      await tester.pumpAndSettle();
      // Sanity: paywall visible, no estamos en home.
      expect(find.byType(PaywallPage), findsOneWidget);
      return router;
    }

    testWidgets('X en AppBar dispara context.pop() y vuelve a /home',
        (tester) async {
      final router = await _pumpPaywallWithStack(tester);

      // El X es el IconButton con tooltip "Close" (paywallClose).
      final closeIcon = find.byTooltip(EsBO.paywallClose);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Debe haber vuelto a /home. (El paywall ya no esta visible.)
      expect(find.byType(PaywallPage), findsNothing);
      expect(find.text('HOME_T20'), findsOneWidget);
      // Router confirma la locacion.
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          '/home');
    });
  });

  group('PaywallPage — Already Pro close button (T20 coverage)', () {
    /// Igual al anterior pero con state Pro (mock prefs con isPro=true).
    /// El paywall muestra "Already Pro" view con un FilledButton "Close"
    /// en vez del X del AppBar. Tambien gated por `canPop()`.
    testWidgets('FilledButton "Close" en Already Pro view dispara pop()',
        (tester) async {
      _useTallViewport(tester);
      final validated = DateTime.now().toUtc();
      SharedPreferences.setMockInitialValues(<String, Object>{
        kIsProKey: true,
        kEntitlementSourceKey: kSourceLifetimePurchase,
        kEntitlementValidatedAtKey: validated.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();
      final payment = _FakePaymentService();
      final repo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entitlementRepositoryProvider.overrideWithValue(repo),
        paymentServiceProvider.overrideWithValue(payment),
      ]);
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('HOME_T20')),
            ),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, _) => const PaywallPage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      router.push('/paywall');
      await tester.pumpAndSettle();

      // Estamos en Already Pro view: el FilledButton con label "Close".
      final closeBtn = find.widgetWithText(FilledButton, EsBO.paywallClose);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Pop realizado: paywall gone, home visible.
      expect(find.byType(PaywallPage), findsNothing);
      expect(find.text('HOME_T20'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          '/home');
    });
  });
}
