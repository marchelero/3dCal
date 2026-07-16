# Plan: Frontend Polish v2 (post-M3 theme)

> Source: `flutter-reviewer` review of 2026-07-16
> Full report: `docs/reports/2026-07-16_0513-frontend-review-v2.report.md`
> Scope: all 22 steps, 1 commit per step, user checkpoint per commit

## Context

3dCal shipped Material 3 "Industrial" theme (commit `b9fed6d`) and adaptive `AppScaffold` (commit `81f923e`). Theme and shell are solid. Second-pass review of all `lib/features/**/presentation/**` + `lib/shared/widgets/**` + theme/router identified:

- 5 quick wins (functional bugs + visual fixes)
- 9 structural refactors (de-duplication, design-system extraction)
- 10 design-system widgets to create in `lib/shared/widgets/`
- 3 theme tokens to add (`AppSpacing`, `AppRadii`, `AppTheme.defaultStar`)
- a11y gap (zero `Semantics` calls)
- i18n gap (~80 hardcoded Spanish strings, only 14 in `EsBO`)

No new dependencies. No architecture changes. All work under existing M3 theme.

## Execution plan (22 commits, 5 phases)

### Phase 1 — Foundation (steps 1-7)

- [ ] **1. Fix dead draft-restore logic** (XS) — `calculator_page.dart:103-108` `_restoreDraftIfAny` only clears. Remove misleading method + field.
- [ ] **2. Move `StatsCard` → `lib/shared/widgets/stat_tile.dart`** (S) — rename to `StatTile`. Update imports in `home_page.dart` + `dashboard_page.dart`.
- [ ] **3. Extract `SectionHeader` + `SectionCard`** (S) — new shared widgets. Use in `settings_page.dart`, `calculator_page.dart`, `dashboard_page.dart`.
- [ ] **4. Extract `ConfirmDialog` helper** (S) — `showConfirmDialog()` in shared. Apply in 4 sites.
- [ ] **5. Extract `MoneyRow`** (S) — replaces `_TotalRow` in `home_page.dart` + `dashboard_page.dart`.
- [ ] **6. Extract `DefaultBadge` + `AvatarIcon`** (S) — replaces `Colors.amber` (1.4) and 40×40 leading container pattern.
- [ ] **7. Generalize `DecimalInputField` → `NumericInputField`** (M) — adds `allowDecimals`, `onBlur`, drops `OutlineInputBorder` override.

### Phase 2 — Forms alignment (steps 8-9)

- [ ] **8. Refactor `filament_form_page` + `printer_form_page`** to use `NumericInputField` + new `TextInputField`. Removes divergent `OutlineInputBorder` overrides.
- [ ] **9. Refactor `settings_page` `_AutoSaveField`** to `NumericInputField` with `onBlur`. Removes custom `FormField` wrapper.

### Phase 3 — Visual polish (steps 10-14)

- [ ] **10. Fix dark-mode dividers in `_SummaryCard`/`_DetailSection`** (XS) — `Colors.white24` → `colorScheme.onPrimaryContainer.withValues(alpha: 0.2)`.
- [ ] **11. Add `MaxWidthScrollView` helper + apply to 7 sites** (S) — biggest responsive win.
- [ ] **12. Unify list tile pattern** (M) — pick one idiom (Card+InkWell or ListTile), apply consistently across history + catalogs.
- [ ] **13. Fix `Colors.amber` defaults** (XS) — covered by step 6 if done; otherwise add `AppTheme.defaultStar`.
- [ ] **14. De-duplicate `_formatMoney` in dashboard** (XS) — use `formatBob()`.

### Phase 4 — Hygiene (steps 15-19)

- [ ] **15. Resolve `AnimatedMaterialRow` phantom** (S) — either extract from `_MaterialRowTile` to `lib/shared/widgets/animated_material_row.dart`, or delete the line from `PROJECT.md`.
- [ ] **16. i18n pass: add common verbs to `EsBO`** — `cancel`, `save`, `delete`, `retry`, `loading`, `errorGeneric`. Mechanical substitution.
- [ ] **17. i18n pass: add feature-specific strings to `EsBO`** — calculator (~30 strings), catalog, history, dashboard. One feature per commit.
- [ ] **18. a11y pass 1: `Semantics` on list items + `ExcludeSemantics` on decorative** — one commit per file.
- [ ] **19. a11y pass 2: semantic labels on chart and form validations** — `profit_bar_chart.dart`, form error announcements.

### Phase 5 — Long-tail (steps 20-22)

- [ ] **20. Add `AppSpacing` tokens** — `xs=4, sm=8, md=12, lg=16, xl=24`. Replace ~30 most-repeated `EdgeInsets` literals.
- [ ] **21. Add `AppRadii` tokens** — `rSm/rMd/rLg/rXl` getters. Replace 39 `BorderRadius.circular` literals.
- [ ] **22. Investigate `_materialsOfProvider` staleness** (S, opportunistic) — only if future sprint adds material editing.

## Commit protocol

Per step:
1. Execute change.
2. Show diff summary + key files touched.
3. `flutter analyze` + `flutter test` if relevant.
4. Checkpoint: `[N/22] {step name} — commitea? (s/n)`.
5. On "s": `git add` + `git commit` with conventional message. On "n": fix, no commit.
6. Move to next step.

## Commit message convention

`<type>(scope): <subject>`
Types: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `perf`
Scope examples: `calculator`, `dashboard`, `catalog/filaments`, `shared/widgets`, `theme`, `l10n`, `a11y`

## Success criteria

- All 22 steps shipped as clean commits on a feature branch.
- `flutter analyze` clean at the end.
- `flutter test` still passing (no regressions).
- No new dependencies in `pubspec.yaml`.
- Final report in `docs/reports/` with summary of all 22 changes.
