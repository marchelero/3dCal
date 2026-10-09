# Sesión 2026-10-09 — F5: amortización de impresora fuera del costo y de los reportes

**Objetivo**: que `purchaseCost`/`usefulLifeHours` (amortización de la impresora) **no entren en el costo** de la cotización (express ni avanzado) y **no aparezcan en ningún reporte** (PDF, imagen PNG, detalle en pantalla, fila de tasas), sin tocar schema/DB y manteniendo el formulario de impresora.

**Resultado**: hecho. `flutter analyze` **0 issues** · `flutter test` **971/971** · **sin commit** (falta verbo).

## Mapeo criterios A1..A5
| # | Criterio | Estado |
|---|---|---|
| A1 | Motor: amortización **no** entra en `coreBase` (express ni avanzado) → total idéntico con/sin amortización cargada | ✅ `coreBase = materialCost + electricCost` en `compute()` y `computeFromSnapshot()`; test de paridad nuevo |
| A2 | `CalculationOutput.amortizationCost` = 0 (nada downstream suma amortización) | ✅ fuerza `Decimal.zero` en ambas vías; `resolveRates` ignora `amortizationCostSnapshot` |
| A3 | Reportes sin fila/nota de amortización: PDF (desglose + fila de tasas + nota), imagen PNG (tabla de tasas), detalle en pantalla | ✅ filas/bloque/nota eliminados |
| A4 | Sin romper contratos: se **conservan** campos/params (`detailAmortizationCost`, `ResolvedRates.amortizationCost`, `amortizationCostSnapshot`, `PdfRateAudit.amortizationPerHour`→`null`, `CalculationOutput.amortizationCost`) | ✅ sólo cambian valores/documentación |
| A5 | Sin cambios de schema/DB ni l10n; formulario de impresora intacto | ✅ cero cambios en `app_database.g.dart`, repos de impresora, `printer_form_page.dart` y archivos `.arb` |

## Archivos modificados (11 míos)
**Dominio**
- `lib/features/calculation/domain/calculation_engine.dart` — doc de fórmula (sin `amortCost`), `coreBase` sin amortización en `compute()` y `computeFromSnapshot()`, salidas en `Decimal.zero`, `resolveRates` fuerza `amortizationCost: Decimal.zero` (param `amortizationCostSnapshot` conservado e ignorado).
- `lib/features/calculation/domain/entities/calculation_output.dart` — documentación: `amortizationCost` siempre 0.

**Export / reportes**
- `lib/core/export/pdf_rate_audit.dart` — `fromRates` → `amortizationPerHour: null`; docs actualizados.
- `lib/core/export/pdf_export.dart` — eliminados `dAmortizationCost`, fila de desglose, fila `(EsBO.pdfRateAmortization, …)`, bloque de nota, helper `money()` y el param `currency` de `_buildRateAuditBlock` (call site incluido).

**UI**
- `lib/features/calculation/presentation/widgets/quote_image_template.dart` — eliminada la fila de amortización de la tabla de tasas (param `detailAmortizationCost` conservado).
- `lib/features/calculation/presentation/widgets/detail_section.dart` — eliminada la fila "Amortización máquina" y el término de `hasExtras`.
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart` — eliminados `amortizationUnit` y el `_Row` de amortización.
- `lib/features/calculation/presentation/state/calculator_notifier.dart` — comentarios F5 (`ResolvedRates`, `_buildInput`); valores ahora 0.

**Tests**
- `test/unit/calculation_engine_test.dart` — AC1 (total 12/12, amort 0), AC2 → **test de paridad** con/sin amortización, profit → 24/36, v17 → `laborCost` 7.5 / `baseCost` 22.5.
- `test/unit/database_repositories_test.dart` — motor espera 0; persistencia/duplicate probadas con `CalculationOutput` manual de 1.75.
- `test/unit/quote_report_variant_test.dart` — audit `amortizationPerHour` → `isNull` (×2) y fila de tasas → `Decimal.zero`.

## Notas de formato (importante para el próximo turno)
- Docs (`README.md:161`, planes) dicen `dart format` **line_length 100**, pero el repo está formateado a **80** con el formatter actual: `git cat-file blob HEAD:lib/core/export/pdf_export.dart` formateado a 80 → **0 cambios**; a 100 → reflow masivo (710/1381).
- Además 5 archivos arrastran **drift por versión de formatter** (HEAD ≠ format@80): `calculation_detail_page` (65/75), `calculation_engine_test` (60/75), `calculator_notifier` (11/11), `quote_report_variant_test` (5/5), `quote_image_template` (3/3).
- Recuperación hecha: `git merge-file` 3-vías por archivo (`base = format@80(HEAD)`, `ours = HEAD`, `theirs = mi estado`) → churn de formato eliminado; 1 conflicto resuelto a mano en `calculation_engine_test.dart` (test v17: se conserva la versión F5). **No correr `dart format --line-length 100` sobre el repo.**

## Verificación
- `flutter analyze` → **No issues found!** (10.5s)
- `flutter test test/unit/{calculation_engine,database_repositories,quote_report_variant}_test.dart` → **121 passed**
- `flutter test` (suite completa) → **02:17 +971: All tests passed!**

## Riesgos / pendientes sin tocar
- **l10n**: cadenas de amortización (`calcDetailAmortization`, `pdfRateAmortization`, …) siguen en los `.arb`; nadie las renderiza. Opcional: limpiar en tarea aparte.
- **`ResolvedRates.amortizationCost` / `detailAmortificationCost`**: siguen en el estado/params con valor 0 (A4). Si se quiere reducir API, requiere tocar consumidores.
- **`amortizationPerHour()` del motor** sigue existiendo (informativo) y `printers.purchase_cost/useful_life_hours` se siguen persistiendo/editando.
- **Snapshot viejo**: cotizaciones guardadas con `amortizationCostSnapshot > 0` ahora muestran 0 y total recalculado; decisión deliberada (test cubre el caso).
- **README/PLANES**: dicen line_length 100, realidad 80 (ver arriba).

## Estado git
- **NO commit** (sin verbo en la sesión).
- Míos: los 11 de arriba.
- Ajenos (otra sesión paralela "release gates", NO tocar): `.gitignore`, `pubspec.yaml`, `pubspec.lock`, `lib/core/constants/app_constants.dart`, `docs/notes/store-compliance.md`, `docs/LATEST.md`, `docs/sessions/LATEST.md`, `docs/reports/2026-10-09_release-gates.report.md`, `docs/sessions/2026-10-09_release-gates.md`.
- HEAD: `cf3c065`. Backup del diff completo pre-reparación: `%TEMP%\opencode\f5_backup.patch`.
- Sesión paralela: `docs/sessions/2026-10-09_release-gates.md` (3/3 gates, también 971/971).
- Sesión previa: `docs/sessions/2026-10-08_tier2-a11y-sec-docs.md` (commiteado `cf3c065`).
