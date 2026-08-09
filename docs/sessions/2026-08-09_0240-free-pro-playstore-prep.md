# Session: F1+F2 Play Store prep completos

**Date**: 2026-08-09 (inicio 2026-08-08_2354)
**Status**: F1 (build) + F2 (wiring) DONE. Suite 289/290 (1 flake pre-existente). Build APK debug VERDE.
**Plan de referencia**: [2026-08-08_2354-free-pro-playstore-prep.plan.md](../plans/2026-08-08_2354-free-pro-playstore-prep.plan.md)
**Reporte**: [2026-08-09_0240-free-pro-playstore-prep.report.md](../reports/2026-08-09_0240-free-pro-playstore-prep.report.md)

---

## Qué pasó en esta sesión

1. **Gap analysis** (code-explorer): plan free/pro casi completo pero 3 wiring perdidos + build roto + ads NO contemplados en el plan.
2. **Plan nuevo creado**: `docs/plans/2026-08-08_2354-free-pro-playstore-prep.plan.md` — 17 tareas, 5 fases (planner).
3. **F1 — Fix build Android ✅** (agente general)
4. **F2 — Restaurar 3 wiring ✅** + **gate advanced mode agregado** (agente general, TDD)

## F1 — Fix build (DONE)

- **`image_gallery_saver` → `gal ^2.3.3`**: `pubspec.yaml` + `lib/core/share/quote_share.dart`
  (`Gal.putImageBytes`, seam `GallerySaver`, catch `GalException`/`PlatformException` → `ShareQuoteException`).
  Nota: gal 2.3.x envuelve PlatformException en `GalException` (catch real = GalException).
- **`android/app/src/main/AndroidManifest.xml`**: + `android.permission.INTERNET` (release lo necesitaba; purchases_flutter no lo declara).
- **`android/gradle.properties`**: `kotlin.incremental=false` (fix build Windows).
- **Assets**: `assets/fonts/JetBrainsMono-{Bold,Medium}.ttf` bundleados (google_fonts fetch fallaba bajo runAsync en tests).
- **Tests nuevos**: `test/unit/gallery_saver_test.dart` (6), `test/widget/quote_save_flow_test.dart` (2).
- **Resultados**: `flutter build apk --debug` VERDE · merged manifest contiene `INTERNET` ✓ y `com.android.vending.BILLING` ✓ · suite 279/279.

## F2 — Wiring (DONE)

- **`lib/main.dart`**: `ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider))])` + `await container.read(paymentServiceProvider).configure()` + `UncontrolledProviderScope`. Dev mode sin `--dart-define=REVENUECAT_GOOGLE_KEY` → warning + no-op (esperado).
- **`lib/core/router/app_router.dart`**: GoRoute `/paywall` → `_slideRight(const PaywallPage())` (full-screen, junto a /calculator, fuera del StatefulShellRoute).
- **5 call sites navegan a PaywallPage** (ya no `_RouterErrorPage`): calculator_page.dart:359, calculations_list_page.dart:195, dashboard_page.dart:263, settings_page.dart:744,845.
- **Gate advanced mode (hallazgo + fix)**: NO existía (revert no detectado; gap analysis erróneo). Agregado en `_switchMode` (calculator_page.dart:247): `mode==advanced && !isPro` → SnackBar `calculatorAdvancedLockedBody` + action Go Pro → `/paywall`, sin cambiar modo. Strings l10n YA existían (restos del T14).
- **Tests nuevos**: `test/widget/paywall_navigation_test.dart` (5 gates→paywall + 2 advanced-mode), `test/integration/full_purchase_flow_test.dart` (4: purchase success / restore / cancel / error).
- **Resultados**: analyze 0 issues nuevos en tocados · suite **289/290** (1 flake, ver abajo).

## ISSUE CONOCIDO (no bloqueante)

- **Flake**: `test/widget/quote_save_flow_test.dart:110` — save-imagen hardcodea pump de 300ms de `runAsync` para captura de engine real; bajo carga del suite completo llega tarde. Pasa en aislamiento. Fix sugerido: `pumpUntilFound` en vez de pump fijo. Archivo de T2 (F1), no tocado.

## Pendiente para próxima sesión

- [ ] **F3 (user tasks, manual)**: T7 RevenueCat dashboard (proyecto `tresdcal`, entitlement `pro`, offering default/package lifetime, service account JSON, SDK key `goog_...`), T8 Play Console (producto IAP `tresdcal_pro_lifetime` non-consumable $4.99, license testers, internal testing track).
- [ ] **F4 (hardening)**: T9 signing (Q: upload keystore propio vs Play App Signing), T10 privacy/terms reales (URLs placeholder `u3dcal.bo/privacy`), T11 Data Safety (Q: mantener WRITE_EXTERNAL_STORAGE maxSdk 28 vs remover), T12 listing assets, T13 semver (Q: 0.1.0 vs 1.0.0), T14 R8/minify, T15 unificar SDK key a `REVENUECAT_GOOGLE_KEY` (docs usan 3 nombres), T16 eliminar `kPackageName` muerto (app_constants.dart:7).
- [ ] **F5**: sandbox purchase real + checklist store-compliance.
- [ ] **Decisiones abiertas**: Q-Web (override isPro=true en web vs bloquear web — hoy regresionada), Q-Signing, Q-Permisos, Q-Version.
- [ ] **Opcional**: ads/consumibles para el free (scope nuevo, NO en plan).

## Cómo verificar al retomar

- `flutter analyze` (0 issues nuevos en tocados) · `flutter test` (expect 289/290, flake quote_save_flow pasa aislado) · `flutter build apk --debug` (verde).
- Suite previa monetización: 271 tests. Hoy: 290 (9 F1 + 10 F2).
