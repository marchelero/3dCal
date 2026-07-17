# Plan Maestro: 3dCalc F1-F7

> **Estado**: F1 COMPLETO, F2 COMPLETO parcial (falta PDF en detail page + tests)
> **Ultima actualizacion**: 2026-07-17
> **Stack**: Flutter 3.x, Drift (SQLite), Riverpod 2.x, Decimal, fl_chart, go_router
> **Tests**: 127/128 pass (1 fail pre-existente en settings header)

---

## F1 (P0) — Mano de obra + Post-procesado ✅ COMPLETO

### Status: 100%

### Changes
- 5 nuevas settings: laborRate, postProcessRate, failureRate, minimumCharge (removida post-feedback), markupOnMaterials
- DB migration v2→v3 con 11 nuevas columnas snapshot
- Engine formula actualizada con cadena completa:
  ```
  materialCost + electricCost + laborCost + postProcessCost = baseCost
  baseCost + failureCost + markupCost + profitAmount = total
  max(total, minimumCharge) - discount = totalPrice
  ```
- `minimumCharge` removida post-feedback por no ser usada
- UI: seccion OTROS collapsable en calculator (Express + Advanced)
- 4 campos en grid 2x2: Mano obra (Bs/h), Post-procesado (%), Tasa falla (%), Desperdicio (%)
- DetailSection expandida con 7 filas de desglose
- SummaryCard, QuoteImageTemplate, calculation_detail_page actualizados
- Draft storage actualizado con OTROS fields
- Formula verificada manualmente: 23g@200/1000 + 1h + 2 Bs/h labor = 6.60 total

### Files principales modificados
- `lib/features/calculation/domain/calculation_engine.dart`
- `lib/features/calculation/domain/entities/calculation_input.dart`
- `lib/features/calculation/domain/entities/calculation_output.dart`
- `lib/features/calculation/presentation/state/calculator_state.dart`
- `lib/features/calculation/presentation/state/calculator_notifier.dart`
- `lib/core/database/app_database.dart` (migration v2→v3)
- `lib/features/calculation/data/tables/calculations_table.dart` (11 columnas)
- `lib/features/calculation/data/calculation_repository.dart`
- `lib/core/storage/calculation_draft.dart`
- `lib/features/calculation/presentation/pages/calculator_page.dart` (UI OTROS)
- `lib/features/calculation/presentation/widgets/summary_card.dart`
- `lib/features/calculation/presentation/widgets/quote_image_template.dart`
- `lib/features/calculation/presentation/widgets/result_sheet.dart`
- `lib/features/calculation/presentation/widgets/detail_section_widget.dart`
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart`

---

## F2 (P1) — Export PDF/CSV + Historial search/filter ✅ CASI COMPLETO

### Status: ~90%

### Sub-fases

#### F2.1 — Search/filter en historial ✅
- Repository: metodo `search(String query)` con SQL LIKE en pieceName/clientName
- `CalculationsNotifier`: rewrite con cache `_all`, filtros por texto + sold/pending/all
- List page: convertida a ConsumerStatefulWidget con SearchBar + FilterChips
- EmptyView con mensaje "Sin resultados" para busquedas sin match
- 129/130 tests

#### F2.2 — CSV export ✅
- Boton `file_download` en AppBar del historial
- Genera CSV con columnas: Fecha, Pieza, Cliente, Total, Vendido, CostoMat, Elect, Profit, Materiales, Horas, Descuento
- `formatRaw()` para doubles sin separadores de miles
- `_escapeCsv()` para manejar comillas/commas
- Comparte via `Share.shareXFiles()` (ShareXFile)

#### F2.3 — PDF export 🔶 EN PROGRESO (falta CI/CD test)
- Paquete `pdf: ^3.13.0` agregado a pubspec.yaml
- `lib/core/export/pdf_export.dart` creado con PDF programatico
- Contenido: header (logo+nombre), fecha, pieza, total hero, desglose completo, materiales, meta, footer
- Boton PDF (icono rojo `picture_as_pdf`) agregado a `_ActionIconRow` en result sheet
- Llamada a `shareQuotePdf()` con datos del state
- **Pendiente**: agregar boton PDF a `CalculationDetailPage`
- **Pendiente**: verificar 6 test fails (probablemente pre-existentes o por PDF)

### Files F2
- `lib/core/export/pdf_export.dart` (nuevo)
- `lib/features/calculation/data/calculation_repository.dart` (search)
- `lib/features/calculation/presentation/notifiers/calculations_notifier.dart`
- `lib/features/calculation/presentation/pages/calculations_list_page.dart`
- `lib/features/calculation/presentation/widgets/result_sheet.dart`
- `pubspec.yaml` (pdf package)

---

## F3 (P1) — Dashboard v2

**Status**: ❌ NO INICIADO

### Scope
- Trends mensuales (cotizado vs vendido por mes)
- Profit real vs estimado
- Filtros por periodo (semana/mes/ano)
- Top materiales mas usados
- Widgets financieros adicionales

### Pending decisions
- Diseno de graficos (fl_chart ya presente, extender)
- Query de agrupacion mensual en repository
- Widget de selector de periodo

---

## F4 (P1) — Multi-moneda USD

**Status**: ❌ NO INICIADO

### Scope
- Toggle BOB/USD en settings y calculator
- Tipo de cambio manual configurable
- CurrencyFormatter soporte multi-moneda
- Mostrar ambos precios (BOB + USD) en quotes

### Pending decisions
- Donde poner el toggle? Settings? Calculator header?
- Rate: manual o fetch automatico (BCB API?)

---

## F5 (P1) — Catalog search

**Status**: ❌ NO INICIADO

### Scope
- Search bar en dialogos de seleccion de filamento/impresora
- Filtrar por nombre, marca, tipo

### Notas
- Dialogos actuales: `_FilamentPickerDialog`, `_PrinterPickerDialog`
- Agregar TextField + filtrado en memoria

---

## F6 (P2) — Multi-idioma EN

**Status**: ❌ NO INICIADO

### Scope
- Sistema de localizacion propio (no Flutter intl)
- Traduccion EN completa (~140 strings en `es_bo.dart`)
- Toggle idioma en settings
- Locale persistido

### Notas
- `es_bo.dart` tiene todas las strings en espanol
- Crear `en_us.dart` con mismas keys
- Renombrar a `app_strings.dart` + delegar por locale

---

## F7 (P2) — Print quote + Onboarding

**Status**: ❌ NO INICIADO

### Scope
- Web print stylesheet para QuoteImageTemplate
- 4 pantallas de onboarding (swipeable)
- Skip button + "No mostrar mas"
- Onboarding solo en primera ejecucion

---

## Estructura de archivos del proyecto

```
lib/
├── core/
│   ├── export/
│   │   └── pdf_export.dart          # F2.3 — generador PDF
│   ├── share/
│   │   └── quote_share.dart         # PNG share pipeline
│   ├── storage/
│   │   └── calculation_draft.dart   # F1 — OTROS fields agregados
│   ├── constants/
│   │   └── app_constants.dart       # F1 — settings keys + defaults
│   └── database/
│       └── app_database.dart        # F1 — migration v2→v3
├── features/
│   ├── calculation/
│   │   ├── domain/
│   │   │   ├── calculation_engine.dart       # F1 — formula completa
│   │   │   └── entities/
│   │   │       ├── calculation_input.dart     # F1 — 11 params
│   │   │       └── calculation_output.dart    # F1 — 15 fields breakdown
│   │   ├── data/
│   │   │   ├── tables/
│   │   │   │   └── calculations_table.dart   # F1 — 11 columnas nuevas
│   │   │   └── calculation_repository.dart   # F2 — search()
│   │   └── presentation/
│   │       ├── state/
│   │       │   ├── calculator_state.dart     # F1 — OTROS fields
│   │       │   └── calculator_notifier.dart  # F1 — buildInput con OTROS
│   │       ├── notifiers/
│   │       │   └── calculations_notifier.dart # F2 — search/filter
│   │       ├── pages/
│   │       │   ├── calculator_page.dart      # F1 — section OTROS collapsable
│   │       │   ├── calculations_list_page.dart # F2 — search + CSV
│   │       │   └── calculation_detail_page.dart # F1 — breakdown detail
│   │       └── widgets/
│   │           ├── result_sheet.dart          # F2 — boton PDF
│   │           ├── summary_card.dart          # F1 — breakdown rows
│   │           ├── quote_image_template.dart  # F1 — breakdown rows
│   │           └── detail_section_widget.dart # F1 — breakdown rows
│   └── settings/
│       ├── domain/settings.dart               # F1 — 5 nuevos fields
│       ├── data/settings_repository.dart      # F1 — 5 typed accessors
│       └── presentation/.../settings_notifier.dart # F1 — 5 update methods
└── ...
```

## Metricas

| Fase | Prioridad | Status | Tests | Archivos tocados |
|------|-----------|--------|-------|-----------------|
| F1   | P0        | ✅ 100% | 127/128 | ~20 |
| F2   | P1        | 🔶 ~90% | 127/128 | ~8 |
| F3   | P1        | ❌ 0%   | - | - |
| F4   | P1        | ❌ 0%   | - | - |
| F5   | P1        | ❌ 0%   | - | - |
| F6   | P2        | ❌ 0%   | - | - |
| F7   | P2        | ❌ 0%   | - | - |
