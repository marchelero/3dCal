// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/revenuecat_keys.dart';
import 'payment_service.dart';

/// Implementacion Android de [PaymentService] via RevenueCat (`purchases_flutter`).
///
/// **Por que RevenueCat en vez de `in_app_purchase` directo**:
/// - 50 lineas de codigo vs 300+ de boilerplate nativo (receipt parse,
///   BillingClient + StoreKit wrappers, restore state machine).
/// - Maneja restoration cross-platform gratis hasta $2.5K MRR.
/// - Codigo ya abstraido detras de [PaymentService] — si en el futuro
///   queremos migrar a `in_app_purchase` directo, solo cambia esta clase.
///
/// **Sin iOS impl** (decision del plan: app Android-only). Si en el
/// futuro se agrega iOS, se crea otra impl.
///
/// **Tests**: el SDK no se mockea facil. Los tests de [EntitlementNotifier]
/// usan un mock de [PaymentService] directamente (no de esta clase).
/// Esta clase se testea manualmente con sandbox de Play Store (T21 del
/// plan de monetizacion).
class RevenueCatPaymentService implements PaymentService {
  /// Track de `configure()` calls para enforce idempotencia. El SDK nativo
  /// tiene su propio guard pero el wrapper lo hace explicito para que el
  /// comportamiento sea predecible.
  bool _configured = false;
  bool _available = false;

  @override
  bool get isAvailable => _available;

  /// Stream controller para el [purchaseStream]. En la practica nunca
  /// emite para one-time unlock (no hay renovacion), pero el campo queda
  /// para que el type system no obligue a eliminarlo.
  // ignore: close_sinks
  final StreamController<PaymentResult> _purchaseController =
      StreamController<PaymentResult>.broadcast();

  /// Stream controller del [proRevocationStream]. Se alimenta desde el
  /// customer info update listener registrado en [configure].
  // ignore: close_sinks
  final StreamController<void> _revocationController =
      StreamController<void>.broadcast();

  /// Ultimo estado del entitlement `pro` reportado por RevenueCat. Se usa
  /// para emitir [proRevocationStream] SOLO en la transicion active →
  /// inactive (evita ruido en cada refresh de foreground de un user free).
  bool _proEntitlementActive = false;

  @override
  Stream<void> get proRevocationStream => _revocationController.stream;

  @override
  Future<void> configure() async {
    if (_configured) return;

    final apiKey = kRevenueCatGoogleKey;
    if (apiKey.isEmpty) {
      // Dev mode: no key. No inicializamos el SDK para no spammear
      // errores de "Invalid API key" en consola. El resto de la app
      // sigue funcionando (free tier, mocks, etc).
      debugPrint(
        '[RevenueCat] SDK key vacia — skip configure. '
        'Pasar --dart-define=REVENUECAT_GOOGLE_KEY=goog_XXX para activar.',
      );
      _configured = true;
      _available = false;
      return;
    }

    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey)
          // appUserID: dejar null → RevenueCat genera uno anonimo y lo
          // persiste en SharedPreferences. Para MVP one-time unlock no
          // necesitamos login. Si en el futuro hay account linking, aca
          // se pasa el user id.
          ..diagnosticsEnabled = kDebugMode,
      );
      _configured = true;
      _available = true;

      // Detectar refunds/cancelaciones en tiempo real. purchases_flutter
      // 10.x NO expone un `purchaseStream` estatico; el mecanismo
      // idiomatico para un non-subscription es el customer info update
      // listener: el SDK lo invoca con la ultima customer info al
      // registrarse y en cada cambio (foreground, restore, refund del
      // dashboard de Google Play). El listener vive mientras la app (la
      // instancia del servicio es un singleton provider) — su ciclo de
      // vida es intencionalmente el de la app.
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoChanged);
    } catch (e, st) {
      // No dejamos que un fallo de init rompa el boot. La app arranca
      // como free (gates cerrados, pero funcional). El user vera el
      // paywall con un error si intenta comprar.
      if (kDebugMode) {
        debugPrint('[RevenueCat] configure fallo: $e\n$st');
      } else {
        debugPrint('[RevenueCat] configure fallo: ${e.runtimeType}');
      }
      _configured = true;
    }
  }

  @override
  Future<PaymentResult> purchase({required String productId}) async {
    if (!_configured) {
      return const PaymentError('Payment unavailable');
    }
    if (!_available) {
      return const PaymentError('Payment unavailable');
    }

    try {
      // 1. Lookup del product en el store. Si no existe (item no
      // activado en Play Console, o package name mismatch), retorna
      // lista vacia → error explicito.
      final products = await Purchases.getProducts([
        productId,
      ], productCategory: ProductCategory.nonSubscription);
      if (products.isEmpty) {
        return const PaymentError('Product not found');
      }

      // 2. Compra. Devuelve PurchaseResult con CustomerInfo + StoreTransaction.
      //    Lanza PlatformException si falla.
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );

      // 3. Verificar que el entitlement `pro` quedo activo. Si RevenueCat
      //    reporto success pero el entitlement no esta activo, es un
      //    bug del dashboard o un mismatch de config.
      final customerInfo = result.customerInfo;
      final proEntitlement = customerInfo.entitlements.all['pro'];
      if (proEntitlement == null || !proEntitlement.isActive) {
        return const PaymentError('Entitlement not active after purchase');
      }

      // 4. parsedAt: el originalPurchaseDate del entitlement es ISO 8601
      // string. Fallback a `now()` si el campo esta vacio (no deberia,
      // pero defensivo).
      final purchasedAt =
          DateTime.tryParse(proEntitlement.originalPurchaseDate) ??
          DateTime.now().toUtc();

      return PaymentSuccess(
        productId: proEntitlement.productIdentifier,
        purchasedAt: purchasedAt,
        source: kSourceLifetimePurchase,
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return switch (code) {
        PurchasesErrorCode.purchaseCancelledError => const PaymentCancelled(),
        PurchasesErrorCode.productNotAvailableForPurchaseError =>
          const PaymentError('Product not available'),
        PurchasesErrorCode.networkError => const PaymentError('Network error'),
        PurchasesErrorCode.purchaseNotAllowedError => const PaymentError(
          'Purchase not allowed',
        ),
        PurchasesErrorCode.productAlreadyPurchasedError => const PaymentError(
          'Product already owned (use Restore)',
        ),
        _ => PaymentError('Purchase failed: ${e.message ?? e.code}'),
      };
    } catch (e) {
      return PaymentError('Unexpected error: ${e.runtimeType}');
    }
  }

  @override
  Future<RestoreResult> restore() async {
    if (!_configured) {
      return const RestoreError('Payment unavailable');
    }
    if (!_available) {
      return const RestoreError('Payment unavailable');
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final proEntitlement = customerInfo.entitlements.all['pro'];

      if (proEntitlement == null || !proEntitlement.isActive) {
        return const RestoreEmpty();
      }

      final purchasedAt =
          DateTime.tryParse(proEntitlement.originalPurchaseDate) ??
          DateTime.now().toUtc();
      return RestoreActive(
        productId: proEntitlement.productIdentifier,
        purchasedAt: purchasedAt,
        validatedAt: DateTime.now().toUtc(),
      );
    } on PlatformException catch (e) {
      return RestoreError('Restore failed: ${e.message ?? e.code}');
    } catch (e) {
      return RestoreError('Unexpected error: ${e.runtimeType}');
    }
  }

  /// Callback de `Purchases.addCustomerInfoUpdateListener`.
  ///
  /// Detecta cuando el entitlement `pro` pasa de activo a inactivo
  /// (refund/cancel) y lo propaga por [proRevocationStream] para que el
  /// [EntitlementNotifier] downgradée a Free en tiempo real.
  void _onCustomerInfoChanged(CustomerInfo customerInfo) {
    final isActive = customerInfo.entitlements.all['pro']?.isActive ?? false;
    if (!isActive && _proEntitlementActive) {
      _revocationController.add(null);
    }
    _proEntitlementActive = isActive;
  }

  @override
  Future<String?> getProPriceString() async {
    if (!_configured || !_available) return null;

    try {
      // Precio real del store desde el offering actual de RevenueCat.
      // Preferimos el package `lifetime` del offering (precio configurado
      // en el dashboard); si el offering no esta configurado, fallback al
      // SKU directo con el mismo productId + categoria del purchase path.
      final offerings = await Purchases.getOfferings();
      final lifetime = offerings.current?.lifetime;
      if (lifetime != null) {
        return lifetime.storeProduct.priceString;
      }

      final products = await Purchases.getProducts(
        [kProProductId],
        productCategory: ProductCategory.nonSubscription,
      );
      if (products.isEmpty) return null;
      return products.first.priceString;
    } catch (e) {
      // Offline / SDK no inicializado / producto inexistente → fallback
      // l10n en el paywall (el caller maneja null).
      if (kDebugMode) {
        debugPrint('[RevenueCat] getProPriceString fallo: $e');
      }
      return null;
    }
  }

  @override
  Stream<PaymentResult> get purchaseStream => _purchaseController.stream;
}
