---
prd: docs/prds/2026-07-16_1754-design-system-overhaul.prd.md
status: DRAFT
created: 2026-07-16_1758
---

# Implementation Plan: Design System Overhaul (3dCal v2)

## Overview

Aplicar la segunda ola de mejoras al design system de 3dCal sobre la base
ya mergeada de `refactor/frontend-polish-v2` (commit `43d534e`). El PRD
define 24 acceptance criteria agrupados en 6 areas; este plan los organiza
en 6 milestones ejecutables, cada uno mergeable de forma independiente y
verificable contra ACs del PRD.

> **Scope discipline**: lo que ya esta hecho (tokens `AppSpacing`/`AppRadii`,
> 8 shared widgets, `MaxWidthScrollView`, i18n parcial, `Semantics` base)
> NO se re-planifica. Empezamos en lo que falta (seccion "Lo que FALTA" del PRD, lineas 27-32).

## Requirements (del PRD)

- Theme M3 nativo con `ColorScheme.fromSeed` + ajustes tonales.
- Tipografia con Google Fonts (Inter + JetBrains Mono) con jerarquia completa.
- Migrar ~40 literales de spacing/radii a `AppSpacing`/`AppRadii`.
- A11y WCAG 2.2 AA: touch 48dp, contraste 4.5:1, focus visible, Semantics.
- Responsive: `AppBreakpoints` + maximos web sensatos, sin overflow a 320dp.
- Quality gates: `dart analyze` clean, tests pasan, bundle web ≤2.5MB.

## Architecture Changes (resumen por milestone)

- **M1**: reescribir `_buildTheme` en `app_theme.dart` para consumir
  `surfaceContainer*`; eliminar `_lightSurfaceBg`/`_lightCardBg` privados.
- **M2**: nuevo `app_typography.dart`; agregar `google_fonts: ^6.x` a
  `pubspec.yaml`; aplicar `FontFeature.tabularFigures()` en widgets monetarios.
- **M3**: refactor mecanico de literales en features/widgets.
- **M4**: extender API de 14 shared widgets con `semanticLabel` +
  `TouchTargetEnforcer` + focus rings; nuevos widgets (W1, W3, W4, W7, W8, W9).
- **M5**: nuevo `app_breakpoints.dart`; consumir en `AppScaffold` y `home_page`.
- **M6**: sin cambios de codigo; verificacion + report artifact.

## Implementation Steps

### Phase 0: Branch & Sanity (pre-M1)

0.1. **Crear rama** desde `main` (post-merge polish-v2).
- Action: `git checkout -b refactor/design-system-v2 main`
- Why: trabajar en aislamiento, sin pisar a `main` ni al branch v2.
- Risk: Bajo. Bloqueante si polish-v2 no esta mergeado (PRD-R7).

0.2. **Smoke test baseline**.
- Action: `flutter analyze` + `flutter test` → registrar cuenta exacta de
  errores/warnings y de tests passed/failed (target: 101 passed + 17 pre-existing
  failures segun PRD AC-021/022).
- Why: medir delta por milestone; no degradar.
- Risk: Bajo.

### Phase 1: Milestone M1 — Theme M3 nativo (AC-001, AC-002, AC-003, AC-004)

**Objetivo**: reescribir `AppTheme` para usar `ColorScheme.fromSeed` puro
+ `surfaceContainer*` family, sin overrides literales innecesarios.

**Archivos a tocar**:
- `lib/core/theme/app_theme.dart` (rewrite de `_buildTheme`, eliminar
  `_lightSurfaceBg` / `_lightCardBg` privados, ajustar referencias a
  `colorScheme.surfaceContainer` / `surfaceContainerLow` / `surfaceContainerHigh`).
- (opcional) `lib/main.dart` → precargar `ColorScheme` para evitar flicker
  inicial (AC-004).
- (opcional) `docs/audits/2026-07-16_dark-contrast-audit.md` → captura
  de auditoria luminancia light+dark (AC-003).

**Acceptance criteria**:
- AC-001: 0 `Color(0xFF...)` literales fuera de `app_theme.dart`.
- AC-002: `scaffoldBackgroundColor` + `cardTheme.color` + `dialogTheme.backgroundColor`
  + `bottomSheetTheme.backgroundColor` derivan de `surfaceContainer*`.
  ≤5 usos justificados de `withValues(alpha:...)` en features/shared.
- AC-003: dark mode parity visual (captura + calculo luminancia).
- AC-004: theme mode persistido sin flicker (<100ms transicion).

**Dependencias**: ninguna. Bloquea M2 (tipografia) y M3 (literales).

**Effort**: **M** (~3-4h). Tarea concentrada en 1 archivo de 290 lineas;
el resto del codigo consume el theme via `Theme.of(context)`, no requiere
cambios si los tonos M3 son razonables.

**Riesgo principal**: **R1 visual regression** (cambiar surface afecta
cards, dialogs, bottom sheets en las 5 pages). Mitigacion: commit aislado,
captura side-by-side de las 5 pages en light+dark antes/despues (no
bloqueante, va al report final).

**Quick wins adentro de M1** (lanzables inmediatamente):
- QW1.1: eliminar `secondary:` / `tertiary:` explicitos en
  `ColorScheme.fromSeed` y dejar que M3 derive del seed (15 min, valida
  el approach antes del rewrite completo).
- QW1.2: cambiar `scaffoldBackgroundColor` de `_lightSurfaceBg` literal
  a `colorScheme.surfaceContainerLow` (1 linea, ya muestra delta).

---

### Phase 2: Milestone M2 — Typography (AC-005, AC-006, AC-007)

**Objetivo**: tipografia con personalidad (Inter para UI, JetBrains Mono
para valores numericos/BOB) + jerarquia completa + tabular figures en
todos los montos.

**Archivos a tocar**:
- `pubspec.yaml` → agregar `google_fonts: ^6.2.1` en `dependencies`.
  Bloqueante si falla R2 (bundle) o R8 (offline build) → mitigation: pin
  versiones + precomputar `TextTheme` en `main.dart` con
  `GoogleFonts.config.allowRuntimeFetching = false` + descargar assets en
  build script (`flutter pub run google_fonts:download`).
- `lib/core/theme/app_typography.dart` (NUEVO) → encapsula
  `AppTypography.light()` y `AppTypography.dark()` con los 15 estilos
  (displayLarge..labelSmall). Consume `GoogleFonts.interTextTheme()` y
  `GoogleFonts.jetBrainsMono()` para estilos que renderizan montos.
- `lib/core/theme/app_theme.dart` → reemplazar `_buildTextTheme` por
  delegacion a `AppTypography.light()` / `AppTypography.dark()`.
- Widgets con montos → agregar `fontFeatures: [FontFeature.tabularFigures()]`:
  - `lib/shared/widgets/money_row.dart`
  - `lib/shared/widgets/stat_tile.dart`
  - `lib/features/calculation/presentation/pages/calculation_detail_page.dart`
  - `lib/features/dashboard/presentation/pages/dashboard_page.dart`
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart`
- `lib/features/dashboard/presentation/widgets/profit_bar_chart.dart` →
  valores BOB del chart usan `JetBrains Mono` via `TextStyle` override.
- `lib/features/calculation/presentation/notifiers/calculator_notifier.dart` →
  resolver Q7: labels `'Filamento'`, `'Material'` → `EsBO.*` (mismo paquete i18n).
- (opcional) `lib/l10n/es_bo.dart` → agregar constantes si faltan.

**Acceptance criteria**:
- AC-005: `AppTypography` con 15 estilos; 0 `fontSize: N` literales fuera
  de `app_theme.dart` y `app_typography.dart`.
- AC-006: 100% de widgets monetarios usan `FontFeature.tabularFigures()`.
- AC-007: jerarquia visual consistente (auditoria grep por tamano de uso).

**Dependencias**: M1 (theme ya estable). No bloquea M3 en strict (literales
se pueden migrar antes que typography) pero logical order es M1 → M2 → M3.

**Effort**: **L** (~5-7h). El grueso es: configurar google_fonts sin romper
offline + escribir 15 estilos + walk por 5-7 archivos para tabular figures
+ smoke test del bundle.

**Riesgo principal**: **R2 bundle web >2.5MB**. Si Inter + JetBrains Mono
agregan >300KB, replantear → fallback a opcion B del PRD (MountainView refinado).
Verificar con `flutter build web --release --analyze-size` (AC-023).

**Quick wins adentro de M2** (lanzables inmediatamente, sin esperar M1):
- QW2.1: agregar `fontFeatures: [FontFeature.tabularFigures()]` en
  `MoneyRow` (1 archivo, 1 cambio, 5 min) → BOB alinean inmediatamente.
  Esto se puede hacer ANTES de M1 sin conflictos.
- QW2.2: resolver Q7 (labels `Filamento`/`Material` a `EsBO`) en
  `calculator_notifier.dart` (1 archivo, ~10 min).

---

### Phase 3: Milestone M3 — Token compliance (AC-008, AC-009, AC-010)

**Objetivo**: cero literales de spacing/radii en features/shared/widgets;
todo consumo via `AppSpacing` / `AppRadii`.

**Archivos a tocar** (~40 sitios, agrupados por concern para commits chicos):
- `lib/features/calculation/presentation/pages/calculator_page.dart`
- `lib/features/calculation/presentation/pages/calculations_list_page.dart`
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart`
- `lib/features/calculation/presentation/pages/home_page.dart`
- `lib/features/catalog/filaments/presentation/pages/filaments_page.dart`
- `lib/features/catalog/filaments/presentation/pages/filament_form_page.dart`
- `lib/features/catalog/printers/presentation/pages/printers_page.dart`
- `lib/features/catalog/printers/presentation/pages/printer_form_page.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/features/dashboard/presentation/widgets/profit_bar_chart.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- 14 archivos en `lib/shared/widgets/` (revisar uno por uno).
- (opcional) `lib/core/theme/app_theme.dart` → ya consume tokens, verificar
  que `cardPadding`, `EdgeInsets.symmetric(horizontal: 16, vertical: 14)`
  del `inputDecorationTheme.contentPadding` se migre a `AppSpacing.lg` +
  valor custom (no documentado en escala; documentar inline).

**Estrategia de ejecucion**: PR por feature (catalog, history, dashboard,
settings, calculation), NO big-bang. Cada PR es un concern.
- Commit pattern: `refactor(tokens): migrate calculator_page to AppSpacing`
- Por cada archivo: grep primero, contar literales, mapear
  `EdgeInsets.symmetric(all: N)` → `AppSpacing.{token}`, `BorderRadius.circular(N)` → `AppRadii.{token}`.

**Acceptance criteria**:
- AC-008: grep `EdgeInsets.(all|symmetric|only|fromLTRB)\([^A]` retorna
  solo matches donde N no es token valido.
- AC-009: grep `BorderRadius.circular\([0-9]` fuera de `app_radii.dart`
  ≤ 3 matches (bottom sheet + casos justificados).
- AC-010: 0 `EdgeInsets.all(20|24)` en features/shared.

**Dependencias**: M1 + M2 (theme + typography estables; asi los tokens
que se aplican no son reescritos al toque).

**Effort**: **L** (~6-8h). Es trabajo mecanico pero ~40 sitios + 14 widgets
+ verificacion grep exhaustiva. Estimacion no incluye re-builds.

**Riesgo principal**: **R6 typos/regresiones en masa**. Mitigacion: PR
por feature, grep pre-commit, correr `flutter test` despues de cada PR,
no mezclar con otros milestones en un mismo commit.

**Quick wins adentro de M3** (lanzables antes que el grueso):
- QW3.1: migrar `lib/features/calculation/presentation/pages/calculator_page.dart`
  (~15 sitios, 1 archivo, ~20 min) → ya es la page mas visible, muestra
  consistencia inmediata.
- QW3.2: auditar y migrar los 14 widgets de `lib/shared/widgets/`
  (~30 sitios, ~45 min) → al estar centralizados, propagan visual
  al resto apenas se importen.

---

### Phase 4: Milestone M4 — A11y WCAG 2.2 AA minimo (AC-011, AC-014, AC-015, AC-016)

**Objetivo**: touch targets ≥48dp, focus visible en web, Semantics en
chart y errores de form, extender API de widgets con `semanticLabel`.

**Archivos a tocar**:
- `lib/shared/widgets/app_scaffold.dart` → focus ring en
  `NavigationBar`/`NavigationRail` destinations (ya tienen focus de M3
  por default, validar).
- 14 shared widgets → agregar parametro opcional `semanticLabel: String?`
  (forwarded a `Semantics` o `MergeSemantics`). Defaults razonables por
  widget (no rompe API actual).
- `lib/shared/widgets/icon_button.dart` (NUEVO si no existe; alternativa:
  wrapper `TouchTargetEnforcer` W6 del PRD-Q4) → garantiza 48x48dp real
  via `MaterialTapTargetSize.padded` o `ConstrainedBox` adicional.
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart`
  → envolver `IconButton` con `size: 16-20` en wrapper 48dp.
- `lib/features/dashboard/presentation/widgets/profit_bar_chart.dart` →
  `Semantics(label: '...', child: ExcludeSemantics(child: chart))` (R4
  mitigation del PRD).
- `lib/shared/widgets/numeric_input_field.dart` → errores envueltos en
  `Semantics(liveRegion: true, child: ...)` para announcement a screen reader.
- `lib/features/calculation/presentation/pages/home_page.dart` →
  `_QuickActionCard` → usar nuevo widget `FocusableActionCard` (W9 del PRD-Q4)
  con focus ring.
- 6 widgets nuevos (W1, W3, W4, W7, W8, W9 del PRD-Q4):
  - `lib/shared/widgets/app_text_input.dart` (W1) — hermano text-only
    de `NumericInputField`.
  - `lib/shared/widgets/key_value_row.dart` (W3) — generico label+value.
  - `lib/shared/widgets/info_banner.dart` (W4) — callout info/warning/error.
  - `lib/shared/widgets/responsive_layout.dart` (W7) — LayoutBuilder +
    breakpoints const.
  - `lib/shared/widgets/error_announcer.dart` (W8) — helper live region.
  - `lib/shared/widgets/focusable_action_card.dart` (W9) — Card tappable
    con focus ring.
- 1 widget en `test/widget/` por cada uno nuevo (smoke test basico).

**Acceptance criteria**:
- AC-011: 14 widgets aceptan `semanticLabel` opcional sin romper API.
- AC-014: todo widget tappable ≥48dp (auditoria `IconButton`).
- AC-015: focus ring visible en web (validar con Playwright si esta
  configurado, sino manual).
- AC-016: `Semantics` en chart + `liveRegion` en errores de form.
- (P1) AC-012: 20 widgets en `lib/shared/widgets/`, smoke test por
  cada uno nuevo, usado en ≥1 sitio real.

**Dependencias**: M3 (tokens ya migrados; no aplicar spacing literals
nuevos en M4). W7 (ResponsiveLayout) anticipa M5, pero el widget en si
es independiente.

**Effort**: **L** (~6-8h). Mucho del trabajo es mecanico (agregar
parametro + Semantics wrap) pero hay 6 widgets nuevos que requieren
diseño de API + tests.

**Riesgo principal**: **R5 romper layouts con touch enforcement** en
`calculation_detail_page` (chips con `size: 14`). Mitigacion: wrapper
solo en `IconButton`/`ActionChip`, NO en `Text` icons. Probar visualmente
cada lugar donde se aplica.

**Quick wins adentro de M4** (lanzables independientemente):
- QW4.1: agregar param `semanticLabel` opcional a los 5 widgets mas
  usados (`StatTile`, `SectionCard`, `MoneyRow`, `SectionHeader`,
  `AvatarIcon`) — 5 archivos, refactor mecanico, no rompe callers.
- QW4.2: `Semantics(liveRegion: true)` en `NumericInputField` error text
  (1 archivo, 5 min) — feedback inmediato para screen reader users.

---

### Phase 5: Milestone M5 — Responsive avanzado (AC-018, AC-019, AC-020)

**Objetivo**: breakpoints centralizados en `AppBreakpoints`; web usa
ancho completo (1024 detail, 1280 dashboard); sin overflow a 320dp.

**Archivos a tocar**:
- `lib/core/theme/app_breakpoints.dart` (NUEVO) — constantes
  `mobile = 600`, `tablet = 1024`, `desktop = 1280`, `wide = 1600` (opcional).
  Helper `AppBreakpoints.of(context)` retorna `BreakpointBucket` enum.
- `lib/shared/widgets/app_scaffold.dart` → reemplazar literales
  `width < 600`, `width < 1024`, `width >= 1280` por `AppBreakpoints`.
- `lib/features/calculation/presentation/pages/home_page.dart` → mismo
  reemplazo si tiene breakpoints hardcoded.
- `lib/shared/widgets/max_width_scroll_view.dart` → aceptar param
  `maxWidth: double?` (default ya era 720); updatear callers:
  home 960, calculator 720, calculation_detail 1024, dashboard 1280,
  settings 720. (Esto cubre AC-019.)
- 7 paginas que ya usan `MaxWidthScrollView` → ajustar el max width
  segun la tabla de AC-019.
- Auditoria visual a 320x568 (iPhone SE 1st gen) en las 5 pages →
  fix overflows puntuales. (Cubre AC-020.)

**Acceptance criteria**:
- AC-018: 0 matches `width (>=|>) [0-9]{3,4}` fuera de `AppBreakpoints`.
- AC-019: `MaxWidthScrollView` con max widths segun tabla.
- AC-020: 0 `RenderFlex overflowed` a 320dp en las 5 pages.

**Dependencias**: ninguna estricta. W7 (ResponsiveLayout) de M4 ya existe,
M5 lo consume. Puede ir paralelo a M4.

**Effort**: **M** (~3-4h). Trabajo concentrado; el grueso es la
auditoria visual a 320dp y 1920x1080 (manual).

**Riesgo principal**: bajo. Los breakpoints ya estaban cerca, solo se
centralizan. El fix de overflows a 320dp puede encontrar issues que
toquen concerns de M4 (touch targets), planificar fix combinado.

**Quick wins adentro de M5** (lanzables independientemente):
- QW5.1: crear `app_breakpoints.dart` + consumir en `app_scaffold.dart`
  (2 archivos, 30 min) — ya es un cleanup visible.
- QW5.2: extender `MaxWidthScrollView` con param `maxWidth` opcional
  (1 archivo, 15 min) — backward compatible, no rompe callers.

---

### Phase 6: Milestone M6 — Quality gates (AC-021, AC-022, AC-023, AC-024)

**Objetivo**: deliverables de verificacion, no de codigo. Confirmar
gates y producir report artifact.

**Tareas**:
- Correr `flutter analyze` → target `No issues found!`. Fix cualquier
  nuevo warning introducido por M1-M5. (No bajar la cuenta de errores
  pre-existentes si los hay, pero no aumentar.)
- Correr `flutter test` → confirmar `101 passed + 17 pre-existing failures`
  (cuenta del baseline Phase 0.2). Tests nuevos de widgets v2 en verde.
- Correr `flutter build web --release` → medir bundle size. Si >2.5MB,
  documentar en report y abrir sub-tarea (probable causa: M2 google_fonts).
- `git diff main..HEAD -- pubspec.yaml` → verificar que solo agrega
  `google_fonts: ^6.x` (o ninguno si Q1=B).
- Capturas side-by-side de las 5 pages (home, calculator, history,
  settings, dashboard) en light+dark × mobile+web = 4 capturas por
  page = 20 capturas. Guardar en `docs/audits/2026-07-16_1758-design-system-overhaul/`.
- Escribir `docs/reports/2026-07-16_1758-design-system-overhaul.report.md`
  con: AC checklist (24/24), screenshots, size budget, test counts,
  analyze output, commit log resumido.

**Acceptance criteria**:
- AC-021: 0 errors, 0 warnings en `lib/`.
- AC-022: tests pasan en la cuenta del baseline o mejor.
- AC-023: bundle web <2.5MB.
- AC-024: `pubspec.yaml` diff limpio.

**Dependencias**: M1-M5 todos cerrados (en main o en la rama del PRD).

**Effort**: **S-M** (~2-3h). Sin codigo, puro verify + report.

**Riesgo principal**: **R1 visual regression descubierta en M6**. Si
pasa, abrir sprint de fix antes de merge. Mitigacion: hacer captura
side-by-side ANTES de empezar M1 (baseline) y comparar en M6.

---

## Dependencias entre milestones (DAG)

```
M1 (Theme) ──┬──> M2 (Typography) ──┐
             │                      ├──> M3 (Tokens) ──┬──> M4 (A11y)  ──┐
             │                      │                  │                    ├──> M6 (Gates)
             │                      │                  └──> M5 (Responsive)─┘
             │                      │                  (M4 ∥ M5 en paralelo)
             │                      │
             └──> M0.1 branch ──────┘
```

- **M1 bloquea M2 y M3**: cambiar theme antes de tocar typography/literals.
- **M2 no bloquea M3 estrictamente** (QW2.1 + QW2.2 pueden ir antes
  que M1), pero logical order es M1 → M2 → M3.
- **M3 bloquea M4**: no agregar nuevos literales cuando ya estamos
  auditando los existentes.
- **M4 y M5 en paralelo** despues de M3: son ortogonales.
- **M6 al final**: gate de todo.

**Critical path**: M1 → M2 → M3 → M4 → M6 (≈20-26h).
**Parallelizable**: M5 puede ir con M4 (ahorra 3-4h).
**Quick wins absorbed en milestones**: ver seccion siguiente.

## Quick wins top 3 (lanzables HOY sin esperar milestones completos)

1. **QW2.1** — `fontFeatures: [FontFeature.tabularFigures()]` en
   `lib/shared/widgets/money_row.dart` (5 min).
   - Impacto: todos los BOB del app alinean en columna inmediatamente.
   - Riesgo: nulo (cambio aditivo, backward compatible).
   - Cubre: AC-006 (parcial — el primer archivo).

2. **QW3.1** — Migrar `lib/features/calculation/presentation/pages/calculator_page.dart`
   a `AppSpacing`/`AppRadii` (~20 min, ~15 sitios).
   - Impacto: la page mas visible del app gana consistencia de spacing/radii.
   - Riesgo: bajo (mecanico, facil de revertir si rompe layout).
   - Cubre: AC-008 + AC-009 (parcial — el primer archivo).

3. **QW4.1** — Agregar `semanticLabel: String?` opcional a 5 widgets
   mas usados: `StatTile`, `SectionCard`, `MoneyRow`, `SectionHeader`,
   `AvatarIcon` (~30 min total, refactor mecanico).
   - Impacto: API mas rica para a11y, no rompe callers existentes.
   - Riesgo: bajo (param opcional).
   - Cubre: AC-011 (parcial — los 5 widgets mas usados).

**Total quick wins**: ~55 min, 0 dependencias, alto impacto visual/UX
percibido. **Recomendacion**: ejecutar los 3 antes de empezar M1, asi
el primer commit del milestone v2 ya muestra progreso tangible.

## Top 3 riesgos con mitigacion

1. **R1 — Visual regression** (Likelihood: High, Impact: High).
   Cambiar theme M3, tipografia, spacing en 14 widgets compartidos puede
   romper pages que hoy se ven OK. `flutter analyze` no detecta esto.
   **Mitigacion**: capturas side-by-side ANTES de empezar (baseline en
   `docs/audits/2026-07-16_1758-design-system-overhaul/baseline/`) y
   DESPUES de cada milestone. Commit por concern (1 widget / 1 page / 1
   token category), NUNCA big-bang. Si se detecta regresion en M6, abrir
   sprint de fix antes de merge.

2. **R2 — Google Fonts bundle >2.5MB web** (Likelihood: Medium,
   Impact: Medium). Inter + JetBrains Mono + es_BO subset ≈ 150-300KB
   raw, pero tree-shaking de Flutter web puede inflar mas. **Mitigacion**:
   - Precomputar `TextTheme` en `main.dart` con
     `GoogleFonts.config.allowRuntimeFetching = false`.
   - Medir con `flutter build web --release --analyze-size` en M2.
   - Si >2.5MB: fallback a opcion B (MountainView refinado sin deps).
   - Documentar en report M6.

3. **R6 — Migracion masiva introduce typos/regresiones** (Likelihood:
   High, Impact: Medium). ~40 sitios con literales a migrar. **Mitigacion**:
   - PR por feature (catalog, history, dashboard, settings, calculation),
     NO un solo PR.
   - `grep -rE "EdgeInsets\.(all|symmetric|only|fromLTRB)\([^A]" lib/`
     pre-commit en cada PR.
   - `flutter test` despues de cada PR (cuenta del baseline no puede bajar).
   - Code review obligatorio antes de merge de cada PR de M3.

## Suggested execution order (timeline indicativo)

| Dia | Manana | Tarde |
|-----|--------|-------|
| **D1** | Phase 0 (branch + baseline) | M1 + quick wins (QW2.1, QW3.1, QW4.1) |
| **D2** | M1 commit + capturas | M2 typography + bundle test |
| **D3** | M3 catalog + history | M3 dashboard + settings + calculation |
| **D4** | M4 shared widgets (semanticLabel + 6 nuevos) | M4 a11y integrations + M5 en paralelo |
| **D5** | M5 responsive + 320dp audit | M6 verify + report |

Total: ~5 dias, 1 desarrollador. Compatible con el "commits chicos"
del polish-v2 (1 concern = 1 commit).

## Testing Strategy

- **Unit tests**: nuevos widgets W1, W3, W4, W7, W8, W9 (1 smoke test
  por widget, `test/widget/{name}_test.dart`).
- **Widget tests existentes**: confirmar que los 14 widgets ya
  cubiertos no rompen tras M3 (literales) y M4 (semanticLabel).
- **Integration**: `test/integration/full_flow_test.dart` debe pasar
  tras M1 (theme no rompe flujos), M2 (typography no rompe renders),
  M3 (tokens no rompen layouts).
- **A11y**: manual + Playwright si esta configurado. Si no, screenshot
  con TalkBack/VoiceOver habilitado en emulador Android y validar
  que se anuncian labels.
- **Visual regression**: opcional. Si Q5=SI, agregar golden files para
  5 pages × 2 modes × 2 viewports = 20 golden files. Si Q5=NO, capturas
  manuales en `docs/audits/.../`.
- **Bundle size**: `flutter build web --release --analyze-size` en M2
  y M6 (2 mediciones).
- **Coverage**: se mantiene % actual (no se exige subir, no se permite
  bajar segun PRD constraint).

## Success Criteria

- [ ] M1: 0 `Color(0xFF...)` literales fuera de `app_theme.dart`; dark
      mode parity auditado.
- [ ] M2: 15 estilos en `AppTypography`; 100% de widgets monetarios con
      `tabularFigures()`; bundle web <2.5MB.
- [ ] M3: 0 literales de spacing/radii en features/shared/widgets (con
      ≤3 excepciones documentadas).
- [ ] M4: 20 widgets en `lib/shared/widgets/` (14 refactored + 6 nuevos);
      touch targets ≥48dp; focus ring visible; Semantics en chart + errores.
- [ ] M5: 0 breakpoints hardcoded fuera de `AppBreakpoints`; 0 overflows
      a 320dp en las 5 pages.
- [ ] M6: `flutter analyze` clean, tests baseline o mejor, bundle <2.5MB,
      report escrito en `docs/reports/2026-07-16_1758-design-system-overhaul.report.md`.
- [ ] Branch `refactor/design-system-v2` mergeado a `main` con PR
      descriptivo + capturas + changelog.
