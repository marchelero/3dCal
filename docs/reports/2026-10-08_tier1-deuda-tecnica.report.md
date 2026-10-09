# Reporte — Tier 1: deuda técnica (god widget, estado, descuentos, guard base64)

**Fecha:** 2026-10-08
**Rama:** `main`
**PRD:** `docs/prds/2026-10-08_1430-tier1-deuda-tecnica.prd.md`
**Alcance:** 4/4 ítems del Tier 1 (T1-1 god widget, T1-2 estado → Riverpod, T1-3 fórmula de
descuento unificada, T1-4 guard de `base64Decode`).
**Estado:** COMPLETADO. `flutter analyze` → **0 issues**. `flutter test` → **947/947 pasan**
(baseline 838 + 109 nuevos: 3 T1-4 + 5 T1-2 + 101 T1-3).
**Commit:** NO realizado (pendiente de consentimiento explícito).

---

## Ítems entregados

### T1-1 — Descomponer el god widget `build` (`result_sheet.dart`)
- `_ResultSheetContentState.build` (~491 líneas, terminaba en `:1134`) descompuesto en
  sub-widgets privados añadidos tras la clase estado:
  `_SheetTitleBlock`, `_CapturableQuote` (RepaintBoundary + QuoteImageTemplate),
  `_PreviewControlsRow`, `_QuantityCard` (ConsumerWidget, con `ref` propio para `setQuantity`),
  `_DiscountTotalCard`. `build` termina ahora en `:786`.
- Sin cambios en árbol renderizado, keys, textos ni estilos → `result_sheet_test.dart` y
  `quote_image_template_test.dart` verdes sin tocar expectativas.

### T1-2 — Estado de negocio → Riverpod (`calculation_detail_page.dart`)
- Nuevo `lib/features/calculation/presentation/state/detail_view_provider.dart`:
  `DetailViewState` inmutable (variant + quantity), `clampDetailQuantity`, `initialDetailViewState`,
  `DetailViewNotifier` y `detailViewProvider = NotifierProvider.autoDispose<...>`.
- **Diseño**: el estado arranca en `null` (= sin editar); mientras es `null`, la pantalla resuelve
  los valores guardados con `initialDetailViewState(widget.calc)`. La primera edición materializa
  el estado con copia (`copyWith`). Así no hay que sembrar el provider en `initState` — Riverpod 3
  lo prohíbe ("Tried to modify a provider while the widget tree was building") — y el primer frame
  ya muestra los valores guardados.
- `_reportVariant` y `_quantity` salen de `setState`: leídos vía `_view`, escritos vía
  `detailViewProvider.notifier` (`setVariant/setQuantity/decrement/increment`, todos con `calc`
  como fallback). `_isBusy` queda local con comentario (estado efímero de UI). `ref.watch` en
  `build` reconstruye al cambiar.
- Tests: `test/unit/detail_view_provider_test.dart` (5) — clamp, derivación de variante,
  materialización perezosa, no-op redundantes; widget tests existentes del detalle verdes.

### T1-3 — Unificar fórmula de descuento
- Nuevo `lib/features/calculation/domain/manual_discount.dart` — fuente ÚNICA:
  - `ManualDiscount.scaled(unitDiscountAmount, quantity)` = `unitDiscountAmount × N` (N < 1 → 1,
    0 si el unitario ≤ 0).
  - `ManualDiscount.pctOf(amount, pct)` = `amount × pct / 100` con redondeo escala 6.
- Migrados todos los call sites (sin cambiar semántica):
  - `pdf_export.dart:604` → `ManualDiscount.scaled(...)`.
  - `quote_image_template.dart:355` y `:685` → `ManualDiscount.scaled(...)`.
  - `calculation_detail_page.dart` → `_lotFigures.manualAmount` usa `ManualDiscount.scaled(...)`; y
    la fila de descuento en pantalla (`:641`) ahora usa `lot.manualAmount` (5to call site que
    re-derivaba `discountAmount × qty`, ahora una sola fuente).
  - `batch_lot_composer.dart` elimina `_pctOf` local (delega en `ManualDiscount.pctOf`);
    `lot_totals.dart` `batchAmount` idem.
- Tests golden de equivalencia: `test/unit/manual_discount_test.dart` (101) — `scaled` == legacy
  `discountAmount × N`; `scaled(pctOf(tf,pct),N) == pctOf(tf×N,pct)`; composer/manual == helper;
  escalón + descuento + piso conserva `max(totalFinal×N − desc_cantidad − desc_manual, piso)`;
  `LotTotals.batchAmount` == helper. `batch_lot_composer_test.dart`, `calculation_engine_test.dart`
  y `quote_report_variant_test.dart` verdes sin debilitar.

### T1-4 — Guard de `base64Decode` de logo (`pdf_export.dart`)
- `_tryDecodeLogoImage(String?)` envuelve `base64Decode` Y la construcción del `pw.MemoryImage`
  (bytes base64 válidos pero no-imagen también crasheaban). Si falla → `debugPrint` + `null`
  (PDF sin logo, no crashea). `_buildHeader` usa `logoImage != null` para el `pw.Image`.
- Test: `test/unit/pdf_export_logo_guard_test.dart` (3) — logo corrupto, base64 válido-no-imagen,
  y sin logo; el PDF resultante es no vacío.

---

## Verificación

- `flutter analyze` → `No issues found!`
- `flutter test` → **947/947** (2m 25s), incluye suites existentes del cálculo/reporte sin relajar
  aserciones.
- Regresión transversal del PRD: cero cambios de montos (los 101 tests T1-3 atan los helpers a los
  valores previos con `Decimal` exacto, sin redondeos nuevos).

## Fuera de alcance (sigue pendiente)
- Commit/push (requiere verbo explícito).
- Tier 2: a11y (contraste, text-scale, `Color(0x`), SEC-01/03/12, docs stale
  (`README.md`, `docs/PROJECT.md`, `docs/PRODUCT.md`).