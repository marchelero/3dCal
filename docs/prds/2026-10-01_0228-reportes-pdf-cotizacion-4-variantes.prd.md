# PRD — Reportes de cotización: 4 variantes (cliente / interno × simple / advanced)

- **Fecha**: 2026-10-01 02:28
- **Autor**: primary (build)
- **Estado**: aprobado por el usuario (diseño confirmado, sin preguntas abiertas)
- **Alcance**: `lib/core/export/pdf_export.dart`, `lib/features/calculation/presentation/widgets/quote_image_template.dart`, `lib/features/calculation/presentation/widgets/detail_section.dart`, `lib/features/calculation/presentation/widgets/result_sheet.dart`, `lib/features/calculation/presentation/pages/calculation_detail_page.dart`, `lib/l10n/{es_bo,pt_br,fr_fr}.dart`, tests

---

## 1. Problema

El PDF de cotización tiene hoy **un solo selector** (`bool showDetail`) con dos estados: "para el cliente" y "para el dueño". La auditoría del generador actual (`buildQuotePdfBytes`, `lib/core/export/pdf_export.dart:391`) encontró huecos en ambos.

### 1.1 Auditoría — reporte simple (`showDetail: false`, para el cliente)

| # | Falta | ¿Expone información sensible? |
|---|-------|-------------------------------|
| 1 | **No muestra los materiales.** La tabla de materiales solo se renderiza bajo `showDetail` (línea 826). El cliente no sabe qué material se le va a imprimir ni cuánto pesa cada uno | No |
| 2 | **El reparto de tiempos es ambiguo.** `_buildMetaBox` lista `Material → 120 g → 2h 30m` sin indicar si ese tiempo es propio del material o el global | No |
| 3 | **No hay "Resumen de la cotización".** Peso, tiempo, cantidad, unitario y total viven en 3 cajas distintas, sin una tabla que los junte en un solo lugar legible | No |
| 4 | **Multi-material sin tiempo propio**: el cliente solo ve un peso agregado | No |

Lo que ya está bien y **no se toca**: branding, N°, fecha, "válido hasta", cliente, pieza, foto, notas, condiciones, `N u. × unitario`, caja de descuentos, moneda (`formatCurrency` ya incluye el símbolo).

### 1.2 Auditoría — reporte detalle (`showDetail: true`, para el dueño)

| # | Falta | Impacto |
|---|-------|---------|
| 1 | La **tabla de materiales** solo tiene `label \| costo` (líneas 866-893). Sin gramos, sin tiempo, **sin fila TOTAL** → el desglose no cuadra a la vista | Alto |
| 2 | El **desglose de costos no cierra**: no hay línea de subtotal. El total solo aparece en el hero de arriba (línea 645), nunca al final del desglose | Alto |
| 3 | **No muestra las tasas usadas** (kWh, $/h, amortización/h, post-proceso %, falla %, markup %, profit %) ni la impresora. No se puede auditar ni recalcular el PDF | Alto |
| 4 | No hay **Margen %** ni **Markup sobre costo %** | Medio |
| 5 | No aparece **"Sin descuento"** cuando hay descuento pero `quantity == 1` | Bajo |
| 6 | No aparece el **estado** (Vendida / Pendiente) | Bajo |
| 7 | **Sin paginación**: `pw.Spacer()` (línea 995) + `pw.Column` sin `pw.MultiPage` → con muchos materiales el contenido se desborda y las páginas 2+ quedan **sin header ni footer** | Medio |
| 8 | Gramos de materiales **sin** tiempo propio no aparecen en ningún lado | Medio |

### 1.3 Bug estructural detectado

`showDetail` es un `bool` **local e independiente** en cada pantalla:
- `result_sheet.dart:494` → `state.showDetail` (vive en `CalculatorState`)
- `calculation_detail_page.dart:178` → `bool _showDetail = false` (local del `State`)

Los dos builders sí son el mismo (`buildQuotePdfBytes`), pero el usuario tiene que re-togglear por pantalla. Y con un `bool` no hay forma de expresar "cliente + multi-material detallado".

---

## 2. Objetivo

Un único selector de **4 variantes** que cubra las dos dimensiones que el usuario pidió:

- **Audience**: cliente (no ve costos internos) vs. dueño (reporte privado de trabajo)
- **Complexity**: simple (una sola cotización) vs. advanced (multi-material, tiempos sueltos por material, sumas y total final)

Aplicado de forma **idéntica** a los 3 canales de salida: **imagen PNG**, **PDF** (share) e **impresión**.

---

## 3. Alcance / No-alcance

### Alcance
1. `enum QuoteReportVariant` de 4 valores que reemplaza al `bool showDetail`.
2. Sección "Resumen de la cotización" (tabla de sumas) en las variantes de cliente.
3. Tabla de materiales con **Peso** y **Tiempo** en las 4 variantes.
4. Fila **TOTAL** en la tabla de materiales.
5. Línea de **subtotal de cierre** (`totalBeforeProfit` → `profitAmount` → `totalFinal`) en el desglose de costos.
6. Sección nueva **"Parámetros de cálculo"** (tabla de tasas + impresora + Margen % + Markup sobre costo %) en las variantes internas.
7. Línea "Sin descuento" cuando hay descuento.
8. Estado de la cotización (Vendida / Pendiente) cuando el caller tiene el dato.
9. **Paginación real** con `pw.MultiPage`: header repetido + pie "Página X de Y" en las 4 variantes.
10. Paridad de contenido en `QuoteImageTemplate` / `DetailSection`.
11. **Segmented control de 4 opciones** en la calculadora y en el detalle de historial.
12. New strings en `es_bo` + `pt_br` + `fr_fr`.

### No-alcance (explícito)
- **No se cambia ninguna fórmula de cálculo.** `CalculationEngine` queda intacto.
- **No se cambia el modelo de datos / drift.** Sin migración.
- **No se agregan campos a la cotización** (tiempo de entrega, forma de pago, datos de contacto). Si el usuario los quiere, es otro PRD.
- **No se toca el export CSV** del historial.
- **No se cambian los defaults** de Settings ni las reglas del tier Free/Pro del branding (`resolveBranding` mantiene su gate).

---

## 4. Decisiones de diseño (confirmadas)

- **D1** → 4 variantes con **Segmented control**, aplicado a imagen + PDF + impresión.
- **D2** → `clientAdvanced` = tabla por material + tabla resumen de sumas, **cero costos**.
- **D3** → `internalDetail` = tabla de tasas/auditoría + Margen % + Markup sobre costo %.
- **D4** → Header repetido + "Página X de Y" en las 4 variantes.

---

## 5. Diseño

### 5.1 `QuoteReportVariant`

Nuevo archivo sugerido: `lib/core/export/quote_report_variant.dart`.

```dart
enum QuoteReportVariant {
  clientSimple,
  clientAdvanced,
  internalDetail,
  internalAdvanced;

  /// Variantes seguras para enviar al cliente (sin costos ni tasas).
  bool get isClientFacing =>
      this == QuoteReportVariant.clientSimple ||
      this == QuoteReportVariant.clientAdvanced;

  /// Variantes con tabla por material completa (multi-material / tiempos sueltos).
  bool get isAdvanced =>
      this == QuoteReportVariant.clientAdvanced ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes que exponen el desglose interno de costos.
  bool get showCostDetail =>
      this == QuoteReportVariant.internalDetail ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes que exponen la tabla de parámetros (tasas, impresora, márgenes).
  bool get showRateAudit =>
      this == QuoteReportVariant.internalDetail ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes con tabla de materiales con al menos 2 columnas de datos.
  bool get showsFullMaterialTable =>
      this == QuoteReportVariant.clientAdvanced ||
      this == QuoteReportVariant.internalAdvanced ||
      this == QuoteReportVariant.internalDetail;
}
```

Regla de uso en el código: **nunca** escribir `variant == QuoteReportVariant.x && variant == ...` en el generador; usar los getters. Es la razón de existir del enum.

**Tabla de decisión de contenido:**

| Bloque | `clientSimple` | `clientAdvanced` | `internalDetail` | `internalAdvanced` |
|---|---|---|---|---|
| Header branding + N°/fecha/validez | ✅ | ✅ | ✅ | ✅ |
| Pieza + cliente + foto | ✅ | ✅ | ✅ | ✅ |
| Caja meta (peso/tiempo total) | ✅ | ✅ | ✅ | ✅ |
| **Tabla materiales: Material \| Peso \| Tiempo** | ⚠️ solo `Material \| Peso` | ✅ | ✅ | ✅ |
| **Fila TOTAL de la tabla materiales** | ❌ | ❌ | ✅ `Σ costo material` | ✅ `Σ costo material` |
| Hero TOTAL final | ✅ | ✅ | ✅ | ✅ |
| `N u. × unitario` | ✅ | ✅ | ✅ | ✅ |
| **Bloque "Resumen de la cotización"** | ✅ | ✅ | ❌¹ | ❌¹ |
| Caja de descuentos | ✅ | ✅ | ✅ | ✅ |
| Desglose de costos | ❌ | ❌ | ✅ | ✅ |
| **Subtotal de cierre (`totalBeforeProfit`)** | ❌ | ❌ | ✅ | ✅ |
| Línea "Sin descuento" | ✅ si hay descuento | ✅ | ✅ | ✅ |
| Estado (Vendida/Pendiente) | ❌ | ❌ | ✅ si hay dato | ✅ si hay dato |
| **Sección "Parámetros de cálculo"** | ❌ | ❌ | ✅ | ✅ |
| Notas + condiciones | ✅ | ✅ | ✅ | ✅ |
| Header repetido + "Página X de Y" | ✅ | ✅ | ✅ | ✅ |

¹ Las variantes internas ya muestran el desglose completo; el bloque "Resumen" se reserva para las de cliente para no duplicar la misma información dos veces en el mismo documento.

### 5.2 `PdfRateAudit` — tabla de parámetros

Nuevo value object en `lib/core/export/pdf_export.dart` (o `quote_rate_audit.dart`). **Inmutable, todo `Decimal`, nullable cuando no aplica.**

```dart
class PdfRateAudit {
  const PdfRateAudit({
    this.printerName,
    this.printerWatts,        // int
    this.kwhRate,             // Decimal — tarifa electrica por kWh
    this.laborRate,           // Decimal — BOB/hora
    this.amortizationPerHour, // Decimal — BOB/hora (0 si no aplica)
    this.postProcessRate,     // Decimal — %
    this.failureRate,         // Decimal — %
    this.markupOnMaterials,   // Decimal — %
    this.profitBase,          // Decimal — %
    this.profitMarginPct,     // Decimal — % = profitAmount / totalBeforeProfit * 100
    this.markupOverCostPct,   // Decimal — % = (totalFinal - baseCost) / baseCost * 100
    this.totalHours,          // Decimal — horas facturadas
  });

  /// True si no hay nada que mostrar (todo null/zero).
  bool get isEmpty => ...;
}
```

Cálculos derivados:
- `amortizationPerHour` = `amortizationCostSnapshot / totalHours` (0 si `totalHours == 0`). Reusa la semántica de `CalculationEngine.amortizationPerHour`.
- `profitMarginPct` = `profitAmount / totalBeforeProfit × 100`, con guard contra división por cero.
- `markupOverCostPct` = `(totalFinal − baseCost) / baseCost × 100`, con guard contra división por cero.

Ambos porcentajes se calculan sobre valores **unitarios** (antes de escalar por qty) — son tasas, no montos.

### 5.3 Resolución de `PdfRateAudit` — helper compartido

**Problema**: los dos callers tienen fuentes distintas y hoy duplican lógica.

- **Path calculadora** (`result_sheet.dart`): settings actuales (`kwhRate`, `laborRate`, `postProcessRate`, `failureRate`, `markupOnMaterials`, `profitBase`) + `activePrinterProvider` + overrides por cotización (`CalculatorState.extraLaborRate`, `extraPostProcessRate`, `extraFailureRate`, `extraMarkupOnMaterials`, que son `String` vacías = sin override).
- **Path historial** (`calculation_detail_page.dart`): snapshots de `Calculation` (`printerWattsSnapshot`, `kwhRateSnapshot`, `laborRateSnapshot`, `postProcessRateSnapshot`, `failureRateSnapshot`, `markupOnMaterialsSnapshot`, `profitBaseSnapshot`, `amortizationCostSnapshot`) con **fallback a Settings**, exactamente igual que hace `CalculationEngine.computeFromSnapshot` (líneas 203-224).

**Diseño**: un único helper puro en el dominio que recibe **tasas ya resueltas** y devuelve el `PdfRateAudit` con los porcentajes calculados. La **resolución snapshot-vs-settings** se delega a `CalculationEngine.computeFromSnapshot` (ya es single source of truth) mediante un método nuevo:

```dart
// En calculation_engine.dart
static ResolvedRates resolveRates({
  required double kwhRateSnapshot,
  required double laborRateSnapshot,
  required double postProcessRateSnapshot,
  required double failureRateSnapshot,
  required double markupOnMaterialsSnapshot,
  required double profitBaseSnapshot,
  required Decimal fallbackKwhRate,
  required Decimal fallbackLaborRate,
  required Decimal fallbackPostProcessRate,
  required Decimal fallbackFailureRate,
  required Decimal fallbackMarkupOnMaterials,
  required Decimal fallbackProfitBase,
});
```

`computeFromSnapshot` pasa a consumir `resolveRates(...)` internamente → **cero cambio de comportamiento** (mismo orden de resolución snapshot → fallback), pero ahora las tasas resueltas son accesibles para el PDF.

El path calculadora llama `resolveRates` con los overrides del `CalculatorState` resueltos primero (`extraXRate` no vacío gana sobre `Settings`) y `0` como snapshot.

### 5.4 Reemplazo de `showDetail`

**Decisión**: `showDetail` se **elimina** de la API pública de exportación y se reemplaza por `variant`. No se deprecia con `@Deprecated` porque:
1. Es un `@required`-ish param en la firma con default `true` (`pdf_export.dart:398`).
2. Hay 4 call sites + 8 usos en tests; mantener dos fuentes de verdad reintroduce el bug de §1.3.
3. El enum es estrictamente más informativo (contiene a `showDetail`).

Migración:
| Antes | Después |
|---|---|
| `shareQuotePdf(showDetail: false, ...)` | `shareQuotePdf(variant: QuoteReportVariant.clientSimple, ...)` |
| `shareQuotePdf(showDetail: true, ...)` | `shareQuotePdf(variant: QuoteReportVariant.internalDetail, ...)` |
| `QuoteImageTemplate(showDetail: bool)` | `QuoteImageTemplate(variant: QuoteReportVariant)` |
| `CalculatorState.showDetail` | `CalculatorState.variant` (default `clientSimple`) |
| `calculator_notifier.toggleDetail()` | `calculator_notifier.cycleVariant()` (0→1→2→3→0) o `setVariant(v)` |
| `_DetailState._showDetail` | `_DetailState._variant` (default `clientSimple`) |

En `QuoteImageTemplate`, `final bool showDetail` se reemplaza por `final QuoteReportVariant variant`, y todas las decisiones internas pasan a usar `variant.showCostDetail` / `variant.isAdvanced` / `variant.isClientFacing`.

### 5.5 Secciones nuevas — layout

#### Bloque "Resumen de la cotización" (variantes de cliente)
Tabla de 2 columnas, sin montos de costo:

```
RESUMEN DE LA COTIZACIÓN
Peso total                          1.240 g
Tiempo total                          6h 45m
Cantidad                                 5 u.
Precio unitario                  Bs. 120,00
Subtotal                         Bs. 600,00
Descuento por cantidad (10%)     -Bs. 60,00
Descuento manual (5%)            -Bs. 27,00
─────────────────────────────────────────
TOTAL FINAL                      Bs. 513,00
```

#### Sección "Parámetros de cálculo" (variantes internas)
Ubicada **después** del desglose de costos y antes de notas.

```
PARÁMETROS DE CÁLCULO
Impresora                     Creality Kobra 3 (120 W)
Tarifa eléctrica                     Bs. 0,70 /kWh
Horas facturadas                          6,75 h
Mano de obra                       Bs. 25,00 /h
Amortización                     Bs. 8,00 /h
Post-procesado                             10 %
Tasa de falla                              5 %
Markup (desperdicio)                       8 %
Profit (ganancia)                        100 %
Margen                                     45,8 %
Markup sobre costo                        58,3 %
```

Se oculta completa si `rateAudit.isEmpty`.

#### Tabla de materiales (todas las variantes)
- `clientSimple`: `Material \| Peso`
- resto: `Material \| Peso \| Tiempo` (+ `Costo` en las internas)
- Fila TOTAL solo en las internas: `Σ costo material = dMaterialCost`
- Cuando el material **no** tiene tiempo propio y la tabla tiene columna Tiempo → texto `global` (o el `metaTime` global entre paréntesis), **nunca un 0 inventado**.

#### Cierre del desglose de costos (internas)
Después de `Ganancia`, agregar:

```
─────────────────────────────────────────
Subtotal (base + falla + markup)  Bs. X
Ganancia                          Bs. Y
─────────────────────────────────────────
Total antes de descuentos         Bs. Z
```

### 5.6 Paginación

Reemplazar el `pw.Column` + `pw.Spacer()` actual por:

```dart
pw.MultiPage(
  header: (context) => pw.Container(...branding + Nº...),   // repetir en cada página
  footer: (context) => pw.Container(... "Página X de Y" ...),
  build: (context) => [ /* todas las secciones, sin Spacer() */ ],
)
```

- El header de la **página 1** conserva el layout actual grande (logo 40x40 + nombre 22pt + caja de Nº/fechas); las páginas 2+ usan una versión **compacta** (logo 20x20 + nombre 12pt + Nº a la derecha). Ambas alimentan el mismo helper `_pdfHeader(compact: bool)`.
- "Página X de Y" usa `context.pageNumber` y `context.pagesCount`.
- El `accent bar` (línea 4pt) se dibuja solo en la página 1.
- **Restricción conocida**: `pw.MultiPage` no admite `pw.Expanded`, `pw.Spacer()` ni `pw.Flexible` dentro de `build`. El código actual no los usa salvo el `Spacer()` del footer → se elimina.

---

## 6. Criterios de aceptación

Formato Given/When/Then. "PDF" = `buildQuotePdfBytes`; "Imagen" = `QuoteImageTemplate` renderizado.

### 6.1 Comunes a las 4 variantes

- **CA-01** — Dado cualquier `variant`, When genero el PDF, Then el documento tiene ≥1 página y `bytes.length > 300`.
- **CA-02** — Dado un PDF de cualquier variante con `quoteNumber != null`, When lo genero, Then el branding y el N° aparecen en **cada** página.
- **CA-03** — Dado un PDF de cualquier variante, Then el pie incluye `Página X de Y` con `Y == pagesCount` real.
- **CA-04** — Dado `isPro: false` con `companyLogoBase64` en settings, Then el PDF **no** contiene `/Subtype /Image` del logo (regresión T13).
- **CA-05** — Dado `isPro: true` + logo válido, Then el PDF contiene ≥1 image XObject.
- **CA-06** — Dado `pieceImageBytes != null`, Then el PDF contiene ≥1 image XObject adicional.
- **CA-07** — Dado todos los montos en 0 (`CalculationOutput.simple`), Then el PDF se genera sin excepción.
- **CA-08** — Dado `notes` y `conditions` con saltos de línea, Then el PDF los renderiza sin truncar.
- **CA-09** — Dado `clientName`, `quoteNumber`, `quoteDate`, `validUntil`, `notes`, `conditions`, Then el PDF con todos esos metadatos pesa **más** que el PDF mínimo equivalente (regresión del assert existente en `pdf_export_test.dart`).
- **CA-10** — Dado `clientSimple` o `clientAdvanced`, Then el PDF **nunca** contiene las tasas (kWh, mano de obra, post-proceso %, falla %, markup %, profit %) ni el nombre de la impresora ni `Margen`.

### 6.2 `clientSimple`

- **CA-20** — Dado `materials` con 2 items **sin** tiempo propio, When genero `clientSimple`, Then el PDF **sí** incluye la tabla de materiales con `Material` y `Peso` por item. *(hoy falla: no aparece nada)*
- **CA-21** — Dado un material con tiempo propio, Then la fila marca explícitamente que el tiempo es propio de ese material.
- **CA-22** — Dado `quantity == 1` y sin descuentos, Then el bloque "Resumen de la cotización" contiene `Peso total`, `Tiempo total`, `Cantidad`, `Subtotal` y `TOTAL FINAL`.
- **CA-23** — Dado `quantity > 1`, Then el resumen incluye `Precio unitario` y `Cantidad`.
- **CA-24** — Dado descuentos (cualquiera de los dos), Then el resumen lista `Subtotal`, una línea por descuento aplicado y `TOTAL FINAL`.
- **CA-25** — Dado `quantity == 1`, Then el PDF **no** muestra `1 u. × ...` (se omite la línea redundante).
- **CA-26** — Given `clientSimple`, Then el PDF pesa **menos** que el mismo input en `internalDetail` (mantiene el assert existente de `pdf_export_test.dart`).

### 6.3 `clientAdvanced`

- **CA-30** — Dado `materials` con 3 items, Then la tabla tiene 3 filas + las columnas `Material`, `Peso`, `Tiempo`.
- **CA-31** — Dado un material **sin** tiempo propio, Then su celda de Tiempo muestra el indicador de tiempo global, **no** `0h 0m` ni un número inventado.
- **CA-32** — Dado `materials` con tiempos propios mezclados (`useOwnTime` en algunos), Then cada fila con tiempo propio muestra su tiempo y las demás muestran el global.
- **CA-33** — Given `clientAdvanced`, Then el PDF **no** contiene columna de costo por material ni la sección de parámetros.
- **CA-34** — Dado `materials` vacío, Then `clientAdvanced` degrada a la misma estructura que `clientSimple` (sin tabla de materiales, sin crash).

### 6.4 `internalDetail`

- **CA-40** — La tabla de materiales tiene columnas `Material`, `Peso`, `Tiempo`, `Costo`, y una **fila TOTAL** cuyo valor es igual a `output.materialCost × quantity`.
- **CA-41** — El desglose de costos termina con: línea `Subtotal (base + falla + markup)` = `output.totalBeforeProfit × qty`, luego `Ganancia`, luego `Total antes de descuentos` = `output.totalFinal × qty`.
- **CA-42** — La aritmética cierra: `baseCost + failureCost + markupCost == totalBeforeProfit` y `totalBeforeProfit + profitAmount == totalFinal`, con los valores **escalados** que imprime el PDF (diferencia ≤ 0,01 por redondeo de formato).
- **CA-43** — La sección "Parámetros de cálculo" lista: impresora (nombre + watts), tarifa kWh, horas facturadas, mano de obra, amortización/hora, post-proceso %, falla %, markup %, profit %.
- **CA-44** — La sección incluye `Margen` = `profitAmount / totalBeforeProfit × 100` y `Markup sobre costo` = `(totalFinal − baseCost) / baseCost × 100`, ambos con el valor correcto para un input conocido.
- **CA-45** — Given `totalBeforeProfit == 0` o `baseCost == 0`, Then los porcentajes no producen `NaN`/`Infinity` — se omiten o muestran `—`.
- **CA-46** — Dado `rateAudit.isEmpty`, Then la sección "Parámetros de cálculo" no se renderiza.
- **CA-47** — Si hay descuento (manual o por cantidad) y `quantity == 1`, Then aparece la línea "Sin descuento" con `output.totalFinal × qty`.
- **CA-48** — Si el caller pasa `quoteStatus`, Then el PDF muestra `Vendida` o `Pendiente`.
- **CA-49** — La caja de descuentos mantiene el orden `Subtotal → Desc. por cantidad → Desc. manual → Total final` (no se rompe con la adición de las secciones nuevas).

### 6.5 `internalAdvanced`

- **CA-50** — La tabla de materiales tiene `Material`, `Peso`, `Tiempo`, `Costo unitario`, `Costo lote`, y la fila TOTAL.
- **CA-51** — `Costo lote` de cada fila está escalado por `quantity`; `Σ costo lote == dMaterialCost`.
- **CA-52** — Contiene **todo** lo de `internalDetail` (CA-40 a CA-49), más el reparto de tiempos por material cuando hay tiempos propios.
- **CA-53** — El reparto de tiempos suma al `Tiempo total` mostrado en la caja meta (con tolerancia de redondeo de 1 minuto).

### 6.6 Imagen PNG — paridad

- **CA-60** — `QuoteImageTemplate` acepta `variant` en lugar de `showDetail` y renderiza el mismo **conjunto de bloques** que el PDF de esa variante.
- **CA-61** — `variant.showCostDetail` controla la presencia de `DetailSection`.
- **CA-62** — `clientSimple`/`clientAdvanced` en la imagen **no** muestran costos ni tasas.
- **CA-63** — `clientAdvanced` en la imagen muestra la tabla por material (peso + tiempo) y el bloque resumen.
- **CA-64** — `internalDetail`/`internalAdvanced` en la imagen muestran el desglose + tabla de materiales con TOTAL + parámetros.
- **CA-65** — La captura (`captureQuoteImageBytes`) sigue funcionando en las 4 variantes sin `RenderFlex overflow`.

### 6.7 UI — segmented control

- **CA-70** — La calculadora (result sheet) muestra un control de 4 opciones con los labels de `EsBO` y el valor inicial es `clientSimple`.
- **CA-71** — El detalle de historial muestra el mismo control de 4 opciones con el valor inicial `clientSimple`.
- **CA-72** — Cambiar la variante en la calculadora **actualiza la imagen, el PDF y la impresión** de forma consistente (el PDF usa la variante seleccionada al momento de exportar).
- **CA-73** — El toggle viejo de "Mostrar/Ocultar detalle" desaparece de ambas pantallas.
- **CA-74** — El segmented control **no** usa `setState` para estado de negocio: la calculadora escribe en `CalculatorState` vía el notifier (Riverpod); el historial usa `setState` local por ser estado de UI efímero no persistido (permitido por la regla de `PROJECT.md`).

### 6.8 l10n

- **CA-80** — Todo getter nuevo existe en `es_bo.dart`, `pt_br.dart` y `fr_fr.dart`, con el **mismo nombre** en los 3.
- **CA-81** — Los labels de las 4 variantes se obtienen de `EsBO` (nunca hardcodeados).

---

## 7. Hitos

| # | Hito | Depende de | Contenido | "Listo" cuando |
|---|------|-----------|-----------|----------------|
| **H1** | Fundaciones | — | `QuoteReportVariant` (+ getters) en archivo nuevo. `PdfRateAudit`. `CalculationEngine.resolveRates()` + refactor de `computeFromSnapshot` para consumirlo (sin cambio de comportamiento). Helper `resolveRateAuditFromRates(...)`. Strings nuevos en los 3 idiomas. | `dart analyze` limpio + test unitario de `resolveRates` que prueba que la resolución snapshot→fallback no cambió vs. el código anterior + test de los getters del enum |
| **H2** | PDF `clientSimple` | H1 | `pdf_export.dart`: firma `variant` en vez de `showDetail`. Tabla de materiales (`Material \| Peso`). Bloque "Resumen de la cotización". Marcador de tiempo propio/global. Línea "Sin descuento". Migrar los 2 callers a `variant`. | Test del PDF cliente: CA-20 a CA-26 pasan + assert de tamaño `basic < full` sigue verde |
| **H3** | PDF `clientAdvanced` | H2 | Tabla de materiales con columna Tiempo + indicador de global. Resumen completo. | CA-30 a CA-34 pasan |
| **H4** | PDF `internalDetail` | H2 | Tabla de materiales completa + fila TOTAL. Subtotal de cierre (`totalBeforeProfit`). Sección "Parámetros de cálculo" + Margen % + Markup sobre costo %. Estado Vendida/Pendiente. | CA-40 a CA-49 pasan |
| **H5** | PDF `internalAdvanced` | H4 | Columnas `Costo unitario` / `Costo lote`, reparto de tiempos, cierre por capas. | CA-50 a CA-53 pasan |
| **H6** | Paginación | H3, H4 | `pw.MultiPage` con header repetido (compacto en pág. 2+) + pie "Página X de Y". Eliminar `pw.Spacer()`. | CA-01 a CA-03 pasan + test que fuerza overflow a 2 páginas y verifica header/footer en ambas |
| **H7** | Paridad imagen | H2-H5 | `QuoteImageTemplate(variant:)`, `DetailSection` extendido (fila TOTAL, parámetros), `MaterialMetaItem` con los datos de la tabla. | CA-60 a CA-65 pasan |
| **H8** | UI segmented control | H7 | `CalculatorState.variant` + `cycleVariant()`/`setVariant()`. Segmented control en result sheet y en detalle de historial. Borrado del toggle viejo. | CA-70 a CA-74 pasan |
| **H9** | Cleanup + verificación | H1-H8 | Quitar `showDetail` de todos los call sites y tests. Actualizar los asserts de tamaño de `pdf_export_test.dart` si el contenido nuevo los invalida (**con justificación escrita en el test**). | `dart analyze` sin warnings + `dart format --set-exit-if-changed .` limpio + `flutter test` 100% verde |

---

## 8. Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Los asserts de tamaño de `pdf_export_test.dart` se rompen.** `basicBytes.length < fullBytes.length` (línea 319) y `rich.length > base.length` (línea 359) comparan longitudes comprimidas con FlateDecode. Agregar contenido nuevo cambia los pesos de forma no intuitiva | Alto | Verificar los 2 asserts **después de H2**. Si el orden se invierte, actualizar el assert con un comentario que explique la nueva distribución de bytes. Alternativa más robusta: reemplazar la comparación de tamaño por un conteo de tokens de texto descomprimido (`/Filter /FlateDecode` + inflate) o por un marcador inequívoco en el PDF |
| **`pw.Spacer()` dentro de `pw.MultiPage`** → runtime error | Alto | Eliminar el `Spacer()` en H6 antes de migrar a `MultiPage`. `MultiPage` prohíbe `Expanded`, `Spacer`, `Flexible` |
| **Overflow de la tabla de materiales** con muchas filas en la imagen (width 400px fijo) | Medio | La tabla de la imagen usa `FittedBox`/`scaleDown` en columnas numéricas y trunca labels largos con `TextOverflow.ellipsis` + `maxLines` |
| **Percentajes NaN/Infinity** cuando `baseCost == 0` o `totalBeforeProfit == 0` | Medio | Guards explícitos en `PdfRateAudit`; CA-45 |
| **Strings en 3 idiomas desincronizados** | Medio | Todo getter nuevo se agrega a los 3 en el mismo commit; CA-80 como criterio de aceptación |
| **`PdfRateAudit` desincronizado del cálculo real** si el helper no usa `resolveRates` | Alto | El helper **debe** consumir `CalculationEngine.resolveRates`; test que compara las tasas resueltas contra las que usa `computeFromSnapshot` |
| **Los 3 canales (imagen / PDF / impresión) se desincronizan** al agregar contenido | Medio | Todo el contenido se decide desde `QuoteReportVariant`; paridad verificada por CA-60 (mismo conjunto de bloques) |
| **Scope creep**: el usuario pidió "2 reportes más" y terminamos con 4 + paginación + tabla de tasas | Bajo | D1-D4 ya están confirmadas explícitamente. Cualquier bloque adicional (tiempo de entrega, datos de contacto) queda fuera (§3) |

---

## 9. Definición de "hecho"

```powershell
# 1. Analisis estatico
dart analyze

# 2. Formato
dart format --output=none --set-exit-if-changed lib test

# 3. Tests completos
flutter test

# 4. Tests del area tocada (rapido)
flutter test test/unit/pdf_export_test.dart
flutter test test/unit/quote_image_template_test.dart
flutter test test/unit/result_sheet_test.dart
flutter test test/widget/quote_save_flow_test.dart
flutter test test/unit/calculator_notifier_test.dart
```

**Hecho = los 4 comandos en verde + los 9 hitos completados + CA-01 a CA-81 cubiertos por tests automatizados.**

**Reportes requeridos** (regla del pack): `docs/reports/` con el resultado de la verificación y `docs/audits/` con el cruce PRD → implementación.
