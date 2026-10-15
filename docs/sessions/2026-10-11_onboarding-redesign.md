# Sesión 2026-10-11 — Rediseño del onboarding / configuración inicial — PAUSADO en Fase 4

**Estado**: Fases 1–3 COMPLETADAS + múltiples ciclos de validación con el dueño.
**Fase 4 (limpieza + suite verde) NO iniciada** (el dispatch se canceló: "PAREMOS ACA").
**Sin commit en todo el proyecto.**

## Qué se construyó

Reemplazo del first-run viejo (9 pantallas: /language + 5 slides marketing +
stepper /initial-config de 1521 líneas) por **una sola ruta `/setup`**:
PageView de 6 páginas (bienvenida+idioma, estilo+moneda, impresora, filamento,
ganancia+costos, cierre), barra nav Atrás/Siguiente con semáforo de
obligatoriedad, ticket preview colapsable, gradiente por paso (paleta mate AA:
#4E6E8C/#8E5F58/#567362/#706284), commit-on-navigate (persiste al navegar /
botón Guardar; sin auto-persistencia en tap de preset).

- **PRD**: `docs/prds/2026-10-11_1045-redesign-onboarding-flow.prd.md`
  (AC-04/05/07 actualizados: impresora+filamento OBLIGATORIOS con gate
  snap-back + SnackBar, nav Atrás/Siguiente permitida, nota de cambio de
  alcance 2026-10-11).
- **Plan**: `docs/plans/2026-10-11_1553-redesign-onboarding-flow.plan.md`
  (4 fases; gate M1 aprobado).
- **Estado flow**: `docs/state/plan-2026-10-11T19-34-40.json`
  (phase=3, completed=[0,1,2,3]).

## Archivos clave (feature-first)

- `lib/features/onboarding/presentation/pages/setup_flow_page.dart` —
  PageView, gate (printer null→máx pág 2, filament null→máx pág 3),
  `_goToPage` async con `commitDraft()` antes del gate, NotificationListener
  (swipe = commit fire-and-forget), PopScope, `_buildNavBar` (keys
  `setup-nav-back/next`), ticket preview págs 1–4.
- `pages/steps/`: `welcome_language_step`, `style_currency_step`,
  `printer_step` (PrinterStepState + commitDraft; colapsable "Impresoras
  populares" con 10 presets; form Personalizada con "Otros datos (opcional)"
  envuelto en `Material(transparency)`), `filament_step` (FilamentStepState +
  commitDraft; chips de marca SetupChip + "Otro..."; nombre opcional
  auto-generado `'${brand} ${grams}g'`), `profit_step` (cards EXPANDIDAS,
  valores ejemplo al primer arranque + ⓘ Tooltip, sliders + Decimal),
  `summary_step` (CTA `configStartButton` → onboardingDone + go('/') +
  push('/calculator')).
- `widgets/`: `setup_chip` (AA), `ticket_preview_card` (colapsable),
  `currency_chips`, `printer_preset_card`, `progress_pills`, `theme_picker`,
  `profit_preview` (huérfano, se borra en F4), `summary_row`.
- `domain/featured_printer_presets.dart` (10 presets, findModel validados).
- l10n ×6: altas de todos los strings `setup*` (Next/Back, NeedPrinter/
  Filament, ProfitTitle "Tu margen y costos", ExampleValuesHint, etc.); bajas
  hechas: `setupAddLater`, `setupCurrencySuggested`; pendiente F4: marketing
  `onboardingTitle1..5/Desc1..5/onboardingStart`.
- **In-app copiado**: `printer_form_page.dart` + `filament_form_page.dart`
  rehechos con el patrón del setup (colapsable presets, chips, "Otros datos");
  guardado múltiple intacto; tests 17/17.
- `settings_page.dart`: wipe redirect → `context.go('/setup')` (+ test).

## Verificación al cierre

- `flutter analyze`: 0 issues · `dart format` aplicado.
- Última suite conocida completa: **58/58** (tras nav Atrás/Siguiente);
  posteriores cambios (commit-on-navigate, profit header, paleta mate,
  forms in-app) dejaron **~7 tests desactualizados** en
  `setup_steps_test.dart` (~L367/422/545/596/767/850) y
  `setup_flow_test.dart` (~L494) — patrón de arreglo: disparar el commit
  navegando (Siguiente/swipe) o tocando Guardar, luego assert.
- `initial_config_stepper_test.dart` era la rojo de seguridad (intacto; se
  borra junto con el stepper en F4).

## Pendiente al retomar (Fase 4)

1. Arreglar los ~7 tests desactualizados de setup (patrón arriba).
2. Borrar `/language`, `/onboarding`, `/initial-config` del router
   (`app_router.dart` imports ~L17-19 + GoRoutes ~L75-83) y las páginas
   `language_selection_page.dart`, `onboarding_page.dart`,
   `initial_config_page.dart` (grep de referencias antes).
3. Borrar `profit_preview.dart` si queda huérfano.
4. Bajas de strings marketing ×6 l10n (grep antes).
5. Borrar tests viejos con tabla de migración de cobertura:
   `language_selection_page_test`, `onboarding_flow_test`,
   `initial_config_stepper_test`.
6. Suite COMPLETA `flutter test` + `flutter build web` + `state.js complete`.

## Reglas del proyecto (recordatorio)

Decimal dinero · setState UI-local con // BUG-006 · comentarios español /
código inglés · sin red · **sin commit sin verbo explícito del dueño** ·
NO correr `dart format --line-length 100` (repo va a 80).
