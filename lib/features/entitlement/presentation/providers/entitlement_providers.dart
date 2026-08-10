// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/storage/draft_storage_providers.dart';
import '../../data/entitlement_cache.dart';
import '../../data/entitlement_repository.dart';
import '../../data/payment_service.dart';
import '../../data/payment_service_revenuecat.dart';
import '../notifiers/entitlement_notifier.dart';

/// Provider de [EntitlementRepository]. Por default usa la impl Drift
/// contra [appDatabaseProvider]. Overridable en tests con un fake
/// (ver `test/unit/entitlement_service_test.dart`).
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return DriftEntitlementRepository(ref.watch(appDatabaseProvider));
});

/// Provider de [EntitlementCache]. Depende de [sharedPreferencesProvider]
/// (overridden en `main()` con la instancia precargada, y en tests con
/// `SharedPreferences.setMockInitialValues`).
final entitlementCacheProvider = Provider<EntitlementCache>((ref) {
  return EntitlementCache(ref.watch(sharedPreferencesProvider));
});

/// Provider de [PaymentService]. Default: impl real RevenueCat. En
/// tests se override con un fake (ver `test/unit/payment_service_test.dart`
/// y `test/integration/purchase_flow_test.dart`).
///
/// **Nota**: el provider crea la instancia, pero `configure()` NO se
/// llama aca. La init del SDK la dispara `main.dart` despues de
/// `ensureInitialized` (necesita ser async + awaited antes del primer
/// `runApp`).
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return RevenueCatPaymentService();
});

/// Async notifier reactivo con el estado de entitlement.
///
/// **Uso**: la UI lo lee via `ref.watch(entitlementNotifierProvider)`
/// y pattern-matchea sobre el [EntitlementState] sellado. La mayoria
/// de los consumers deberian usar [isProProvider] en su lugar.
final entitlementNotifierProvider =
    AsyncNotifierProvider<EntitlementNotifier, EntitlementState>(
  EntitlementNotifier.new,
);

/// Provider derived: `true` si el user es Pro.
///
/// **Uso**: este es el provider que la mayoria del codigo de gates
/// (T12-T17) debe leer. Se deriva de [entitlementNotifierProvider]
/// chequeando si el state es [EntitlementPro].
///
/// **Durante loading** (antes del primer `build()` complete) retorna
/// `false` — el AsyncValue.loading tiene `valueOrNull=null`, asi que
/// el match contra [EntitlementPro] falla. Esto evita flicker "Pro"
/// durante el cold start.
final isProProvider = Provider<bool>((ref) {
  return ref.watch(entitlementNotifierProvider).value is EntitlementPro;
});
