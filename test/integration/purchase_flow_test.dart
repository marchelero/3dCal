// ignore_for_file: public_member_api_docs, use_setters_to_change_properties
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/notifiers/entitlement_notifier.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';

/// Integration test del flow completo de pago (T9 del plan de monetizacion).
///
/// **Stack real**: `DriftEntitlementRepository` con DB in-memory
/// (`NativeDatabase.memory()`) + `EntitlementCache` con
/// `SharedPreferences` mock + `PaymentService` fake (sin SDK nativo).
///
/// **Cubre los 5 paths del spec de T9**:
/// - `purchase()` success → DB tiene row + SP cache true + isProProvider=true
/// - `purchase()` cancel → sin cambios
/// - `purchase()` error → sin cambios
/// - `restore()` active → unlock (idempotente con purchase)
/// - `restore()` empty → clear() llamado + isPro=false
///
/// **Diferencia con `entitlement_notifier_restore_test.dart`**: ese
/// usa repos fake (sin DB). Este usa la DB real (in-memory) para
/// verificar que la persistencia efectivamente escribe la fila.

/// Fake [PaymentService] in-memory.
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

Future<void> _waitForAsync() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakePaymentService paymentService;

  Future<ProviderContainer> setupContainer() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    paymentService = _FakePaymentService();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        paymentServiceProvider.overrideWithValue(paymentService),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await db.close();
    });
    return container;
  }

  test(
    'happy path: purchase() success → DB row + SP cache true + isPro=true',
    () async {
      final container = await setupContainer();
      await container.read(entitlementNotifierProvider.future);
      expect(container.read(isProProvider), isFalse);

      paymentService.seedPurchase(
        PaymentSuccess(
          productId: kProProductId,
          purchasedAt: DateTime.utc(2026, 7, 22),
        ),
      );

      await container
          .read(entitlementNotifierProvider.notifier)
          .purchase(productId: kProProductId);

      // isProProvider reactivo.
      expect(container.read(isProProvider), isTrue);

      // DB tiene la fila activa.
      final active = await db.select(db.entitlements).get();
      expect(active, hasLength(1));
      expect(active.first.isActive, isTrue);
      expect(active.first.productId, kProProductId);
      expect(active.first.source, kSourceLifetimePurchase);

      // SP cache dice Pro.
      expect(prefs.getBool(kIsProKey), isTrue);
      expect(prefs.getString(kEntitlementSourceKey), kSourceLifetimePurchase);
      expect(prefs.getString(kEntitlementValidatedAtKey), isNotNull);
    },
  );

  test(
    'cancel path: purchase() cancel → DB vacia + SP sin cache + isPro=false',
    () async {
      final container = await setupContainer();
      await container.read(entitlementNotifierProvider.future);

      paymentService.seedPurchase(const PaymentCancelled());

      await container
          .read(entitlementNotifierProvider.notifier)
          .purchase(productId: kProProductId);

      expect(container.read(isProProvider), isFalse);

      final rows = await db.select(db.entitlements).get();
      expect(rows, isEmpty);
      expect(prefs.getBool(kIsProKey), isNull);
    },
  );

  test(
    'error path: purchase() error → DB vacia + sin cache + isPro=false',
    () async {
      final container = await setupContainer();
      await container.read(entitlementNotifierProvider.future);

      paymentService.seedPurchase(const PaymentError('network'));

      await container
          .read(entitlementNotifierProvider.notifier)
          .purchase(productId: kProProductId);

      expect(container.read(isProProvider), isFalse);

      final rows = await db.select(db.entitlements).get();
      expect(rows, isEmpty);
      expect(prefs.getBool(kIsProKey), isNull);
    },
  );

  test(
    'restore path: restore() active → DB row + SP cache + isPro=true',
    () async {
      final container = await setupContainer();
      await container.read(entitlementNotifierProvider.future);

      paymentService.seedRestore(
        RestoreActive(
          productId: kProProductId,
          purchasedAt: DateTime.utc(2026, 1, 15),
          validatedAt: DateTime.utc(2026, 7, 22),
        ),
      );

      await container.read(entitlementNotifierProvider.notifier).restore();

      expect(container.read(isProProvider), isTrue);

      final active = await db.select(db.entitlements).get();
      expect(active, hasLength(1));
      expect(active.first.isActive, isTrue);
      expect(active.first.source, kSourceLifetimePurchase);

      expect(prefs.getBool(kIsProKey), isTrue);
    },
  );

  test(
    'restore empty path: restore() empty → DB cleared + SP cleared + isPro=false',
    () async {
      final container = await setupContainer();
      await container.read(entitlementNotifierProvider.future);

      // Seed state Pro primero (compra previa).
      paymentService.seedPurchase(
        PaymentSuccess(
          productId: kProProductId,
          purchasedAt: DateTime.utc(2026, 7, 22),
        ),
      );
      await container
          .read(entitlementNotifierProvider.notifier)
          .purchase(productId: kProProductId);
      expect(container.read(isProProvider), isTrue);

      // Ahora: restore dice empty (refund).
      paymentService.seedRestore(const RestoreEmpty());

      await container.read(entitlementNotifierProvider.notifier).restore();

      expect(container.read(isProProvider), isFalse);

      // DB: 0 activas (la fila se desactiva por clear, no se borra).
      final active = await (db.select(
        db.entitlements,
      )..where((e) => e.isActive.equals(true))).get();
      expect(active, isEmpty);

      // Total rows puede ser >= 1 (auditoria), pero ninguna activa.
      final all = await db.select(db.entitlements).get();
      expect(all.every((r) => r.isActive == false), isTrue);

      // SP: keys borradas.
      expect(prefs.getBool(kIsProKey), isNull);
      expect(prefs.getString(kEntitlementSourceKey), isNull);
      expect(prefs.getString(kEntitlementValidatedAtKey), isNull);
    },
  );

  test('boot stale + restore active → state reactivo Pro', () async {
    // Pre-poblar SP con cache Pro stale ANTES de crear el container.
    final stale = DateTime.now().toUtc().subtract(const Duration(days: 10));
    SharedPreferences.setMockInitialValues(<String, Object>{
      kIsProKey: true,
      kEntitlementSourceKey: kSourceLifetimePurchase,
      kEntitlementValidatedAtKey: stale.toIso8601String(),
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    paymentService = _FakePaymentService();

    // Mock: store confirma Pro.
    paymentService.seedRestore(
      RestoreActive(
        productId: kProProductId,
        purchasedAt: stale,
        validatedAt: DateTime.now().toUtc(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        paymentServiceProvider.overrideWithValue(paymentService),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async => db.close());

    final state = await container.read(entitlementNotifierProvider.future);
    expect(
      state,
      isA<EntitlementPro>(),
      reason: 'Cache Pro stale debe dar primera emit = Pro.',
    );

    await _waitForAsync();

    // Tras el restore fire-and-forget, el state sigue Pro.
    final finalState = container.read(entitlementNotifierProvider).value;
    expect(finalState, isA<EntitlementPro>());

    // Restore fue llamado al menos una vez.
    expect(paymentService.restoreCalls, greaterThanOrEqualTo(1));

    // DB tiene la fila activa.
    final active = await (db.select(
      db.entitlements,
    )..where((e) => e.isActive.equals(true))).get();
    expect(active, isNotEmpty);
  });
}
