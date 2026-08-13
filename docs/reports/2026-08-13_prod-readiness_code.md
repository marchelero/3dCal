# Reporte: Producción-Readiness (código) — 3dCalc

Fecha: 2026-08-13 · Agente: code-reviewer · Estado: READY WITH FIXES

## Verificación ejecutada
- `flutter analyze`: No issues found (19.4s)
- Suite de tests: 421/421 pasan

## Hallazgos

| Sev | Hallazgo | Referencia |
|---|---|---|
| ALTO | Privacy Policy / ToS apuntan a dominio muerto (`u3dcal.bo` no resuelve DNS). Play Store exige URL de privacidad válida para apps con IAP → rechazo. | `lib/core/constants/app_constants.dart:146,150` |
| ALTO | Release sin `--dart-define=REVENUECAT_GOOGLE_KEY` ⇒ IAP muerto silencioso (no-op + debugPrint, sin fail-fast). | `lib/features/entitlement/data/payment_service_revenuecat.dart:49-61` |
| MEDIO | Precio paywall hardcodeado ($4,99) en l10n; nunca se consulta `getOfferings()` para mostrar precio real de store. | `lib/l10n/*.dart`, `app_constants.dart:142` |
| MEDIO | Sin crash reporting / observabilidad; 24 call sites de `debugPrint` en catch. Fallos invisibles en prod. | `pubspec.yaml`, `result_sheet.dart:446,490`, `backup_service.dart:174,233` |
| BAJO | `debugPrint` sin guard en paths de error (sale en release). | `payment_service_revenuecat.dart:79-81` |
| BAJO | Web manifest con placeholders de template Flutter (description, theme_color). | `web/manifest.json:8,6-7` |
| BAJO | iOS folder presente pero pagos Android-only: `configure()` usaría key GOOGLE en iOS. Documentar o gatear. | `payment_service_revenuecat.dart:20-22` |
| BAJO | `ValueKey(child.hashCode)` en transiciones del router (hashCode inestable entre builds). | `lib/core/router/app_router.dart:30` |
| BAJO | 8 fuentes ≈1,3 MB bundleadas; web es el target afectado. | `assets/fonts/` |

## Áreas OK
- Secrets: sin keys hardcodeadas; key.properties/local.properties gitignoreados
- Migraciones drift v7 con onUpgrade completa + tests no-destructivos
- Error handling UI con SnackBar real en save/share/PDF
- Android: minSdk 24 / target 36, R8 activo, allowBackup=false, cleartext bloqueado
- RevenueCat: entitlement check post-compra y post-restore correctos
- Cap free: conteo+insert atómico en transacción, sin race
- Rendimiento: drift en isolate nativo, fonts bundleados (sin FOUT)

## Checklist externo (no verificable en código)
- [ ] Product `tresdcal_pro_lifetime` existe en Play Console y vinculado a entitlement `pro`
- [ ] Dominio privacy/ToS registrado y respondiendo (hoy NO)
- [ ] CI pasa `REVENUECAT_GOOGLE_KEY` en release
- [ ] `version: 0.1.0+1` sincronizada entre `pubspec.yaml` y `app_constants.dart`
