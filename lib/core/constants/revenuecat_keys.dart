// ignore_for_file: dangling_library_doc_comments
/// Constantes de RevenueCat (SDK key + thresholds relacionados).
///
/// Single source of truth para el SDK key de Google Play. Se lee en
/// build time via `--dart-define=REVENUECAT_GOOGLE_KEY=goog_XXX` y se
/// guarda en una constante para que el codigo de pago no haga
/// `String.fromEnvironment` directamente (mas facil de mockear/testear).

/// Public SDK key de Google Play RevenueCat.
///
/// Setear en build time:
/// ```
/// flutter build apk --release \
///   --dart-define=REVENUECAT_GOOGLE_KEY=goog_XXXXX
/// ```
///
/// **Sin valor en dev = no se inicializa RevenueCat**. El [PaymentService]
/// detecta el string vacio y log warning + no-op (asi dev mode corre sin
/// key, sin crashear el SDK).
///
/// **Nunca commitear un valor real** aca. El valor vive en
/// `~/tresdcal-secrets/revenuecat.txt` (ver `docs/notes/revenuecat-setup.md`)
/// y se pasa como `--dart-define` en CI/local builds.
const String kRevenueCatGoogleKey = String.fromEnvironment(
  'REVENUECAT_GOOGLE_KEY',
);

/// Threshold para trigger de `restore()` async en cold start.
///
/// Si el `validatedAt` del cache tiene mas de este tiempo, el boot dispara
/// un `restore()` fire-and-forget contra el store (best-effort, no bloquea
/// el primer frame). El notifier mantiene el state Pro mientras corre.
///
/// **Por que 7 dias**: es el mismo valor que RevenueCat usa para
/// `cachedCustomerInfoTTL` por default. Si el cache local dice Pro pero
/// la store no lo valida en 7 dias, asumimos que el cache puede estar
/// stale (refund, cancelacion, etc).
const Duration kEntitlementStaleThreshold = Duration(days: 7);
