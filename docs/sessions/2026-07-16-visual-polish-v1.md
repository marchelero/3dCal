# 2026-07-16 (segundo snapshot) - Visual Polish v1 Round 1

## Status

- **main**: `595b85c` (merge commit, --no-ff de feature/visual-polish-v1)
- **Push**: OK a `origin/main` (`81dfc11..595b85c`)
- **Branch `feature/visual-polish-v1`**: borrada
- **Working tree**: clean

## Hecho en este round

| Commit | Tipo | Descripcion |
|--------|------|-------------|
| `d96abc4` | feat(widgets) | give SectionHeader a tonal background and generous padding (V3) |
| `e97edfb` | feat(widgets) | make EmptyView hero-shaped with bigger icon and titleLarge (V2) |
| `2697434` | feat(calc) | promote primary monetary totals to hero display style (V1) |
| `e2ec363` | docs(prd) | add visual polish v1 round 1 addendum to design system PRD |
| `a6b1d45` | docs(sessions) | snapshot M1+M2 design system merge round |
| `595b85c` | merge | visual polish v1 round 1 (--no-ff) |

## Cambios visuales aplicados (V1-V3)

| # | Widget/screen | Cambio |
|---|---------------|--------|
| V1 | calculator "Big price" | displaySmall (36sp) -> displayMedium (45sp) + FittedBox |
| V1 | calculation detail "Total" | headlineSmall (24sp) -> headlineMedium (28sp) + FittedBox |
| V1 | calculation detail "Total" label | titleMedium -> titleLarge + w600 |
| V2 | EmptyView container | 80x80 -> 96x96 |
| V2 | EmptyView icono | 36dp -> 48dp |
| V2 | EmptyView mensaje | titleMedium -> titleLarge + w600 |
| V2 | EmptyView spacing | xl -> xxl entre icono y mensaje |
| V3 | SectionHeader background | nuevo Container surfaceContainerHighest + outlineVariant border |
| V3 | SectionHeader texto | titleSmall+primary -> titleMedium+onSurface |
| V3 | SectionHeader icono | 18dp -> 20dp |
| V3 | SectionHeader padding | flat row -> lg horizontal + md vertical |
| V3 | SectionHeader layout | Expanded wrap del Text |

## Validacion

- `flutter analyze` en 4 archivos editados: 13 issues, todos `public_member_api_docs` pre-existentes, 0 errors/warnings nuevos.
- FittedBox.scaleDown en V1 evita overflow con numeros largos (BOB 1,234,567.89) en mobile 320dp.
- Semantics wrapping (header: true en SectionHeader, container: true en EmptyView) preservado.
- Bundle: sin cambio (todo reuse del round M1+M2).

## Out of scope (este round)

- **V4** — SnackBar semantico con icono + color (success/error/info). 30 min. Pendiente de decision.

## Pendiente (original design system)

- M3: Token compliance (~6-8h)
- M4: A11y WCAG 2.2 AA completo (~6-8h)
- M5: Responsive + max widths (~3-4h)
- M6: Quality gates - tests + bundle size check (~2-3h)

## Proximo paso

Cuando vuelvas: retomar M3 (token compliance) o decidir sobre V4. Si retomas M3, branch nueva `feature/design-system-m3`.
