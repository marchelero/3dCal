# Store Compliance — tresdcal (bo.u3dcal.tresdcal)

Checklist para cumplimiento de Google Play Store (apps con IAP).

## Pricing & Display

- [x] Precio claro en paywall: `$4.99` USD one-time (mostrado en `paywall_price`)
- [x] Moneda USD visible (no confunde con BOB ni otras monedas locales)
- [x] Sin cargos recurrentes ni suscripciones (one-time unlock, no subscription)
- [x] Sin promociones engañosas, "free trial" statements o "limited time" falsos
- [x] El precio displayed es referencial (store define el real), pero es el mismo ID en RC + Play Console

## Restore Purchases

- [x] Boton "Restore" accesible en paywall (`RestoreButton` en `PaywallPage`)
- [x] Boton "Restaurar compras" en settings (`_RestoreButton` en `SettingsPage`, seccion Restaurar Compras)
- [x] Restore flow: llama `PaymentService.restore()`, muestra SnackBar con resultado (success / empty / error)
- [x] No requiere login — restore usa las credenciales de Google Play del dispositivo

## Privacy & Terms

- [x] Link a Privacy Policy en paywall (abajo del boton Restore)
- [x] Link a Terms of Service en paywall (misma fila, separado por `|`)
- [x] Seccion "Legal" en settings page (entre Acerca de y el spacer final)
- [x] Los links abren en browser externo (`launchMode: externalApplication`)

## IAP Compliance (Play Store)

- [ ] **USER TASK (T8)**: Configurar IAP product `tresdcal_pro_lifetime` en Google Play Console
  - Producto: `tresdcal_pro_lifetime`
  - Tipo: Non-consumable
  - Precio: $4.99 USD
  - Estado: ACTIVADO
- [ ] **USER TASK (T8)**: Configurar RevenueCat project `tresdcal` con:
  - Google Play service account (JSON key)
  - Entitlement `pro` asociado al product `tresdcal_pro_lifetime`
  - Offering `default` con el package `lifetime`
- [ ] **USER TASK**: Publicar Privacy Policy + Terms of Service en una URL publica
  - Opciones recomendadas: GitHub Pages, Iubenda, PrivacyPolicies.com
  - URLs configuradas en `lib/core/constants/app_constants.dart`:
    - `kPrivacyPolicyUrl` = `https://u3dcal.bo/privacy`
    - `kTermsOfServiceUrl` = `https://u3dcal.bo/terms`

## Compliance General

- [x] App declara permiso `com.android.vending.BILLING` (AndroidManifest)
- [x] App ID: `bo.u3dcal.tresdcal` (namespace en build.gradle.kts)
- [x] Sin datos de usuario recolectados (100% local, sin backend)
- [x] Sin analiticas de terceros excepto RevenueCat (datos de transacciones, sin PII)
- [x] `purchases_flutter` SDK configurado via `--dart-define=REVENUECAT_GOOGLE_KEY=...`
- [ ] **USER TASK**: Agregar Privacy Policy + Terms URLs en el listing de Play Console
- [ ] **USER TASK**: Configurar test accounts/license testers en Play Console para sandbox

## Verificacion Pre-Release

- [ ] T21 integration test (full purchase flow mocked) — requiere T8 primero
- [ ] Sandbox purchase real via RevenueCat + Play internal testing track
- [ ] Confirmar restore button funciona con compra real
- [ ] Verificar privacy/terms links en dispositivo real (no emulador sin browser)
- [ ] `flutter build apk --release` sin errores
