---
prd: docs/prds/2026-07-22_0943-free-pro-monetization.prd.md
status: APPROVED
created: 2026-07-22_1100
---

# Plan: Free/Pro Monetization (tresdcal)

## Overview

Modelo free/pro con **one-time unlock** a **$4.99 USD**. **Android-only**
(Google Play Store). No hay build ni soporte para iOS ni web. Persistencia
local con Drift (`entitlements` table) + cache rapido en `shared_preferences`.
Pagos via `purchases_flutter` (RevenueCat). `PaymentService` interface queda
abstracto por clean code (sin iOS impl).

## Requirements (extraidos del PRD)

- SC1-SC3, SC5-SC10 del PRD (SC4 = iOS diferido, SC11 = web all free en lugar
  de license key)
- Drift schema v4→v5 con tabla `entitlements`
- `isPro` reactivo (Riverpod), fuente: cache SP → DB → revalidate
- Branding (companyName + companyLogo) gate pro, free forzado a "3dCalc"
- CalculatorMode.advanced gate pro, free solo express
- Historial cap 10 en free, ilimitado pro
- CSV export gate pro, PDF siempre disponible
- Dashboard charts gate pro, stats basicas free
- Paywall screen + 4 puntos de entrada
- Restore purchases funcional

## Architecture Changes

- **Nuevo package**: `purchases_flutter: ^8.0.0` (RevenueCat SDK oficial).
  No usamos `in_app_purchase` directo.
- **Nuevo modulo**: `lib/features/entitlement/` con:
  - `data/entitlements_table.dart` (Drift)
  - `data/entitlement_repository.dart`
  - `data/entitlement_cache.dart` (SharedPreferences wrapper)
  - `data/payment_service.dart` (abstraccion de payment; impl Google Play via
    RevenueCat; sin iOS impl)
  - `presentation/paywall_page.dart` + `notifiers/entitlement_notifier.dart`
  - `presentation/widgets/pro_gate.dart` (widget reusable que dispara upsell)
- **Modificacion Drift**: `app_database.dart` schemaVersion 4→5 +
  `m.createTable(entitlements)` + `Entitlements` en `@DriftDatabase(tables:)`
- **Modificacion `core/providers.dart`**: agregar
  `entitlementRepositoryProvider`, `entitlementNotifierProvider`,
  `paymentServiceProvider`, `isProProvider` (derived)
- **Modificacion `core/router/app_router.dart`**: agregar ruta `/paywall` y
  `/restore` (en settings, anidado)
- **Modificacion `core/constants/app_constants.dart`**: agregar keys
  `isPro`, `entitlementSource`, `entitlementValidatedAt` +
  `kFreeHistoryCap = 10`, `kProProductId = 'tresdcal_pro_lifetime'`
- **Modificacion `core/export/pdf_export.dart`**: aceptar `forceBranding`
  flag, default branding "3dCalc" cuando forceBranding=true
- **Modificacion settings page**: companyName + logo UI con gate visual
- **Modificacion calculator_page.dart**: ocultar toggle advanced en free
- **Modificacion calculations_list_page.dart**: cap 10 con upsell en save +
  CSV gate
- **Modificacion home_page.dart / dashboard_page.dart**: branding
  hardcoded "3dCalc" cuando isPro=false; charts gate en dashboard
- **Modificacion Android manifest**: agregar `com.android.vending.BILLING`
  permission (necesario para Google Play Billing v6+)

## Implementation Steps (DAG)

### Phase 0 — Schema + constants (parallel)

```yaml
- id: T1
  title: Add entitlements table + Drift migration v4→v5
  size: M
  depends_on: []
  owner: drift-schema-reviewer + tdd-guide
  verify: |
    - migration en onUpgrade(from<=4) crea tabla
    - build_runner genera app_database.g.dart sin errores
    - flutter analyze pasa
    - test database_repositories_test.dart sigue verde
  files_hint:
    - lib/features/entitlement/data/entitlements_table.dart
    - lib/core/database/app_database.dart
    - lib/core/database/app_database.g.dart (regen)
    - test/unit/database_repositories_test.dart (extension)
- id: T2
  title: Add entitlement cache + constants in app_constants.dart
  size: XS
  depends_on: []
  owner: flutter-reviewer
  verify: |
    - constants `kIsProKey`, `kEntitlementSourceKey`,
      `kEntitlementValidatedAtKey`, `kFreeHistoryCap=10`,
      `kProProductId='tresdcal_pro_lifetime'` existen
    - flutter analyze pasa
  files_hint:
    - lib/core/constants/app_constants.dart
```

### Phase 1 — Domain layer (sequential after T1+T2)

```yaml
- id: T3
  title: Implement EntitlementRepository (Drift read/write)
  size: S
  depends_on: [T1]
  owner: drift-schema-reviewer + tdd-guide
  verify: |
    - unit test inserta Entitlement, lee de vuelta, match
    - unit test elimina y re-inserta (id auto-increment ok)
    - metodos: save(Entitlement), getActive(), clear()
  files_hint:
    - lib/features/entitlement/data/entitlement_repository.dart
    - test/unit/entitlement_repository_test.dart
- id: T4
  title: Implement EntitlementService (Riverpod) + cache SP + isProProvider
  size: M
  depends_on: [T3, T2]
  owner: flutter-reviewer + tdd-guide
  verify: |
    - boot path: lee SP first, fallback a Drift, fallback false
    - isProProvider reactivo (StateNotifier)
    - unit test: SP vacio + DB vacia → isPro=false
    - unit test: SP con isPro=true → isPro=true sin tocar DB
    - unit test: source 'play' | 'appstore' | 'license_key' reconocido
  files_hint:
    - lib/features/entitlement/data/entitlement_cache.dart
    - lib/features/entitlement/presentation/notifiers/entitlement_notifier.dart
    - lib/core/providers.dart (extension: isProProvider, entitlementRepositoryProvider)
    - test/unit/entitlement_service_test.dart
```

### Phase 2 — Payment integration (parallel where possible)

```yaml
- id: T6
  title: Add purchases_flutter to pubspec + PaymentService interface
  size: S
  depends_on: []
  owner: flutter-reviewer + backend-patterns
  verify: |
    - pubspec.yaml incluye purchases_flutter compatible con SDK 3.12
    - flutter pub get sin errores
    - PaymentService interface: `Future<PurchaseResult> purchase()`,
      `Future<RestoreResult> restore()`, `Future<void> configure()`
    - Android impl wraps Purchases.configure + getProducts + purchasePackage
  files_hint:
    - pubspec.yaml
    - lib/features/entitlement/data/payment_service.dart
    - lib/features/entitlement/data/payment_service_revenuecat.dart
- id: T7
  title: Configure RevenueCat dashboard + Android manifest BILLING permission
  size: S
  depends_on: [T6]
  owner: backend-patterns (manual config guidance)
  verify: |
    - AndroidManifest.xml main tiene
      `<uses-permission android:name="com.android.vending.BILLING" />`
    - README o docs/notes tiene instrucciones para:
      1. Crear cuenta RevenueCat
      2. Crear proyecto "tresdcal"
      3. Configurar Google Play service con package `bo.u3dcal.tresdcal`
      4. Obtener public SDK key Android
      5. Crear entitlement "pro" + product "tresdcal_pro_lifetime" non-consumable
    - flutter build apk --debug no falla por manifest
  files_hint:
    - android/app/src/main/AndroidManifest.xml
    - docs/notes/revenuecat-setup.md (nuevo)
- id: T8
  title: Google Play Console: create IAP product tresdcal_pro_lifetime + test account
  size: XS
  depends_on: [T7]
  owner: USER (manual config, NO codigo)
  verify: |
    - Play Console → tresdcal → Monetize → Products → In-app products
      tiene `tresdcal_pro_lifetime` (non-consumable, USD)
    - License testers: agregar email del user para sandbox
    - Internal testing track: agregar email del user
    - User confirma en chat con screenshot/console URL
  files_hint: []
- id: T9
  title: Wire PaymentService → EntitlementService (purchase/restore → persist)
  size: L
  depends_on: [T6, T7]
  owner: flutter-reviewer + tdd-guide
  verify: |
    - integration test con mock PaymentService:
      - purchase() success → EntitlementRepository tiene row + SP cache true
      - purchase() cancel → sin cambios
      - purchase() error → sin cambios + log
      - restore() success → idem purchase
      - restore() empty → clear() llamado + isPro=false
    - al boot, si SP.isPro=true y validatedAt > 7 dias → trigger restore
      async (best-effort, no block UI)
  files_hint:
    - lib/features/entitlement/presentation/notifiers/entitlement_notifier.dart (extension)
    - test/integration/purchase_flow_test.dart
```

### Phase 3 — Paywall + Restore UI (after T9)

```yaml
- id: T10
  title: Build paywall screen + go_router route + l10n strings
  size: M
  depends_on: [T9, T4]
  owner: flutter-reviewer + frontend-patterns
  verify: |
    - ruta `/paywall` existe, navegable
    - screen muestra: precio, lista de features pro, boton "Comprar",
      boton "Restaurar compras", link "Terminos" + "Privacidad"
    - boton "Comprar" disabled mientras loading
    - widget test: tap "Comprar" → invoca PaymentService.purchase
    - widget test: paywall dismiss con back/pop OK
  files_hint:
    - lib/features/entitlement/presentation/paywall_page.dart
    - lib/core/router/app_router.dart (extension)
    - lib/l10n/es_bo.dart (extension: paywallTitle, paywallFeature*, paywallCta, paywallRestore)
    - lib/l10n/en_us.dart (extension)
    - lib/l10n/app_strings.dart (interface)
    - test/widget/paywall_page_test.dart
- id: T11
  title: Add restore purchases button in settings page
  size: S
  depends_on: [T10]
  owner: flutter-reviewer
  verify: |
    - settings page tiene seccion "Cuenta" con tile "Restaurar compras Pro"
    - tap → invoca paymentService.restore() + muestra snackbar resultado
    - widget test del flow
  files_hint:
    - lib/features/settings/presentation/pages/settings_page.dart (extension)
    - test/widget/settings_page_test.dart (extension)
```

### Phase 4 — Feature gates (parallel, all depend on T4)

```yaml
- id: T12
  title: Gate branding (companyName + companyLogo) to Pro in settings
  size: S
  depends_on: [T4]
  owner: flutter-reviewer + frontend-patterns
  verify: |
    - free user: companyName field disabled, valor forzado "3dCalc"
    - free user: logo picker disabled con badge "Pro"
    - pro user: ambos editables
    - widget test: free ve disabled, pro ve enabled
  files_hint:
    - lib/features/settings/presentation/pages/settings_page.dart
    - lib/features/settings/presentation/notifiers/settings_notifier.dart
    - test/widget/settings_page_test.dart
- id: T13
  title: Gate PDF branding — force "3dCalc" footer/header when free
  size: S
  depends_on: [T4, T12]
  owner: flutter-reviewer
  verify: |
    - shareQuotePdf() y buildQuotePdfBytes() aceptan `isPro: bool`
    - isPro=false → companyName=null → PDF usa "3dCalc" hardcoded
    - isPro=true → companyName=user value, logo=user logo
    - widget test genera PDF en ambos casos, verifica texto (snapshot o grep)
  files_hint:
    - lib/core/export/pdf_export.dart
    - lib/features/calculation/presentation/widgets/result_sheet.dart (call site)
    - test/unit/pdf_export_test.dart
- id: T14
  title: Gate CalculatorMode.advanced — hide toggle in free + upsell
  size: S
  depends_on: [T4]
  owner: flutter-reviewer + frontend-patterns
  verify: |
    - free user: solo ve "Express" en _ModeSelector, advanced tap → paywall
    - pro user: ve ambos
    - widget test: free tap en advanced segment → context.push('/paywall')
  files_hint:
    - lib/features/calculation/presentation/pages/calculator_page.dart
    - test/widget/calculator_page_test.dart
- id: T15
  title: Gate history cap (10 free, ilimitado pro) + upsell on save
  size: M
  depends_on: [T4]
  owner: flutter-reviewer + tdd-guide
  verify: |
    - free + countAll >= 10 + try save → error + dialog "Upgrade a Pro"
    - pro: sin cap
    - integration test: inserta 10 calcs + try 11th → exception controlada
  files_hint:
    - lib/features/calculation/data/calculation_repository.dart
    - lib/features/calculation/presentation/pages/calculator_page.dart (save flow)
    - lib/features/calculation/presentation/state/calculator_notifier.dart
    - test/integration/history_cap_test.dart
- id: T16
  title: Gate CSV export — disabled in free with upsell tooltip
  size: S
  depends_on: [T4]
  owner: flutter-reviewer
  verify: |
    - free: IconButton CSV deshabilitado + tooltip "Pro: Exportar CSV"
    - tap disabled → paywall route
    - pro: enabled, exporta OK
    - widget test del estado disabled
  files_hint:
    - lib/features/calculation/presentation/pages/calculations_list_page.dart
    - test/widget/calculations_list_page_test.dart
- id: T17
  title: Gate dashboard charts (pro) — basic stats always, charts in pro only
  size: M
  depends_on: [T4]
  owner: flutter-reviewer
  verify: |
    - free: muestra stats tiles (countAll, countSold, conversion) + totalQuoted/totalSold
    - free: oculta MonthlyTrendChart y ProfitBarChart + TopMaterials
    - pro: muestra todo
    - widget test: free snapshot vs pro snapshot (golden)
  files_hint:
    - lib/features/dashboard/presentation/pages/dashboard_page.dart
    - test/widget/dashboard_page_test.dart
```

### Phase 5 — Tests + compliance (after Phase 3+4)

```yaml
- id: T19
  title: Migration test v4→v5 with existing fixture
  size: S
  depends_on: [T1]
  owner: tdd-guide
  verify: |
    - test crea DB v4 con datos existentes (filamentos, cotizaciones)
    - upgrade v4→v5 aplica migration
    - datos v4 intactos + tabla entitlements existe vacia
  files_hint:
    - test/integration/migration_v4_to_v5_test.dart
- id: T20
  title: Unit + widget tests for entitlement + branding + cap logic
  size: M
  depends_on: [T4, T12, T15]
  owner: tdd-guide
  verify: |
    - todos los tests de T3, T4, T12, T15 verde
    - coverage 80%+ en lib/features/entitlement/
  files_hint:
    - test/unit/entitlement_* (extension)
    - test/widget/settings_page_test.dart (extension)
- id: T21
  title: Integration test full purchase flow (mocked PaymentService)
  size: M
  depends_on: [T9, T10, T11, T14, T15, T16, T17]
  owner: tdd-guide + flutter-reviewer
  verify: |
    - happy path: paywall tap → mock purchase success → todos los gates unlock
    - restore path: tap restore → mock restore success → unlock
    - cancel path: mock cancel → sin cambios
    - error path: mock error → snackbar error + sin cambios
  files_hint:
    - test/integration/full_purchase_flow_test.dart
- id: T22
  title: Store compliance: privacy/terms links, refund docs, HIG check
  size: S
  depends_on: [T10, T11]
  owner: flutter-reviewer (manual guidance)
  verify: |
    - paywall tiene links a Privacy Policy + Terms
    - settings page tiene seccion legal (links)
    - docs/notes/store-compliance.md con checklist:
      - restore button accessible
      - clear pricing display
      - no misleading claims
  files_hint:
    - lib/features/entitlement/presentation/paywall_page.dart (extension)
    - lib/features/settings/presentation/pages/settings_page.dart (extension)
    - docs/notes/store-compliance.md (nuevo)
```

## Critical Path

```
T1 (M) → T3 (S) → T4 (M) → T6 (S) → T9 (L) → T10 (M) → T21 (M)
```

Length: 1L + 3M + 2S ≈ ~5-6 dias de trabajo puro (sin paralelo).

## Parallel Groups

```
Wave 1 (parallel):  T1, T2, T6
Wave 2 (parallel):  T3 (after T1), T7 (after T6)
Wave 3 (parallel):  T4 (after T3), T8 (after T7, manual)
Wave 4 (sequential): T9 (after T7)
Wave 5 (parallel):  T10 (after T4, T9), T12, T13, T14, T15, T16, T17, T19
Wave 6 (parallel):  T11 (after T10), T20
Wave 7 (sequential): T21 (after T9, T10, T11), T22 (after T10, T11)
```

**Max parallelism**: despues de T4+T9 (~3 dias), se disparan 7 gates + 1
restore + 1 test en paralelo. Botleneck real = T9 (IAP integration).

## Total Effort

```
1L + 1M + 11S + 1XS + 8M ≈ 1L + 9M + 11S + 1XS
```

Desglose: 1 large (T9) + 9 medium + 11 small + 1 XS. **Sin XL**.

## Trade-off: payment library

**Recomendacion: `purchases_flutter` (RevenueCat)**.

Argumento (3 lineas):
- `in_app_purchase` oficial = ~300 lineas de boilerplate (receipt parse, Play
  + StoreKit wrappers, restore state machine) vs `purchases_flutter` ~50
  lineas con un SDK que ya maneja eso. Para MVP one-time-unlock, menos codigo
  = menos bugs de billing.
- Free tier $2.5K MRR (mas que suficiente para ticket de $5-15 one-time
  en volumen bajo). Cero vendor lock-in real: si crecen o cambia el pricing,
  migrar a `in_app_purchase` directo es feasible (el modelo `Entitlement` ya
  esta abstraido detras de `PaymentService`).
- Trade-off conocido: dependencia de un vendor cloud (RC) para validar
  receipts. Pero el cache local en Drift + SP hace que la app siga
  funcionando offline post-compra (validacion es best-effort, no bloqueante).

## Top Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | Google Play Console IAP product + test account no seteados | High | High | T8 es USER task, bloq real-device test. Documentar pasos en `docs/notes/revenuecat-setup.md` (T7). Si no completa T8 antes de T21, T21 corre con mock. |
| 2 | Drift migration v4→v5 falla en update con datos existentes | Low | High | T19 (migration test con fixture). Drift's `onUpgrade(from<=4)` tested. Si falla, rollback con version bump + re-fix. |
| 3 | Refactor de `SettingsRepository` (T12) rompe tests existentes | Medium | Medium | T20 (unit tests) cubre. Code review checklist: no cambiar firma de metodos publicos. |
| 4 | SharedPreferences cache stale despues de refund | Medium | Medium | T9: on cold start con cache > 7 dias, trigger restore async. T11: restore manual disponible. Edge: si user pide refund y nunca abre la app, cache queda stale hasta 7 dias. |
| 5 | `purchases_flutter` version incompatible con SDK 3.12 | Low | High | T6 verifica con `flutter pub get` + `flutter analyze`. Si falla, fallback a `in_app_purchase` (cambio de T6+T9, no del resto). |

## Open Questions Residuales (resolubles en implementacion)

- **Q4** Pricing tier amount: confirmado **$4.99 USD one-time** (decision del
  user). Config en Play Console + RevenueCat dashboard. Se crea el IAP product
  con ese precio en T8 (USER task).
- **Q5** Trial period: NO para MVP. Codigo PaymentService acepta `introductory`
  field pero no lo activa.
- **Q6** Catalog limits: confirmado NO gate (PRD A7). T12/T15 no tocan
  filamentos/impresoras.
- **Q7** Brand name free: confirmado "3dCalc" (ya en `Settings.defaults`).
- **Q9** Restore UX: T11 lo pone en settings + T10 en paywall (cumple HIG).
- **Q10** Subscription future: non-consumable IAP permite migrar a
  subscription con cambios minimos (mismo `Entitlement` model + nuevo
  `period` field en tabla). Documentado en `docs/notes/store-compliance.md`.

## Disonancias PRD vs Codigo detectadas

1. **PRD asume StoreKit (iOS) en SC4**. User decidio Google Play only + sin
   iOS en MVP. SC4 se difiere. `PaymentService` interface queda (clean code)
   sin iOS stub.

2. **PRD tabla de gates dice "companyName forzado a 3dCalc en free"** —
   el codigo ya tiene `Settings.defaults.companyName = '3dCalc'` y
   `setCompanyName()` permite cambiarlo. Hay que AGREGAR la validacion
   `if (!isPro)` en el notifier (T12), no en el repository. El default
   ya esta bien.

3. **PRD asume `drift_flutter` y schema v4**. Confirmado en codigo:
   `app_database.dart:40` schemaVersion=4, `drift_flutter` en pubspec.
   Migration v4→v5 path ya esta testeado en code previo (v1→v4 tienen
   migrations testeadas). T1 sigue el mismo patron.

4. **No hay tests de "gate" existentes**. Tests actuales son de logica
   (calculation engine) y widgets atomicos. T20 introduce el primer patron
   de "feature gate test" — puede requerir helper `overrideEntitlement(true)`
    en `setUp` para widget tests. Documentar en `test/widget/helpers/`.

## Naming

- Plan: `docs/plans/2026-07-22_1100-free-pro-monetization.plan.md`
- Report (al cerrar): `docs/reports/2026-07-22_HHMM-free-pro-monetization.report.md`
- Audit (opcional): `docs/audits/2026-07-22_HHMM-free-pro-monetization.audit.md`

## Success Criteria (de este plan)

- [ ] Drift schema v5 con `entitlements` table persiste isPro entre cierres
- [ ] `isProProvider` reactivo <100ms al boot
- [ ] Compra Google Play sandbox desactiva gates en <2s
- [ ] Restore purchases funciona en fresh install
- [ ] Branding "3dCalc" forzado en free (home + PDF)
- [ ] CalculatorMode.advanced oculto en free
- [ ] Historial cap 10 con upsell en save
- [ ] CSV export deshabilitado en free
- [ ] Dashboard charts solo en pro
- [ ] Tests 80%+ coverage en `lib/features/entitlement/`
- [ ] Migration v4→v5 testeada con fixture
- [ ] Compliance docs + privacy/terms links

## Telemetry / Aggregate Metrics

Sin backend, "cuantos pagaron" / "revenue" se obtiene de:

- **RevenueCat dashboard** (web app, free hasta $2.5K MRR): paid users count,
  conversion rate, churn, cohort retention. **Clave**: RevenueCat no es solo
  SDK de pago, es analytics dashboard que ve cada purchase en su cloud.
- **Google Play Console -> Sales reports** (CSV export diario): units sold,
  revenue, refunds, taxes. Oficial de Google.
- **Firebase Analytics** (opcional, +10 LOC): funnel de paywall. Complementa,
  no reemplaza.

Combo MVP: RevenueCat SDK (gate) + RC dashboard + Play Console ($$). Sin
codigo custom. Backend solo si >$2.5K MRR o A/B testing de paywall.
