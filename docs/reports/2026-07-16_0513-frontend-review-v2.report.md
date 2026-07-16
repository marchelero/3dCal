<task id="ses_095d0823fffeUmKRIQyYo0CZyw" state="completed">
<task_result>
# Flutter UI Review — 3dCal (second pass)

Reviewed: `lib/app.dart`, `lib/main.dart`, `lib/core/theme/app_theme.dart`, `lib/core/router/app_router.dart`, `lib/core/theme_mode_provider.dart`, `lib/core/storage/*`, `lib/l10n/es_bo.dart`, all 5 `lib/shared/widgets/*`, and every page/notifier/widget under `lib/features/{calculation,catalog/*,dashboard,settings}/presentation/**`.

Theme system (`app_theme.dart`) and shell (`app_scaffold.dart`) are solid. The remaining UI has good bones but is held together by inline Spanish strings, duplicated list/detail patterns, and a few bugs that hide under consistent-looking shells.

---

## 1. Top 5 Quick Wins (≤30 min each, high visual impact)

### 1.1 Fix dead draft-restore logic (functional bug, ~10 min)
- **File:** `lib/features/calculation/presentation/pages/calculator_page.dart:103-108`
- **Problem:** `_restoreDraftIfAny` only does `storage.clear()` — it never reads or restores anything. The boolean `_draftRestored` plus the method name imply a real restore, but the entire DraftStorage feature silently wipes the persisted draft on every app open. The `_saveDraft` listener still writes drafts, so users *see* them being saved then immediately deleted.
- **Fix:** Either delete the dead code path (since `load()` in `initState` already returns `null` and the subsequent `loadFilamentDefaults` is what runs), or actually call `storage.load()` and write the values back into controllers + notifier. Minimal version: replace the method body with `await storage.clear();` and rename it `_clearStaleDraft`. Remove the misleading `_draftRestored` field.
- **Effort:** XS (~10 min, ≤20 LOC).

### 1.2 Replace `Colors.white24` dividers in the result card (visual bug in dark mode, ~10 min)
- **File:** `lib/features/calculation/presentation/pages/calculator_page.dart:1341, 1389`
- **Problem:** The `_SummaryCard` and `_DetailSection` paint dividers with `color: Colors.white24`. This is invisible on the `primaryContainer` background in dark mode (where `onPrimaryContainer` is near-black) and clashes in light mode.
- **Fix:** Use `Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.2)` (or a `Divider` themed to that color). One line each.
- **Effort:** XS.

### 1.3 De-duplicate `_formatMoney` in dashboard (cleanup, ~15 min)
- **File:** `lib/features/dashboard/presentation/pages/dashboard_page.dart:158-166`
- **Problem:** The dashboard re-implements currency formatting with a private `_formatMoney` while `formatBob()` in `lib/core/money/currency_formatter.dart` already does it the right way (and is imported in `home_page.dart`, `calculations_list_page.dart`, `calculation_detail_page.dart`).
- **Fix:** Import `formatBob` and use it for `value: formatBob(stats.totalQuoted)` / `formatBob(stats.totalSold)`. If K/M abbreviations are wanted, add an optional `abbreviated: true` flag to `formatBob` instead of forking it. Removes 8 lines and a divergent formatter.
- **Effort:** XS.

### 1.4 Unify "default" star color (consistency, ~10 min)
- **Files:**
  - `lib/features/catalog/filaments/presentation/pages/filaments_page.dart:83` — `const Icon(Icons.star, color: Colors.amber)`
  - `lib/features/catalog/printers/presentation/pages/printers_page.dart:75` — same
  - `lib/features/calculation/presentation/pages/calculator_page.dart:723` — `f.isDefault ? Colors.amber : …`
- **Problem:** Hardcoded `Colors.amber` instead of the theme's `tertiary` or a new token. The "default" indicator should be one color, and it should follow the dark mode accent.
- **Fix:** Add `static const Color defaultStar = Color(0xFFFFC107);` (or `tertiary` if visual fits) to `AppTheme` and reference it via a small `DefaultBadge` widget (also helps with the size+container treatment). The three sites should all use the same `Icon(Icons.star_rounded, color: AppTheme.defaultStar, size: …)`.
- **Effort:** XS.

### 1.5 Constrain calculator/form width on wide screens (responsive, ~20 min)
- **File:** `lib/features/calculation/presentation/pages/calculator_page.dart:280, 410` (and `calculation_detail_page.dart:90`, `dashboard_page.dart:61`, `home_page.dart:24`, `filament_form_page.dart:142`, `printer_form_page.dart:115`, `settings_page.dart:50`)
- **Problem:** Every form and detail page uses `SingleChildScrollView` / `ListView` with `padding: EdgeInsets.all(16)` and no max width. On a 1920px web viewport with the 1280+ NavigationRail, the input fields expand to absurd widths and the form becomes hard to scan. PROJECT.md mentions a 1280+ tier but pages don't respect it.
- **Fix:** Wrap each scroll view's child in `Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: …))` for forms / 960 for detail pages. One helper widget `MaxWidthScrollView` in `lib/shared/widgets/` would do all of them. Or apply only to `CalculatorPage` for the most visible win.
- **Effort:** S (~20 min, 7 sites, 1 shared helper).

---

## 2. Structural Issues (refactor-level)

### 2.1 `_TotalRow` is duplicated in two feature pages
- **Location:**
  - `lib/features/calculation/presentation/presentation/pages/home_page.dart:298-333` (class `_TotalRow`)
  - `lib/features/dashboard/presentation/pages/dashboard_page.dart:169-204` (identical class `_TotalRow`)
- **Problem:** Two identical (byte-for-byte after formatting) private widgets. Diverging in the future is a trap.
- **Approach:** Promote to `lib/shared/widgets/money_row.dart` as `MoneyRow({label, value, isBold, color})`. Use `formatBob` internally; accept a `Decimal` or pre-formatted string.
- **Files affected:** 2 pages, 1 new shared file.
- **Effort:** S. Risk: low (purely additive).

### 2.2 `SectionHeader` and `SectionCard` should be shared
- **Location:**
  - `lib/features/settings/presentation/pages/settings_page.dart:268-298` (`_SectionHeader`)
  - `lib/features/calculation/presentation/pages/calculator_page.dart:563-603` (`_SectionCard`)
- **Problem:** Two private widgets with overlapping purpose. `settings_page.dart` uses `_SectionHeader` (icon + title). `calculator_page.dart` uses `_SectionCard` (Card containing icon + title + child). `dashboard_page.dart:130-142` inlines a third copy of "icon + title in primary color" without a Card. Three near-identical visual idioms.
- **Approach:** Two new shared widgets:
  - `SectionHeader({icon, title, color})` in `lib/shared/widgets/section_header.dart`.
  - `SectionCard({icon, title, color, child})` in `lib/shared/widgets/section_card.dart`.
  - Have `SectionCard` use `SectionHeader` internally.
- **Files affected:** settings, calculator, dashboard pages.
- **Effort:** S. Risk: low.

### 2.3 Delete-confirm dialog is copy-pasted 4×
- **Location:**
  - `lib/features/catalog/filaments/presentation/pages/filaments_page.dart:119-135`
  - `lib/features/catalog/printers/presentation/pages/printers_page.dart:115-131`
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart:236-252`
  - `lib/features/calculation/presentation/pages/calculation_detail_page.dart:33-52`
- **Problem:** Same AlertDialog with "Eliminar X" / "¿Eliminar …?" / "Cancelar" / "Eliminar". Diverging labels are a translation risk.
- **Approach:** Add `Future<bool> showConfirmDialog(BuildContext, {required String title, required String message, String confirmLabel = 'Eliminar'})` in `lib/shared/widgets/confirm_dialog.dart`.
- **Files affected:** 4 files collapse to one-liner `if (await showConfirmDialog(...)) ...`.
- **Effort:** S. Risk: low.

### 2.4 List tile patterns are inconsistent
- **Location:**
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart:65-191` — Card + InkWell with custom 3-column row (leading avatar, body, trailing price+menu).
  - `lib/features/catalog/filaments/presentation/pages/filaments_page.dart:66-110` — plain `ListTile` with `Divider` separators, no card.
  - `lib/features/catalog/printers/presentation/pages/printers_page.dart:58-103` — same as filaments.
- **Problem:** Two visually different idioms for "list of saved items". Catalog lists look like a 2018 settings list, history looks like a Material 3 feed.
- **Approach:** Unify on the Card-based pattern (it's nicer and matches `dashboard_page` cards). Either upgrade `filaments_page` and `printers_page` to Cards, or downgrade `calculations_list_page` to ListTiles. Cards fit the design system better.
- **Files affected:** 3 files.
- **Effort:** M (touches layout in 2 files, risk of breaking tap targets).
- **Risk:** medium (visual regression possible).

### 2.5 Form field wrappers have diverged
- **Location:**
  - `lib/features/calculation/presentation/widgets/decimal_input_field.dart` — `DecimalInputField` (decimal-typed TextField, with live validation, suffixText).
  - `lib/features/catalog/filaments/presentation/pages/filament_form_page.dart:145-196` — raw `TextFormField` with `OutlineInputBorder()`, `FilteringTextInputFormatter`, manual validator.
  - `lib/features/catalog/printers/presentation/pages/printer_form_page.dart:118-150` — same raw pattern, no decimal.
  - `lib/features/settings/presentation/pages/settings_page.dart:335-424` — custom `_AutoSaveField` wrapping `FormField` + `TextFormField` with auto-save on blur.
- **Problem:** Three form field approaches in one app. The `OutlineInputBorder` on form pages **overrides** the theme's no-border style (theme has `BorderSide.none` for the resting border). Inconsistent error display, helperText, label behavior.
- **Approach:** Generalize `DecimalInputField` into `NumericInputField({label, controller, allowDecimals, suffix, helperText, onChanged, onBlur, autofocus, validator})` that:
  - Always uses the theme's `inputDecorationTheme` (drop `OutlineInputBorder` override).
  - Optional `onBlur` callback (powers settings auto-save).
  - Optional `allowDecimals` (replaces `TextInputType.number` variants).
  Then delete `_AutoSaveField` and the inline `TextFormField` blocks in both form pages, replacing with `NumericInputField` plus a separate `TextInputField` for non-numeric (name, brand).
- **Files affected:** form pages, settings, decimal_input_field.
- **Effort:** M. Risk: medium (visible behavior change — test in both themes).

### 2.6 `AnimatedMaterialRow` is a phantom reference
- **Location:** Mentioned in `docs/PROJECT.md:52` (`shared/widgets/ # AnimatedMaterialRow, etc`) and in the directory layout comment for `lib/shared/widgets/`. No file exists.
- **Problem:** Documentation describes a widget that doesn't ship. Either build it (e.g., for the calculator's `_MaterialRowTile` insertion/removal in `calculator_page.dart:945-1063`, which currently uses `AnimatedList` + `SizeTransition` ad-hoc) or remove the mention.
- **Approach:** Either extract the current `_MaterialRowTile` to `lib/shared/widgets/animated_material_row.dart` with an `AnimatedList`-friendly variant, or delete the line from `PROJECT.md`.
- **Files affected:** PROJECT.md or new shared widget.
- **Effort:** S.

### 2.7 `_materialsOfProvider` is a `FutureProvider.family` that never re-fetches
- **Location:** `lib/features/calculation/presentation/pages/calculation_detail_page.dart:421-424`
- **Problem:** When the user marks the calculation as sold on the same detail page, `calculationsNotifierProvider` updates but this provider doesn't refetch. Currently the only "impact" is that materials don't change on sold toggle, so it's invisible — but it will bite if a future Sprint adds editable materials.
- **Approach:** Either make the provider read the underlying repository directly with a `ref.watch(repo)` of the calculation list, or document why it's intentionally stale. Low priority but flag.
- **Files affected:** detail page only.
- **Effort:** S. Risk: low.

### 2.8 `_OutputSection` mixes 3 states with an `if/else` chain
- **Location:** `lib/features/calculation/presentation/pages/calculator_page.dart:1107-1128`
- **Problem:** `_calculating` (a private `bool`), `output == null`, and "has output" are encoded as separate booleans. Adding "stale" / "error" later will fork more.
- **Approach:** Drive the section off the state version: render `LoadingView` if `computeVersion` was bumped less than ~300ms ago, else the appropriate card. Or: keep the bool but document the trade-off. Since the engine is synchronous, the "Calculando..." animation is purely cosmetic — the simplest fix is to remove the artificial 1.2s spinner and just render the result with an `AnimatedSwitcher`.
- **Files affected:** `_OutputSection`, `_CalculatingAnimation`.
- **Effort:** S. Risk: low.

### 2.9 NavigationRail 1024-1279 tier may feel cramped with the calculator inside the shell
- **Location:** `lib/shared/widgets/app_scaffold.dart:86-124`
- **Problem:** At 1024-1279, `extended: false` shows compact NavigationRail. The "Nueva cotización" action lives at `/calculator` (full-screen push, not a tab) — so the user never directly uses the rail to enter it. But the `home_page` quick actions (`Nueva cotizacion`, `Historial`, `Dashboard`) all sit in the first tab; from a 1024+ web layout the rail is taking 80dp and the home content is centered in the remaining 944dp with no max-width (see 1.5). This is a recurring complaint in responsive Flutter apps.
- **Approach:** Apply the `MaxWidthScrollView` helper from 1.5 to all shell pages.
- **Files affected:** home, dashboard, history.
- **Effort:** S. Risk: low.

---

## 3. Style/Theme Inconsistencies

All `Colors.*` literals, `fontSize:`, `EdgeInsets.*`, and `BorderRadius.circular(N)` calls outside the theme file, grouped by file.

### 3.1 `Colors.X` literals (6 sites)
| File | Line | Code | Notes |
|---|---|---|---|
| `lib/features/catalog/filaments/presentation/pages/filaments_page.dart` | 83 | `Icon(Icons.star, color: Colors.amber)` | should be `AppTheme.defaultStar` |
| `lib/features/catalog/printers/presentation/pages/printers_page.dart` | 75 | `Icon(Icons.star, color: Colors.amber)` | same |
| `lib/features/calculation/presentation/pages/calculator_page.dart` | 723 | `f.isDefault ? Colors.amber : …` | same |
| `lib/features/calculation/presentation/pages/calculator_page.dart` | 1341 | `const Divider(height: 8, color: Colors.white24)` | breaks dark mode |
| `lib/features/calculation/presentation/pages/calculator_page.dart` | 1389 | `const Divider(height: 12, color: Colors.white24)` | breaks dark mode |
| `lib/core/theme/app_theme.dart` | 80, 95, 102 | `surfaceTintColor: Colors.transparent` | acceptable (in theme) |

### 3.2 Hardcoded `fontSize:` literals (6 sites)
| File | Line | Value | Notes |
|---|---|---|---|
| `lib/core/theme/app_theme.dart` | 147, 157, 168 | 16 | button themes — acceptable |
| `lib/features/calculation/presentation/pages/calculator_page.dart` | 768 | 12 | `_ActionChip` label — use `textTheme.labelSmall` |
| `lib/features/calculation/presentation/pages/calculations_list_page.dart` | 215 | 14 | PopupMenu item |
| `lib/features/calculation/presentation/pages/calculations_list_page.dart` | 223 | 14 | PopupMenu item |

### 3.3 `EdgeInsets.*` literals (53 sites)
Major offenders with non-theme values that should be in a layout token:
- `lib/features/calculation/presentation/pages/home_page.dart:25` — `EdgeInsets.symmetric(horizontal: 20, vertical: 16)` (different from the standard `horizontal: 16, vertical: 12` used everywhere else)
- `lib/features/calculation/presentation/pages/home_page.dart:134-137` — `EdgeInsets.only(left: …, right: …)` (could use a horizontal: 8 SizedBox pattern for consistency)
- `lib/features/calculation/presentation/pages/calculator_page.dart:770, 794, 965, 966, 1137, 1170, 1227, 1256, 1295, 1398` — many one-off paddings
- `lib/features/calculation/presentation/pages/calculations_list_page.dart:54` — `EdgeInsets.only(bottom: 10)` (use SizedBox)
- `lib/core/theme/app_theme.dart:129` — `EdgeInsets.symmetric(horizontal: 16, vertical: 14)` for inputs (this should be the canonical reference)

**Fix:** Add `class AppSpacing { static const xs = 4; static const sm = 8; static const md = 12; static const lg = 16; static const xl = 24; }` in `lib/core/theme/app_spacing.dart`. Replace magic numbers in the most-repeated sites (the form pages, the section cards).

### 3.4 `BorderRadius.circular(N)` literals (39 sites)
Theme defines `12, 14, 16, 20` as visual tokens. Most of the 39 literal calls already pick one of these values — the duplication itself is the smell. Frequent collisions:
- `BorderRadius.circular(10)` — 6 sites (settings_page.dart, stats_card.dart, calculations_list_page.dart, calculator_page.dart × 3). No token for 10.
- `BorderRadius.circular(12)` — 12 sites. Matches `inputDecorationTheme`.
- `BorderRadius.circular(14)` — 5 sites. Matches `filledButtonTheme`.
- `BorderRadius.circular(16)` — 5 sites. Matches `cardTheme`.
- `BorderRadius.circular(20)` — 6 sites. Matches `dialogTheme`.
- `BorderRadius.circular(8)` — 2 sites. No token for 8.

**Fix:** Add a `BorderRadiusGeometry get rSm/rMd/rLg/rXl` getter set in `app_theme.dart` (or `AppRadii` class) and replace literals. Low priority — the values already match the theme. Main risk is a future design change.

### 3.5 `Color(0x…)` literals
Only in `app_theme.dart` — acceptable (defines the theme).

---

## 4. Missing Design-System Widgets

Widgets that should live in `lib/shared/widgets/` to consolidate duplication and ensure consistency.

### 4.1 `SectionCard`
- **Repeats in:** `calculator_page.dart:563-603` (private `_SectionCard`), conceptually similar in `settings_page.dart` (Card wrapping Column).
- **API sketch:**
  ```dart
  SectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color? accentColor,  // default: theme.colorScheme.primary
  })
  ```

### 4.2 `SectionHeader`
- **Repeats in:** `settings_page.dart:268-298` (private `_SectionHeader`), `dashboard_page.dart:130-142` (inline), and `_SectionCard`'s header row.
- **API sketch:**
  ```dart
  SectionHeader({
    required IconData icon,
    required String title,
    Color? accentColor,
  })
  ```

### 4.3 `MoneyRow`
- **Repeats in:** `home_page.dart:298-333`, `dashboard_page.dart:169-204` (both private `_TotalRow`).
- **API sketch:**
  ```dart
  MoneyRow({
    required String label,
    required String value,  // already formatted (caller uses formatBob)
    bool isBold = false,
    Color? valueColor,
  })
  ```

### 4.4 `ConfirmDialog` helper
- **Repeats in:** 4 files (filaments, printers, calculations_list, calculation_detail) — see 2.3.
- **API sketch:**
  ```dart
  Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    bool destructive = true,
  })
  ```

### 4.5 `EmptyOutputCard` (or reuse `EmptyView`)
- **Current:** `calculator_page.dart:1161-1191` has a private `_EmptyOutput` card. It's a less-polished version of `EmptyView`.
- **API sketch:** Drop `_EmptyOutput` and call `EmptyView(icon: Icons.calculate_outlined, message: 'Completa peso, precio y tiempo de impresion\npara ver la cotizacion.')` instead. Or add a `compact: true` flag to `EmptyView`.

### 4.6 `StatTile` (already exists as `StatsCard`, but private to dashboard)
- **Location:** `lib/features/dashboard/presentation/widgets/stats_card.dart` — used in both `dashboard_page.dart` and `home_page.dart` (cross-feature import!), but the file lives in the dashboard feature folder.
- **Fix:** Move to `lib/shared/widgets/stat_tile.dart` and rename `StatsCard` → `StatTile`. Update imports in `home_page.dart` and `dashboard_page.dart`.
- **API sketch:** Already correct, just relocate.

### 4.7 `DefaultBadge`
- **Repeats in:** 3 places (filaments_page.dart:83, printers_page.dart:75, calculator_page.dart:723).
- **API sketch:**
  ```dart
  DefaultBadge({bool isDefault = true, double size = 24})
  ```
  Renders an `Icon(Icons.star_rounded, color: AppTheme.defaultStar, size: size)` or empty SizedBox. Removes the `condition ? amber : …` ternary in 3 places.

### 4.8 `MaxWidthScrollView`
- See 1.5. The helper is the single biggest responsive UX fix.
- **API sketch:**
  ```dart
  MaxWidthScrollView({
    required Widget child,
    double maxWidth = 720,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  })
  ```

### 4.9 `AvatarIcon` (leading icon container)
- **Repeats in:** `calculator_page.dart:713-727` (filament dialog), `calculator_page.dart:860-870` (printer dialog), `settings_page.dart:152-160, 174-179` (catalog tiles). All use the pattern: 40×40 Container, `colorScheme.primaryContainer` (or `secondaryContainer`, `tertiaryContainer`), `BorderRadius.circular(10)`, child Icon.
- **API sketch:**
  ```dart
  AvatarIcon({
    required IconData icon,
    Color? background,  // defaults to colorScheme.primaryContainer
    Color? foreground,  // defaults to onBackground
    double size = 40,
    double iconSize = 20,
    double radius = 10,
  })
  ```

### 4.10 `ActionChipM3`
- **Current:** `calculator_page.dart:753-773` private `_ActionChip` is a 2-arg `ActionChip` with an avatar. Useful enough to extract if reused.
- **API sketch:**
  ```dart
  ActionChipM3({required IconData icon, required String label, required VoidCallback onTap})
  ```

---

## 5. Accessibility & i18n Gaps

### 5.1 Accessibility (no `Semantics` calls anywhere in `lib/`)
- **Missing:** `Semantics`, `semanticLabel`, `ExcludeSemantics`, `MergeSemantics` are zero across the codebase.
- **Concrete gaps:**
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart:145-152` — the decorative dot separator (3×3 black circle) is announced as "black circle" by screen readers. Wrap in `ExcludeSemantics(child: …)`.
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart:99-110` — the leading icon's color encodes `isSold` (green check vs gray receipt). Add `Semantics(label: calc.isSold ? 'Cotización vendida' : 'Cotización pendiente', child: …)`.
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart:201-228` — `PopupMenuButton` without a tooltip. Add `tooltip: 'Más acciones'`.
  - `lib/features/catalog/filaments/presentation/pages/filaments_page.dart:82-84` and `printers_page.dart:74-76` — leading `Icons.star`/`Icons.label_outline` conveys "is default" only visually. Add `Semantics(label: filament.isDefault ? 'Filamento por defecto' : null, child: …)`.
  - `lib/features/calculation/presentation/pages/calculator_page.dart:998-1005` — IconButton has `tooltip: 'Quitar'` but the red color also encodes "destructive". OK as-is, but the trash icon alone may be ambiguous for new users.
  - `lib/features/dashboard/presentation/widgets/profit_bar_chart.dart:55, 65` — chart bars have no semantic description of the value they encode. fl_chart doesn't auto-emit one.
  - `lib/shared/widgets/empty_view.dart:35-43` and `error_view.dart:30-42` — the icon Container is purely decorative. Wrap in `ExcludeSemantics` so the screen reader announces only the message.

### 5.2 Touch targets
- All `IconButton`s use Material default 48dp. ✓
- `lib/features/catalog/filaments/presentation/pages/filaments_page.dart:30-36` and `printers_page.dart:23-28` — the "+" IconButton has a tooltip (good), no override needed.
- `lib/features/calculation/presentation/pages/calculations_list_page.dart:201-228` — `PopupMenuButton` with `iconSize: 18, padding: EdgeInsets.zero` may shrink the tap target below 48dp. Test on actual device. Default `IconButton` tap target is fine; `PopupMenuButton` may need `iconSize: 24` to be safe.

### 5.3 i18n gaps
- `EsBO` (14 constants) covers nav + settings only. Inline Spanish literals are everywhere else.
- **Missing from `EsBO`:** `cancel`, `save`, `delete`, `retry`, `confirm`, `loading`, `errorGeneric`, `back`, `close`, plus the entire calculator/catalog/history/dashboard string sets (~80 strings total).
- **Concrete inline-Spanish hot spots:**
  - `lib/features/calculation/presentation/pages/calculator_page.dart` — ~30 literals: `'Cotizacion'`, `'Pieza'`, `'Filamento'`, `'Impresora'`, `'Tiempo de impresion'`, `'Descuento'`, `'Horas'`, `'Minutos'`, `'Cancelar'`, `'Guardar cotizacion'`, `'Restablecer valores'`, `'Completa peso, precio y tiempo de impresion\npara ver la cotizacion.'`, `'Calculando...'`, `'Ocultar detalle'`, `'Ver detalle'`, `'Costo material'`, `'Costo energia'`, `'Costo base'`, `'Ganancia'`, `'Costo total final'`, `'Descuento'`, `'Total cotizado'`, `'Total vendido'`, etc.
  - `lib/features/calculation/presentation/pages/calculation_detail_page.dart` — ~15 literals: `'Detalle cotizacion'`, `'Eliminar'`, `'Materiales'`, `'Desglose'`, `'Costo material'`, `'Total'`, `'Reusar'`, `'Marcar pendiente'`, `'Marcar vendida'`, `'Cliente'`, `'Vendida'`, `'Sin nombre'`, etc.
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart` — ~10 literals: `'Cotizaciones'`, `'Sin cotizaciones guardadas'`, `'Crea una desde el calculator y toca Guardar.'`, `'Nueva cotizacion'`, `'Marcar pendiente'`, `'Marcar vendida'`, `'Eliminar'`, `'Eliminar cotizacion'`, `'¿Eliminar permanentemente?'`, `'Cancelar'`, `'Error cargando cotizaciones'`, `'Cotizacion · $client'`, `'Cotizacion sin nombre'`.
  - `lib/features/catalog/filaments/presentation/pages/filament_form_page.dart` — ~10 literals: `'Editar filamento'`, `'Nuevo filamento'`, `'Nombre'`, `'Marca'`, `'Precio bobina (BOB)'`, `'Gramos por bobina'`, `'Requerido'`, `'Numero invalido'`, `'Debe ser > 0'`, `'Debe ser entero'`, `'Maximo 100 caracteres'`, `'Guardar'`, `'Error guardando: $e'`.
  - `lib/features/catalog/printers/presentation/pages/printer_form_page.dart` — similar list.
  - `lib/features/dashboard/presentation/pages/dashboard_page.dart` — `'Cotizado vs Ganado'`, `'Aun no cotizaste nada'`, `'Crea tu primera cotizacion desde el inicio.'`, `'Ir a Home'`, `'Error al cargar el dashboard'`, `'Cotizaciones'`, `'Vendidas'`, `'Conversion'`, `'Total cotizado'`, `'Total vendido'`, `'Bs. …K'`.
  - `lib/features/settings/presentation/pages/settings_page.dart:117, 128, 163, 181, 223` — `'Apariencia'`, `'Tema'`, `'Gestiona tus filamentos'`, `'Registra tus impresoras'`, `'v0.1.0'`.
  - `lib/features/calculation/presentation/pages/home_page.dart:62, 72, 78, 119, 171, 208, 228, 233, 244, 253, 262, 278, 284, 92, 99, 106, 207` — many.
- **System:** No `MaterialApp.localizationsDelegates` / `supportedLocales`. `EsBO` is a class of static `String` — works for the "Spanish-only" non-negotiable but blocks any future locale. If a French/Quechua version is on the roadmap, plan to migrate to ARB + `flutter gen-l10n`. Not urgent.

---

## 6. Recommended Execution Order

Sequenced for clean, individually-shippable commits. Each item ≤ one PR; dependencies noted.

1. **Fix dead draft logic** (Quick Win 1.1) — commit `fix(calculator): correctly clear stale draft` or remove the dead method. Foundation: no other change should depend on broken draft restore.
2. **Move `StatsCard` → `lib/shared/widgets/stat_tile.dart` (renamed `StatTile`)** — touches 2 imports. Foundation for 3.
3. **Extract `SectionHeader` + `SectionCard` to `lib/shared/widgets/`** — touches settings, calculator, dashboard. Use `SectionHeader` inside `SectionCard`. Foundation for 4.
4. **Extract `ConfirmDialog` helper + apply in 4 sites** — pure cleanup, no behavior change.
5. **Extract `MoneyRow` to `lib/shared/widgets/money_row.dart`** — kills `_TotalRow` duplication in home + dashboard. Prereq for 6.
6. **Extract `DefaultBadge` + `AvatarIcon` to `lib/shared/widgets/`** — replaces `Colors.amber` (1.4) and the 40×40 leading container pattern. No new behavior.
7. **Generalize `DecimalInputField` → `NumericInputField`** with `allowDecimals`, `onBlur` — prereq for 8 and 9.
8. **Refactor `filament_form_page` and `printer_form_page` to use `NumericInputField` + a new `TextInputField`** for name/brand. Removes the divergent `OutlineInputBorder` overrides. Aligns all 3 form pages.
9. **Refactor `settings_page` `_AutoSaveField` to `NumericInputField` with `onBlur`**. Removes the custom FormField wrapper.
10. **Fix dark-mode dividers in `_SummaryCard`/`_DetailSection`** (Quick Win 1.2) — quick visual win in dark mode.
11. **Add `MaxWidthScrollView` helper + apply to calculator/detail/dashboard/home/settings** (Quick Win 1.5). The big responsive win.
12. **Unify list tile pattern (Card+InkWell in catalog pages)** — or alternatively, simplify history to ListTile. Pick one and stick with it. Visual only.
13. **Fix `Colors.amber` defaults** (Quick Win 1.4) — already covered by `DefaultBadge` if 6 is done.
14. **De-duplicate `_formatMoney` in dashboard** (Quick Win 1.3) — small, ships as a 1-line fix.
15. **Resolve `AnimatedMaterialRow` phantom** (Structural 2.6) — either build it (extract from calculator's `_MaterialRowTile`) or delete from `PROJECT.md`. Smallest item, but it closes a doc gap.
16. **i18n pass: add common verbs to `EsBO`** (`cancel`, `save`, `delete`, `retry`, `loading`, `errorGeneric`). Mechanical substitution. Can be broken into per-feature passes (catalog → history → settings → dashboard → calculator).
17. **i18n pass: add feature-specific strings to `EsBO`** for calculator (largest set, ~30 strings). One feature at a time, each its own commit.
18. **Accessibility pass 1: Semantics on list items + ExcludeSemantics on decorative elements** (5.1). Group by file, one commit per file.
19. **Accessibility pass 2: semantic labels on chart and form validations** (5.1).
20. **Responsive polish: `Padding`/spacing tokens (`AppSpacing` class)** to replace the 53 literal `EdgeInsets` and 32 SizedBox height/width magic numbers. Pure cleanup, no visual change.
21. **Radii tokens (`AppRadii` class)** — same idea, lower priority.
22. **Investigate `_materialsOfProvider` staleness** (Structural 2.7) — only if a future Sprint adds material editing.

Each step is a single commit. Steps 1-2-3-4-5-6 form a "design-system foundation" arc; 7-8-9 align forms; 10-11-12-13-14 are visual polish; 15 closes a doc issue; 16-19 are a11y/l10n hygiene; 20-21 are long-tail refactors; 22 is opportunistic.

No new dependencies required. No new architecture introduced. Every change ships under the existing Material 3 theme.
</task_result>
</task>