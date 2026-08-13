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

/// Tests del boot sync contra la store (FIX: cache Pro mintiendo hasta 7
/// dias cuando el refund/revocacion paso con la app cerrada).
///
/// En cada boot con cache Pro, el [EntitlementNotifier] consulta
/// `PaymentService.isProActiveOnStore()` como fuente de verdad (async, no
/// bloquea el primer frame):
/// - store dice `false` → downgrade a Free + cache/DB limpiados.
/// - store dice `true` → se mantiene Pro y se refresh `validatedAt`.
/// - store no puede determinar (`null`, offline/web) → cache como fallback;
///   si ademas el cache esta stale, cae al legacy `restore()`.
///
/// **Mocks**: `_FakePaymentService` con `isProActiveOnStore` configurable
/// + `_FakeRepo` in-memory. Sin red, sin platform channels.
class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  int storeCheckCalls = 0;
  bool? storeProActive;
  PaymentResult purchaseResult = const PaymentCancelled();
  RestoreResult restoreResult = const RestoreEmpty();
  final _revocations = StreamController<void>.broadcast();

  void seedPurchase(PaymentResult r) => purchaseResult = r;
  void seedRestore(RestoreResult r) => restoreResult = r;

  /// Configura el resultado del store check: `true` activo, `false`
  /// inactivo (refund), `null` = no se puede determinar (offline/web).
  void setStoreProActive(bool? value) => storeProActive = value;

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
  Future<bool?> isProActiveOnStore() async {
    storeCheckCalls++;
    return storeProActive;
  }

  @override
  Stream<PaymentResult> get purchaseStream => const Stream.empty();

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Stream<void> get proRevocationStream => _revocations.stream;
}

/// Fake [EntitlementRepository] in-memory. Cuenta las llamadas para
/// verificar writes/clears del sync.
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

/// Drena las microtasks pendientes (el sync del boot es fire-and-forget).
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
    Entitlement? seedRow,
  }) async {
    SharedPreferences.setMockInitialValues(spInitial);
    prefs = await SharedPreferences.getInstance();
    paymentService = _FakePaymentService();
    repo = _FakeRepo()..seedActive(seedRow);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entitlementRepositoryProvider.overrideWithValue(repo),
        paymentServiceProvider.overrideWithValue(paymentService),
      ],
    );
  }

  tearDown(() => container.dispose());

  Entitlement activeRow(DateTime validated) => Entitlement(
    id: 1,
    source: kSourceLifetimePurchase,
    productId: kProProductId,
    purchasedAt: validated,
    validatedAt: validated,
    expiresAt: null,
    receiptData: null,
    isActive: true,
  );

  Map<String, Object> proCache(DateTime validatedAt) => <String, Object>{
    kIsProKey: true,
    kEntitlementSourceKey: kSourceLifetimePurchase,
    kEntitlementValidatedAtKey: validatedAt.toIso8601String(),
  };

  test(
    'boot cache Pro + store dice INACTIVO (refund con app cerrada) → '
    'downgrade a Free + cache/DB limpiados',
    () async {
      final validated = DateTime.now().toUtc();
      await setupContainer(
        spInitial: proCache(validated),
        seedRow: activeRow(validated),
      );
      // Store: el entitlement ya NO esta activo (refund/revocado).
      paymentService.setStoreProActive(false);

      // Primer frame: Pro desde cache (fast, no bloquea).
      final state = await container.read(entitlementNotifierProvider.future);
      expect(state, isA<EntitlementPro>());

      // Sync fire-and-forget completa → downgrade a Free.
      await _waitForAsync();

      final finalState = container.read(entitlementNotifierProvider).value;
      expect(
        finalState,
        isA<EntitlementFree>(),
        reason: 'Store inactivo en boot debe bajar a Free al instante.',
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
      expect(
        paymentService.restoreCalls,
        0,
        reason: 'Store dio respuesta: el legacy restore no aplica.',
      );
    },
  );

  test(
    'boot cache Pro + store dice ACTIVO → se mantiene Pro + validatedAt '
    'refrescado (cache + repo)',
    () async {
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
      await setupContainer(
        spInitial: proCache(stale),
        seedRow: activeRow(stale),
      );
      paymentService.setStoreProActive(true);

      final state = await container.read(entitlementNotifierProvider.future);
      expect(state, isA<EntitlementPro>());

      await _waitForAsync();

      final finalState = container.read(entitlementNotifierProvider).value;
      expect(
        finalState,
        isA<EntitlementPro>(),
        reason: 'Store activo → el user sigue Pro.',
      );
      expect(container.read(isProProvider), isTrue);
      expect(
        prefs.getString(kEntitlementValidatedAtKey),
        isNotNull,
      );
      final refreshed = DateTime.tryParse(
        prefs.getString(kEntitlementValidatedAtKey)!,
      );
      expect(
        refreshed!.isAfter(stale),
        isTrue,
        reason: 'validatedAt debio refrescarse al momento del sync.',
      );
      expect(
        repo.saveCalls,
        1,
        reason: 'La fila activa de la DB tambien refresca su validatedAt.',
      );
      expect(
        paymentService.restoreCalls,
        0,
        reason: 'Store dio respuesta: el legacy restore no aplica.',
      );
    },
  );

  test(
    'boot cache Pro + store null (offline) + cache FRESH → se mantiene Pro, '
    'sin restore()',
    () async {
      final fresh = DateTime.now().toUtc().subtract(const Duration(days: 1));
      await setupContainer(
        spInitial: proCache(fresh),
        seedRow: activeRow(fresh),
      );
      paymentService.setStoreProActive(null);

      final state = await container.read(entitlementNotifierProvider.future);
      expect(state, isA<EntitlementPro>());

      await _waitForAsync();

      final finalState = container.read(entitlementNotifierProvider).value;
      expect(
        finalState,
        isA<EntitlementPro>(),
        reason: 'Offline: el cache local es el fallback.',
      );
      expect(prefs.getBool(kIsProKey), isTrue);
      expect(
        paymentService.restoreCalls,
        0,
        reason: 'Offline + cache fresh: no hay nada que re-validar.',
      );
      expect(repo.clearCalls, 0);
    },
  );

  test(
    'boot cache Pro + store null (offline) + cache STALE → restore() '
    'fire-and-forget (fallback legacy preservado)',
    () async {
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
      await setupContainer(
        spInitial: proCache(stale),
        seedRow: activeRow(stale),
      );
      paymentService.setStoreProActive(null);
      // Store confirma el entitlement al re-validar (restore active).
      paymentService.seedRestore(
        RestoreActive(
          productId: kProProductId,
          purchasedAt: stale,
          validatedAt: DateTime.now().toUtc(),
        ),
      );

      final state = await container.read(entitlementNotifierProvider.future);
      expect(state, isA<EntitlementPro>());

      await _waitForAsync();

      expect(
        paymentService.restoreCalls,
        greaterThanOrEqualTo(1),
        reason: 'Offline + stale: el legacy restore debe re-validar.',
      );
      final finalState = container.read(entitlementNotifierProvider).value;
      expect(
        finalState,
        isA<EntitlementPro>(),
        reason: 'Restore activo confirma Pro (cache refresh via activate).',
      );
    },
  );

  test(
    'boot cache Pro + store ACTIVO + validatedAt mas nuevo que el sync → '
    'NO se sobrescribe (purchase en vuelo gana)',
    () async {
      // Cache con timestamp "futuro" (mas nuevo que cualquier syncTime).
      final future = DateTime.now().toUtc().add(const Duration(days: 1));
      await setupContainer(
        spInitial: proCache(future),
        seedRow: activeRow(future),
      );
      paymentService.setStoreProActive(true);

      final state = await container.read(entitlementNotifierProvider.future);
      expect(state, isA<EntitlementPro>());

      await _waitForAsync();

      final stored = DateTime.tryParse(
        prefs.getString(kEntitlementValidatedAtKey)!,
      );
      expect(
        stored,
        future,
        reason: 'Un validatedAt mas nuevo que el sync no debe pisarse.',
      );
      expect(
        repo.saveCalls,
        0,
        reason: 'No debe re-escribir la fila con un timestamp viejo.',
      );
      final finalState = container.read(entitlementNotifierProvider).value;
      expect(finalState, isA<EntitlementPro>());
    },
  );
}
