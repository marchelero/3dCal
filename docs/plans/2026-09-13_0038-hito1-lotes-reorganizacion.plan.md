---
prd:
  - docs/prds/2026-09-13_1100-costos-pieza-lotes-insumos-servicios.prd.md
status: DRAFT
created: 2026-09-13_0038
---

# Plan de Implementación: HITO 1 (escalones de cantidad + reorganización) — 3dCal 2026-09-13

## Overview

Hito 1 del PRD `2026-09-13_1100` = **Feature A** (descuento mayorista por cantidad con
línea propia en desglose/export y snapshot en la cotización) + **Feature D**
(reorganización: sección "Otros" → "Costos de la pieza" y Ajustes reordenado).
Solo A y D: insumos (B) y servicios diseño/pintado (C) quedan para hitos 2 y 3, pero el
diseño deja el punto de extensión (subtotal de impresión separado, migración aditiva,
subgrupos de sección) para que encajen sin tocar el contrato del motor.

## Requirements

- Feature A — Escalones: tabla `discount_tiers`; CRUD en Ajustes → "Descuentos por
  cantidad" (FREE, sin paywall — decisión P1); aplicación automática con la cantidad N
  existente; escalón = mayor `min_qty ≤ N`; N bajo el primer escalón → 0 % sin línea.
- Regla P3: `desc_cantidad` solo sobre `subtotal_impresion = (costo_base + falla + markup) × N`
  (no toca insumos/servicios); línea SEPARADA de la manual; el descuento manual se
  aplica como hoy (escalado, sobre el total).
- Snapshot en `calculations`: `batch_discount_percent` + `batch_discount_amount`
  (TEXT `decimal`, NULL sin escalón); editar escalones después NO altera cotizaciones.
- Regla del 95 %: Express con N=1 o sin escalón → flujo, línea y total idénticos a hoy.
- Money siempre `decimal`; columnas batch como TEXT `decimal`; migración drift ADITIVA
  con tests (patrón `migration_v10_to_v11_test.dart`).
- Feature D — Cotizador: sección colapsable "Otros" → **"Costos de la pieza"**,
  estructura de subgrupos con "Tarifas" (los 4 campos actuales, gate Pro sin cambios);
  Insumos/Servicios NO se renderizan en hito 1 (criterio 95 %).
- Feature D — Ajustes en el orden: Empresa / Energía / Costos de impresión /
  Descuentos por cantidad / Catálogos / Moneda e idioma / Apariencia / Datos / Cuenta /
  Acerca (los últimos 5 mantienen su orden actual relativo).
- i18n: sin strings sin traducir; es_BO neutro (sin voseo); código y comentarios en inglés.
- `flutter analyze` + `flutter test` limpios al cierre de cada fase.

## Architecture Changes

- **Nuevo**: `lib/features/settings/domain/discount_tier.dart` — entidad `DiscountTier`
  (id TEXT UUID, minQty, percent Decimal, sortOrder), `toRow`/`fromRow`.
- **Nuevo**: `lib/features/settings/data/tables/discount_tiers_table.dart` — tabla drift.
- **Nuevo**: `lib/features/settings/data/discount_tiers_repository.dart` — stream ordenado
  por `sort_order`, upsert, delete, re-sort automático.
- **Nuevo**: `lib/features/calculation/domain/batch_discount_resolver.dart` — resolución
  pura del escalón aplicado.
- **Nuevo**: `lib/features/calculation/domain/batch_lot_composer.dart` — composición de
  lote pura (Decimal) que implementa las reglas 7–11 del PRD sección 3. **El motor
  unitario NO se toca** (decisión D1: "sin cambios sobre el contrato del motor unitario").
- **Nuevo**: `lib/features/settings/presentation/notifiers/discount_tiers_notifier.dart`
  (AsyncNotifier manual — patrón del repo, ver D6) y
  `lib/features/settings/presentation/widgets/discount_tiers_section.dart`.
- **Modifica**: `app_database.dart` (schemaVersion 12, migración aditiva),
  `calculations_table.dart` (+2 columnas batch TEXT NULL), `calculator_state.dart` /
  `calculator_notifier.dart` (campos de lote), `calculator_page.dart` (bottom bar +
  rename sección), `result_sheet.dart`, `quote_image_template.dart`, `pdf_export.dart`,
  `calculation_detail_page.dart` (recompute con batch), `calculation_repository.dart`
  (snapshot + CSV), `settings_page.dart` (reorden + nueva sección), l10n ×6 archivos.

## Implementation Steps

> DAG de dependencias entre fases:
>
> ```
> FASE 1 ──► FASE 2 ──► FASE 3
> FASE 1 ──► FASE 4
> FASE 1 ──► FASE 5
> FASE 6 (cierre, después de todo)
> ```
>
> FASE 4 y FASE 5 se pueden ejecutar en PARALELO después de FASE 1 (F4 usa el repo de
> F1; F5 usa las i18n de F1). Cada fase es mergeable por separado; PRs sugeridos en un
> solo branch `feat/hito1-lotes-reorganizacion`: PR-1 = F1+F2 (fundación + feature A
> visible), PR-2 = F3 (exports/snapshot), PR-3 = F4 (Ajustes), PR-4 = F5 (cotizador).

### FASE 0 — Setup · 1 task (0.5 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 0.1 | Pre-flight: leer el PRD (secciones A, D, 3, 4) y este plan; verificar `flutter analyze` y `flutter test` limpios en `main`. | — | CHECKPOINT |

### FASE 1 — Fundación: i18n + dominio + schema (A) · 9 tasks (6 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 1.1 | Agregar ~18 getters abstractos a `AppStrings` (sección `// === Hito 1: lotes y reorganización (T-H1) ===`): `calcSectionPieceCosts`, `calcSectionTarifas`, `settingsGroupEnergy`, `settingsGroupPrintingCosts`, `settingsGroupDiscountTiers`, `discountTierAdd`, `discountTierEdit`, `discountTierDelete`, `discountTierEmpty`, `discountTierHeaderMinQty`, `discountTierHeaderPercent`, `discountTierMinQty`, `discountTierPercent`, `discountTierValidationMinQty`, `discountTierValidationPercent`, `discountTierCapHint`, `calcDetailBatchDiscount(int pct)`, `quoteBatchDiscountPct(int pct)`, `pdfBatchDiscountPct(int pct)`. | `lib/l10n/app_strings.dart` | MODIFICA |
| 1.2 | Implementar los 19 strings en `EsImpl` — es_BO neutro (sin voseo). | `lib/l10n/es_bo.dart` | MODIFICA |
| 1.3 | Implementar en `EnImpl` (en_US). | `lib/l10n/en_us.dart` | MODIFICA |
| 1.4 | Implementar en `PtBrImpl` (pt_BR). | `lib/l10n/pt_br.dart` | MODIFICA |
| 1.5 | Implementar en `DeImpl` (de_DE) y `FrImpl` (fr_FR). El PRD lista 3 idiomas, pero `AppStrings` es abstract → el compilador exige las 5 impls (riesgo R2). | `lib/l10n/de_de.dart`, `lib/l10n/fr_fr.dart` | MODIFICA |
| 1.6 | Entidad `DiscountTier` (id TEXT UUID, minQty int, percent Decimal, sortOrder int; `toRow`/`fromRow`; validación min_qty ≥ 2 y 0 < % ≤ 100). | `lib/features/settings/domain/discount_tier.dart` | NUEVO |
| 1.7 | Tabla drift `DiscountTiersTable` (id TEXT PK, min_qty INTEGER NOT NULL, percent TEXT NOT NULL, sort_order INTEGER NOT NULL) + migración v11→v12 ADITIVA en `AppDatabase`: `schemaVersion = 12`, `onCreate` crea la tabla, `onUpgrade(11, 12)` la crea + agrega a `calculations` `batch_discount_percent TEXT NULL` y `batch_discount_amount TEXT NULL` (defaults NULL = comportamiento actual intacto). | `lib/features/settings/data/tables/discount_tiers_table.dart` (NUEVO), `lib/core/database/app_database.dart`, `lib/features/calculation/data/tables/calculations_table.dart` | NUEVO + MODIFICA |
| 1.8 | Test de migración v11→v12 (patrón exacto de `migration_v10_to_v11_test.dart`: seed raw del schema v11 = v10 + `filaments.color TEXT NULL`, `PRAGMA user_version = 11`, `NativeDatabase.opened` + `AppDatabase.forTesting`): verificar `discount_tiers` vía `pragma_table_info`, columnas batch TEXT nullable en `calculations`, fila existente preservada, `user_version = 12`; re-open idempotente. | `test/integration/migration_v11_to_v12_test.dart` | NUEVO |
| 1.9 | `DiscountTiersRepository`: `watchAll()` stream ordenado por `sort_order`, `upsert`, `delete`, re-sort/slot automático en guardado. Unit tests (insert, update, delete, orden, stream). | `lib/features/settings/data/discount_tiers_repository.dart` (NUEVO), `test/unit/discount_tiers_repository_test.dart` (NUEVO) | NUEVO |

### FASE 2 — Motor de lote + UI del cotizador (A) · 6 tasks (6 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 2.1 | `BatchDiscountResolver` (función pura): aplica el escalón con mayor `min_qty ≤ N`; N bajo el primer escalón → null (0 % sin línea); validaciones del tier. Tests: N=10 → 10 %; N=1 sin escalón → null; escalones [10→10 %, 25→15 %] con N=26 → 15 %; empate por `sort_order`. | `lib/features/calculation/domain/batch_discount_resolver.dart` (NUEVO), `test/unit/batch_discount_resolver_test.dart` (NUEVO) | NUEVO |
| 2.2 | `BatchLotComposer` (puro, Decimal): `subtotal_impresion = (baseCost + failureCost + markupCost) × N`; `desc_cantidad = % × subtotal_impresion`; `desc_manual = manual% × (output.totalFinal × N)` (decisión D2: base total como hoy, incluye ganancia); `total = max(totalFinal × N − desc_cantidad − desc_manual, minimumCharge × N)`; `unitario = total ÷ N`. Punto de extensión para hitos 2/3: parámetro opcional de insumos/servicios sin romper el contrato actual. Tests: ejemplo de verificación del PRD adaptado a hito 1 (N=10, base 20, falla 10 %, markup 5 % × 8 = 0,40, escalón 10→10 %, manual 0 → subtotal_impresion 224,00, desc_cantidad 22,40, total 201,60); 95 %: N=1 sin tier → idéntico al math de hoy; profit > 0 → la base de desc_manual no cambia. | `lib/features/calculation/domain/batch_lot_composer.dart` (NUEVO), `test/unit/batch_lot_composer_test.dart` (NUEVO) | NUEVO |
| 2.3 | `CalculatorState` += `batchAppliedPercent`, `batchDiscountAmount`, `subtotalImpression`, `lotTotal` y flag `showsBatchLine`; `calculator_notifier._recompute`: cuando `quantity > 1` y el resolver devuelve escalón → componer vía `BatchLotComposer`; N=1 o sin escalón → los campos quedan en cero y el flujo es literalmente el actual. | `lib/features/calculation/presentation/state/calculator_state.dart`, `lib/features/calculation/presentation/state/calculator_notifier.dart` | MODIFICA |
| 2.4 | Bottom bar del cotizador (hoy `totalPrice * Decimal.fromInt(quantity)` en `calculator_page.dart:676-677`): usar `lotTotal` del estado; cuando `showsBatchLine`, renderizar línea SEPARADA `calcDetailBatchDiscount(pct)` antes del descuento manual (patrón línea actual de descuento ~713); hint junto al campo Cantidad ("X % desde N u."). | `lib/features/calculation/presentation/pages/calculator_page.dart` | MODIFICA |
| 2.5 | CHECKPOINT (D1): `DetailSection` NO se toca — sigue unitario hasta `totalFinal`; las líneas de descuento las renderizan los consumidores (bottom bar, result sheet, image, PDF). | `lib/features/calculation/presentation/widgets/detail_section.dart` | CHECKPOINT |
| 2.6 | Widget tests: Express con N=1 y sin escalones → cero líneas nuevas y total idéntico (regla 95 %); N=10 con escalón 10 % → 2 líneas ("Descuento por cantidad (10 %)" y "Descuento (X %)"). | `test/widget/lot_lines_test.dart` | NUEVO |

### FASE 3 — Exports, snapshot e historial (A) · 7 tasks (5 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 3.1 | `QuoteImageTemplate`: parámetros `batchDiscountPct`/`batchDiscountAmount`; línea "Descuento por cantidad (X %)" + monto (patrón existente `quoteDiscountPct`/`discountAmount * qty` en ~260-261); `displayTotal` = `unitPrice × qty` se mantiene. | `lib/features/calculation/presentation/widgets/quote_image_template.dart` (MODIFICA), `test/unit/quote_image_template_test.dart` (MODIFICA) | MODIFICA |
| 3.2 | `pdf_export`: mostrar línea batch escalada ×N y restarla del total (patrón `dDiscountAmount = output.discountAmount * qtyD` en ~372; línea `calcLabelDiscount` en ~667); `displayTotal = unitPrice × qtyD` se mantiene; línea desglosada `N × unitario`. | `lib/core/export/pdf_export.dart` (MODIFICA), `test/unit/pdf_export_test.dart` (MODIFICA) | MODIFICA |
| 3.3 | `result_sheet`: línea batch antes de la línea del descuento manual (`EsBO.calcLabelDiscount` en `result_sheet.dart:903`). | `lib/features/calculation/presentation/widgets/result_sheet.dart` | MODIFICA |
| 3.4 | Snapshot al guardar: `CalculationsCompanion` incluye `batch_discount_percent`/`batch_discount_amount` (TEXT, NULL cuando no aplica); `calculation_repository` insert/read + CSV export con los 2 campos nuevos. | `lib/features/calculation/data/calculation_repository.dart` | MODIFICA |
| 3.5 | Detail page: recompute del lote desde snapshots con `qty` (patrón `calculation_detail_page.dart:1054-1055` y líneas de desglose ~596-666): línea batch (pct snapshot + monto ×qty) antes del descuento manual; snapshot NULL → sin línea (95 %). | `lib/features/calculation/presentation/pages/calculation_detail_page.dart` | MODIFICA |
| 3.6 | Historial/CSV (donde se exporta el CSV, tooltip `historyExportCsv` en Historial): agregar columnas batch al export; la suma de `effectiveTotal` (dashboard `home_page.dart:891,975`) ya toma el total guardado. | `lib/features/calculation/presentation/pages/calculations_list_page.dart` (verificar dónde se genera el CSV) | MODIFICA |
| 3.7 | Tests: `quote_save_flow_test.dart` aserción snapshot guardado con escalón y NULL sin escalón; `dashboard_stats_test.dart` si assert descuentos. | `test/widget/quote_save_flow_test.dart`, `test/unit/dashboard_stats_test.dart` | MODIFICA |

### FASE 4 — Ajustes: reorden + sección "Descuentos por cantidad" (A + D) · 6 tasks (4.5 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 4.1 | Reordenar `settings_page.dart`: partir "Parámetros globales" (~l.140-201) en grupo **"Energía"** (solo kWh) y grupo **"Costos de impresión"** (solo Ganancia base %); orden resultante: Empresa → Energía → Costos de impresión → Descuentos por cantidad → Catálogos (~l.217) → Moneda e idioma → Apariencia → Datos → Cuenta → Acerca. (Decisión D10: el PRD lista solo los 5 primeros; el resto mantiene orden relativo.) | `lib/features/settings/presentation/pages/settings_page.dart` (MODIFICA), `test/widget/settings_page_test.dart` (MODIFICA: aserciones de orden de títulos) | MODIFICA |
| 4.2 | `DiscountTiersNotifier`: `AsyncNotifier` manual sobre el repo (patrón `settings_notifier.dart` — ver D6); exposición del listado ordenado. | `lib/features/settings/presentation/notifiers/discount_tiers_notifier.dart` | NUEVO |
| 4.3 | `DiscountTiersSection`: tabla de escalones (min_qty | % | acciones editar/eliminar), add/edit vía bottom sheet con validación (`min_qty ≥ 2`, `% 0–100`, cap 10 default decisión P5), auto-sort al guardar, empty state (`discountTierEmpty`); SIN badge Pro ni paywall (FREE, decisión P1). | `lib/features/settings/presentation/widgets/discount_tiers_section.dart` | NUEVO |
| 4.4 | Wire de la sección dentro del nuevo grupo "Descuentos por cantidad". | `lib/features/settings/presentation/pages/settings_page.dart` | MODIFICA |
| 4.5 | Widget tests: CRUD completo, validaciones (min_qty 1 rechazada, % 101/0 rechazada), persistencia tras rebuild, ausencia de badge Pro. | `test/widget/discount_tiers_section_test.dart` | NUEVO |
| 4.6 | Unit tests del notifier (estados empty/loaded/error, orden). | `test/unit/discount_tiers_notifier_test.dart` | NUEVO |

### FASE 5 — Reorganización del cotizador (D) · 4 tasks (2.5 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 5.1 | Renombrar la sección colapsable: header usa `calcSectionPieceCosts` ("Costos de la pieza", zona ~1090-1200 de `calculator_page.dart`); estructura de subgrupos con SOLO "Tarifas" (los 4 campos actuales labor/post-process/failure/markup, gate Pro por ítem sin cambios — decisión P1); Insumos/Servicios NO se renderizan en hito 1 (regla 95 %); `_OtrosPeekPreview` (l.2651+) muestra los 4 labels de tarifas como hoy. | `lib/features/calculation/presentation/pages/calculator_page.dart` | MODIFICA |
| 5.2 | Deprecar `calcSectionOthers`: marcar `@Deprecated` en `AppStrings`/`EsBO` y las 5 impls; eliminar usos. | `lib/l10n/app_strings.dart`, `lib/l10n/es_bo.dart`, `lib/l10n/en_us.dart`, `lib/l10n/pt_br.dart`, `lib/l10n/de_de.dart`, `lib/l10n/fr_fr.dart` | MODIFICA |
| 5.3 | Actualizar tests que referencian "Otros": `pro_badge_navigation_test.dart` (AC-103 "badge del header 'Otros'" → "Costos de la pieza") y `pro_locked_visual_test.dart` (~l.428). | `test/widget/pro_badge_navigation_test.dart`, `test/widget/pro_locked_visual_test.dart` | MODIFICA |
| 5.4 | Widget test nuevo: sección renombrada visible; en free el subgrupo Tarifas muestra badge Pro y tap → paywall (patrón existente); en Pro contenido idéntico al actual. | `test/widget/piece_costs_section_test.dart` | NUEVO |

### FASE 6 — Verificación final · 2 tasks (1.5 h)

| # | Task | Archivo(s) | Tipo |
|---|---|---|---|
| 6.1 | `dart format --set-exit-if-changed lib/ test/`, `flutter analyze`, `flutter test` (suite completa) y verificación de coverage targets. | — | CHECKPOINT |
| 6.2 | QA manual: Express N=1 sin escalones idéntico (95 %); N=10 con escalón → 2 líneas en bottom bar, result sheet, imagen y PDF; guardado → snapshot correcto en detalle/historial; editar escalones no altera cotizaciones previas; Ajustes en el orden indicado; CRUD de escalones y validaciones; 5 idiomas sin strings crudos. | — | CHECKPOINT |

## Testing Strategy

- **Unit (dominio, puros)**: `batch_discount_resolver_test.dart` (≥90 %), `batch_lot_composer_test.dart` (≥90 % — incluye ejemplo PRD y regla 95 %), `discount_tiers_repository_test.dart` (≥80 %), `discount_tiers_notifier_test.dart` (≥75 %).
- **Integración**: `migration_v11_to_v12_test.dart` (patrón v10→v11: seed raw, `PRAGMA user_version`, `AppDatabase.forTesting`, verificaciones con `pragma_table_info` y datos preservados).
- **Widget**: `lot_lines_test.dart`, `discount_tiers_section_test.dart`, `piece_costs_section_test.dart` (nuevos); actualizar `settings_page_test.dart`, `pro_badge_navigation_test.dart`, `pro_locked_visual_test.dart`, `quote_save_flow_test.dart`.
- **Regresiones**: `calculation_engine_test.dart`, `calculator_notifier_test.dart`, `pdf_export_test.dart`, `quote_image_template_test.dart`, `calculations_notifier_test.dart` deben pasar SIN cambios de aserciones donde el motor no cambió.

## Risks & Mitigations

| Riesgo | Mitigación |
|---|---|
| **R1 — Base del descuento manual con ganancia (gap del PRD)**: la fórmula 10 del PRD excluye la ganancia del `subtotal`, pero el comportamiento actual la incluye (`totalFinal`); el ejemplo del PRD usa profit 0 y no discrimina. | Decisión D2: mantener base actual (`totalFinal × N`, incluye ganancia) para `desc_manual` ("comportamiento actual escalado" + regla 95 %). Si el dueño de producto quiere la fórmula literal, el cambio es una línea en `BatchLotComposer` con test asociado. |
| **R2 — 5 locales vs "tres idiomas" del PRD**: el repo tiene `EsImpl`, `EnImpl`, `PtBrImpl`, `DeImpl`, `FrImpl`; `AppStrings` abstract rompe el build si no se implementan las 5. | Tasks 1.2–1.5 cubren las 5 impls; los strings de de/fr siguen el estilo existente. |
| **R3 — Cantidad gateada Pro (hoy)**: `_buildQuantitySection` está detrás de paywall; usuarios free configuran escalones que nunca disparan (N=1 fijo). El PRD no reabre ese gate. | Fuera de alcance del hito 1 (flag para futuro): documentar en el plan; la lógica de lote es FREE y funcionará para Pro. |
| **R4 — Schema del PRD M1 "única"**: el PRD define UNA migración con tablas de B/C; este hito solo crea `discount_tiers` + columnas batch. | Migración partida por hito (M1-A ahora; M1-B/C en hitos 2/3) — coherente con "un plan por hito" y "cada hito enviable por sí solo"; columnas de A con defaults NULL preservan comportamiento. |
| **R5 — Snapshots actuales en `REAL` (double)** vs regla "dinero TEXT `decimal`": las columnas de snapshot existentes son `REAL`; las nuevas batch deben ser TEXT y parsearse con `Decimal.parse` al leer. | Columnas batch TEXT NULL (no REAL); CSV/detalle leen y formatean vía `decimal` (patrón `DecimalParse.fromString`). |
| **R6 — Regresión de "Otros" en tests existentes** (AC-103 badges, locked visual). | Tasks 5.3/5.4 actualizan las aserciones con el nuevo nombre; la sección mantiene el mismo gate por ítem. |

## Success Criteria

- [ ] `discount_tiers` creada y migración v11→v12 aditiva con tests (datos preservados, idempotente).
- [ ] CRUD de escalones en Ajustes → "Descuentos por cantidad" (FREE, validación min_qty ≥ 2, % 0–100, auto-sort, cap 10).
- [ ] N=10 con escalón 10 % → línea SEPARADA "Descuento por cantidad (10 %)" sobre `subtotal_impresion` en bottom bar, result sheet, imagen y PDF; el descuento manual sigue su línea y base actual.
- [ ] N=1 o sin escalones → cero líneas nuevas, total y flujo idénticos (regla 95 %).
- [ ] Snapshot `batch_discount_percent`/`_amount` guardado en `calculations` (NULL sin escalón); editar escalones después no cambia cotizaciones pasadas.
- [ ] Sección "Otros" → "Costos de la pieza"; subgrupo "Tarifas" conserva el gate Pro por ítem; `calcSectionOthers` deprecado.
- [ ] Ajustes en orden: Empresa / Energía / Costos de impresión / Descuentos por cantidad / Catálogos / Moneda e idioma / Apariencia / Datos / Cuenta / Acerca.
- [ ] i18n completa en 5 locales, es_BO neutro; `flutter analyze` y `flutter test` limpios.

## Verificación (comandos)

```powershell
dart format --set-exit-if-changed lib/ test/
flutter analyze
flutter test
# Coverage de targets (si el repo tiene script de coverage):
flutter test --coverage test/unit/batch_lot_composer_test.dart test/unit/batch_discount_resolver_test.dart
```

## Estimación rough

- FASE 0: 0,5 h · FASE 1: 6 h · FASE 2: 6 h · FASE 3: 5 h · FASE 4: 4,5 h · FASE 5: 2,5 h · FASE 6: 1,5 h
- **Total: ≈ 26 h** (incluye tests; 3–4 sesiones de trabajo enfocado).
- **Coverage target global**: `batch_lot_composer.dart` ≥ 90 % · `batch_discount_resolver.dart` ≥ 90 % · `discount_tiers_repository.dart` ≥ 80 % · `discount_tiers_notifier.dart` ≥ 75 % · `discount_tiers_section.dart` ≥ 70 % · `calculation_engine.dart` se mantiene ≥ 95 % (intacto).