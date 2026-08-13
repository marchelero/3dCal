// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_cache.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/notifiers/entitlement_notifier.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';

/// Fake [EntitlementRepository] para tests del notifier.
///
/// In-process (no DB), permite controlar el resultado de `getActive` via
/// [seedActive] y observa cuantas veces se invoca cada metodo. Tambien
/// soporta bloquear `getActive` con [blockGetActive] para tests que
/// necesitan inspeccionar el state durante el loading inicial.
class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;
  Completer<Entitlement?>? _getActiveCompleter;
  Object? getActiveError;
  int getActiveCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;
  EntitlementsCompanion? lastSaved;

  /// Setea la fila activa que retornara `getActive`. `null` = sin activa.
  // ignore: use_setters_to_change_properties
  void seedActive(Entitlement? e) {
    _active = e;
  }

  /// Bloquea la proxima llamada a `getActive` hasta que se llame
  /// [unblockGetActive]. Util para tests que quieren inspeccionar el
  /// state durante la fase de loading.
  void blockGetActive() {
    _getActiveCompleter = Completer<Entitlement?>();
  }

  /// Desbloquea la llamada pendiente a `getActive`, retornando la fila
  /// activa actual.
  void unblockGetActive() {
    final completer = _getActiveCompleter;
    if (completer == null || completer.isCompleted) {
      throw StateError('No hay getActive bloqueado.');
    }
    completer.complete(_active);
    _getActiveCompleter = null;
  }

  @override
  Future<Entitlement?> getActive() {
    getActiveCalls++;
    final error = getActiveError;
    if (error != null) return Future<Entitlement?>.error(error);
    final completer = _getActiveCompleter;
    if (completer != null && !completer.isCompleted) {
      return completer.future;
    }
    return Future<Entitlement?>.value(_active);
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
  Stream<Entitlement?> watchActive() {
    return Stream<Entitlement?>.value(_active);
  }
}

/// Fake [PaymentService] in-memory. Minimo — solo lo que
/// [EntitlementNotifier.build] necesita en el path stale.
class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  RestoreResult restoreResult = const RestoreEmpty();
  PaymentResult purchaseResult = const PaymentCancelled();
  String? lastPurchaseProductId;

  // ignore: use_setters_to_change_properties
  void seedRestore(RestoreResult r) => restoreResult = r;
  // ignore: use_setters_to_change_properties
  void seedPurchase(PaymentResult r) => purchaseResult = r;

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
  Stream<PaymentResult> get purchaseStream => const Stream.empty();

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

void main() {
  // ---------- EntitlementCache ----------

  group('EntitlementCache', () {
    late SharedPreferences prefs;
    late EntitlementCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      cache = EntitlementCache(prefs);
    });

    test('cache vacio retorna defaults (isPro=false, source=null, '
        'validatedAt=null)', () {
      expect(cache.isPro, isFalse);
      expect(cache.source, isNull);
      expect(cache.validatedAt, isNull);
    });

    test('setActive persiste los 3 keys en SharedPreferences', () async {
      final ts = DateTime.utc(2026, 7, 22, 10, 30);
      await cache.setActive(source: 'lifetime_purchase', validatedAt: ts);

      expect(prefs.getBool(kIsProKey), isTrue);
      expect(prefs.getString(kEntitlementSourceKey), 'lifetime_purchase');
      expect(prefs.getString(kEntitlementValidatedAtKey), ts.toIso8601String());
    });

    test(
      'setActive con validatedAt=null NO escribe la key de timestamp',
      () async {
        await cache.setActive(source: 'lifetime_purchase');

        expect(prefs.getBool(kIsProKey), isTrue);
        expect(prefs.getString(kEntitlementSourceKey), 'lifetime_purchase');
        expect(prefs.containsKey(kEntitlementValidatedAtKey), isFalse);
      },
    );

    test('clear borra los 3 keys y lectura retorna defaults', () async {
      final ts = DateTime.utc(2026, 7, 22);
      await cache.setActive(source: 'lifetime_purchase', validatedAt: ts);
      expect(prefs.containsKey(kIsProKey), isTrue);

      await cache.clear();

      expect(prefs.containsKey(kIsProKey), isFalse);
      expect(prefs.containsKey(kEntitlementSourceKey), isFalse);
      expect(prefs.containsKey(kEntitlementValidatedAtKey), isFalse);
      expect(cache.isPro, isFalse);
      expect(cache.source, isNull);
      expect(cache.validatedAt, isNull);
    });

    test('round-trip: lectura refleja setActive previo', () async {
      final ts = DateTime.utc(2026, 7, 22, 12, 0);
      await cache.setActive(source: 'lifetime_purchase', validatedAt: ts);

      // Re-instanciar para forzar lectura fresca desde SP.
      final fresh = EntitlementCache(prefs);
      expect(fresh.isPro, isTrue);
      expect(fresh.source, 'lifetime_purchase');
      expect(fresh.validatedAt, ts);
    });
  });

  // ---------- EntitlementNotifier ----------

  group('EntitlementNotifier', () {
    late ProviderContainer container;
    late _FakeEntitlementRepository repo;
    late _FakePaymentService paymentService;
    late SharedPreferences prefs;

    /// Configura un container limpio con SP mock + fake repo + fake
    /// PaymentService.
    ///
    /// [spInitial] permite pre-poblar SharedPreferences con el state
    /// que queremos testear.
    Future<void> setupContainer({
      Map<String, Object> spInitial = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(spInitial);
      prefs = await SharedPreferences.getInstance();
      repo = _FakeEntitlementRepository();
      paymentService = _FakePaymentService();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(paymentService),
        ],
      );
    }

    /// Espera a que cualquier microtask pendiente (incluyendo el refresh
    /// fire-and-forget del boot) se complete. Es deterministico para
    /// 2 hops de microtask encadenados.
    Future<void> waitForAsyncRefresh() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    tearDown(() {
      container.dispose();
    });

    test(
      'boot: cache vacio + repo sin fila activa → EntitlementFree',
      () async {
        await setupContainer();

        final state = await container.read(entitlementNotifierProvider.future);

        expect(state, isA<EntitlementFree>());
        expect(
          repo.getActiveCalls,
          1,
          reason: 'Debio consultar DB una sola vez (no habia cache).',
        );
      },
    );

    test('boot: cache.isPro=true → EntitlementPro sin tocar repo', () async {
      final validated = DateTime.now().toUtc();
      await setupContainer(
        spInitial: <String, Object>{
          kIsProKey: true,
          kEntitlementSourceKey: 'lifetime_purchase',
          kEntitlementValidatedAtKey: validated.toIso8601String(),
        },
      );

      final state = await container.read(entitlementNotifierProvider.future);

      expect(state, isA<EntitlementPro>());
      final pro = state as EntitlementPro;
      expect(pro.source, 'lifetime_purchase');
      expect(pro.validatedAt, validated);
      expect(
        repo.getActiveCalls,
        0,
        reason: 'No debe consultar DB si cache ya dice Pro.',
      );
    });

    test('boot: cache vacio + repo con fila activa → EntitlementPro + '
        'cache SP actualizada', () async {
      await setupContainer();
      final now = DateTime.now().toUtc();
      repo.seedActive(
        Entitlement(
          id: 1,
          source: 'lifetime_purchase',
          productId: kProProductId,
          purchasedAt: now,
          validatedAt: now,
          expiresAt: null,
          receiptData: null,
          isActive: true,
        ),
      );

      final state = await container.read(entitlementNotifierProvider.future);

      expect(state, isA<EntitlementPro>());
      final pro = state as EntitlementPro;
      expect(pro.source, 'lifetime_purchase');
      expect(pro.validatedAt, now);

      // Cache SP debe haberse hidratado desde DB.
      expect(prefs.getBool(kIsProKey), isTrue);
      expect(prefs.getString(kEntitlementSourceKey), 'lifetime_purchase');
      expect(
        prefs.getString(kEntitlementValidatedAtKey),
        now.toIso8601String(),
      );
    });

    test('boot: cache Pro stale (validatedAt > 7 dias) → trigger restore '
        'async que reescribe cache', () async {
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
      await setupContainer(
        spInitial: <String, Object>{
          kIsProKey: true,
          kEntitlementSourceKey: 'lifetime_purchase',
          kEntitlementValidatedAtKey: stale.toIso8601String(),
        },
      );
      // Store confirma el entitlement con timestamp fresco.
      final fresh = DateTime.now().toUtc();
      paymentService.seedRestore(
        RestoreActive(
          productId: kProProductId,
          purchasedAt: stale,
          validatedAt: fresh,
        ),
      );

      final state = await container.read(entitlementNotifierProvider.future);
      expect(
        state,
        isA<EntitlementPro>(),
        reason: 'Primera emit (sync) debe venir del cache: Pro.',
      );

      // Esperar a que el restore fire-and-forget complete.
      await waitForAsyncRefresh();

      expect(
        paymentService.restoreCalls,
        greaterThanOrEqualTo(1),
        reason:
            'El restore async debio consultar el PaymentService '
            'al menos 1 vez.',
      );

      // Cache SP debe haberse actualizado con timestamp fresco.
      final cache = EntitlementCache(prefs);
      expect(cache.validatedAt, isNotNull);
      expect(
        cache.validatedAt!.isAfter(stale),
        isTrue,
        reason: 'validatedAt debio refrescarse via activate().',
      );
    });

    test('boot: cache Pro stale + restore empty → downgrade a Free', () async {
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
      await setupContainer(
        spInitial: <String, Object>{
          kIsProKey: true,
          kEntitlementSourceKey: 'lifetime_purchase',
          kEntitlementValidatedAtKey: stale.toIso8601String(),
        },
      );
      // Store dice "no hay entitlement" (refund, etc).
      paymentService.seedRestore(const RestoreEmpty());

      final state = await container.read(entitlementNotifierProvider.future);
      expect(
        state,
        isA<EntitlementPro>(),
        reason: 'Primera emit (sync) es Pro desde cache.',
      );

      await waitForAsyncRefresh();

      // Tras el restore empty, el state debe haber bajado a Free.
      final finalState = container.read(entitlementNotifierProvider).value;
      expect(
        finalState,
        isA<EntitlementFree>(),
        reason: 'Restore empty + cache stale → downgrade a Free.',
      );

      // Y la cache debe haberse limpiado.
      final cache = EntitlementCache(prefs);
      expect(cache.isPro, isFalse);
    });

    test('activate(source) → Pro + cache actualizada + repo.save llamado '
        'con productId=kProProductId', () async {
      await setupContainer();
      // Esperar a que el boot complete (state = Free).
      await container.read(entitlementNotifierProvider.future);

      await container
          .read(entitlementNotifierProvider.notifier)
          .activate(source: 'lifetime_purchase');

      final state = container.read(entitlementNotifierProvider).value;
      expect(state, isA<EntitlementPro>());
      final pro = state as EntitlementPro;
      expect(pro.source, 'lifetime_purchase');
      expect(pro.validatedAt, isNotNull);

      // Verificar repo.save con los parametros correctos.
      expect(repo.saveCalls, 1);
      expect(repo.lastSaved!.source.value, 'lifetime_purchase');
      expect(repo.lastSaved!.productId.value, kProProductId);
      expect(repo.lastSaved!.purchasedAt.value, pro.validatedAt);

      // Verificar cache SP.
      expect(prefs.getBool(kIsProKey), isTrue);
      expect(prefs.getString(kEntitlementSourceKey), 'lifetime_purchase');
      expect(prefs.getString(kEntitlementValidatedAtKey), isNotNull);
    });

    test('deactivate() → Free + cache cleared + repo.clear llamado', () async {
      await setupContainer();
      // Activar primero.
      await container
          .read(entitlementNotifierProvider.notifier)
          .activate(source: 'lifetime_purchase');
      expect(
        container.read(entitlementNotifierProvider).value,
        isA<EntitlementPro>(),
      );

      // Desactivar.
      await container.read(entitlementNotifierProvider.notifier).deactivate();

      final state = container.read(entitlementNotifierProvider).value;
      expect(state, isA<EntitlementFree>());
      expect(repo.clearCalls, 1);
      expect(prefs.getBool(kIsProKey), isNull);
      expect(prefs.getString(kEntitlementSourceKey), isNull);
      expect(prefs.getString(kEntitlementValidatedAtKey), isNull);
    });

    test('refresh() con DB nueva fila → transiciona Free→Pro y actualiza '
        'cache', () async {
      await setupContainer();
      await container.read(entitlementNotifierProvider.future);
      expect(
        container.read(entitlementNotifierProvider).value,
        isA<EntitlementFree>(),
      );

      // Ahora seed: DB tiene fila activa.
      final now = DateTime.now().toUtc();
      repo.seedActive(
        Entitlement(
          id: 1,
          source: 'lifetime_purchase',
          productId: kProProductId,
          purchasedAt: now,
          validatedAt: now,
          expiresAt: null,
          receiptData: null,
          isActive: true,
        ),
      );
      final callsBefore = repo.getActiveCalls;

      await container.read(entitlementNotifierProvider.notifier).refresh();

      final state = container.read(entitlementNotifierProvider).value;
      expect(state, isA<EntitlementPro>());
      expect(
        repo.getActiveCalls,
        callsBefore + 1,
        reason: 'refresh() debio consultar DB.',
      );
      expect(prefs.getBool(kIsProKey), isTrue);
      expect(prefs.getString(kEntitlementSourceKey), 'lifetime_purchase');
    });

    test(
      'refresh() con DB vacia → transiciona Pro→Free y limpia cache',
      () async {
        final validated = DateTime.now().toUtc();
        await setupContainer(
          spInitial: <String, Object>{
            kIsProKey: true,
            kEntitlementSourceKey: 'lifetime_purchase',
            kEntitlementValidatedAtKey: validated.toIso8601String(),
          },
        );
        await container.read(entitlementNotifierProvider.future);
        expect(
          container.read(entitlementNotifierProvider).value,
          isA<EntitlementPro>(),
        );

        // DB ahora vacia (e.g. restore reporto "no subscription").
        repo.seedActive(null);

        await container.read(entitlementNotifierProvider.notifier).refresh();

        final state = container.read(entitlementNotifierProvider).value;
        expect(state, isA<EntitlementFree>());
        expect(prefs.getBool(kIsProKey), isNull);
      },
    );
  });

  // ---------- isProProvider ----------

  group('isProProvider', () {
    ProviderContainer? container;
    late _FakeEntitlementRepository repo;
    late _FakePaymentService paymentService;
    late SharedPreferences prefs;

    Future<void> setupContainer({
      Map<String, Object> spInitial = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(spInitial);
      prefs = await SharedPreferences.getInstance();
      repo = _FakeEntitlementRepository();
      paymentService = _FakePaymentService();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(paymentService),
        ],
      );
    }

    tearDown(() {
      container?.dispose();
      container = null;
    });

    test('false durante loading (antes que build() complete)', () async {
      // Bloqueamos getActive para mantener al notifier en AsyncValue.loading.
      // Asi, isProProvider lee valueOrNull=null (loading no expone data) y
      // retorna false. Esto evita flicker "Pro" durante el cold start.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p = await SharedPreferences.getInstance();
      final r = _FakeEntitlementRepository()..blockGetActive();
      final ps = _FakePaymentService();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          entitlementRepositoryProvider.overrideWithValue(r),
          paymentServiceProvider.overrideWithValue(ps),
        ],
      );
      try {
        expect(
          c.read(isProProvider),
          isFalse,
          reason: 'Mientras el notifier esta en loading, isPro=false.',
        );
      } finally {
        r.unblockGetActive();
        c.dispose();
      }
    });

    test('false cuando state es EntitlementFree', () async {
      await setupContainer();
      await container!.read(entitlementNotifierProvider.future);
      expect(container!.read(isProProvider), isFalse);
    });

    test('true cuando state es EntitlementPro', () async {
      final validated = DateTime.now().toUtc();
      await setupContainer(
        spInitial: <String, Object>{
          kIsProKey: true,
          kEntitlementSourceKey: 'lifetime_purchase',
          kEntitlementValidatedAtKey: validated.toIso8601String(),
        },
      );
      await container!.read(entitlementNotifierProvider.future);
      expect(container!.read(isProProvider), isTrue);
    });

    test('reactivo: cambia cuando el state transiciona Free→Pro', () async {
      await setupContainer();
      await container!.read(entitlementNotifierProvider.future);
      expect(container!.read(isProProvider), isFalse);

      await container!
          .read(entitlementNotifierProvider.notifier)
          .activate(source: 'lifetime_purchase');

      expect(container!.read(isProProvider), isTrue);
    });
  });

  // ---------- resolveIsPro ----------

  group('resolveIsPro', () {
    test(
      'respeta el override de plataforma aunque el entitlement sea Free',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            entitlementRepositoryProvider.overrideWithValue(
              _FakeEntitlementRepository(),
            ),
            paymentServiceProvider.overrideWithValue(_FakePaymentService()),
            // Simula el override web de main.dart sin depender de kIsWeb.
            isProProvider.overrideWithValue(true),
          ],
        );
        addTearDown(container.dispose);

        final resolvedIsProProvider = FutureProvider<bool>(resolveIsPro);
        expect(await container.read(resolvedIsProProvider.future), isTrue);
        expect(
          container.read(entitlementNotifierProvider).value,
          isA<EntitlementFree>(),
        );
      },
    );

    test('timeout respeta el override efectivo Pro', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeEntitlementRepository()..blockGetActive();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(_FakePaymentService()),
          isProProvider.overrideWithValue(true),
        ],
      );
      addTearDown(() {
        repo.unblockGetActive();
        container.dispose();
      });

      final resolvedIsProProvider = FutureProvider<bool>(resolveIsPro);
      expect(await container.read(resolvedIsProProvider.future), isTrue);
    });

    test('error usa false como fallback efectivo por defecto', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeEntitlementRepository()
        ..getActiveError = StateError('storage unavailable');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(repo),
          paymentServiceProvider.overrideWithValue(_FakePaymentService()),
        ],
      );
      addTearDown(container.dispose);

      final resolvedIsProProvider = FutureProvider<bool>(resolveIsPro);
      expect(await container.read(resolvedIsProProvider.future), isFalse);
    });
  });
}
