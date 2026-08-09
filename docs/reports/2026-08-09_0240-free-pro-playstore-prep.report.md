# Report: F1+F2 — Free/Pro Play Store prep

**Date**: 2026-08-09_0240
**Plan**: docs/plans/2026-08-08_2354-free-pro-playstore-prep.plan.md
**Status**: FASE 1 ✅ · FASE 2 ✅ · F3/F4/F5 pendientes

---

## Fase 1 — Fix build Android (DONE)

| Criterio (plan) | Resultado |
|---|---|
| `image_gallery_saver` → `gal` (pubspec + quote_share.dart) | ✅ `gal ^2.3.3`; `Gal.putImageBytes` + seam `GallerySaver`; catch `GalException` (gal 2.3.x envuelve PlatformException) → `ShareQuoteException`; guard kIsWeb intacto |
| `flutter pub get` sin errores | ✅ |
| Tests save flow | ✅ `test/unit/gallery_saver_test.dart` (6) + `test/widget/quote_save_flow_test.dart` (2) |
| `flutter build apk --debug` verde | ✅ (fix previo: `kotlin.incremental=false` en gradle.properties por build Windows) |
| Merged manifest: `INTERNET` + `com.android.vending.BILLING` | ✅ ambos presentes |
| `flutter analyze` sin issues nuevos | ✅ 0 en archivos tocados |

Cambios extra (justificados): `INTERNET` declarado en manifest main (release dependía solo del manifest debug; purchases_flutter no lo declara); JetBrainsMono 500/700 bundleados como assets (google_fonts fetch fallaba bajo `runAsync` en tests — además mejora prod offline).

## Fase 2 — Restaurar 3 wiring (DONE)

| Criterio (plan) | Resultado |
|---|---|
| main.dart: ProviderContainer + configure() pre-runApp + override dashboard | ✅ `sharedPreferencesProvider.overrideWithValue(prefs)`, `dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider))`, `await paymentServiceProvider.configure()`, `UncontrolledProviderScope` |
| Ruta `/paywall` → PaywallPage | ✅ GoRoute full-screen con `_slideRight` (junto a /calculator) |
| 5 call sites → PaywallPage (no `_RouterErrorPage`) | ✅ calculator:359, calculations_list:195, dashboard:263, settings:744,845 |
| Test E2E paywall→unlock + cancel/error sin cambios | ✅ `test/integration/full_purchase_flow_test.dart` (4 tests: success/restore/cancel/error) |
| Tests navegación gates | ✅ `test/widget/paywall_navigation_test.dart` (5 + 2 advanced-mode) |
| Suite completa verde | ⚠️ 289/290 (flake pre-existente, ver abajo) |

## Hallazgo: gate advanced mode faltante (fix agregado)

El gap analysis daba T14 (gate advanced mode) como DONE, pero el código no tenía gate: `CalculatorMode.advanced` era libre. Fix TDD en `calculator_page.dart:_switchMode`: `mode==advanced && !isPro` → SnackBar `calculatorAdvancedLockedBody` + action Go Pro → `/paywall`. Strings l10n ya existían (restos del T14). Tests: free→locked+paywall; pro→unlock.

## Issues conocidos

1. **Flake** `test/widget/quote_save_flow_test.dart:110`: pump fijo 300ms de `runAsync` bajo carga del suite completo → falla intermitente; pasa aislado. Fix sugerido: `pumpUntilFound`. (Archivo de F1/T2, no relacionado con F2.)
2. `flutter analyze lib/` global: baseline 608 → 648 (delta de F1/pack, ajeno a F2).

## Estado de la suite

- Pre-monetización: 271 tests. Hoy: **290** (F1 +9, F2 +10).
- Commits: **ninguno** (regla git: esperar permiso explícito). Trabajo sin commitear.

## Próximos pasos

- **F3** (user): RevenueCat dashboard + Play Console IAP (`tresdcal_pro_lifetime`, $4.99) + license testers + internal track. Requiere acceso a consolas.
- **F4** (código+user): signing, privacy/terms reales, Data Safety, listing, semver, R8, unificar SDK key, limpiar `kPackageName`.
- **F5**: sandbox purchase real + checklist store-compliance.
- **Decisiones pendientes**: Q-Web, Q-Signing, Q-Permisos, Q-Version (ver plan líneas 556-565).

---

## Actualización 2026-08-09 (retoma) — Review + fixes + F4 código

### Code review F1+F2 (code-reviewer)

Veredicto: **APPROVE-WITH-NITS**. 0 CRITICAL / 0 HIGH / 1 MEDIUM / 3 LOW / 3 NIT. Verificó: configure() una sola vez antes de runApp, override dashboard sin circularidad, gate `_switchMode` sin estado inconsistente, sin keys hardcodeadas, merged manifest con INTERNET+BILLING (Play Billing 8.3.0), gal API correcta.

### Fixes aplicados (resumen)

- **MEDIUM**: feedback de error en paywall — `purchase()` ahora retorna `Future<PaymentResult>`; `_onUnlock`/`_onRestore` muestran AppSnackBar.error en PaymentError/RestoreError (cancel → no-op). 4 tests nuevos.
- **LOW**: comentario stale en full_purchase_flow_test corregido; gate advanced con estado loading → swallow (sin falso negativo cold start); flake de quote_save_flow_test → helper `_pumpUntilFound` (sin delays fijos).
- **Q-Web (decisión user)**: `main.dart` con `kIsWeb` → `isProProvider.overrideWithValue(true)` + skip configure() RevenueCat en web. Web queda 100% free, build web release OK.

### F4 código (DONE)

- **T14 R8**: `isMinifyEnabled=true` + `isShrinkResources=true` + proguard-rules.pro (única regla defensiva `-keepattributes *Annotation*`; RevenueCat/gal/drift/pdf no necesitan reglas app-level). `flutter build apk --release` **VERDE** → `app-release.apk` (68 MB).
- **T15**: SDK key unificada a `REVENUECAT_GOOGLE_KEY` en docs (store-compliance.md, revenuecat-setup.md). Restos solo en plan (registro histórico).
- **T16**: `kPackageName` eliminado (0 usos en lib/test).
- **T13**: semver **0.1.0+1** confirmado (decisión user, sin cambios).

### Decisiones del usuario (registradas)

| Q | Decisión |
|---|---|
| Q-Web | Web = todo free (override isPro=true) ✅ implementado |
| Q-Signing | Play App Signing (ejecutar: upload key) |
| Q-Permisos | Mantener storage (maxSdk 28) — ya en manifest |
| Q-Version | 0.1.0+1 ✅ |

### Estado final de la sesión

- **Tests**: **294/294** estables (2 corridas; flake eliminado).
- **Builds**: apk debug ✓ · apk release (R8) ✓ · web release ✓.
- **analyze**: 0 issues nuevos en archivos tocados (baseline repo: 643 pre-existentes).
- **Commits**: ninguno (esperando permiso).

### Queda (todo user tasks en consolas)

- **F3**: T7 RevenueCat dashboard (proyecto `tresdcal`, entitlement `pro`, offering default/package lifetime, service account, SDK key) + T8 Play Console (IAP `tresdcal_pro_lifetime` $4.99 non-consumable, license testers, internal track).
- **F4 user**: T9 upload key (Play App Signing), T10 privacy/terms reales (URLs placeholder), T11 Data Safety form, T12 listing assets.
- **F5**: T17 sandbox purchase real + checklist store-compliance.
