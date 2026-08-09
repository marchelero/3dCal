---
prd: docs/prds/2026-07-22_0943-free-pro-monetization.prd.md
status: APPROVED
created: 2026-08-08_2354
---

# Plan: Free/Pro Play Store Prep (tresdcal)

## Overview

Cierre del feature free/pro para **publicacion en Google Play Store**.
La feature esta casi completa y testeada (271/271 tests PASS), pero quedan
**2 bloqueantes criticos** (build Android roto + 3 wiring perdidos en el
commit `cfd9853`) y un set de tareas de Play Store hardening. Este plan NO
implementa ads ni consumibles: una sola app con unlock in-app (scope ya
decidido, ver "Fuera de Alcance").

## Contexto (gap analysis)

Estado verificado a `2026-08-08`:

- **App**: Flutter 3.44 / Dart 3.12, `tresdcal` (applicationId
  `bo.u3dcal.tresdcal`, minSdk 24, targetSdk 36, versionName 0.1.0+1).
  Android-only para monetizacion. Drift v5, Riverpod + go_router,
  `purchases_flutter 10.4.2`. Suite completa: 271/271 PASS.

- **BLOQUEANTE A — Build Android roto**: `flutter build apk` (debug y
  release) falla con `Gradle task assembleDebug failed`. Causa:
  `image_gallery_saver 2.0.3` (`pubspec.yaml:26`, usado en
  `lib/core/share/quote_share.dart:95`) no declara `namespace` → AGP 8.9+ /
  Gradle 9.1 lo rechaza. Fix: migrar a `gal` en `quote_share.dart` + pubspec,
  actualizar tests que tocan share/guardado, VERIFICAR con
  `flutter build apk --debug` verde. Post-fix: verificar en el merged
  manifest que `INTERNET` y `com.android.vending.BILLING` queden declarados
  (hoy `INTERNET` solo esta en debug/profile manifests
  `android/app/src/{debug,profile}/AndroidManifest.xml`; `BILLING` depende
  del merge de `purchases-android`; el manifest main no declara ninguno).

- **BLOQUEANTE B — 3 wiring perdidos antes del commit `cfd9853`**:
  1. `lib/main.dart` (30 lineas, version pre-T9) NO llama
     `PaymentService.configure()` → RevenueCat nunca se inicializa en
     runtime → `purchase()`/`restore()` devuelven
     `PaymentError('PaymentService no configurado')`. Fix: restaurar el
     refactor de `docs/reports/2026-07-22_1230-t9-payment-service-wire.report.md`
     (`ProviderContainer` + `UncontrolledProviderScope` + `await configure()`
     antes de `runApp`).
  2. La ruta `/paywall` NO existe en `lib/core/router/app_router.dart`; 5
     call sites navegan a `_RouterErrorPage`: `calculator_page.dart:359`,
     `calculations_list_page.dart:195`, `dashboard_page.dart:263`,
     `settings_page.dart:744,845`. Fix: registrar `/paywall` →
     `PaywallPage` (existe en
     `lib/features/entitlement/presentation/pages/paywall_page.dart`).
  3. `dashboard_entitlement_provider.dart:19` default `false` y nadie lo
     overridea → charts ocultos hasta para Pro. Fix:
     `dashboardIsProProvider.overrideWithValue(ref.watch(isProProvider))`
     en el ProviderScope root.

- **T8 (user tasks, NO codigo)**: IAP `tresdcal_pro_lifetime`
  (non-consumable $4.99) en Play Console; proyecto RevenueCat `tresdcal`
  (entitlement `pro`, offering default + package lifetime, service account
  JSON, SDK key `goog_...`); license testers + internal testing track.

- **Play Store (medio/bajo)**: release signing con debug keystore
  (`android/app/build.gradle.kts:32`); privacy/terms placeholder
  (`app_constants.dart:133,137` → `https://u3dcal.bo/privacy` y `/terms`,
  sin DNS); Data Safety form (declarar READ/WRITE_EXTERNAL_STORAGE,
  `AndroidManifest.xml:4-7`); listing assets (screenshots, feature graphic,
  descripcion, categoria, icono default `@mipmap/ic_launcher`); versionName
  a fijar semver; R8/minifyEnabled recomendable; 3 nombres distintos de SDK
  key segun docs (`REVENUECAT_ANDROID_SDK_KEY` en `revenuecat-setup.md:134`,
  `REVENUECAT_API_KEY` en `store-compliance.md:50`, `REVENUECAT_GOOGLE_KEY`
  en `revenuecat_keys.dart:24`) → unificar; constante muerta
  `kPackageName='bo.3dcal.tresdcal'` ≠ applicationId
  (`app_constants.dart:7`, sin usos en `lib/`).

## Objetivos

- Desbloquear el build Android (debug + release) verde.
- Restaurar los 3 wiring para que RevenueCat funcione en runtime.
- Completar los gates de verificacion manual (RevenueCat + Play Console).
- Hardening de Play Store (signing, legal, data safety, listing, R8).
- Verificacion final pre-subida con checklist de compliance.

## Architecture Changes

- **`pubspec.yaml`**: quitar `image_gallery_saver: ^2.0.3`, agregar
  `gal: ^2.3.3`.
- **`lib/core/share/quote_share.dart`**: reemplazar `ImageGallerySaver`
  por `Gal.putImageBytes` (try/catch `PlatformException` → mapear a
  `ShareQuoteException`). Mantener intacta la branch `kIsWeb` (conditional
  import `save_platform_web.dart`). Opcional: wrapper chico `GallerySaver`
  como seam testeable.
- **`lib/main.dart`**: refactor a `ProviderContainer` + overrides
  (`sharedPreferencesProvider` + `dashboardIsProProvider`) +
  `UncontrolledProviderScope` + `await container.read(paymentServiceProvider).configure()`
  antes de `runApp` (patron del report T9).
- **`lib/core/router/app_router.dart`**: nueva ruta top-level `/paywall` en
  la seccion full-screen (push, sin shell) con `_slideRight` → `PaywallPage`.
- **`android/app/src/main/AndroidManifest.xml`**: verificar (y declarar si
  faltan tras el merge) `INTERNET` + `com.android.vending.BILLING`.
- **Play Store (no codigo)**: signing config, URLs legales, Data Safety,
  listing, semver, R8, docs de unificacion de SDK key.

## Implementation Steps (DAG)

### Phase 1 — Fix build Android (critica)

```yaml
- id: T1
  title: Migrar image_gallery_saver → gal en pubspec + quote_share.dart
  size: M
  depends_on: []
  owner: flutter-reviewer
  verify: |
    - pubspec.yaml: quitar `image_gallery_saver: ^2.0.3`, agregar `gal: ^2.3.3`
    - flutter pub get sin errores
    - quote_share.dart: `Gal.putImageBytes(imageBytes, name: 'cotizacion_3dcalc_$timestamp')`
      dentro de try/catch PlatformException → ShareQuoteException (mensaje
      con errorMessage). NOTA: `putImageBytes` en gal 2.3.x no devuelve
      Map isSuccess; el fallo se propaga como PlatformException
    - branch kIsWeb intacta (guard antes de tocar Gal) — gal no tiene impl
      web pero compila; el guard evita MissingPluginException en runtime
    - doc comment de saveQuoteImage actualizado (sin referencias a
      image_gallery_saver; permisos: API <= 29 WRITE_EXTERNAL_STORAGE,
      requestLegacyExternalStorage ya presente en manifest main:12)
    - flutter analyze sin issues nuevos en archivos tocados
  files_hint:
    - pubspec.yaml
    - lib/core/share/quote_share.dart
- id: T2
  title: Actualizar/crear tests del save flow (gal)
  size: S
  depends_on: [T1]
  owner: tdd-guide
  verify: |
    - grep `test/` por saveQuoteImage|ImageGallerySaver: hoy NO hay tests que
      toquen el save flow (gap: el save de galeria no esta cubierto)
    - si se introdujo wrapper `GallerySaver` en T1: unit test del mapeo
      PlatformException → ShareQuoteException + happy path
    - widget test: save button en result_sheet.dart:325 y
      calculation_detail_page.dart:122 dispara captura + save y surfcea
      AppSnackBar en error
    - suite completa sigue verde (271+ tests)
  files_hint:
    - lib/core/share/quote_share.dart (extension: wrapper)
    - lib/features/calculation/presentation/widgets/result_sheet.dart
    - lib/features/calculation/presentation/pages/calculation_detail_page.dart
    - test/widget/quote_save_flow_test.dart (nuevo)
    - test/unit/gallery_saver_test.dart (nuevo, si hay wrapper)
- id: T3
  title: Verificar build apk --debug verde + merged manifest (INTERNET, BILLING)
  size: S
  depends_on: [T1]
  owner: flutter-reviewer
  verify: |
    - `flutter build apk --debug` termina OK (ya NO falla por namespace)
    - merged manifest del debug build contiene
      `android.permission.INTERNET` y `com.android.vending.BILLING`:
      buscar en `build/app/intermediates/merged_manifests/**/AndroidManifest.xml`
      (path varia por version de AGP; usar grep -m)
    - si INTERNET no aparece (release: hoy solo existe en debug/profile
      manifests) → declarar `<uses-permission android:name="android.permission.INTERNET"/>`
      en android/app/src/main/AndroidManifest.xml y re-build
    - si BILLING no aparece → verificar merge de purchases-android
      (purchases_flutter 10.4.2); si falta, declarar explicitamente en main
  files_hint:
    - android/app/src/main/AndroidManifest.xml (fix si aplica)
    - build/app/intermediates/merged_manifests/**/AndroidManifest.xml (verificacion)
```

### Phase 2 — Restaurar 3 wiring (critica)

```yaml
- id: T4
  title: main.dart — ProviderContainer + configure() + override dashboard
  size: M
  depends_on: []
  owner: flutter-reviewer + backend-patterns
  verify: |
    - patron del report docs/reports/2026-07-22_1230-t9-payment-service-wire.report.md:
      ```
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        dashboardIsProProvider.overrideWithValue(ref.watch(isProProvider)),  // ver nota
      ]);
      await container.read(paymentServiceProvider).configure();
      runApp(UncontrolledProviderScope(container: container, child: const TresdcalApp()));
      ```
    - NOTA wiring: `dashboardIsProProvider.overrideWithValue` necesita un ref
      de container; usar `overrideWith((ref) => ref.watch(isProProvider))` en
      los overrides del container (correcto en ProviderContainer)
    - app arranca sin crash; log de configure() OK (o warning dev-mode sin key)
    - flutter analyze sin issues nuevos
    - suite completa verde (271+ tests, sin regresiones)
  files_hint:
    - lib/main.dart
    - lib/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart
    - lib/features/entitlement/presentation/providers/entitlement_providers.dart
    - docs/reports/2026-07-22_1230-t9-payment-service-wire.report.md (referencia)
- id: T5
  title: Registrar ruta /paywall → PaywallPage en app_router.dart
  size: S
  depends_on: []
  owner: flutter-reviewer
  verify: |
    - import de paywall_page.dart agregado
    - GoRoute `path: '/paywall'` con `pageBuilder: _slideRight(const PaywallPage())`
      en la seccion full-screen (push, sin shell) — junto a /calculator,
      NO dentro de las branches del StatefulShellRoute
    - los 5 call sites navegan a PaywallPage: calculator_page.dart:359,
      calculations_list_page.dart:195, dashboard_page.dart:263,
      settings_page.dart:744,845 (ya no _RouterErrorPage)
    - flutter analyze sin issues
  files_hint:
    - lib/core/router/app_router.dart
    - lib/features/entitlement/presentation/pages/paywall_page.dart
- id: T6
  title: Tests Fase 2 — navegacion a /paywall desde cada gate + E2E paywall→unlock
  size: M
  depends_on: [T4, T5]
  owner: tdd-guide + flutter-reviewer
  verify: |
    - widget test parametrizado: desde cada uno de los 5 call sites, el tap
      en el gate navega a PaywallPage (pump router real, assert PaywallPage
      montada; NO _RouterErrorPage)
    - E2E widget/integration test (mock PaymentService via paymentServiceProvider):
      - tap paywall → mock purchase success → gates unlock (dashboard charts
        visibles via dashboardIsProProvider override + isProProvider, CSV
        habilitado, advanced mode visible)
      - restore success path idem
      - cancel/error path → snackbar + sin cambios (sin unlock)
    - suite completa verde (271+ tests + nuevos)
  files_hint:
    - test/widget/paywall_navigation_test.dart (nuevo)
    - test/integration/full_purchase_flow_test.dart (nuevo o extension de
      test/integration/purchase_flow_test.dart existente)
    - test/widget/dashboard_page_test.dart (extension: charts visibles con isPro)
```

### Phase 3 — T8 gates (user tasks, NO codigo)

```yaml
- id: T7
  title: RevenueCat dashboard — proyecto tresdcal configurado
  size: S
  depends_on: []
  owner: USER (manual) + backend-patterns (guia)
  verify: |
    - proyecto RevenueCat "tresdcal" existe
    - Google Play service vinculado con package `bo.u3dcal.tresdcal`
    - entitlement `pro` creado
    - offering default con package lifetime (product `tresdcal_pro_lifetime`)
    - service account JSON generado (para API/webhooks)
    - public SDK key Android obtenida (`goog_...`) — guardada en
      ~/tresdcal-secrets/ (nunca en el repo)
    - actualizar docs/notes/revenuecat-setup.md si los pasos cambiaron
  files_hint:
    - docs/notes/revenuecat-setup.md (actualizar si aplica)
- id: T8
  title: Google Play Console — IAP product + license testers + internal track
  size: XS
  depends_on: [T7]
  owner: USER (manual config, NO codigo)
  verify: |
    - Play Console → tresdcal → Monetize → Products → In-app products:
      `tresdcal_pro_lifetime` (non-consumable, USD $4.99) activo
    - License testers: email del user agregado (sandbox)
    - Internal testing track: build subido + email del user agregado
    - User confirma en chat con screenshot/console URL
  files_hint: []
```

### Phase 4 — Play Store hardening

```yaml
- id: T9
  title: Release signing — upload key o Play App Signing (nunca debug keystore)
  size: S
  depends_on: []
  owner: USER + security-reviewer (secrets)
  verify: |
    - decision: generar upload keystore propio O activar Play App Signing
    - si keystore propio: android/key.properties creado y referenciado en
      build.gradle.kts:32 (release signingConfig) — key.properties + keystore
      NUNCA commiteados (verificar .gitignore)
    - doc docs/notes/playstore-signing.md con backup del keystore + passwords
      (perder el keystore = no poder publicar updates)
    - `flutter build apk --release` firma con la upload key (verificar
      `apksigner verify` o subir a internal track como smoke)
  files_hint:
    - android/app/build.gradle.kts
    - android/key.properties (nuevo, gitignored)
    - docs/notes/playstore-signing.md (nuevo)
- id: T10
  title: Privacy/terms URLs reales (placeholder → publicadas)
  size: XS
  depends_on: []
  owner: USER + flutter-reviewer
  verify: |
    - paginas https://u3dcal.bo/privacy y https://u3dcal.bo/terms publicadas
      (DNS + contenido legal real: no usa datos personales, payments via
      Google Play, politicas de reembolso)
    - app_constants.dart:133 y :137 apuntan a las URLs finales (sin cambio
      de constantes si las URLs no cambian; cambiar valores si DNS difiere)
    - smoke: url_launcher abre ambas URLs en el paywall (settings legal links)
  files_hint:
    - lib/core/constants/app_constants.dart
    - lib/features/entitlement/presentation/pages/paywall_page.dart
- id: T11
  title: Data Safety form + revision de permisos post-gal
  size: S
  depends_on: [T1]
  owner: USER + flutter-reviewer
  verify: |
    - revisar manifest main:4-7 tras migracion a gal: WRITE_EXTERNAL_STORAGE
      (maxSdk 28) y READ_EXTERNAL_STORAGE (maxSdk 32) — gal solo necesita
      WRITE en API <= 29; requestLegacyExternalStorage:12 ya esta
    - decidir: mantener permisos (compat API 24-28) o remover los innecesarios;
      si se remueven, actualizar manifest + tests afectados
    - Play Console → App content → Data safety: declarar exactamente los
      permisos del merged manifest (consistencia form vs APK)
    - registrar decisiones en docs/notes/store-compliance.md
  files_hint:
    - android/app/src/main/AndroidManifest.xml
    - docs/notes/store-compliance.md (extension)
- id: T12
  title: Listing assets — screenshots, feature graphic, descripcion, icono
  size: S
  depends_on: []
  owner: USER
  verify: |
    - screenshots (2+ por orientacion, formato Play: 1080x1920/1920x1080 PNG)
      del flujo real: calculator, resultado, dashboard, paywall
    - feature graphic 1024x500 PNG
    - descripcion corta (80 chars) + completa (4000 chars) en es_ES (y en_US)
    - categoria + contenido (madurez) definidos
    - icono: revisar @mipmap/ic_launcher (mipmap por densidad: mdpi..xxxhdpi);
      generar icono final si el default no es aceptable
  files_hint:
    - android/app/src/main/res/mipmap-*/ (iconos)
    - docs/notes/listing-assets.md (nuevo, checklist + assets)
- id: T13
  title: Semver versionName + versionCode definidos
  size: XS
  depends_on: []
  owner: USER (decision) + flutter-reviewer
  verify: |
    - version en pubspec.yaml:4 definida (recomendado: mantener 0.1.0+1 para
      el primer release interno, o 1.0.0+1 si se sube publico)
    - versionCode y versionName derivan de flutter.versionCode/versionName
      (build.gradle.kts:24-25) — verificar que la sintaxis semver es valida
      para Play (X.Y.Z, sin prefijo "v")
  files_hint:
    - pubspec.yaml
    - android/app/build.gradle.kts
- id: T14
  title: R8/minifyEnabled en release + keep rules de plugins
  size: M
  depends_on: [T1]
  owner: flutter-reviewer + security-reviewer
  verify: |
    - build.gradle.kts release: `isMinifyEnabled = true` +
      `isShrinkResources = true`
    - proguard-rules.pro (nuevo): keep de RevenueCat SDK (purchases-android)
      y de gal si hacen falta (testear con release build; la mayoria del
      codigo Dart no se ofusca, pero el codigo nativo Java/Kotlin si)
    - `flutter build apk --release` verde + smoke test en device:
      calculator, save a galeria (gal), paywall (RevenueCat init sin crash
      por R8)
    - si R8 rompe algo: ajustar keep rules, NO desactivar minify
  files_hint:
    - android/app/build.gradle.kts
    - android/app/proguard-rules.pro (nuevo)
- id: T15
  title: Unificar nombre del SDK key → REVENUECAT_GOOGLE_KEY en docs y builds
  size: XS
  depends_on: []
  owner: flutter-reviewer
  verify: |
    - hoy hay 3 nombres: REVENUECAT_ANDROID_SDK_KEY
      (docs/notes/revenuecat-setup.md:134), REVENUECAT_API_KEY
      (docs/notes/store-compliance.md:50) y REVENUECAT_GOOGLE_KEY
      (lib/core/constants/revenuecat_keys.dart:24, el unico que lee el codigo)
    - unificar docs y comandos de build al nombre que lee el codigo:
      REVENUECAT_GOOGLE_KEY
    - grep final en docs/ + lib/ + scripts: un solo nombre referenciado
    - flutter build apk --release --dart-define=REVENUECAT_GOOGLE_KEY=goog_XXX
      compila (sin el define, dev mode sigue funcionando sin key)
  files_hint:
    - docs/notes/revenuecat-setup.md
    - docs/notes/store-compliance.md
    - lib/core/constants/revenuecat_keys.dart (sin cambios si ya es el bueno)
- id: T16
  title: Eliminar kPackageName muerto ('bo.3dcal.tresdcal')
  size: XS
  depends_on: []
  owner: flutter-reviewer
  verify: |
    - grep confirmo 1 unico match (la definicion en app_constants.dart:7);
      sin usos en lib/ ni test/
    - eliminar la constante (o corregir a 'bo.u3dcal.tresdcal' si en algun
      futuro se usa para deep links/packages)
    - flutter analyze sin issues; suite verde
  files_hint:
    - lib/core/constants/app_constants.dart
```

### Phase 5 — Verificacion final pre-subida (opcional, gate de subida)

```yaml
- id: T17
  title: Checklist final store-compliance.md + sandbox purchase real
  size: S
  depends_on: [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16]
  owner: USER + tdd-guide
  verify: |
    - suite completa: 271+ tests verdes (flutter test)
    - flutter build apk --release --dart-define=REVENUECAT_GOOGLE_KEY=goog_XXX
      verde, firmado con upload key (no debug)
    - sandbox purchase REAL en device (internal testing + license tester):
      paywall → compra $4.99 test → gates unlock en <2s → restore en fresh
      install OK
    - review del checklist de docs/notes/store-compliance.md completo
      (restore accesible, pricing claro, privacy/terms links funcionales)
    - merged manifest final: INTERNET + BILLING presentes
  files_hint:
    - docs/notes/store-compliance.md
```

## Checklist de Ejecucion

### Phase 1 — Fix build Android (critica)

- [x] T1 — Migrar image_gallery_saver → gal en pubspec + quote_share.dart
- [x] T2 — Actualizar/crear tests del save flow (gal)
- [x] T3 — Verificar build apk --debug verde + merged manifest (INTERNET, BILLING)

### Phase 2 — Restaurar 3 wiring (critica)

- [x] T4 — main.dart: ProviderContainer + configure() + override dashboard
- [x] T5 — Registrar ruta /paywall → PaywallPage en app_router.dart
- [x] T6 — Tests Fase 2: navegacion a /paywall desde cada gate + E2E paywall→unlock
- [x] Extra — Gate advanced mode (hallazgo: faltaba; TDD) + fixes code-review (paywall error feedback, cold-start gate, flake)

### Phase 3 — T8 gates (user tasks)

- [ ] T7 — RevenueCat dashboard: proyecto tresdcal configurado
- [ ] T8 — Play Console: IAP product + license testers + internal track

### Phase 4 — Play Store hardening

- [ ] T9 — Release signing: upload key o Play App Signing (decision: Play App Signing — ejecutar)
- [ ] T10 — Privacy/terms URLs reales
- [ ] T11 — Data Safety form + revision de permisos post-gal (decision: mantener storage maxSdk 28 — form pendiente)
- [ ] T12 — Listing assets (screenshots, feature graphic, descripcion, icono)
- [x] T13 — Semver versionName + versionCode (decision: 0.1.0+1, ya fijado)
- [x] T14 — R8/minifyEnabled en release + keep rules
- [x] T15 — Unificar nombre SDK key → REVENUECAT_GOOGLE_KEY
- [x] T16 — Eliminar kPackageName muerto
- [x] Q-Web — Override isPro=true en web (todo free, decision del usuario; build web OK)

### Phase 5 — Verificacion final (opcional, gate de subida)

- [ ] T17 — Checklist final store-compliance.md + sandbox purchase real

## Critical Path

```
T1 (M) → T3 (S) → T11 (S) / T14 (M) → T17 (S)
T4 (M) → T6 (M) → T17 (S)
```

Length: 2M + 2S ≈ ~2-3 dias (sin contar tareas manuales USER en paralelo).

## Parallel Groups

```
Wave 1 (parallel):  T1, T4, T5, T7, T9, T10, T12, T13, T15, T16
Wave 2 (parallel):  T2 (after T1), T3 (after T1), T8 (after T7),
                    T11 (after T1), T14 (after T1)
Wave 3 (parallel):  T6 (after T4, T5)
Wave 4 (sequential): T17 (after todo lo anterior)
```

**Max parallelism**: Wave 1 dispara las 2 fases criticas (build + wiring) y
todas las tareas manuales de Play Store en paralelo. Bottleneck real =
T8/T9 (config manual del user en consolas).

## Total Effort

```
4M + 8S + 5XS  (sin XL)
```

Desglose: 4 medium (T1, T4, T6, T14) + 8 small (T2, T3, T5, T7, T9, T11,
T12, T17) + 5 XS (T8, T10, T13, T15, T16). Las tareas USER (T7, T8, T9, T10,
T12) corren en paralelo y dependen de acceso a consolas, no de codigo.

## Top Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | `gal` rompe el build web (no tiene impl web) | Low | Medium | Branch `kIsWeb` intacta en quote_share.dart (guarda antes de tocar Gal). Si web sigue en scope, smoke `flutter build web`; si no, aceptado (web fuera de alcance). |
| 2 | Migracion gal cambia la API de resultado (era Map isSuccess, ahora PlatformException) | Medium | Medium | T1 usa try/catch PlatformException + mapping a ShareQuoteException; T2 cubre error path con tests. |
| 3 | INTERNET ausente en main manifest → release build sin red (RevenueCat falla en runtime) | Medium | High | T3 verifica merged manifest post-build; si falta, declarar en main. |
| 4 | R8 rompe keep rules de plugins (purchases-android, gal) | Medium | Medium | T14: release build + smoke test en device; ajustar proguard-rules.pro, nunca desactivar minify. |
| 5 | T7/T8 (manual) no completadas → sin sandbox purchase real | High | High | T6 corre con mock PaymentService. T17 (gate final) requiere sandbox real; si no esta, el release se sube a internal testing y se valida post-subida. |
| 6 | main.dart refactor rompe boot (ProviderContainer lifecycle) | Low | High | T4 sigue el patron ya documentado y testeado del report T9; verify: app arranca + suite verde. |
| 7 | Data Safety mismatch (permisos declarados vs usados) → rechazo en review | Medium | Medium | T11 revisa manifest contra lo que gal realmente requiere (solo WRITE en API <= 29); consistencia form vs APK. |
| 8 | Perdida del upload keystore → no poder publicar updates | Low | High | T9: backup documentado en docs/notes/playstore-signing.md; alternativa Play App Signing. |

## Fuera de Alcance (decisiones de scope)

- **"Dos versiones free y de paga con publicidad"**: el pedido original
  sugirio free con ads + paga sin ads. El plan actual (y la feature ya
  implementada) es **UNA sola app con unlock in-app** (free → $4.99 one-time
  via RevenueCat). NO hay ads ni consumibles: `google_mobile_ads` NO esta en
  pubspec ni en el codigo. Agregar ads mas adelante es un feature nuevo
  (require integracion AdMob + gate isPro para ocultarlas), NO parte de este
  plan.
- **Web**: hoy la web esta regresionada (gates aplicados con paywall roto
  tras perder los wiring). Opciones: (a) override `isPro=true` en web
  (todo free), o (b) bloquear web. Es **decision del usuario** — se documenta
  aqui, NO se implementa en este plan. En paralelo, T1 no debe romper el
  build web (branch kIsWeb intacta).
- **iOS / StoreKit**: sigue diferido (SC4 del PRD). `PaymentService` queda
  abstracto sin impl iOS.

## Naming

- Plan: `docs/plans/2026-08-08_2354-free-pro-playstore-prep.plan.md`
- Report (al cerrar): `docs/reports/2026-08-08_HHMM-free-pro-playstore-prep.report.md`
- Audit (opcional): `docs/audits/2026-08-08_HHMM-free-pro-playstore-prep.audit.md`

## Success Criteria (de este plan)

- [ ] `flutter build apk --debug` verde tras migracion a gal (bloqueante A resuelto)
- [ ] Merged manifest release contiene `INTERNET` + `com.android.vending.BILLING`
- [ ] RevenueCat se inicializa al boot: `configure()` llamado pre-`runApp`
      (main.dart) y `purchase()`/`restore()` ya no devuelven
      `PaymentError('PaymentService no configurado')`
- [ ] Los 5 call sites de gates navegan a `PaywallPage` (no `_RouterErrorPage`)
- [ ] Dashboard charts visibles para Pro (override `dashboardIsProProvider`
      wireado al `isProProvider` root)
- [ ] Test E2E: paywall → mock purchase success → gates unlock (y paths de
      cancel/error sin cambios)
- [ ] Suite completa verde: 271+ tests (incluidos los nuevos de Fase 2)
- [ ] Checklist RevenueCat + Play Console completado (T7, T8)
- [ ] Release build firmado con upload key / Play App Signing (no debug keystore)
- [ ] Privacy/terms URLs reales publicadas y funcionales (url_launcher)
- [ ] Data Safety form consistente con el merged manifest final
- [ ] Listing assets completos (screenshots, feature graphic, descripcion, icono)
- [ ] Semver definido; `kPackageName` muerto eliminado; SDK key unificada a
      `REVENUECAT_GOOGLE_KEY`
- [ ] R8 habilitado en release + smoke test OK
- [ ] Sandbox purchase real verificada en device + store-compliance checklist completo (T17)

## Open Questions / Decisiones Pendientes

- **Q-Web**: web regresionada → override isPro=true (todo free) o bloquear
  web. Decision del usuario, fuera de este plan.
- **Q-Signing**: upload keystore propio vs Play App Signing (T9). Play App
  Signing es menos riesgo de perdida de key; keystore propio da control.
- **Q-Permisos**: mantener READ/WRITE_EXTERNAL_STORAGE por compat API 24-28
  o remover tras gal (T11). Mantener = form Data Safety mas simple; remover
  = APK mas limpio pero rompe save en API < 29 si algo se escapa.
- **Q-Version**: 0.1.0+1 (primer release interno) vs 1.0.0+1 (publico) (T13).
