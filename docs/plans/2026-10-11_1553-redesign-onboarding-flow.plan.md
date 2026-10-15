---
prd: docs/prds/2026-10-11_1045-redesign-onboarding-flow.prd.md
status: DRAFT
created: 2026-10-11_1553
---

# Implementation Plan: Rediseño del onboarding / configuración inicial

## Overview

Reemplazar las 9 pantallas actuales del first-run (5 slides marketing + idioma + stepper de 3 pasos, 1521 líneas) por **un único flujo continuo** en una sola ruta `/setup`: PageView de 6 pantallas (5 decisiones + cierre), gradiente animado por paso, pills de progreso, **ticket preview vivo** (pasos 1–4) como hilo conductor, persistencia instantánea vía los notifiers existentes (cero botones "Guardar") y cierre idéntico al actual (`onboardingDone=true` + Home + calculador). Entrega en 4 fases alineadas a los milestones del PRD, con gate de validación con el usuario al cierre de la Fase 1.

## Requirements Restatement

- **Una sola ruta** `/setup` (splash → `/setup` cuando `onboardingDone=false`); eliminadas `/language`, `/onboarding`, `/initial-config` del router y del código.
- **6 pantallas** en un PageView deslizable + pills tappable + back del sistema = retrocede un paso sin perder elecciones:
  1. **Paso 0 — Bienvenida + Idioma**: logo (`assets/images/3dlogo.png`), tagline, 5 tarjetas con nombre nativo (Español, English, Deutsch, Français, Português — proper nouns, no se traducen). Tap → `LocaleNotifier.setLocale()` instantáneo + scale/check. Sin ticket preview.
  2. **Paso 1 — Estilo + Moneda**: `ThemePicker` extraído (claro/oscuro con preview de gradiente) + chips de moneda con pre-selección por idioma (es→BOB, en→USD, pt→BRL, de/fr→EUR) + "Ver más" → bottom sheet con `WorldCurrency.all`. Persisten al tocar (`themeModeProvider.setMode`, `settingsNotifierProvider.updateCurrency`).
  3. **Paso 2 — Tu impresora (opcional)**: grid de presets táctiles de ~8–12 impresoras populares derivados del catálogo (`findModel` → watts + `usefulLifeHours`); tap crea printer default auto-llenada (`printersNotifierProvider.create(asDefault: true)`); tarjeta "Personalizada" abre `PrinterCatalogSelector(compact: true)` simplificado con auto-persist al completar; enlace "Lo agrego después" avanza sin crear nada.
  4. **Paso 3 — Tu filamento (opcional)**: chips de marca (`kKnownFilamentBrands`), precio con hint de rango típico, `FilamentColorField`; con marca+precio válidos → `filamentsNotifierProvider.create(asDefault: true)` automático (nombre auto-generado `${marca} 1000g`, grams default 1000); "Lo agrego después".
  5. **Paso 4 — Tu ganancia**: slider grande 0–500% + `NumericInputField` sincronizado + `_ProfitPreview` extraído ("x1.3 sobre costo" en vivo); sección kWh **plegada** mostrando `kDefaultKwhRate`, expandible con slider 0–5 + input; persisten al cambiar (`updateProfitBase`, `updateKwhRate`, Decimal siempre).
  6. **Cierre**: resumen tipo ticket de todo lo configurado (estados "pendiente" donde aplique), celebración visual, CTA **"Empezar a cotizar"** (string existente `configStartButton`) → `SettingsKeys.onboardingDone=true` + `router.go('/')` + `push('/calculator')` (semántica `_finish()` actual intacta).
- **Invariantes**: sin botón "Guardar"/"Siguiente" en todo el flujo (AC-07); cada elección llama exactamente a la API actual de notifiers; estado de negocio SOLO en Riverpod; `setState` solo para índice de página, controllers y flags UI-efímeros (excepción BUG-006 documentada); money = `Decimal` nunca `double`; i18n ×5 (abstract + EsBO facade + 5 impls, `l10n_parity_test` valida); comentarios español / código inglés; sin red; feature-first bajo `lib/features/onboarding/`.
- **AC-13 (reanudación)**: matar y reabrir regresa al paso 0 con elecciones pre-cargadas → cada paso inicializa su estado "guardado" **leyendo los providers** (no flags locales solamente).
- **AC-15 (wipe)**: "Borrar datos y reiniciar" → paso 0 preservando idioma y tema (`LocalDataWipeService` ya los preserva); solo cambia el redirect destino.

## Architecture Changes

| Archivo | Acción | Detalle |
|---|---|---|
| `lib/features/onboarding/presentation/pages/setup_flow_page.dart` | **CREA** | Container `ConsumerStatefulWidget`: `PageController` + `_currentPage` (UI-local), gradiente `AnimatedContainer` por paso (mapa `[0,1,2,3,0,3]` sobre `AppTheme.onboardingSlideColors`, 400 ms `easeInOut` como el onboarding actual), `ProgressPills`, slot de `TicketPreviewCard` (pasos 1–4), `PopScope` (back = página anterior vía `animateToPage`; en paso 0 permite pop). Pasa `VoidCallback onNext` a los pasos 2–3 ("lo agrego después"). |
| `lib/features/onboarding/presentation/pages/steps/welcome_language_step.dart` | **CREA** | Paso 0. Logo animado (TweenAnimationBuilder scale-in), 5 `LanguageOptionCard`. Reutiliza layout de `language_selection_page.dart` (MaxWidthScrollView 480, tarjeta logo). |
| `lib/features/onboarding/presentation/pages/steps/style_currency_step.dart` | **CREA** | Paso 1. `ThemePicker` extraído + `CurrencyChips` (5 sugeridas por locale + "Ver más" → `CurrencyPickerSheet` con `WorldCurrency.all` y scroll). Auto-aplica sugerencia al primer arrival si la moneda persistida sigue en default de fábrica `'USD'` (`Settings.defaults.currencyCode`); tap explícito setea flag local `_userTouchedCurrency` y previene override. |
| `lib/features/onboarding/presentation/pages/steps/printer_step.dart` | **CREA** | Paso 2. Grid `PrinterPresetCard` de presets destacados + tarjeta "Personalizada" (`PrinterCatalogSelector(compact: true)` + auto-create al completar brand/model/watts con guard once + `updatePrinter` en ediciones posteriores) + "Lo agrego después". Estado guardado inicializado desde `printersNotifierProvider` (default exists → tarjeta saved con "editar", patrón `_DeviceSetupCard`). |
| `lib/features/onboarding/presentation/pages/steps/filament_step.dart` | **CREA** | Paso 3. Chips marca (`Wrap` de `ChoiceChip` sobre `kKnownFilamentBrands` + opción manual), `NumericInputField` precio con hint `setupFilamentPriceHint`, `FilamentColorField`. Auto-create al tener marca+precio válidos (guard once; nombre auto `${marca} 1000g`; grams fijo 1000). Estado guardado desde `filamentsNotifierProvider`. |
| `lib/features/onboarding/presentation/pages/steps/profit_step.dart` | **CREA** | Paso 4. Slider 0–500 (div 5) + `NumericInputField` sincronizado + `ProfitPreview` extraído; `ExpansionTile` kWh plegado (label con `kDefaultKwhRate`) → slider 0–5 + input; persist onChangeEnd/onBlur: `Decimal.fromInt` (profit) / `Decimal.tryParse` con `,`→`.` (kwh), guard null-safe. |
| `lib/features/onboarding/presentation/pages/steps/summary_step.dart` | **CREA** | Cierre. Resumen ticket (filas reutilizando patrón `_SummaryRow` extraído), celebración (AnimatedScale + stagger de filas, sin dependencias nuevas), CTA `configStartButton` → flag + `go('/')` + `push('/calculator')`. |
| `lib/features/onboarding/presentation/widgets/theme_picker.dart` | **CREA (extracción)** | `ThemePicker` + `ThemeOptionCard` públicos, copia literal de `_ThemePicker`/`_ThemeOptionCard` (L832–976 de initial_config_page). `initial_config_page.dart` pasa a importarlos (borra privados) → `initial_config_stepper_test` sigue verde como red de seguridad. |
| `lib/features/onboarding/presentation/widgets/profit_preview.dart` | **CREA (extracción)** | `ProfitPreview` público de `_ProfitPreview` (L1099–1138); **corregir** el string hardcodeado `'sobre costo'` → nuevo string `profitPreviewOverCost` ×5 locales. |
| `lib/features/onboarding/presentation/widgets/summary_row.dart` | **CREA (extracción)** | `SummaryRow` público de `_SummaryRow` (L1476+), reutilizado por ticket preview y cierre. |
| `lib/features/onboarding/presentation/widgets/progress_pills.dart` | **CREA** | 5 pills encadenados (AnimatedContainer + checkmark en completados, resalta actual), tappable → `animateToPage`, `Semantics` label con `configStepCounter`. |
| `lib/features/onboarding/presentation/widgets/ticket_preview_card.dart` | **CREA** | Tarjeta inferior persistente tipo ficha (borde dashed vía `Perforation` de `shared/widgets/perforation.dart`); filas: moneda (`selectedCurrencyProvider`), tema (`themeModeProvider`), impresora/filamento (notifiers, default o "pendiente"), ganancia xN, kWh. **Solo `ref.watch`** → actualización en la misma interacción por reactividad. |
| `lib/features/onboarding/presentation/widgets/language_option_card.dart` | **CREA** | Tarjeta idioma grande: nombre nativo + code, scale+check al seleccionar, `Semantics(button, selected)`. |
| `lib/features/onboarding/presentation/widgets/currency_chips.dart` + `currency_picker_sheet.dart` | **CREA** | Chips sugeridos (símbolo + code) con pre-selección; sheet bottom con `WorldCurrency.all` (scroll, `useSafeArea`, patrón sheets existentes). |
| `lib/features/onboarding/presentation/widgets/printer_preset_card.dart` | **CREA** | Tarjeta preset: marca/modelo, watts, check si ya es default. |
| `lib/features/onboarding/presentation/domain/featured_printer_presets.dart` | **CREA** | Lista curada `(brand, model)` de ~8–12 presets populares (ej: Bambu Lab A1/A1 Combo/P1S/X1C, Creality Ender-3 V3/K1 Max, Anycubic Kobra 3, Photon Mono M7, Prusa MK4S, Elegoo Neptune 4 Pro) validada con `findModel()`; `catalogWattsFor` para fallback. Curada porque 208 modelos en grid es inutilizable. |
| `lib/core/router/app_router.dart` | **EDITA** | M1: agrega `GoRoute('/setup', SetupFlowPage)` + import. M4: elimina rutas `/language`, `/onboarding`, `/initial-config` + sus 3 imports. |
| `lib/features/splash/presentation/pages/splash_screen.dart` | **EDITA** | M1: `go('/language')` → `go('/setup')` (L66) + actualizar doc comment L15/L65. |
| `lib/features/settings/presentation/pages/settings_page.dart` | **EDITA** | M4: wipe redirect `context.go('/language')` → `context.go('/setup')` (L1316) + comment L1312. |
| `lib/features/onboarding/presentation/pages/initial_config_page.dart` | **EDITA (M2) → BORRA (M4)** | M2: importa widgets extraídos, borra `_ThemePicker`/`_ThemeOptionCard`/`_ProfitPreview`/`_SummaryRow` privados. M4: archivo eliminado. |
| `lib/features/onboarding/presentation/pages/language_selection_page.dart` | **BORRA (M4)** | Absorbida por paso 0. |
| `lib/features/onboarding/presentation/pages/onboarding_page.dart` | **BORRA (M4)** | Marketing descartado. |
| `lib/l10n/app_strings.dart` + `es_bo.dart` (facade+EsImpl) + `en_us.dart` + `de_de.dart` + `fr_fr.dart` + `pt_br.dart` | **EDITA** | Altas por fase (ver Testing/Strings); bajas en M4: `onboardingTitle1..5`, `onboardingDesc1..5`, `onboardingPageCounter`, `onboardingNext`, `onboardingConfigure`, `onboardingStart`, y tras borrar initial_config: `configTitle`, `configStep1..3Title`, `configStepSubtitle1..3`, `configStepCounter`, `configContinue`, `configBack`, + grep de `configPrinterRequired`/`configFilamentOptional`/`configFilamentSkip*`/`configProfitHelper`/etc. (`configStartButton` y `languagePageTitle/Subtitle` se **conservan** por reuso). |
| `test/widget/setup_flow_test.dart` | **CREA** | Reemplaza a `onboarding_flow_test.dart`. |
| `test/widget/setup_steps_test.dart` | **CREA** | Reemplaza a `initial_config_stepper_test.dart` (tests por paso). |
| `test/widget/language_selection_page_test.dart` | **BORRA (M4)** | Cobertura migra a paso 0 en setup_flow_test. |
| `test/widget/settings_page_test.dart` | **EDITA (M4)** | Sección wipe: expect `/language` → `/setup` (L945, L988–989). |

**Strings nuevos (agregar en la fase donde se usan; 6 archivos cada uno — abstract + facade EsBO + EsImpl + 4 impls):**

- F1: `setupWelcomeTagline`, `setupProgressSemantics(int, int)` (o reusar `configStepCounter` hasta M4).
- F2: `setupCurrencySeeAll`, `setupCurrencySuggested` (badge "para tu idioma"), `profitPreviewOverCost` (extracción), `setupPrinterTitle`, `setupPrinterSubtitle`, `setupPrinterCustom`, `setupAddLater` (nuevo genérico; reemplaza `configFilamentLater` en flujo nuevo), `setupPrinterPending`/`setupTicketPending` ("Pendiente").
- F3: `setupFilamentTitle`, `setupFilamentPriceHint` ("Ej: 100–150", localizado), `setupProfitTitle`, `setupKwhRateLabel` (o reusar `settingsKwhRate(symbol)`), `setupKwhDefaultHint`, `setupDoneTitle`, `setupDoneSubtitle`.
- Reusados sin cambio: `languagePageTitle/Subtitle`, `configTheme`, `configCurrency`, `configCurrencyHelper`, `configPrinterSaved`, `configFilamentSaved`, `configSummaryTitle`, `configSummaryImprint`, `configStartButton`, `settingsProfitBase`, `configProfitHelper`, `printerWatts`, `filamentBrand/Name/Price/Grams` + helpers.

## Implementation Steps

### Phase 1 — Esqueleto navegable + paso 0 (M1) · ⛔ GATE: validación con el usuario

1. **Strings base** (Files: `lib/l10n/app_strings.dart`, `es_bo.dart`, `en_us.dart`, `de_de.dart`, `fr_fr.dart`, `pt_br.dart`)
   - Action: agregar `setupWelcomeTagline` (+ cualquier string del skeleton) en los 6 archivos; correr `l10n_parity_test`.
   - Why: todo widget nuevo necesita strings desde el primer compilado; el parity test es la red.
   - Dependencies: ninguna. Risk: **LOW**.
2. **Ruta `/setup` + splash** (Files: `lib/core/router/app_router.dart`, `lib/features/splash/presentation/pages/splash_screen.dart`)
   - Action: registrar `GoRoute(path: '/setup', builder: SetupFlowPage)` (import nuevo); splash `go('/language')` → `go('/setup')` + actualizar comments. Rutas viejas quedan huérfanas funcionales hasta M4 (transicional, sin rotura: los tests viejos construyen sus propios GoRouters o pumpean la page directo).
   - Why: el gate M1 exige que la primera ejecución real entre al flujo nuevo. Dependencies: paso 4 (page existe) — se compila junto. Risk: **LOW**.
3. **`SetupFlowPage` container** (File: `lib/features/onboarding/presentation/pages/setup_flow_page.dart`)
   - Action: `ConsumerStatefulWidget` con `PageController` (UI-local, comment BUG-006), 6 children (pasos 2–5 pueden ser `SizedBox` placeholder temporal en M1), `onPageChanged → setState(_currentPage)`, gradiente `AnimatedContainer` (mapa página→`AppTheme.onboardingSlideColors`, texto blanco AA ya verificado), `PopScope` (back: `_currentPage > 0` → `animateToPage(_currentPage - 1)`, consume; si no, permite pop), slot `TicketPreviewCard` visible para `1 <= _currentPage <= 4` (shell vacío en M1), `MaxWidthScrollView(maxWidth: 480)` por paso dentro de `SingleChildScrollView` (teclado/web safe). Sin botones de navegación.
   - Why: esqueleto que valida swipe/back/gradiente antes de pulir contenido. Dependencies: 1, 4, 5, 6. Risk: **MEDIUM** (PageView + scroll interno + teclado — probar con `resizeToAvoidBottomInset` default y viewport 800×2000 como el stepper test actual).
4. **`ProgressPills`** (File: `lib/features/onboarding/presentation/widgets/progress_pills.dart`)
   - Action: 5 pills horizontales encadenados (línea conectora), estado completado = check, actual = resaltado, tappable → callback `animateToPage`; `Semantics(label: configStepCounter(i+1, 5))`.
   - Why: navegación por taps sin botones (AC-09). Dependencies: 1. Risk: **LOW**.
5. **Paso 0 — `WelcomeLanguageStep` + `LanguageOptionCard`** (Files: `steps/welcome_language_step.dart`, `widgets/language_option_card.dart`)
   - Action: logo `assets/images/3dlogo.png` con scale-in (`TweenAnimationBuilder`, 500 ms), `setupWelcomeTagline`, `Wrap`/Column de 5 tarjetas (nombre nativo hardcodeado: Español/English/Deutsch/Français/Português + `AppLocale` correspondiente). Tap → `ref.read(localeProvider.notifier).setLocale(locale)` (persiste en prefs vía notifier existente) + feedback scale+check. El rebuild global lo hace el `ref.listen(localeProvider)` de `app.dart` (ya existe). Layout inspirado en `language_selection_page.dart` actual (reusar patrón container logo 72×72).
   - Why: AC-02; absorbe slides marketing + página de idioma. Dependencies: 1, 3. Risk: **LOW**.
6. **Ticket preview shell** (File: `widgets/ticket_preview_card.dart`)
   - Action: card inferior con borde punteado (`Perforation`), filas placeholder que ya `watch`ean `selectedCurrencyProvider`/`themeModeProvider`/notifiers (en M1 muestran defaults + "pendiente"). Se oculta en paso 0 y cierre.
   - Why: prepara el "hilo conductor" sin bloquear el gate. Dependencies: 1. Risk: **LOW**.
7. **Tests Fase 1** (File: `test/widget/setup_flow_test.dart`)
   - Action: `_pumpSetup` (patrón `_pumpOnboarding`: SharedPreferences mock + ProviderContainer + `MaterialApp.router` con router de prueba que incluye `/setup`, `/`, `/calculator`); casos: (a) 6 páginas, swipe avanza/retrocede; (b) back del sistema en paso >0 retrocede, en paso 0 permite pop; (c) pills tappable navegan; (d) tap idioma persiste locale en prefs y cambia strings al instante (aserción migrada de `language_selection_page_test`); (e) gradiente presente (`AnimatedContainer` con color del paso). Correr junto a `initial_config_stepper_test` (sigue verde) como smoke.
   - Why: AC-02/09/11/13(placeholder). Dependencies: 2–6. Risk: **LOW**.
8. **Analyze + format + gate** 
   - Action: `flutter analyze`, `dart format` archivos tocados, `flutter test test/widget/setup_flow_test.dart test/widget/initial_config_stepper_test.dart`; **presentar el flujo al usuario para validación** (M1 = prototipo navegable). No seguir a F2 sin OK (o feedback iterado aquí, antes de invertir en los pasos 2–5).
   - Why: milestone explícito del PRD. Dependencies: 7. Risk: **LOW**.

### Phase 2 — Decisiones visuales: tema, moneda, impresora (M2)

9. **Extracción de widgets reutilizables** (Files: `widgets/theme_picker.dart`, `widgets/profit_preview.dart`, `widgets/summary_row.dart`, `initial_config_page.dart`)
   - Action: copiar `_ThemePicker`/`_ThemeOptionCard` (L832–976), `_ProfitPreview` (L1099–1138, reemplazar `'sobre costo'` hardcodeado por `profitPreviewOverCost`), `_SummaryRow` (L1476+) a archivos públicos con nombres sin guion bajo (`ThemePicker`, `ThemeOptionCard`, `ProfitPreview`, `SummaryRow`); editar `initial_config_page.dart` para importarlos y borrar sus copias privadas; agregar `profitPreviewOverCost` a los 6 archivos l10n.
   - Why: **extracción ANTES de cualquier reescritura/borrado** — `initial_config_stepper_test` queda verde y prueba que la extracción no cambió comportamiento. Dependencies: ninguna. Risk: **LOW**.
10. **Paso 1 — `StyleCurrencyStep`** (Files: `steps/style_currency_step.dart`, `widgets/currency_chips.dart`, `widgets/currency_picker_sheet.dart`, l10n ×6)
    - Action: `ThemePicker` extraído arriba; `CurrencyChips` con sugeridas según `localeProvider` (mapa `AppLocale → [WorldCurrency, WorldCurrency]`: es→BOB, en→USD, ptBr→BRL, de/fr→EUR, usando `WorldCurrency.fromCode`), badge `setupCurrencySuggested`, "Ver más" → `showModalBottomSheet(useSafeArea, isScrollControlled)` con lista `WorldCurrency.all` (patrón de los sheets existentes en settings). Tap chip/sheet → `updateCurrency(code)` instantáneo. **Pre-selección**: al primer build del paso, si `settings.currencyCode == 'USD'` (default de fábrica) y el sugerido difiere → `updateCurrency(sugerido)`; flag local `_userTouchedCurrency` (UI-efímero) corta la auto-aplicación tras el primer tap explícito.
    - Why: AC-03. Dependencies: 9. Risk: **MEDIUM** (ambigüedad "pre-seleccionada vs. elección previa" — regla documentada arriba y cubierta por tests: locale es + currency USD ⇒ auto-BOB; tap USD antes de arrival ⇒ no se override).
11. **Presets destacados del catálogo** (File: `lib/features/onboarding/presentation/domain/featured_printer_presets.dart` + test unitario ligero en `setup_steps_test` o `test/unit/`)
    - Action: lista `const` de pares `(brand, model)` de ~8–12 modelos populares (Bambu Lab A1/A1 Combo/P1S/X1C, Creality Ender-3 V3/K1 Max, Anycubic Kobra 3, Photon Mono M7, Prusa MK4S, Elegoo Neptune 4 Pro — verificar nombres exactos contra `kPrinterCatalog` al implementar; cada par debe resolver `findModel() != null`). Helper `featuredPresets()` que resuelve watts + usefulLifeHours del catálogo.
    - Why: AC-04 sin grid de 208 modelos. Dependencies: ninguna. Risk: **LOW**.
12. **Paso 2 — `PrinterStep` + `PrinterPresetCard`** (Files: `steps/printer_step.dart`, `widgets/printer_preset_card.dart`, l10n ×6)
    - Action: al montar, observar `printersNotifierProvider`: si existe default → estado saved (nombre + "editar" → vuelve a grid, edición con `updatePrinter`); si no, grid de presets + tarjeta "Personalizada" (toggle → `PrinterCatalogSelector(brandController, modelController, wattsController, compact: true)` + `NumericInputField` watts; auto-create cuando brand+model+watts válidos y no creado aún — guard `_createdPrinterId`; cambios posteriores → `updatePrinter(id, ...)`) + TextButton `setupAddLater` ("Lo agrego después") → `onNext()`. Preset tap → `create(name: model, brand: brand, averageWatts: catalogWattsFor(...)!, usefulLifeHours: findModel(...)?.usefulLifeHours, asDefault: true)` + SnackBar `configPrinterSaved` + check en la card. Ticket preview ya refleja impresora (watch). Todo el manejo de "saving" es flag local UI; la persistencia es el notifier.
    - Why: AC-04/08. Dependencies: 3, 6, 11. Risk: **MEDIUM** (auto-create sin botón: cubrir con test de doble-tap y de "completar then editar"; validar con `printersNotifierProvider` state, no solo prefs).
13. **Tests Fase 2** (Files: `test/widget/setup_steps_test.dart`, `setup_flow_test.dart`)
    - Action: patrón `_pumpStepper` actual (drift `NativeDatabase.memory()`, `AppDatabase.forTesting`, physicalSize 800×2000) portado a `/setup`. Casos: tema tap persiste `themeMode`; moneda: (a) locale es + factory default ⇒ BOB auto-persistida al entrar a paso 1; (b) tap USD ⇒ persiste USD y no lo pisa el locale; (c) "Ver más" abre sheet con `WorldCurrency.all` y selección persiste; impresora: (a) preset crea default con watts/life del catálogo (assert DB row); (b) "Personalizada" completa ⇒ auto-create; (c) "lo agrego después" ⇒ avanza sin crear; (d) re-entrar con default existente ⇒ estado saved; no existen texts "Guardar"/"Siguiente" en el flujo (AC-07 grep-ish assertion).
    - Why: AC-03/04/07 + red de persistencia. Dependencies: 10, 12. Risk: **LOW**.
14. **Checkpoint** 
    - Action: analyze + format + `flutter test test/widget/setup_flow_test.dart test/widget/setup_steps_test.dart test/widget/initial_config_stepper_test.dart` (viejo aún verde). 
    - Dependencies: 13. Risk: **LOW**.

### Phase 3 — Filamento, ganancia y cierre (M3)

15. **Paso 3 — `FilamentStep`** (Files: `steps/filament_step.dart`, l10n ×6)
    - Action: `Wrap` de `ChoiceChip` con `kKnownFilamentBrands` (tap ⇒ controller brand) + chip "Otra" ⇒ `TextField` manual; `NumericInputField` precio (`label: filamentPrice(symbol)`, helper `setupFilamentPriceHint`, `allowDecimals: true`, validators migrados `_requiredNumber`/`_positiveIntegerGrams`); grams fijo 1000 (hidden o small field, decidir al implementar: hidden con default documentado = menos fricción); `FilamentColorField` (value/onChanged local). Auto-persist: marca no-vacía + precio Decimal > 0 válidos ⇒ `create(name: '${brand} 1000g', brand, pricePerBobbin, gramsPerBobbin: 1000, asDefault: true, color)` una vez (guard `_createdFilamentId`; ediciones posteriores ⇒ `updateFilament`); "Lo agrego después" ⇒ `onNext()`. Saved-state inicial desde `filamentsNotifierProvider` (AC-13).
    - Why: AC-05. Dependencies: 3, 6. Risk: **MEDIUM** (mismo patrón auto-create que impresora — reusar lecciones del test F2).
16. **Paso 4 — `ProfitStep`** (Files: `steps/profit_step.dart`, l10n ×6)
    - Action: slider `SliderTheme` grande 0–500, divisions 50, label en vivo; `NumericInputField` (allowDecimals: false) sincronizado bidireccional (slider→ctrl, ctrl→slider via double.tryParse solo para display); `ProfitPreview(value: sliderValue, color)` extraído debajo; persist: `onChangeEnd` y `onBlur` ⇒ `updateProfitBase(Decimal.fromInt(v.round()))` si cambió (initState precarga de `settingsNotifierProvider` como el actual: vacío si `Decimal.zero`). kWh: `ExpansionTile` collapsed mostrando `settingsKwhRate(symbol)` con default `kDefaultKwhRate`; expanded ⇒ slider 0–5 (div 50, allowDecimals) + input ⇒ `updateKwhRate(Decimal.tryParse(text.replaceAll(',', '.')))`. `SingleChildScrollView` por paso ya garantiza teclado-safe.
    - Why: AC-06. Dependencies: 9 (ProfitPreview), 3. Risk: **MEDIUM** (sincronía slider/input con Decimal — mantener `Decimal` como source of truth, `double` solo en el volado del slider con comment).
17. **Cierre — `SummaryStep`** (Files: `steps/summary_step.dart`, `widgets/summary_row.dart` ya extraído, l10n ×6)
    - Action: resumen ticket completo (`SummaryRow`s: moneda, tema, impresora nombre/"pendiente", filamento marca-color-precio/"pendiente", ganancia xN, kWh) leyendo providers + `Perforation` decorativa; celebración: `AnimatedScale`+`AnimatedOpacity` stagger de filas (Interval 0.1×i, 600 ms) + check grande — sin paquetes nuevos; `FilledButton` ancho `configStartButton` ("Empezar a cotizar") ⇒ **sin persistir profit/kwh de nuevo** (ya live-persisted) solo: `prefs.setBool(SettingsKeys.onboardingDone, true)` + `GoRouter.of(context)` `.go('/')` luego `await .push('/calculator')` (copiar comment del `_finish()` actual sobre stack limpio). 
    - Why: AC-07/10. Dependencies: 15, 16. Risk: **LOW**.
18. **Ticket preview completo + wiring onNext** (File: `widgets/ticket_preview_card.dart`, `setup_flow_page.dart`)
    - Action: completar filas del ticket (impresora/filamento/ganancia/kWh con "pendiente" → `setupTicketPending`); container pasa `onNext: () => _pageCtrl.animateToPage(_currentPage+1)` a pasos 2–3; refresh animación al cambiar página del ticket (AnimatedSize/switch).
    - Why: AC-08. Dependencies: 12, 15, 16. Risk: **LOW**.
19. **Tests Fase 3** (Files: `test/widget/setup_steps_test.dart`, `setup_flow_test.dart`)
    - Action: filamento: chips marca + precio ⇒ auto-create (assert DB, nombre auto, asDefault); skip ⇒ no crea; color se persiste; ganancia: slider ⇒ `updateProfitBase` (assert prefs/settings y `ProfitPreview` "x1.3"); input ⇒ mismo; kWh collapsed muestra default, expand + cambio ⇒ `updateKwhRate`; cierre: recorrer flujo completo paso 0→CTA ⇒ `onboardingDone=true`, ruta `/` + `/calculator` en el test router, sin `/setup` vivo en stack; AC-13: precargar prefs/DB (idioma en, printer default existente, profit 30) ⇒ al pump, paso 0 y pasos muestran estado pre-cargado; AC-14 text-scale: pump a 1.5× sin exceptions de overflow en pasos 3–4 (precaución con `tester.view.textScaleFactor`).
    - Why: AC-05/06/10/13. Dependencies: 15–18. Risk: **LOW**.
20. **Checkpoint** 
    - Action: analyze + format + suite nueva completa + `initial_config_stepper_test` (aún verde). Flujo completo funcional de punta a punta.
    - Dependencies: 19. Risk: **LOW**.

### Phase 4 — Limpieza y suite verde (M4)

21. **Borrado de páginas y rutas viejas** (Files: `initial_config_page.dart`, `language_selection_page.dart`, `onboarding_page.dart`, `app_router.dart`)
    - Action: **antes de borrar**, grep exhaustivo: `rg "InitialConfigPage|LanguageSelectionPage|OnboardingPage|/initial-config|/language|'/onboarding'" lib/ test/` → cada hit resuelto (router, splash comment, tests); borrar 3 pages; router: eliminar 3 `GoRoute` + 3 imports; splash: comment cleanup.
    - Why: AC-01. Dependencies: 9 (extracción completada), suite nueva verde (20). Risk: **MEDIUM** (huérfanos — el grep es la mitigación; AC-01 lo verifica).
22. **Baja de strings marketing + obsoletos** (Files: l10n ×6)
    - Action: `rg "onboardingTitle|onboardingDesc|onboardingPageCounter|onboardingNext|onboardingConfigure|onboardingStart|configTitle|configStep[123]Title|configStepSubtitle|configStepCounter|configContinue|configBack|configPrinterRequired|configFilamentOptional" lib/ test/` → eliminar del abstract + facade + EsImpl + 4 impls solo los que quedaron sin referencias (conservar `configStartButton`, `languagePageTitle/Subtitle`, y cualquier `config*` que el flujo nuevo reutilice — la lista de reusos está en Architecture Changes). `l10n_parity_test` debe pasar.
    - Why: AC-12. Dependencies: 21. Risk: **LOW** (grep antes de cada baja; el parity test valida los 5 impls).
23. **Ajuste wipe en settings** (Files: `settings_page.dart`, `test/widget/settings_page_test.dart`)
    - Action: redirect `go('/language')` → `go('/setup')` + comment; test: expectations L945/L988–989 → `/setup`, reason message update. Verificar caso "wipe fallido no resetea" intacto.
    - Why: AC-15. Dependencies: 21. Risk: **LOW**.
24. **Borrado/reescritura de tests viejos** (Files: `onboarding_flow_test.dart` BORRA, `initial_config_stepper_test.dart` BORRA, `language_selection_page_test.dart` BORRA)
    - Action: verificar que toda cobertura valiosa migra: marketing (descartado por PRD), stepper (cubierta en setup_steps_test), idioma (cubierta en setup_flow_test). Añadir cualquier caso faltante detectado al comparar con los archivos viejos antes de borrar (releerlos completos: 103 + 763 + ~126 líneas).
    - Why: AC-14. Dependencies: 21–23. Risk: **MEDIUM** (pérdida silenciosa de cobertura — checklist de casos viejos vs. nuevos antes del borrado).
25. **Verificación final** 
    - Action: `rg "'/language'|'/initial-config'|'/onboarding'" lib/ test/` ⇒ cero hits; `flutter analyze` (0 issues); `dart format` todos los tocados; **suite completa** `flutter test` en verde (incluye `router_guards_test`, `text_scale_test`, `paywall_navigation_test` sin cambios — solo setean el flag —, `printer_catalog_selector_test`, `brand_selector_field_test`, `l10n_parity_test`); revisión checklist de los 5 impls de strings nuevos; `flutter build web` (precedente del plan settings). Actualizar estado del flow (`state.js update` por fase completada).
    - Why: AC-14/12. Dependencies: 24. Risk: **LOW**.

## Dependencies

**Externas**: ninguna — sin red, sin paquetes nuevos (animaciones solo con SDK: `AnimatedContainer`, `TweenAnimationBuilder`, `AnimatedScale`/`AnimatedOpacity`; perforado reusando `Perforation` existente).

**Internas (orden crítico)**:
- Extracción de widgets (paso 9) **antes** de reescribir/borrar `initial_config_page.dart` (paso 21) — el stepper test viejo es la red de seguridad entre medias.
- Ruta `/setup` + splash (paso 2) en F1 para el gate de validación; borrado de rutas viejas recién en F4.
- Strings ×5 locales desde la fase donde se usan (nunca "dejo strings para después"); `l10n_parity_test` corre en cada fase.
- Tests nuevos crecen incrementalmente por fase; tests viejos se borran solo en F4 con checklist de migración de cobertura.
- Wipe redirect + su test se cambian juntos (paso 23).

## Risks

| # | Riesgo | Sev | Mitigación |
|---|---|---|---|
| R1 | **Regresión de persistencia** al reemplazar 1521 líneas (elecciones que "no se guardan") | HIGH | Notifiers llamados idénticos a hoy (`updateCurrency/updateProfitBase/updateKwhRate/setMode/create(asDefault:true)`); widget test por paso que asserta SharedPreferences + drift memory DB; saved-state leído de providers (AC-13) |
| R2 | **La "sincronía" visual no se siente** (dolor original del usuario) | HIGH | Animaciones concretas definidas en este plan (gradiente 400 ms easeInOut mapeado por paso, stagger 0.1×i, scale+check, ticket reactivo por Riverpod sin código extra); **gate M1 obligatorio antes de pulir pasos 2–5** |
| R3 | Doble-create de impresora/filamento (re-entrar al paso, doble tap, auto-create + edición) | MED | Guard once por step (`_createdId`), estado saved inicializado desde notifier, ediciones → `update*` con id; tests de doble-tap y re-entrada |
| R4 | PageView + teclado (NumericInputField pasos 3–4) overflow en web/chicas | MED | Cada paso en `SingleChildScrollView` + `MaxWidthScrollView`; `resizeToAvoidBottomInset` default; test con physicalSize 800×2000 y text-scale 1.5× |
| R5 | Pre-selección de moneda pisa elección explícita del usuario | MED | Regla determinista: solo auto-aplica si `currencyCode == 'USD'` de fábrica y flag `_userTouchedCurrency == false`; tests de los 2 órdenes (auto vs. tap previo) |
| R6 | Huérfanos: imports/rutas/strings de páginas borradas | MED | Grep exhaustivo antes y después de cada borrado (pasos 21–22, 25); `l10n_parity_test` + `flutter analyze` como red final |
| R7 | Pérdida de cobertura de tests al borrar los 3 archivos viejos | MED | Checklist de migración: releer archivos viejos completos y mapear cada caso a un test nuevo antes de borrar (paso 24) |
| R8 | Quitar impresora/filamento como requeridos rompe supuesto del calculador | LOW | Ya verificado a nivel de código (empty states en `calculator_bottom_bar` y `material_management`); prueba manual post-M2: cotizar sin catálogo |
| R9 | Auto-create sin botón percibido como bug ("se guardó solo") | LOW | SnackBar `configPrinterSaved`/`configFilamentSaved` + tarjeta saved con check + "editar"; feedback inmediato documenta la acción |
| R10 | Presets destacados con nombres que no casan exactos con `kPrinterCatalog` | LOW | Validación `findModel() != null` por cada par + test unitario que falla si el catálogo renombra un modelo |

## Estimated Complexity

**HIGH** — rewrite completo de un feature core de first-run: ~6 pages/pasos + ~10 widgets nuevos, extracción de 3 widgets de un archivo de 1521 líneas, router+splash+wipe, l10n ×6 archivos en 3 fases (altas) + 1 (bajas), reescritura de la suite del flujo (3 archivos viejos → 2 nuevos con cobertura equivalente o mayor).

Estimación: **3–5 días-equipo** (F1: 0.5–1 d incl. gate de usuario; F2: 1–1.5 d; F3: 1–1.5 d; F4: 0.5–1 d). ~2 000–2 500 líneas creadas, ~1 700 borradas. Cada fase es mergeable independiente (app funcional en todo punto: F1 ya entrega un flujo navegable, F2–F3 completan pasos, F4 solo limpieza).

## Testing Strategy

- **Unit**: `featured_printer_presets` (resolución `findModel`); `l10n_parity_test` (existente, corre siempre).
- **Widget nuevos**: `setup_flow_test.dart` (skeleton, swipe/pills/back, idioma instantáneo, sin "Guardar", stack limpio del finish, text-scale 1.5×) + `setup_steps_test.dart` (por paso: persistencia a prefs/DB, auto-creates con guards, pre-selección moneda, profit/kWh Decimal, reanudación AC-13). Harness: patrón actual del stepper test (`AppDatabase.forTesting(NativeDatabase.memory())`, prefs mock, `UncontrolledProviderScope`, viewport 800×2000).
- **Ajustados**: `settings_page_test.dart` (redirect wipe `/setup`).
- **Eliminados con migración verificada**: `onboarding_flow_test`, `initial_config_stepper_test`, `language_selection_page_test`.
- **Sin cambios (regresión pasiva)**: `router_guards_test`, `text_scale_test`, `paywall_navigation_test`, `printer_catalog_selector_test`, `brand_selector_field_test`.
- **Manual en gates**: M1 = experiencia de sincronía/animación con el usuario; M2 = "cotizar sin catálogo" tras skip; M4 = primera ejecución limpia en 5 locales + `flutter build web`.

## Success Criteria

- [ ] AC-01: `/language` e `/initial-config` no existen en router ni en ningún import (`rg` cero hits).
- [ ] AC-02/09/11: flujo navegable de ≤6 pantallas en una ruta, swipe+pills+back, gradiente AA por paso, idioma instantáneo persistido.
- [ ] AC-03: moneda pre-seleccionada por idioma + "ver más" + persistencia al tocar.
- [ ] AC-04/05: impresora y filamento skipeables; presets/auto-create persisten `asDefault:true`.
- [ ] AC-06: slider ganancia + preview vivo + kWh plegado, ambos persistidos con Decimal.
- [ ] AC-07: cero botones "Guardar"/"Siguiente"; única acción de cierre = "Empezar a cotizar".
- [ ] AC-08: ticket preview en pasos 1–4 refleja cada elección en la misma interacción.
- [ ] AC-10/15: finish con stack limpio idéntico a hoy; wipe reinicia en paso 0 preservando idioma/tema.
- [ ] AC-12: strings nuevos en abstract + 5 impls; marketing retirado de los 5 archivos; parity test verde.
- [ ] AC-13: kill+reopen ⇒ paso 0 con elecciones pre-cargadas.
- [ ] AC-14: `flutter analyze` limpio, `dart format` aplicado, suite completa en verde.
