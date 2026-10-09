# PRD — Tier 1: deuda técnica (god widget, estado, descuentos, guard base64)

- **Fecha:** 2026-10-08
- **Estado:** Propuesto (pendiente de aprobación)
- **Rama base:** `main` @ `33a2d44` (+ `d572d3e`)
- **Baseline:** `flutter analyze` 0 issues · `flutter test` **838/838 verde**
- **Regla transversal:** cero regresiones. Al cierre: analyze 0 issues y suite ≥ 838 verde.

---

## 1. Problema

De la revisión completa quedó un backlog "Tier 1" de deuda técnica verificada contra el
fuente. No son bugs que rompan al usuario hoy, pero aumentan el costo de cambio y el
riesgo de inconsistencias futuras:

1. Un god widget de ~491 líneas que mezcla layout, estado y handlers.
2. Estado de negocio (variante de reporte y cantidad) manejado con `setState` local en
   vez de Riverpod.
3. La fórmula de descuento (manual escalado y su base) está re-derivada en ≥4 lugares.
4. Un `base64Decode` sin guard sobre datos de branding que puede crashear la exportación
   a PDF.

---

## 2. Objetivo

Reducir esa deuda con cambios de estructura/robustez **sin alterar comportamiento
observable** (UI y montos idénticos), cubiertos por tests. Cada ítem es independiente y
entregable por separado.

---

## 3. Alcance (in-scope)

| # | Ítem | Archivo(s) |
|---|------|-----------|
| T1-1 | Descomponer el god widget `build` | `lib/features/calculation/presentation/widgets/result_sheet.dart` |
| T1-2 | Migrar estado de negocio a Riverpod | `lib/features/calculation/presentation/pages/calculation_detail_page.dart` |
| T1-3 | Unificar fórmula de descuento | `pdf_export.dart`, `quote_image_template.dart`, `calculation_detail_page.dart`, `batch_lot_composer.dart`, `calculation_engine.dart` |
| T1-4 | Guard de `base64Decode` de logo | `lib/core/export/pdf_export.dart` |

## 4. Fuera de alcance

- Cambios de diseño visual o de copy.
- a11y (contraste, text-scale, `Color(0x`), seguridad monetización/backups (SEC-01/03/12).
- Índices de DB (hallazgo NO verificado; se descarta).
- Cualquier cambio en el motor que altere montos.

---

## 5. Requisitos por ítem

### T1-1 — Descomponer `_ResultSheetContentState.build`
**Estado actual:** `build` en `result_sheet.dart:643` y la siguiente clase en `:1134` → **~491 líneas**.

**Requisito:** extraer bloques lógicos a sub-widgets privados (`_HeaderSection`, `_CostsSection`,
`_BatchSection`, `_DiscountSection`, `_ActionsSection`, según el contenido real), cada uno
`StatelessWidget`/`ConsumerWidget`, sin cambiar el árbol renderizado ni el orden.

**Criterios de aceptación:**
- [ ] Ningún método `build` de la clase estado supera ~120 líneas.
- [ ] El árbol de widgets y los `Key`/textos/estilos permanecen equivalentes (mismos finders en tests).
- [ ] `result_sheet_test.dart` y `quote_image_template_test.dart` siguen verdes sin cambios de expectativas.

### T1-2 — Estado de negocio → Riverpod
**Estado actual:** `_DetailState` (`calculation_detail_page.dart:115`) usa:
- `_isBusy` (`:117`) — busy de UI.
- `_reportVariant` (`:122`) y `_quantity` (`:128`) — **afectan el reporte y el monto exportado** (negocio).

**Requisito:** migrar `_reportVariant` y `_quantity` a un `AutoDisposeNotifier` (o `NotifierProvider.family`
por `calc.id`) de alcance de pantalla. `_isBusy` puede permanecer local (justificarlo con comentario:
es estado efímero de UI, no de negocio).

**Criterios de aceptación:**
- [ ] `_reportVariant` y `_quantity` dejan de vivir en `setState`; se leen/escriben vía provider.
- [ ] Cambiar la variante o la cantidad produce el mismo resultado en preview y export que hoy.
- [ ] El provider se auto-dispose al salir de la pantalla (sin fugas).
- [ ] Test de widget: cambiar variante/cantidad actualiza el reporte mostrado; test de notifier para el estado.

### T1-3 — Unificar fórmula de descuento
**Estado actual (duplicación verificada):** el descuento manual escalado `output.discountAmount * qty`
se re-deriva en al menos:
- `pdf_export.dart:602-605`
- `quote_image_template.dart:355` y `:685`
- `calculation_detail_page.dart:420`
y la base `manualPct × (totalFinal × N)` se documenta/repite en `batch_lot_composer.dart:27-57,99-106`
y `calculator_state.dart:349-357`.

**Requisito:** extraer una **única fuente de verdad** en dominio (p.ej.
`ManualDiscount.scaled(output, quantity)` y/o un helper de aplicación de porcentaje) y hacer que
los 4 call sites la usen. No cambiar la semántica (`desc_manual = manualPct × (totalFinal × N)`,
`total = max(totalFinal × N − desc_cantidad − desc_manual, minimumCharge)`).

**Criterios de aceptación:**
- [ ] Existe un único helper de dominio; los call sites dejan de recomputar `discountAmount * qty`.
- [ ] Tests de equivalencia: para un set de casos (N=1, N>1, con/sin escalón, con/sin descuento
      manual, piso de cargo mínimo) el valor nuevo == valor anterior (golden numérico).
- [ ] `quote_report_variant_test.dart`, `calculation_engine_test.dart` y `batch_lot_composer_test.dart`
      siguen verdes (o se amplían, nunca se debilitan).

### T1-4 — Guard de `base64Decode` en PDF
**Estado actual:** `pdf_export.dart:1146` llama `base64Decode(branding.logo!)` sin try/catch; con un
blob corrupto la exportación a PDF crashea. Otros sitios (`settings_page.dart:756`, `home_page.dart:310`,
`quote_image_template.dart:549`, `backup_service.dart:499`) ya decodifican con guard.

**Requisito:** envolver la decodificación: si falla, `debugPrint` + **omitir el logo** de ese PDF
(no crashear) y continuar el documento.

**Criterios de aceptación:**
- [ ] Un `branding.logo` inválido NO lanza excepción; el PDF se genera sin logo.
- [ ] Un `branding.logo` válido se sigue renderizando igual.
- [ ] Test unitario que exporte con logo corrupto y verifique que el PDF resultante es no vacío.

---

## 6. Plan de test

- Unit: notifier de T1-2; equivalencia numérica de T1-3; guard de T1-4.
- Widget: `result_sheet` y `calculation_detail` (variante/cantidad).
- Golden/no-regresión: reutilizar suites existentes del cálculo y reporte sin relajar aserciones.

## 7. Riesgos

- T1-1: mover código puede cambiar `BuildContext`/scrolling sutil → mitigar con tests de widget existentes.
- T1-2: providers `family` mal scoped pueden retener estado entre cotizaciones → autoDispose + test.
- T1-3: la equivalencia debe ser **exacta** con `decimal` (nada de redondeos nuevos) → golden numérico.
- T1-4: no silenciar errores reales; solo degradar la imagen del logo.

## 8. No-regresión (criterio de cierre)

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → ≥ **838** pass, 0 fail.
- [ ] Reporte en `docs/reports/` + snapshot en `docs/sessions/` (sin commit sin verbo explícito).
