# 2026-07-16 - Design System Overhaul (M1+M2 merged to main)

## Status

- **main**: `81dfc11` (8 commits ahead of polish-v2 merge, 41 ahead of origin/main)
- **Push**: OK a `origin/main` (`b9fed6d..81dfc11`)
- **Branch `feature/design-system-overhaul`**: borrada (FF-mergeada)
- **Branch `refactor/frontend-polish-v2`**: existe local, mergeada a main en `43d534e`
- **Working tree**: clean

## Hecho hoy

| Commit | Tipo | Descripcion |
|--------|------|-------------|
| `1b5daca` | refactor(calculator) | migrate spacing literals to AppSpacing tokens |
| `91e2dbe` | feat(widgets) | add optional semanticLabel to top 5 shared widgets |
| `cb3ed6c` | refactor(theme) | migrate surfaces to M3 tonal containers |
| `29c17d1` | chore(theme) | add google_fonts dep and preload fonts at startup |
| `24046cf` | feat(theme) | apply Inter as global text theme family |
| `b168697` | feat(theme) | use JetBrains Mono for monetary values in shared widgets |
| `3eb8567` | feat(theme) | use JetBrains Mono for monetary values in calculation pages |
| `81dfc11` | docs | add PRD and implementation plan |

QW2.1 (tabular figures en MoneyRow) ya estaba aplicado en `refactor/frontend-polish-v2`.

## Decisiones tomadas

- **Fonts**: Google Fonts build-time con `GoogleFonts.pendingFonts()`. Inter para texto, JetBrains Mono para cifras. Sin CDN runtime, funciona offline. +600KB bundle.
- **Seed color**: `0xFF1B4D7A` (azul) mantenido. Overrides de paleta primaria/secundaria/terciaria preservados por identidad PLA (naranja no derivable del seed azul).
- **A11y**: WCAG 2.2 AA mínimo. No skip links, no keyboard nav full, no live regions.
- **Tabular figures**: 12 matches en 7 archivos. Retenido en MoneyRow + StatTile + calc pages.

## Validacion

- `flutter analyze` full project: 89 issues, todos `info` pre-existentes (`public_member_api_docs`), 0 errors/warnings nuevos.
- `flutter analyze` específico en 7 archivos editados: No issues found.
- Grep `_lightSurfaceBg|_lightCardBg|0xFFF0EFEC|0xFFFCFCFA`: 0 matches (M1 confirmado).
- Grep `google_fonts` import: 6 archivos.
- Grep `tabularFigures`: 12 matches en 7 archivos.

## Pendiente (M3-M6, ~17-23h)

| # | Milestone | Effort | ACs |
|---|-----------|--------|-----|
| M3 | Token compliance (~40 literales a AppSpacing/AppRadii) | L (~6-8h) | 008-010 |
| M4 | A11y WCAG 2.2 AA (touch 48dp, focus, Semantics, +6 widgets) | L (~6-8h) | 011, 014-016, 012 |
| M5 | Responsive (AppBreakpoints + max widths + 320dp audit) | M (~3-4h) | 018-020 |
| M6 | Quality gates (analyze, tests, bundle ≤2.5MB) | S-M (~2-3h) | 021-024 |

Critical path: M3 → M4 → M6. M5 puede ir en paralelo a M4.

## Artefactos

- `docs/prds/2026-07-16_1754-design-system-overhaul.prd.md` (PRD con 24 ACs)
- `docs/plans/2026-07-16_1758-design-system-overhaul.plan.md` (Plan con 6 milestones)

## Riesgos abiertos

- **R1 visual regression**: mitigado con commits chicos + commits por concern. Sin capturas baseline formales. Si se ven problemas visuales, comparar contra tag antes de M1 (no existe tag, se puede comparar contra `43d534e`).
- **R2 bundle +600KB por Google Fonts**: monitorear en M6 con `flutter build web --analyze-size`. Threshold 2.5MB.
- **R6 typos en M3**: mitigar con grep pre-commit por tokens faltantes y tests después de cada PR por feature.

## Proximo paso

Cuando vuelvas: retomar M3 (token compliance) o mergear PRs existentes primero. Si retomas M3, usar `feature/design-system-overhaul-m3` como branch nueva.
