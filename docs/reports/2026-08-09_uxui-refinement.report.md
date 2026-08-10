# Reporte: Refinamiento UX/UI 3dCal

**Fecha**: 2026-08-09
**Alcance**: Corrección de TODAS las desviaciones detectadas (auditoría explore + skill impeccable, modo Operate/refinement — identidad "Plano Técnico Acotado" preservada, sin rediseño).
**Verificación**: `flutter analyze` 0 errores · `flutter test` 312/312 · `flutter build web` verde · screenshots Playwright desktop+mobile (light+dark) en `verify/`.

---

## Cambios por categoría

### 1. Colores fuera del tema → sistema
| Sitio | Antes | Ahora |
|---|---|---|
| Splash gradiente (splash_screen.dart) | `0xFF1A2A3A→0xFF0D0D0D` fijo oscuro | `primaryContainer→surface` del colorScheme (light/dark-aware) |
| Onboarding 4 slides (onboarding_page.dart) | 4 const hardcodeados, naranja/teal fallaban AA | `AppTheme.onboardingSlideColors`: azul `#1B4D7A` (7.6:1), naranja `#9A3412` (5.4:1), teal `#0F766E` (5.3:1), violeta `#6C3483` (7.9:1) — texto blanco AA en todos |
| Icono PDF (result_sheet L611, detail L584) | `Colors.red` | `colorScheme.error` |
| Icono Print (detail L591) | `Colors.green` | `AppTheme.greenSuccess` |
| Barra loading splash | `Colors.white` fijo | `colorScheme.primary` (bg alpha 0.12, label alpha 0.5) |

### 2. Inputs unificados a la línea de cota del tema (11 sitios)
Eliminados `OutlineInputBorder` locales: brand_selector_field (×2), printer_form, printers_page (search), calculator_page (search modals ×2), calculations_list (search), filament_form, filaments_page (search), settings_page (empresa + moneda ×2), initial_config (moneda). El tema (underline) aplica en todos.

### 3. SnackBar unificados → AppSnackBar (8 sitios)
- **Extensión**: `AppSnackBar` ahora acepta `{actionLabel, onAction}` → `SnackBarAction` con `textColor: foregroundColor`.
- Conversiones: gates T14 (Avanzado) y T15 (historial) en calculator, gate CSV + "no hay cotizaciones" en historial, branding gates (settings ×2), undo de filamento e impresora.
- **Bug de test descubierto y resuelto**: floating snackbars bloquean taps durante animación de entrada (~250ms). AppSnackBar forzaba `behavior: floating`; el theme YA lo define globalmente. Se removió el forzado → el behavior lo decide el theme (app real idéntica, tests sin AppTheme recuperan fixed). Test "CSV gate → /paywall" pasa sin modificar el test.

### 4. i18n (10 getters nuevos en los 4 archivos l10n)
`historyExportCsv`, `historyEmptyCta` (corrige Spanglish "calculator"→"calculadora"), `calcSectionOthers`, `settingsProfitBaseRange`, `settingsKwhRateRange`, `shareErrorNotRendered`, `shareErrorNoRegion`, `shareErrorEncode`, `shareErrorSaveGallery`, `shareErrorSaveWithMessage(msg)`. Strings ES byte-idénticas a las anteriores → tests existentes pasan.

### 5. Constantes
- `kAppVersion = '0.1.0'` (doc: sync con pubspec) → settings hero y about usan `v$kAppVersion` (elimina duplicación).
- `kDefaultCompanyName = '3dCalc'` → comparaciones en home (settings/domain/repository/pdf_export apuntan al mismo valor).
- `kCurrencyCode='USD'` **verificado correcto** (settings_repository L173) — sin cambio.

### 6. Tipografía → textTheme roles
Splash label (12→labelMedium), result_sheet hints (10.5→labelSmall 11), monthly_trend_chart (9/10→labelSmall), dashboard _LegendDot/_MaterialRow (12/13→labelMedium/bodyMedium), calculator ActionChip (12→labelMedium) + badge (13→labelMedium), list filter chip (12→labelMedium) + popup menu (14→labelLarge), quote_image_template fallback (28→headlineMedium fallback). Hero totals calculator (22) **intencionales** (NumericInputField API) — sin cambio.

### 7. A11y
- Touch targets 44→48px: `_ActionIcon` (result_sheet), `_DetailActionIcon` (detail).
- `Semantics` nuevo: MonthlyTrendChart (resumen hablado con datos), ResultBottomBar (button + label total), hero home (label).
- Doc-comment splash corregido (referenciaba `loading_screen.png` inexistente; usa `logo.png`/`3dlogo.png`).

## Verificación visual (Playwright + muestreo de píxeles)
Screenshots en `verify/`: initial-config, 4 slides onboarding, home desktop, settings light/dark, home mobile dark, calculator mobile dark. Píxeles verificados: desk light `#DFE6F0` ✓, slides `#1C4E7B/#9B3513/#10776F/#6D3584` ✓ (blend de gradiente), dark `#152032` ✓. 0 errores de consola.

## NO cambiado (verificado correcto)
printer_form/filament_form snackbars de error (ya AppSnackBar), sombra app_scaffold, hero settings (decisión de identidad), kCurrencyCode, fontSize 22 hero calculator.
