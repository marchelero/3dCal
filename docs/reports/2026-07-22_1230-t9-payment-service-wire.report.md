# T9: Wire PaymentService → EntitlementNotifier

> Task T9 del plan `2026-07-22_1100-free-pro-monetization`. Status: **DONE**.

## Archivos

**Creados**:
- `lib/core/constants/revenuecat_keys.dart` — SDK key + stale threshold.
- `lib/features/entitlement/data/payment_service.dart` — interface + sealed
  `PaymentResult`/`RestoreResult`.
- `lib/features/entitlement/data/payment_service_revenuecat.dart` — impl
  con `purchases_flutter` 10.4.2.
- `test/unit/payment_service_test.dart` — sealed types + pattern matching
  (8 tests).
- `test/unit/entitlement_notifier_restore_test.dart` — `purchase()`,
  `restore()`, boot stale/fresh (12 tests).
- `test/integration/purchase_flow_test.dart` — full flow con DB in-memory
  real + PaymentService mock (6 tests).

**Modificados**:
- `lib/features/entitlement/presentation/notifiers/entitlement_notifier.dart`
  — agregué `purchase()`, `restore()` publicos + movi la logica de
  revalidate de DB-only a store-driven.
- `lib/features/entitlement/presentation/providers/entitlement_providers.dart`
  — agregué `paymentServiceProvider`.
- `lib/main.dart` — refactor a `ProviderContainer` + `UncontrolledProviderScope`
  para poder hacer `configure()` async pre-`runApp`.
- `test/unit/entitlement_service_test.dart` — agregué `_FakePaymentService`
  + override de `paymentServiceProvider` en setup; actualice 2 tests de
  stale (de "consulta DB" a "consulta PaymentService").

## Tests

| File | Tests | Status |
|------|-------|--------|
| `payment_service_test.dart` | 8 | PASS |
| `entitlement_notifier_restore_test.dart` | 12 | PASS |
| `purchase_flow_test.dart` | 6 | PASS |
| **Total nuevos T9** | **26** | **PASS** |
| Full suite proyecto | 215 / 215 | PASS (sin regresiones) |

## Analyze

```
$ flutter analyze lib/features/entitlement/ lib/main.dart \
    test/unit/payment_service_test.dart \
    test/unit/entitlement_notifier_restore_test.dart \
    test/integration/purchase_flow_test.dart \
    lib/core/constants/revenuecat_keys.dart \
    test/unit/entitlement_service_test.dart
No issues found! (ran in 8.3s)
```

Cero issues nuevos en archivos tocados por T9. Los 608 issues pre-existentes
en el resto del proyecto (public_member_api_docs en `lib/shared/widgets/`,
dead_null_aware en `calculation_repository.dart`, etc) son del baseline y
no fueron tocados.

## `configure()` de RevenueCat

**Donde**: `lib/main.dart`, antes de `runApp`.

**Como**:
```dart
final container = ProviderContainer(overrides: [
  sharedPreferencesProvider.overrideWithValue(prefs),
]);
await container.read(paymentServiceProvider).configure();
runApp(UncontrolledProviderScope(
  container: container,
  child: const TresdcalApp(),
));
```

**Por que este patron**:
- `ProviderScope` no permite `await` antes de construir el widget tree.
  La init del SDK de RevenueCat es async (llama un MethodChannel).
- `ProviderContainer` se crea antes de `runApp`, permite leer providers
  sync y hacer init work.
- `UncontrolledProviderScope` pasa el container ya construido a TresdcalApp
  sin crear uno nuevo (sino perderiamos los overrides).
- En tests se sigue usando `ProviderScope` con overrides — eso esta bien,
  TresdcalApp no acopla al wrapper.

**Failure mode**: `configure()` envuelve el SDK init en try/catch + log.
Si falla (key invalida, network), log warning + `_configured = true` (skip
futuros). La app arranca como free — los gates funcionan, las compras
fallan con `PaymentError('PaymentService no configurado')` cuando el user
intenta pagar.

**Dev mode**: si la key esta vacia (`--dart-define` no se paso), `configure()`
log warning + skip. Asi dev mode corre sin secrets y los tests funcionan sin
necesidad de mockear el SDK.

## API real de `purchases_flutter` 10.4.2

**Diferencia vs spec**: la spec decia `Purchases.purchaseStoreProduct(storeProduct)`
directo, pero ese metodo esta **deprecated** en 10.4.2. El reemplazo es
`Purchases.purchase(PurchaseParams.storeProduct(storeProduct))`.

```dart
// spec (deprecated):
final result = await Purchases.purchaseStoreProduct(products.first);
// actual:
final result = await Purchases.purchase(
  PurchaseParams.storeProduct(products.first),
);
```

`PurchaseParams.storeProduct(...)` es el constructor correcto. Tambien
hay `.package(Package)` y `.subscriptionOption(...)` para otros paths.

**`getProducts` con `productCategory: ProductCategory.nonSubscription`**:
necesario para que el SDK busque INAPPs (no subscriptions). Si se deja
el default (`subscription`), el SDK no encuentra el product lifetime en
Play Console.

**Manejo de errores**: la spec sugeria chequear
`PurchasesErrorCode.purchaseCancelledError` y mapear el resto a error.
La API real lanza `PlatformException` y se usa `PurchasesErrorHelper.getErrorCode`
para extraer el enum. Mapeo implementado:
- `purchaseCancelledError` → `PaymentCancelled`
- `productNotAvailableForPurchaseError` → `PaymentError('Product not available')`
- `networkError` → `PaymentError('Network error')`
- `purchaseNotAllowedError` → `PaymentError('Purchase not allowed')`
- `productAlreadyPurchasedError` → `PaymentError('Product already owned (use Restore)')`
- resto → `PaymentError('Purchase failed: <msg>')`

**`isActive` y `originalPurchaseDate`**: campos accesibles via
`customerInfo.entitlements.all['pro']`. `isActive` es `bool`,
`originalPurchaseDate` es `String` ISO 8601 (parseo defensivo con
`DateTime.tryParse`, fallback a `now()` si falla).

**`restorePurchases()` no requiere `await appUserID`**: el SDK ya
trackea el appUserID internamente (anonimo por default si no se setea
en `PurchasesConfiguration.appUserID`).

## Decisiones de diseno

1. **Reemplace `_revalidateFromDb` con `restore()` en el boot path**.
   T4 implementaba una revalidation contra la DB local al detectar cache
   stale. T9 lo cambio para que vaya contra el store (PaymentService).
   Razon: el store es la fuente de verdad autoritativa. La DB es un
   mirror local. Si el user tiene refund en Play pero la DB todavia
   tiene la fila, validar contra DB diria "Pro" cuando en realidad no
   lo es. Validar contra store lo corrige. El trade-off: +1 round-trip
   de red en cold start stale. Aceptable (best-effort, fire-and-forget).

2. **`restore()` reutiliza `activate()` internamente** en vez de duplicar
   la logica de persistencia. La spec mostraba `_cache.setActive(...)`
   post-`activate()`, pero `activate()` ya lo hace. Use `activate()` y
   dejo que el state manager centralice la escritura a DB + cache.

3. **`ProviderContainer` + `UncontrolledProviderScope` en main.dart**.
   La init de RevenueCat es async (MethodChannel). No se puede hacer en
   `initState` de un widget (race conditions + "LateInitializationError"
   si el primer read del provider llega antes). Patron standard de
   Riverpod para pre-`runApp` setup. El cambio rompe `main.dart` pero
   no rompe tests (siguen usando `ProviderScope` con overrides).

4. **Singleton `RevenueCatPaymentService` via provider**. Crear la
   instancia por llamada seria costoso (init del SDK cada vez). El
   provider es lazy pero cacheado por Riverpod. El `StreamController`
   interno no se cierra (vive la vida del provider, que vive la vida de
   la app). Anotado con `// ignore: close_sinks` para que el linter
   no se queje.

5. **NO genere un evento de `purchases_flutter` `customerInfoUpdateListener`**.
   Para one-time unlock, el entitlement no cambia sin que el user
   compre de nuevo. `purchaseStream` queda en la interface pero
   internamente no emite (controller vacio). Si en el futuro se migra
   a suscripciones, ahi si se conecta al listener nativo.

6. **Tests del `RevenueCatPaymentService` real no se hicieron (TDD
   mockeando SDK)**. El SDK no se mockea facil (MethodChannel + tipos
   `CustomerInfo`/`StoreProduct` pesados). El test del `Notifier` con
   PaymentService mock cubre el wire. La impl real se testea
   manualmente con sandbox de Play Store (T21 del plan).

## Verificacion TDD

- **RED**: tests escritos antes de la impl. Compilaban contra la
  interface nueva pero fallaban al linkear el notifier (sin
  `paymentServiceProvider` ni `restore()`/`purchase()`). Confirmado.
- **GREEN**: impl + wire + init. 26/26 nuevos tests PASS.
- **No regression**: 215/215 total tests PASS.
- **No new analyze issues** en archivos T9.
