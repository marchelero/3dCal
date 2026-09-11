# Reporte — Historial avanzado: filtros de fecha, orden, materiales, resumen y cliente

**Fecha**: 2026-09-11 · **Estado**: 607/607 tests verdes · analyze: 0 issues
**Alcance**: Feature nueva según PRD `docs/PRD/2026-09-11-historial-filtros-avanzados.md` (aprobado). 5 entregables + 7 fixes de code review.

## Entregables implementados

1. **Filtros combinados en `CalculationsNotifier`** — pipeline AND: clientFilter (exacto case-insensitive) → dateRange (`createdAt.toLocal()`) → soldFilter → búsqueda (pieceName OR clientName OR materialLabels) → sort. Filtros expuestos via getters (`searchQuery`, `soldFilter`, `dateRange`, `clientFilter`); la página ya no tiene estado de filtro local (mejora Riverpod: antes `_soldFilter` vivía en la página con setState).
2. **Búsqueda en materiales** — nueva query `CalculationRepository.materialLabelsByCalcId()` con `LEFT JOIN calculation_materials` + `GROUP_CONCAT(label, '|')` + `GROUP BY id` + `is_template = 0`. Cache `Map<int, String>` en el notifier (build + _reload). Sin BLOBs, sin migración, contrato de `CalculationListItem` intacto.
3. **Ordenamiento** — enum público `HistorySort` (`lib/features/calculation/presentation/notifiers/history_sort.dart`): dateNewest (default), dateOldest, priceHigh, priceLow, clientAz. Orden por precio usa **total efectivo** (snapshot × quantity con clamp <1). Sheet de 5 opciones en AppBar.
4. **Filtro por fechas** — chip "Fechas" con presets (Hoy, 7 días, 30 días, Este mes, Este año, Todo) + personalizado (`showDateRangePicker`); label compacto del rango activo + × para limpiar.
5. **Filtro por cliente** — tap en el nombre del cliente en la card → filtra (highlight primario + chip con ×); comparación case-insensitive en ambos lados.
6. **Resumen del filtro** — barra "N cotizaciones · Total Bs." visible solo con ≥1 filtro activo; suma con `fold<Decimal>` de `effectiveTotal` (sin doubles intermedios); contador free oculto con filtros activos.
7. **i18n 6 locales** — 17 strings nuevos (`history*`), interfaz `AppStrings` compile-time (analyze no pasa con strings faltantes).

## Fixes post-review (code-reviewer)

| ID | Hallazgo | Fix |
|----|----------|-----|
| M1 | CSV exportaba el set filtrado (heredado, criterio #10 del PRD literalmente falso) | Getter `all` en notifier; `_exportCsv` itera `notifier.all` → historial completo real |
| M2 | `effectiveTotal` duplicado en 2 lugares (regla de dinero con clamp sutil) | Getter `Decimal get effectiveTotal` en `CalculationListItem`; `home_page` y página migradas; alias top-level conservado para tests |
| M3 | CSV perdía el acceso directo (<480dp caía al ⋮) | CSV en `priority` de `SmartAppBarActions`; solo el sort colapsa |
| N1 | Toggle/highlight de cliente case-sensitive vs filtro CI | `.toLowerCase()` en ambos lados |
| N2 | `hasActiveFilter` incompleto | Alineado a `notifier.searchQuery` + soldFilter + dateRange + clientFilter |
| N3 | Strings muertos `historySearchHint` y `historyFilterClient` (verificado con grep: 0 usos) | Borrados de los 6 archivos l10n |
| N4 | `de_de` traducía el chip de fechas como 'Daten' | → 'Zeitraum' |

## Bugs reales destapados por TDD

1. Riverpod no notificaba estado idéntico: `_applyFilters()` devolvía la misma instancia `_all` con solo sort → fix: siempre copiar la lista (`List.of`).
2. Sheets de 7 ListTiles desbordaban verticalmente en superficies bajas → `SingleChildScrollView`.
3. Card desbordaba a 320dp (columna precio + fila cliente/fecha) → fecha en `Flexible` con ellipsis.
4. Drift guarda DateTime con precisión de 1 segundo → bornes de rango a segundos enteros en tests.

## Archivos

**Creados**: `lib/features/calculation/presentation/notifiers/history_sort.dart`, `test/unit/calculations_notifier_test.dart` (17 tests)
**Modificados**: `calculations_notifier.dart`, `calculation_repository.dart`, `calculations_list_page.dart`, `home_page.dart`, 6 × l10n (`app_strings`, `es_bo`, `en_us`, `pt_br`, `fr_fr`, `de_de`), `test/widget/calculations_list_page_test.dart` (+6 tests)

## Verificación

- `flutter analyze` → **0 issues**
- `flutter test` → **607/607 passed** (+17 unit +17 widget vs 584 previos)
- Riesgo abierto: `GROUP_CONCAT` en web/wasm (sqlite3 wasm) no testeable localmente — motor SQLite idéntico, query texto puro sin variables interpoladas; riesgo bajo, validar en CI web.

## Notas

- Sin commits realizados: working tree listo para revisión y commit con consentimiento explícito.
- CSV export conserva el gate Pro y el empty-check sobre el set completo.
- El total del resumen puede diferir en centavos del dashboard (redondeo por-item vs SUM SQL al final) — patrón pre-existente, no introducido acá.