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

/// Tests del downgrade en tiempo real por revocacion (FIX 2): cuando
/// RevenueCat detecta que el entitlement `pro` quedo inactivo (refund /
/// cancelacion de un non-subscription) mientras la app corre, el
/// [EntitlementNotifier] debe bajar a Free y limpiar el cache local — sin
/// esperar el restore stale de 7 dias.
///
/// **Mocks**: `_FakePaymentService` con un [StreamController] que el test
/// usa para emitir revocaciones (`emitRevocation`), replicando lo que en
/// prod hace el `Purchases.addCustomerInfoUpdateListener` dentro de
/// `RevenueCatPaymentService`. El repo y el cache son fakes in-memory.
class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  PaymentResult purchaseResult = const PaymentCancelled();
  RestoreResult restoreResult = const RestoreEmpty();
  final _revocations = StreamController<void>.broadcast();

  void seedPurchase(PaymentResult r) => purchaseResult = r;
  void seedRestore(RestoreResult r) => restoreResult = r;

  /// Simula el `addCustomerInfoUpdateListener` de RevenueCat reportando
  /// que el entitlement `pro` quedo inactivo (refund/cancel).
  void emitRevocation() => _revocations.add(null);

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
  Future<bool?> isProActiveOnStore() async => null;

  @override
  Stream<void> get proRevocationStream => _revocations.stream;
}

/// Fake [EntitlementRepository] in-memory. Cuenta las llamadas a `clear()`
/// para verificar que el downgrade por revocacion limpia la DB.
class _FakeRepo implements EntitlementRepository {
  Entitlement? _active;
  int getActiveCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;

  void seedActive(Entitlement? e) => _active = e;

  @override
  Future<Entitlement?> getActive() async {
    getActiveCalls++;
    return _active;
  }

  @override
  Future<int> save(EntitlementsCompanion entry) async {
    saveCalls++;
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

/// Drena las microtasks pendientes (el handler de revocacion es
/// fire-and-forget → `deactivate()` async).
Future<void> _waitForAsync() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
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

  test('revocacion desde Pro → downgrade a Free + cache/DB limpiados', () async {
    // Pre-poblar cache Pro fresh (para que el boot emita Pro sin restore).
    final validated = DateTime.now().toUtc();
    await setupContainer(
      spInitial: <String, Object>{
        kIsProKey: true,
        kEntitlementSourceKey: kSourceLifetimePurchase,
        kEntitlementValidatedAtKey: validated.toIso8601String(),
      },
    );
    // Seed DB con fila activa (caso real: user compro, ahora refund).
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

    // RevenueCat reporta que el entitlement quedo inactivo.
    paymentService.emitRevocation();
    await _waitForAsync();

    final state = container.read(entitlementNotifierProvider).value;
    expect(
      state,
      isA<EntitlementFree>(),
      reason: 'Refund detectado en vivo debe bajar a Free.',
    );
    expect(container.read(isProProvider), isFalse);
    expect(
      repo.clearCalls,
      1,
      reason: 'El downgrade debe limpiar la fila activa de la DB.',
    );
    expect(
      prefs.getBool(kIsProKey),
      isNull,
      reason: 'La cache local debe borrarse.',
    );
    expect(prefs.getString(kEntitlementSourceKey), isNull);
    expect(prefs.getString(kEntitlementValidatedAtKey), isNull);
  });

  test('revocacion en estado Free → no-op (sin clear, sin escrituras)', () async {
    await setupContainer();

    await container.read(entitlementNotifierProvider.future);
    expect(
      container.read(entitlementNotifierProvider).value,
      isA<EntitlementFree>(),
    );

    paymentService.emitRevocation();
    await _waitForAsync();

    final state = container.read(entitlementNotifierProvider).value;
    expect(state, isA<EntitlementFree>());
    expect(
      repo.clearCalls,
      0,
      reason: 'User free: una revocacion no debe tocar la DB.',
    );
    expect(repo.saveCalls, 0);
  });

  test('revocacion tras una compra posterior → vuelve a Free (re-arm)', () async {
    await setupContainer();

    await container.read(entitlementNotifierProvider.future);

    // Compra exitosa → Pro.
    paymentService.seedPurchase(
      PaymentSuccess(
        productId: kProProductId,
        purchasedAt: DateTime.now().toUtc(),
      ),
    );
    await container
        .read(entitlementNotifierProvider.notifier)
        .purchase(productId: kProProductId);
    expect(container.read(isProProvider), isTrue);

    // Refund posterior → vuelve a Free.
    paymentService.emitRevocation();
    await _waitForAsync();

    expect(container.read(isProProvider), isFalse);
    expect(
      container.read(entitlementNotifierProvider).value,
      isA<EntitlementFree>(),
    );
    expect(prefs.getBool(kIsProKey), isNull);
  });

  test('revocacion durante loading (boot sin terminar) → no-op', () async {
    await setupContainer();
    // Disparamos la revocacion ANTES de que el boot complete, sin leer el
    // future (el state puede estar en loading). El handler no debe crashear
    // ni escribir.
    paymentService.emitRevocation();
    await _waitForAsync();

    // Boot normal completa a Free.
    final state = await container.read(entitlementNotifierProvider.future);
    expect(state, isA<EntitlementFree>());
    expect(
      repo.clearCalls,
      0,
      reason: 'Revocacion durante loading debe ser un no-op.',
    );
  });
}
