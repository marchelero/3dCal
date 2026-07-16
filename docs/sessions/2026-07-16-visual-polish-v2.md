# 2026-07-16 - Visual Polish v2 (AppSnackBar + final state)

## Status

- **main**: post-merge --no-ff de `feature/visual-polish-v2`
- **Push**: OK a `origin/main`
- **Branch `feature/visual-polish-v2`**: borrada
- **Working tree**: clean

## Round Visual Polish v1+v2 (mismo dia, dos merges --no-ff)

### v1 (e49bdc1) - flash visual gordo
- V1 hero monetary totals: displaySmall (36sp) → displayMedium (45sp) + FittedBox (calculator)
- V1 detail total: headlineSmall (24sp) → headlineMedium (28sp) + FittedBox (calculation_detail)
- V2 EmptyView: 80→96dp, icon 36→48dp, titleMedium→titleLarge+w600
- V3 SectionHeader: nuevo Container surfaceContainerHighest + outlineVariant border + AppRadii.md + padding lg/md

### v2 (este merge) - feedback semantico
- V4 AppSnackBar widget: 4 factories (success/error/warning/info)
  - success: check_circle + verde + 2s
  - error: error + rojo + 4s
  - warning: warning_amber + amarillo + 3s
  - info: info + colorScheme.primary + 2s (requires context)
  - SnackBarBehavior.floating + AppRadii.md shape
- 7 call sites migrados:
  - calculator_page: 4 (1 warning, 1 success, 2 error)
  - settings_page: 1 success
  - printer_form_page: 1 error
  - filament_form_page: 1 error

## Validacion

- `flutter analyze` full: 93 issues, todos `info` pre-existentes (`public_member_api_docs`), 0 errors/warnings nuevos
- `flutter analyze` app_snack_bar.dart: 0 issues
- Bundle sin cambio (V4 reusa M2 typography)
- FittedBox.scaleDown evita overflow con numeros largos (V1)
- SnackBar duration y text identicos a antes, solo cambia visualizacion

## Total del dia (m0096 → ahora)

| Round | Commits | Resultado |
|-------|---------|-----------|
| Design System Overhaul M1+M2 | 8 | Theme M3 + Inter + JetBrains Mono (foundation invisible) |
| Visual Polish v1 | 3 + merge | V1+V2+V3 visibles (hero text, empty, headers) |
| Visual Polish v2 | 2 + merge | V4 AppSnackBar feedback semantico |

## Pendiente (M3-M6, ~17-23h)

| # | Milestone | Effort | ACs |
|---|-----------|--------|-----|
| M3 | Token compliance (~40 literales) | L (~6-8h) | 008-010 |
| M4 | A11y WCAG 2.2 AA (touch 48dp, focus, Semantics) | L (~6-8h) | 011, 014-016, 012 |
| M5 | Responsive (AppBreakpoints + max widths + 320dp audit) | M (~3-4h) | 018-020 |
| M6 | Quality gates (analyze, tests, bundle ≤2.5MB) | S-M (~2-3h) | 021-024 |

Critical path: M3 → M4 → M6. M5 puede ir en paralelo a M4.

## V5+ ideas (visual polish continuation, opcional)

- V5 Loading states (skeleton placeholders en cards/list, no spinners solos)
- V6 Cards elevation (sombras visibles o surfaceContainer en jerarquia)
- V7 Hero header en home (welcome card con displayMedium)
- V8 Stat tiles mejorados (trend indicator, sparkline)
- V9 Snackbar actions (undo, retry, etc)
- V10 Onboarding tour (coaching overlay primera vez)

## Artefactos

- `docs/prds/2026-07-16_1754-design-system-overhaul.prd.md` (PRD original 24 ACs)
- `docs/prds/2026-07-16_1754-design-system-overhaul.prd.md` (mismo archivo, con addendum V1-V3 en seccion aparte)
- `docs/plans/2026-07-16_1758-design-system-overhaul.plan.md`

## Riesgos abiertos

- **R1 visual regression**: mitigado con commits chicos. Sin baseline formal (no se crearon golden tests).
- **R2 bundle +600KB Google Fonts**: monitorear en M6. Si pasa 2.5MB, fallback a MountainView.
- **R6 typos en M3 (tokens)**: usar grep pre-commit por literales y tests despues de cada PR.

## Proximo paso

Cuando vuelvas: priorizar M3 (token compliance) o seguir con V5+ (loading states, V7 hero header). Si M3, branch sugerida: `feature/ds-overhaul-m3`.
