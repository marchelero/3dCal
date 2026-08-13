// ignore_for_file: public_member_api_docs, close_sinks, use_setters_to_change_properties
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/notifiers/entitlement_notifier.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';

/// Tests del wire [PaymentService] → [EntitlementNotifier] (T9 del plan
/// de monetizacion).
///
/// **Scope**: verifica que:
/// - `notifier.purchase()` despacha al [PaymentService] y maneja los 3
///   resultados (success → activate, cancel → no-op, error → no-op).
/// - `notifier.restore()` despacha al [PaymentService] y maneja los 3
///   resultados (active → activate, empty → deactivate, error → no-op).
/// - En el boot, si el cache dice Pro pero esta stale, se dispara
///   `restore()` async (fire-and-forget). Si esta fresh, NO se dispara.
///
/// **Mocks**: `_FakePaymentService` (sin SDK nativo) +
/// `_FakeRepo` in-memory. Sin red, sin platform channels.

/// Fake [PaymentService] in-memory. Sin platform channels, sin red.
/// El test setea el resultado que va a retornar cada metodo.
class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;
  int configureCalls = 0;
  int purchaseCalls = 0;
  String? lastPurchaseProductId;
  PaymentResult purchaseResult = const PaymentCancelled();
  int restoreCalls = 0;
  RestoreResult restoreResult = const RestoreEmpty();
  final _purchaseStream = StreamController<PaymentResult>.broadcast();

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

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

/// Fake [EntitlementRepository] in-memory.
class _FakeRepo implements EntitlementRepository {
  Entitlement? _active;
  int getActiveCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;
  EntitlementsCompanion? lastSaved;

  void seedActive(Entitlement? e) => _active = e;

  @override
  Future<Entitlement?> getActive() async {
    getActiveCalls++;
    return _active;
  }

  @override
  Future<int> save(EntitlementsCompanion entry) async {
    saveCalls++;
    lastSaved = entry;
    _active = Entitlement(
      id: 1,
      source: entry.source.value,
      productId: entry.productId.value,
      purchasedAt: entry.purchasedAt.value,
      validatedAt: entry.validatedAt.present ? entry.validatedAt.value : null,
      expiresAt: entry.expiresAt.present ? entry.expiresAt.value : null,
      receiptData: entry.receiptData.present ? entry.receiptData.value : null,
      isActive: entry.isActive.present ? entry.isActive.value : true,
    );
    return 1;
  }

  @override
  Future<int> clear() async {
    clearCalls++;
    _active = null;
    return 0;
  }

  @override
  Stream<Entitlement?> watchActive() => Stream<Entitlement?>.value(_active);
}

/// Espera 5 microtask hops para drenar fire-and-forget del boot.
Future<void> _waitForAsync() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('EntitlementNotifier.purchase()', () {
    late ProviderContainer container;
    late _FakePaymentService paymentService;
    late _FakeRepo repo;
    late SharedPreferences prefs;

    Future<void> setupContainer({
      Map<String, Object> spInitial = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(spInitial);
      prefs = await SharedPreferences.getInstance();
      paymentService = _FakePaymentService();
      repo = _FakeRepo();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(paymentService),
        ],
      );
    }

    tearDown(() => container.dispose());

    test(
      'PaymentSuccess → activate: state Pro + repo.save + cache true',
      () async {
        await setupContainer();
        await container.read(entitlementNotifierProvider.future);
        expect(
          container.read(entitlementNotifierProvider).value,
          isA<EntitlementFree>(),
        );

        final purchasedAt = DateTime.utc(2026, 7, 22);
        paymentService.seedPurchase(
          PaymentSuccess(productId: kProProductId, purchasedAt: purchasedAt),
        );

        await container
            .read(entitlementNotifierProvider.notifier)
            .purchase(productId: kProProductId);

        // PaymentService fue llamado con el productId correcto.
        expect(paymentService.purchaseCalls, 1);
        expect(paymentService.lastPurchaseProductId, kProProductId);

        // Repo.save fue llamado.
        expect(repo.saveCalls, 1);
        expect(repo.lastSaved!.source.value, kSourceLifetimePurchase);
        expect(repo.lastSaved!.productId.value, kProProductId);

        // State es Pro.
        final state = container.read(entitlementNotifierProvider).value;
        expect(state, isA<EntitlementPro>());

        // Cache SP actualizado.
        expect(prefs.getBool(kIsProKey), isTrue);
        expect(prefs.getString(kEntitlementSourceKey), kSourceLifetimePurchase);
        expect(prefs.getString(kEntitlementValidatedAtKey), isNotNull);
      },
    );

    test('PaymentCancelled → sin cambios (state sigue Free)', () async {
      await setupContainer();
      await container.read(entitlementNotifierProvider.future);
      expect(
        container.read(entitlementNotifierProvider).value,
        isA<EntitlementFree>(),
      );

      paymentService.seedPurchase(const PaymentCancelled());

      await container
          .read(entitlementNotifierProvider.notifier)
          .purchase(productId: kProProductId);

      expect(paymentService.purchaseCalls, 1);
      expect(repo.saveCalls, 0, reason: 'Cancel no debe escribir en DB.');
      expect(
        container.read(entitlementNotifierProvider).value,
        isA<EntitlementFree>(),
      );
      expect(prefs.getBool(kIsProKey), isNull);
    });

    test(
      'PaymentError → sin cambios (state sigue Free, no cache write)',
      () async {
        await setupContainer();
        await container.read(entitlementNotifierProvider.future);

        paymentService.seedPurchase(const PaymentError('boom'));

        await container
            .read(entitlementNotifierProvider.notifier)
            .purchase(productId: kProProductId);

        expect(paymentService.purchaseCalls, 1);
        expect(repo.saveCalls, 0);
        expect(
          container.read(entitlementNotifierProvider).value,
          isA<EntitlementFree>(),
        );
        expect(prefs.getBool(kIsProKey), isNull);
      },
    );
  });

  group('EntitlementNotifier.restore()', () {
    late ProviderContainer container;
    late _FakePaymentService paymentService;
    late _FakeRepo repo;
    late SharedPreferences prefs;

    Future<void> setupContainer({
      Map<String, Object> spInitial = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(spInitial);
      prefs = await SharedPreferences.getInstance();
      paymentService = _FakePaymentService();
      repo = _FakeRepo();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(paymentService),
        ],
      );
    }

    tearDown(() => container.dispose());

    test(
      'RestoreActive → activate: state Pro + repo.save + cache true',
      () async {
        await setupContainer();
        await container.read(entitlementNotifierProvider.future);

        final purchasedAt = DateTime.utc(2026, 1, 15);
        final validatedAt = DateTime.utc(2026, 7, 22);
        paymentService.seedRestore(
          RestoreActive(
            productId: kProProductId,
            purchasedAt: purchasedAt,
            validatedAt: validatedAt,
          ),
        );

        await container.read(entitlementNotifierProvider.notifier).restore();

        expect(paymentService.restoreCalls, 1);
        expect(repo.saveCalls, 1);
        expect(repo.lastSaved!.source.value, kSourceLifetimePurchase);
        final state = container.read(entitlementNotifierProvider).value;
        expect(state, isA<EntitlementPro>());
        expect(prefs.getBool(kIsProKey), isTrue);
      },
    );

    test(
      'RestoreEmpty → deactivate: state Free + repo.clear + cache cleared',
      () async {
        await setupContainer();
        await container.read(entitlementNotifierProvider.future);

        paymentService.seedRestore(const RestoreEmpty());

        await container.read(entitlementNotifierProvider.notifier).restore();

        expect(paymentService.restoreCalls, 1);
        expect(repo.clearCalls, 1);
        final state = container.read(entitlementNotifierProvider).value;
        expect(state, isA<EntitlementFree>());
        expect(prefs.getBool(kIsProKey), isNull);
        expect(prefs.getString(kEntitlementSourceKey), isNull);
        expect(prefs.getString(kEntitlementValidatedAtKey), isNull);
      },
    );

    test(
      'RestoreEmpty desde Pro (cache Pro + DB active) → downgrade a Free',
      () async {
        final validated = DateTime.now().toUtc();
        await setupContainer(
          spInitial: <String, Object>{
            kIsProKey: true,
            kEntitlementSourceKey: kSourceLifetimePurchase,
            kEntitlementValidatedAtKey: validated.toIso8601String(),
          },
        );
        // Seed DB con fila activa (caso: user compro, ahora refund).
        repo.seedActive(
          Entitlement(
            id: 1,
            source: kSourceLifetimePurchase,
            productId: kProProductId,
            purchasedAt: validated,
            validatedAt: validated,
            expiresAt: null,
            receiptData: null,
            isActive: true,
          ),
        );
        await container.read(entitlementNotifierProvider.future);
        expect(
          container.read(entitlementNotifierProvider).value,
          isA<EntitlementPro>(),
        );

        // Mock: store dice "no hay entitlement" (refund).
        paymentService.seedRestore(const RestoreEmpty());

        await container.read(entitlementNotifierProvider.notifier).restore();

        expect(paymentService.restoreCalls, 1);
        expect(repo.clearCalls, 1);
        final state = container.read(entitlementNotifierProvider).value;
        expect(state, isA<EntitlementFree>());
        expect(prefs.getBool(kIsProKey), isNull);
      },
    );

    test('RestoreError → sin cambios (state intacto)', () async {
      final validated = DateTime.now().toUtc();
      await setupContainer(
        spInitial: <String, Object>{
          kIsProKey: true,
          kEntitlementSourceKey: kSourceLifetimePurchase,
          kEntitlementValidatedAtKey: validated.toIso8601String(),
        },
      );
      await container.read(entitlementNotifierProvider.future);
      expect(
        container.read(entitlementNotifierProvider).value,
        isA<EntitlementPro>(),
      );

      paymentService.seedRestore(const RestoreError('network'));

      await container.read(entitlementNotifierProvider.notifier).restore();

      expect(paymentService.restoreCalls, 1);
      expect(repo.saveCalls, 0);
      expect(repo.clearCalls, 0);
      // State sigue Pro.
      final state = container.read(entitlementNotifierProvider).value;
      expect(state, isA<EntitlementPro>());
    });
  });

  group('EntitlementNotifier boot — stale vs fresh cache', () {
    late _FakePaymentService paymentService;
    late _FakeRepo repo;
    late SharedPreferences prefs;

    Future<ProviderContainer> setupContainer({
      Map<String, Object> spInitial = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(spInitial);
      prefs = await SharedPreferences.getInstance();
      paymentService = _FakePaymentService();
      repo = _FakeRepo();
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(paymentService),
        ],
      );
    }

    test(
      'cache Pro stale (validatedAt > 7 dias) → boot dispara restore()',
      () async {
        final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
        final container = await setupContainer(
          spInitial: <String, Object>{
            kIsProKey: true,
            kEntitlementSourceKey: kSourceLifetimePurchase,
            kEntitlementValidatedAtKey: stale.toIso8601String(),
          },
        );
        addTearDown(container.dispose);

        // Mock: store confirma entitlement.
        paymentService.seedRestore(
          RestoreActive(
            productId: kProProductId,
            purchasedAt: stale,
            validatedAt: DateTime.now().toUtc(),
          ),
        );

        final state = await container.read(entitlementNotifierProvider.future);
        expect(
          state,
          isA<EntitlementPro>(),
          reason: 'Primera emit (sync) viene del cache: Pro.',
        );

        // Esperar a que el restore fire-and-forget complete.
        await _waitForAsync();

        expect(
          paymentService.restoreCalls,
          greaterThanOrEqualTo(1),
          reason: 'Boot stale debio disparar restore() al menos 1 vez.',
        );
      },
    );

    test('cache Pro stale + restore empty → downgrade a Free', () async {
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
      final container = await setupContainer(
        spInitial: <String, Object>{
          kIsProKey: true,
          kEntitlementSourceKey: kSourceLifetimePurchase,
          kEntitlementValidatedAtKey: stale.toIso8601String(),
        },
      );
      addTearDown(container.dispose);

      // Mock: store dice "no entitlement" (refund).
      paymentService.seedRestore(const RestoreEmpty());

      final state = await container.read(entitlementNotifierProvider.future);
      expect(
        state,
        isA<EntitlementPro>(),
        reason: 'Primera emit (sync) desde cache: Pro.',
      );

      await _waitForAsync();

      // Tras el restore, el state debe haber bajado a Free.
      final finalState = container.read(entitlementNotifierProvider).value;
      expect(
        finalState,
        isA<EntitlementFree>(),
        reason: 'Restore empty + cache stale → downgrade a Free.',
      );

      // Y la cache debe haberse limpiado.
      expect(prefs.getBool(kIsProKey), isNull);
    });

    test(
      'cache Pro fresh (validatedAt < 7 dias) → NO dispara restore()',
      () async {
        final fresh = DateTime.now().toUtc().subtract(const Duration(days: 1));
        final container = await setupContainer(
          spInitial: <String, Object>{
            kIsProKey: true,
            kEntitlementSourceKey: kSourceLifetimePurchase,
            kEntitlementValidatedAtKey: fresh.toIso8601String(),
          },
        );
        addTearDown(container.dispose);

        final state = await container.read(entitlementNotifierProvider.future);
        expect(state, isA<EntitlementPro>());

        await _waitForAsync();

        expect(
          paymentService.restoreCalls,
          0,
          reason: 'Cache fresh no debe disparar restore() en boot.',
        );
      },
    );

    test(
      'cache Pro + validatedAt=null (stale por default) → dispara restore',
      () async {
        final container = await setupContainer(
          spInitial: <String, Object>{
            kIsProKey: true,
            kEntitlementSourceKey: kSourceLifetimePurchase,
            // Sin validatedAt — tratado como stale por default.
          },
        );
        addTearDown(container.dispose);

        paymentService.seedRestore(const RestoreEmpty());

        final state = await container.read(entitlementNotifierProvider.future);
        expect(state, isA<EntitlementPro>());

        await _waitForAsync();

        expect(
          paymentService.restoreCalls,
          greaterThanOrEqualTo(1),
          reason: 'validatedAt=null + cache Pro → restore disparado.',
        );
      },
    );

    test('cache Free (o vacio) → NO dispara restore() en boot', () async {
      final container = await setupContainer();
      addTearDown(container.dispose);

      final state = await container.read(entitlementNotifierProvider.future);
      expect(state, isA<EntitlementFree>());

      await _waitForAsync();

      expect(
        paymentService.restoreCalls,
        0,
        reason:
            'Cache Free no debe disparar restore() — no hay nada '
            'que validar.',
      );
    });
  });
}
