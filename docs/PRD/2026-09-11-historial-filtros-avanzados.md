# PRD: Historial avanzado — filtros de fecha, orden, búsqueda en materiales, resumen y filtro por cliente

**Fecha**: 2026-09-11
**Estado**: Aprobado (usuario validó el scope de 5 puntos: fechas, orden, materiales, resumen, cliente)
**Scope**: UI (Flutter), i18n 6 locales, tests unit + widget, query drift (solo lectura)

## Problema

El historial (`calculations_list_page.dart`) ya tiene búsqueda por texto
(pieceName + clientName) y filtro por estado de venta (chips Todas/Vendidas/
Pendientes), implementados en memoria en `CalculationsNotifier`. Con un
historial que crece semana a semana, el usuario no puede responder preguntas
básicas del negocio:

1. **"¿Qué cotizaciones hice la semana pasada?"** — no existe filtro por rango
   de fechas.
2. **"¿Cuál fue mi cotización más cara?"** — sin ordenamiento, solo fecha desc.
3. **"Esta pieza con PLA+..."** — buscar por el filamento usado no encuentra
   nada: `_applyFilters()` solo matchea pieceName y clientName, y
   `CalculationListItem` no incluye los labels de materiales.
4. **"¿Cuánto cotizó Juan en total?"** — no hay forma de aislar un cliente:
   el nombre es texto libre en cada cotización y no hay filtro por cliente.
5. **"¿Cuánto suman estas 12 cotizaciones?"** — la lista no muestra resumen
   (conteo + total) del set filtrado.

## Decisiones (propuestas, pendientes de validación)

- **Filtro de fechas**: presets rápidos (Hoy, 7 días, 30 días, Este mes, Este
  año, Todo) + rango personalizado (`showDateRangePicker`). Filtrado **en
  memoria** sobre `createdAt.toLocal()`, consistente con el approach actual de
  search/sold (sin paginación no hay necesidad de SQL).
- **Ordenamiento**: menú con 5 opciones — Fecha reciente (default), Fecha
  antigua, Precio mayor, Precio menor, Cliente A-Z. El orden por precio usa el
  **total efectivo** (`totalPriceSnapshot × quantity`), no el snapshot unitario.
- **Búsqueda en materiales**: nueva query ligera en el repo
  `materialLabelsByCalcId()` → `Map<int, String>` (id → labels unidos con `|`),
  cacheada en el notifier en `build()` y `_reload()`. `_applyFilters()` matchea
  pieceName OR clientName OR materialLabels. **No** se agrega el campo derivado
  a `CalculationListItem` (contrato intacto).
- **Resumen del filtro**: barra sutil entre chips y lista que muestra
  "N cotizaciones · Total Bs. X,XX". Visible **solo cuando hay ≥1 filtro
  activo** (search, sold, fechas o cliente — el sort no cuenta). Total =
  suma del total efectivo del set filtrado.
- **Filtro por cliente**: tap en el nombre del cliente dentro de una card →
  activa `clientFilter` (match exacto case-insensitive) + chip "Cliente: X [×]"
  en la fila de filtros. Se descarta el dropdown de clientes en v1
  (simplicidad: el tap es más directo y el quemado de `recentClientNames` ya
  existe para el diálogo de guardado).
- **Combinación**: todos los filtros son AND (search + sold + fechas + cliente
  + sort) — mismo patrón que el soldFilter actual.
- **CSV export sin cambios**: sigue exportando el historial completo (no el
  set filtrado). No-goal explícito.

## Entregables

### 1. Estado del notifier (`CalculationsNotifier`)

Variables nuevas:

```dart
DateTimeRange? _dateRange;          // rango activo (null = todo)
_HistorySort _sort = _HistorySort.dateNewest;
String? _clientFilter;              // cliente activo (null = todos)
Map<int, String> _materialLabels = {}; // cache id → 'PLA|PLA+' para búsqueda
```

- `setDateRange(DateTimeRange?)` → re-aplica filtros.
- `setSort(_HistorySort)` → re-aplica filtros.
- `setClientFilter(String?)` → re-aplica filtros.
- `_applyFilters()` pipeline: `_all` → clientFilter → dateRange (sobre
  `createdAt.toLocal()`) → soldFilter → search (piece+client+materials) →
  sort → resultado.
- `build()` y `_reload()` cargan también `_materialLabels` desde el repo
  (una query extra, sin BLOBs).

Enums nuevos (en el mismo archivo o `history_sort.dart`):

```dart
enum _HistorySort { dateNewest, dateOldest, priceHigh, priceLow, clientAz }
```

### 2. Query del repositorio (`CalculationRepository`)

```dart
/// Map id → labels de materiales separados por '|' (excluye plantillas).
/// Query ligera: sin BLOBs. Alimenta la búsqueda en materiales del notifier.
Future<Map<int, String>> materialLabelsByCalcId();
```

Implementación: `customSelect` con `LEFT JOIN calculation_materials` +
`GROUP_CONCAT(cm.label, '|')` + `GROUP BY c.id` + `is_template = 0`. Sin
migración de schema (solo lectura).

### 3. UI — `calculations_list_page.dart`

- **Chip "Fechas"** en la fila de filter chips (junto a Todas/Vendidas/
  Pendientes). Tap → bottom sheet con presets + "Personalizado" (abre
  `showDateRangePicker`). Con rango activo, el chip muestra label compacto
  ("30 d" o "12/08 – 12/09") + icono × para limpiar.
- **Menú de orden**: icono `sort` en el AppBar (colapsa al `⋮` en angosto vía
  `SmartAppBarActions` si desborda) o segundo chip "Orden" en la fila. Tap →
  bottom sheet con las 5 opciones + check en la activa.
- **Chip de cliente activo**: aparece en la fila de chips con icono person +
  label + × para limpiar. El nombre del cliente filtrado en las cards se puede
  resaltar (color primario) como indicador visual.
- **Resumen**: barra entre chips y lista, texto
  `historyFilterSummary(count, total)` en typo mono para el total.
- **Tap en cliente**: `_CalculationCard` — el nombre del cliente pasa a ser
  tappable (InkWell) → `notifier.setClientFilter(clientName)`.

### 4. i18n — `app_strings.dart` + 6 locales

Strings nuevos (prefijo `history*`), siguiendo el patrón actual
(interfaz en `app_strings.dart`, implementación + proxy estático en
`es_bo.dart`, implementación en `en_us.dart`, `pt_br.dart`, `fr_fr.dart`,
`de_de.dart`):

- `historyFilterDate` — label del chip ("Fechas")
- `historyDatePresetToday` / `historyDatePreset7d` / `historyDatePreset30d` /
  `historyDatePresetMonth` / `historyDatePresetYear` / `historyDatePresetAll`
- `historyDatePresetCustom` ("Personalizado")
- `historyDateRangeLabel(DateTimeRange)` — label compacto del chip activo
- `historySortTitle` + `historySortDateNewest` / `historySortDateOldest` /
  `historySortPriceHigh` / `historySortPriceLow` / `historySortClientAz`
- `historyFilterClient` — label del chip de cliente activo
- `historyClientFilterChip(label)` — "Cliente: {label}"
- `historyFilterSummary(int count, String total)` — "{count} cotizaciones · {total}"
- `historySearchMaterialsHint` — helper del campo de búsqueda
  ("También busca en el filamento usado")

### 5. Tests

- **Nuevo** `test/unit/calculations_notifier_test.dart`:
  - search matchea por label de material (PLA+ en materials, no en nombre).
  - dateRange (preset 7d / custom) filtra por `createdAt.toLocal()`.
  - clientFilter matchea exacto case-insensitive.
  - sort por precio efectivo asc/desc (con quantity > 1).
  - combinación search + sold + date + client (AND).
  - resumen: conteo + total efectivo del set filtrado.
- **Extender** `test/widget/calculations_list_page_test.dart`:
  - chips de fecha abren presets; aplicar preset filtra la lista.
  - resumen visible con filtro activo / oculto sin filtros.
  - tap en cliente filtra y muestra chip activo; × limpia.
  - menú de orden cambia el orden de las cards.
  - overflow en 320dp sin error (nueva fila de chips no rompe).

## Criterios de aceptación

1. Desde el historial se puede filtrar por rango de fechas (presets +
   personalizado); el chip muestra el rango activo y permite limpiarlo.
2. Tap en el nombre de un cliente filtra solo sus cotizaciones; el chip
   "Cliente: X" aparece con botón de limpiar.
3. La búsqueda encuentra cotizaciones por el label del filamento usado.
4. El resumen "N cotizaciones · Total Bs." aparece solo con filtros activos
   y suma el total efectivo (unitario × cantidad).
5. El orden cambia entre las 5 opciones; el default es fecha reciente
   (comportamiento actual intacto).
6. Los filtros se combinan con AND; limpiar uno no resetea los demás.
7. Los 6 locales compilan (`dart analyze` limpio).
8. `flutter test` verde (nuevos tests de notifier + widget).
9. La lista sin filtros activos se ve idéntica a hoy (sin resumen visible,
   mismo orden, sin chips nuevos seleccionados).
10. CSV export sigue exportando el historial completo (sin cambio).

## No-goals

- **Paginación/virtualización** del historial (descartada por el usuario en
  la selección de scope).
- Filtro por impresora o por filamento específico (solo búsqueda libre en
  labels).
- Persistir filtros/orden entre sesiones.
- CSV export filtrado (exporta todo el historial).
- Cambios al motor de cálculo, al schema de drift o a la migración.
- Filtro por cliente vía dropdown (solo tap en card, v1).