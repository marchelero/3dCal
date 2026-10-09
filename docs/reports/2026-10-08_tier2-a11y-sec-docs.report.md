# Reporte — Tier 2: a11y + seguridad + docs (2026-10-08)

- **PRD**: `docs/prds/2026-10-08_1700-tier2-a11y-sec-docs.prd.md`
- **Baseline**: 947/947 tests, `flutter analyze` 0 issues.
- **Final**: **971/971 tests**, `flutter analyze` **0 issues** (+24 tests nuevos).
- **Commits**: NINGUNO — todo en working tree sobre `main` (= `origin/main` @ `d572d3e`). Regla de consentimiento respetada.

## Decisiones del dueño (confirmadas por question tool)

1. **SEC-01**: "revisar y endurecer" → implementado (T2-1).
2. **SEC-12** (URLs legales placeholder `u3dcal.bo`): **diferir a release checklist** — sin cambios de código; ver §Release gates.
3. **a11y**: alcance **alto impacto** (contraste + text-scale + Semantics); NO se tokenizaron los 74 `Color(0x` (74 = 47 theme + 18 paleta filamentos + 6/2/1 onboarding).

## Ítems

| Ítem | Qué se hizo | Verificación |
|---|---|---|
| **T2-1 SEC-01** — boot Free no consultaba la store | `entitlement_notifier.dart`: camino Free ahora dispara `_hydrateProFromStoreIfActive()` (fire-and-forget): store `true` → `activate()` persiste DB+cache+state Pro; `false`/`null` → no-op (sin legacy restore en Free). Guards de race (purchase en vuelo gana) + cede un tick si el build está en vuelo. | 3 tests nuevos en `entitlement_boot_sync_test.dart` (store ACTIVO/INACTIVO/offline) → 8/8; suites entitlement+paywall+settings 97/97 |
| **T2-2 SEC-03** — backups sin integridad | Nuevo `lib/core/backup/backup_signature.dart`: HMAC-SHA256 (`crypto ^3.0.7`), clave 256-bit por dispositivo (SharedPreferences, 1er uso, idempotente) + `installId` por instalación. Export → envoltorio `{backup, signature, deviceId}`. Import: mismo dispositivo + firma válida → OK; mismo dispositivo + mismatch → `signatureMismatch` (rechazado); **otro dispositivo → aceptado** (cross-device no se rompe); sin firma (legacy) → aceptado con aviso. Constant-time compare. Código nuevo + caso en `settings_page._backupErrorText` + string localizado en 7 archivos l10n (5 idiomas). | `backup_signature_test.dart` 9/9; legacy `backup_roundtrip+validation` 36/36 intactos |
| **T2-3 contraste WCAG AA** | `app_theme.dart`: `blueSuccess #1E88E5→#1769C0` (snack blanco 3.68→**5.50**), `inkSoft` claro `#5A6B85→#52627C` (4.26→**4.86**), `outline` claro `#7C8CA3→#75859C` (2.82→**3.10**). Sin cambios en la paleta de filamentos (datos). | `test/unit/theme_contrast_test.dart` 6/6 (light+dark, WCAG relative luminance) |
| **T2-4 text-scale 1.5×** | Nuevo harness `test/widget/text_scale_test.dart`: app real (TresdcalApp + router real) con `textScaleFactorTestValue = 1.5` sobre 6 pantallas (home, calculator, settings, history, paywall, detail con seed). Sanity-check: `MediaQuery.textScaler.scale(14) == 21` (escala REAL aplicada, no verde vacío). | **6/6 sin overflow — hallazgo: la app ya resistía 1.5×, cero fixes de UI necesitados** |
| **T2-5 Semantics** | 4 botones stepper `±` (result_sheet + calculation_detail_page) y cierre de diálogo en settings ahora con `tooltip` (nombre accesible): +3 keys l10n (`calcQuantityDecrease`, `calcQuantityIncrease`, `commonClose`) en abstract + facade + 5 impls. Scan previo: 3 icon-only candidates, 2 ya cubiertos (Tooltip/`tooltip:` existentes). | analyze 0; `settings_page_test` 32/32; `text_scale_test` 6/6 |
| **T2-6 docs stale** | `README.md`: stack real (Flutter 3.47/Dart 3.13/Riverpod 3.x/go_router 17), Status **v0.6.0+13 · 970→971 tests**, 11 features actuales, estructura de directorios real (l10n/ en raíz, features entitlement/legal/onboarding/splash, docs/sessions). `docs/PROJECT.md`: Stack (5 locales, RevenueCat, schema v17, crypto), Directory Layout y nota Riverpod manual (sin `@riverpod` en lib/, verificado). `PRODUCT.md` (raíz): tecnología + i18n + red mínima (RevenueCat+share; "cero red" ya era falso). `kFreeHistoryCap=10` verificado → claim de historial free sigue vigente. | revisión manual contra pubspec/lib |

## Bug de diseño detectado y corregido durante T2-2

La primera implementación rechazaba **cualquier** firma no coincidente → un backup firmado en el dispositivo A se rechazaba en el dispositivo B (**rompía la restauración cross-device**, el caso de uso principal). Corregido con `deviceId` (installId) en el envoltorio: solo se verifica cuando el backup es del MISMO dispositivo (donde sí aplica el threat model: archivo editado fuera de la app). Test `backup de OTRO dispositivo → ACEPTADO` fija el contrato.

## Métricas

- `flutter analyze`: **0 issues**.
- `flutter test`: **971/971** (947 baseline + 24: 6 contraste + 8 firma + 6 text-scale + 3 boot-Free + 1 cross-device).
- Dependencias: **+`crypto ^3.0.7`** (pubspec + lock).
- Archivos nuevos: 1 lib (`backup_signature.dart`) + 5 tests + 1 PRD + este reporte + snapshot.
- l10n: 3 keys × 7 archivos.

## Limitaciones documentadas (deliberadas, no bugs)

1. **HMAC con clave en SharedPreferences**: extraerla requiere root/sandbox. Es detección de corrupción/tampering casual, no criptografía fuerte contra un atacante con acceso al dispositivo.
2. **Bypass conocido**: un atacante que reescribe el archivo puede quitar el envoltorio entero → cae al camino legacy (aceptado con aviso). Mismo comportamiento que pre-T2-2, sin regresión; anotado en `backup_signature.dart` y en los debugPrint.
3. **Cross-device no verificable**: firma con clave ajena no es comprobable localmente → se acepta (decisión explícita; rechazar rompía migración de celular).

## Release gates (SEC-12 + auditoría 2026-08-13) — pendientes ANTES de publicar

1. **URLs legales**: reemplazar `https://u3dcal.bo/privacy|terms` (`app_constants.dart:158,162`) por URLs reales (SEC-12, diferido por decisión del dueño).
2. **Firma de release**: `android/key.properties` + keystore (gitignored pero en repo) — sacar del repo / rotar antes de publicar.
3. **`sqlite3_flutter_libs 0.6.0+eol`**: evaluar upgrade (audit #4).

## Siguiente paso

- Falta el **verbo commit** del dueño (no se commitea sin pedido explícito).
- Post-commit candidatos: release checklist con los 3 gates de arriba.
