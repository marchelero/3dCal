// ignore_for_file: public_member_api_docs
import 'dart:async';

/// Abstraccion sobre el sistema de pagos.
///
/// Define el contrato entre el codigo de la app y un provider de pagos
/// (hoy: RevenueCat para Google Play, sin iOS). El [EntitlementNotifier]
/// depende solo de este contrato, no del SDK de RevenueCat, lo que permite:
///
/// - **Tests** sin SDK nativo: mockear [PaymentService] y verificar la
///   logica del notifier sin levantar la plataforma de pago.
/// - **Multi-store ready**: si en el futuro se agrega iOS o web, se
///   implementa otra clase que cumpla este contrato. El notifier no se
///   toca.
///
/// **No hay iOS impl** (decision de T0 del plan de monetizacion: app
/// Android-only).

// ============================================================================
// Sealed results
// ============================================================================

/// Resultado de un intento de compra. Sealed para que el caller haga
/// pattern matching exhaustivo sobre success / cancel / error.
sealed class PaymentResult {
  const PaymentResult();
}

/// Compra exitosa. [productId] es el SKU que se compro (e.g.
/// `'tresdcal_pro_lifetime'`). [purchasedAt] es UTC. [source] identifica
/// el origen del entitlement (hoy siempre `'lifetime_purchase'`, pero el
/// campo queda por si en el futuro hay multiples paths de activacion).
class PaymentSuccess extends PaymentResult {
  const PaymentSuccess({
    required this.productId,
    required this.purchasedAt,
    this.source = 'lifetime_purchase',
  });

  final String productId;
  final DateTime purchasedAt;
  final String source;
}

/// User cancelo el flow de Play Store (tap "Atras" en el sheet).
/// El state NO debe cambiar.
class PaymentCancelled extends PaymentResult {
  const PaymentCancelled();
}

/// Error de Play Store o del SDK (red, item no disponible, billing
/// deshabilitado, etc). [message] es user-friendly.
class PaymentError extends PaymentResult {
  const PaymentError(this.message);

  final String message;
}

/// Resultado de un intento de restore. Sealed para pattern matching.
sealed class RestoreResult {
  const RestoreResult();
}

/// Hay un entitlement Pro activo. Se activa localmente con
/// [EntitlementNotifier.activate].
class RestoreActive extends RestoreResult {
  const RestoreActive({
    required this.productId,
    required this.purchasedAt,
    required this.validatedAt,
  });

  final String productId;

  /// Fecha de la compra original (UTC, del receipt).
  final DateTime purchasedAt;

  /// Momento en que RevenueCat valido este entitlement (UTC).
  /// Basicamente `now()` en el momento del restore.
  final DateTime validatedAt;
}

/// No hay entitlement Pro para esta cuenta de Play Store. El user nunca
/// compro, o su compra expiro/refunde. Se debe desactivar el Pro local.
class RestoreEmpty extends RestoreResult {
  const RestoreEmpty();
}

/// Error al hablar con Play Store / RevenueCat. No se cambia el state
/// (asumimos cache local es valido hasta evidencia en contrario).
class RestoreError extends RestoreResult {
  const RestoreError(this.message);

  final String message;
}

// ============================================================================
// PaymentService interface
// ============================================================================

/// Contrato del servicio de pagos.
///
/// **Lifecycle**: una sola instancia por app (provider en
/// `entitlement_providers.dart`). `configure()` se llama una vez en
/// `main.dart` despues de `ensureInitialized`. `purchase()` y `restore()`
/// se llaman bajo demanda (paywall, settings restore button, boot stale).
abstract class PaymentService {
  /// Inicializa el SDK. Llamar una vez en `main.dart` despues de
  /// `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// Lee el SDK key de `--dart-define=REVENUECAT_GOOGLE_KEY`. Si la key
  /// esta vacia (dev mode sin secret), log warning y no-op (asi el dev
  /// puede correr la app sin configurar RevenueCat, y los mocks siguen
  /// funcionando).
  ///
  /// **Idempotente**: llamadas multiples no rompen (el SDK nativo
  /// internamente hace guard, pero por las dudas el wrapper lo enforce).
  Future<void> configure();

  /// Compra el [productId] (e.g. `'tresdcal_pro_lifetime'`).
  ///
  /// Muestra la UI nativa de Play Store. El flow es:
  /// 1. Lookup del product en el store.
  /// 2. Sheet de pago.
  /// 3. Compra o cancel.
  ///
  /// Retorna [PaymentSuccess] / [PaymentCancelled] / [PaymentError].
  /// El caller (paywall) hace pattern matching.
  Future<PaymentResult> purchase({required String productId});

  /// Restaura purchases del user actual.
  ///
  /// Usado en:
  /// - **Cold start** si el cache local dice Pro pero esta stale
  ///   (> [kEntitlementStaleThreshold] desde el ultimo validate).
  /// - **Boton "Restaurar"** en settings o paywall (cumple HIG de
  ///   Apple, aunque la app es Android-only).
  ///
  /// Retorna [RestoreActive] / [RestoreEmpty] / [RestoreError].
  Future<RestoreResult> restore();

  /// Stream reactivo de purchases que llegan fuera de banda (e.g.
  /// subscription renewal via Play Store mientras la app esta en
  /// background). Para one-time unlock (caso de tresdcal) normalmente
  /// no emite, pero el campo queda para futuro (suscripciones).
  Stream<PaymentResult> get purchaseStream;
}
