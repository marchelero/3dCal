# Reporte: Code review — calculation engine, repositories, persistence, UI

Fecha: 2026-08-24 · Agente: primary (code-reviewer sub-agente indisponible) · Estado: **FIXED — todos los hallazgos resueltos (2026-08-25)**

> **Resolución (2026-08-25):** ALTO-1 y los 8 MEDIO/BAJO corregidos. Schema v8
> (`quantity` default 1, multiplicación en read-time), l10n completo (5 locales),
> stats queries disparo-concurrente, DRY formatter, Consumer reactivo, docs.
> Bonus: 4 tests pre-existentes de HEAD reparados (migraciones v7→v8,
> `totalOriginal` fallback en template, finder ambiguo `$ 36,00`, chevron
> desactualizado). `flutter analyze`: 0 issues. Suite completa: **455/455**.

## Alcance

Commits `84b8542` + `11b83ef` (`84b8542~1..HEAD`): motor de cálculo, repositorio de cálculos, capas de persistencia, dashboard Pro (rangos/charts/insights), selector de cantidad (lote), suite de tests.

## Verificación ejecutada

- `flutter analyze`: 3 issues (2 warnings, 1 info — ver BAJO-5)
- Tests de los archivos nuevos/cambiados: 45/45 pasan (`dashboard_stats_test.dart`, `database_repositories_test.dart`)

## Hallazgos

| Sev | Hallazgo | Referencia |
|---|---|---|
| ALTO | **Cantidad (N) no se persiste**: la UI muestra y exporta `unitario × N`, pero `_buildDraft` guarda `output.totalPrice` UNITARIO; ni `CalculationDraft` ni la tabla `calculations` tienen columna quantity. Historial/dashboard/guardado muestran precio unitario ⇒ lo cotizado ≠ lo guardado, dashboard sub-reporta ventas por lote. PRD F2 exige persistir quantity + snapshot. | `calculator_notifier.dart:373-404`, `calculation_repository.dart:109-165`, `calculator_page.dart:669` |
| MEDIO | Strings hardcoded en español fuera de l10n: "Cantidad de Piezas", "Cotizar por lote / volumen", "Cantidad". Regla: UI vía l10n. | `calculation_detail_page.dart:642,653`, `result_sheet.dart:631` |
| MEDIO | `dashboardStatsProvider` encadena 11 awaits secuenciales; las queries son independientes → `Future.wait` reduciría latencia ~Nx. | `dashboard_stats.dart:130-143` |
| MEDIO | Dinero persistido como REAL/double con round-trip `toStringAsFixed(2)`; excepción de facto al non-negotiable `decimal`. Error despreciable en rangos normales, pero documentar o migrar a TEXT/int-centavos. | `calculation_repository.dart:390,402,418,432,480,509,539,568` |
| BAJO | Warnings de analyze: variable `cs` sin usar; import unused `calculation_output.dart`; double literal innecesario. | `calculator_page.dart:665,1391`, `calculator_notifier.dart:16` |
| BAJO | Comentario stale en entidad: dice `totalOriginal = totalFinal * quantity` pero el engine setea el totalFinal unitario (la multiplición correcta ocurre en el template). | `calculation_output.dart:101` vs `calculation_engine.dart:102` |
| BAJO | `_filamentIdFromLabel` parsea labels con formato "id:N" — frágil si un usuario nombra su material literalmente "id:5". | `calculation_repository.dart:596-602` |
| BAJO | DRY: `_formatGrams`/`_formatKg` duplican el formato g→kg de `_MaterialRow`. | `dashboard_page.dart:443-452` vs `601-606` |
| BAJO | `result_sheet` lee entitlement/isPro vía `ProviderScope.containerOf(ctx).read` (no reactivo dentro del sheet); anti-patrón frente a Consumer. | `result_sheet.dart:609-615` |

## Áreas OK

- Cap free: conteo+inserción atómicos en transacción drift, con test de concurrencia (`Future.wait` de dos guardados, solo 1 pasa)
- Exclusión de plantillas centralizada (`excludeTemplatesFilter`) + tests exhaustivos (historial, dashboard, search, cap, analytics)
- Motor y derivadas en `Decimal` con escala explícita (`scaleOnInfinitePrecision`), división por cero guardada (marginPct/avgTicket retornan null)
- Fechas consistentes en UTC (`created_at` y cutoffs de rango, chips estables vía initState)
- Duplicate: copia snapshots/materiales con id nuevo, isSold=false documentado, plantilla→cotización normal cubierta por test
- i18n por delegación EsBO funciona (patrón establecido); descuento × cantidad consistente en template (totalOriginal×qty, discountAmount×qty)

## Recomendación

Resolver ALTO-1 antes de cerrar F2-lotes: agregar columna `quantity` (migración aditiva v8), snapshot del % de descuento, y guardar `totalPriceSnapshot = unitario × N − descuento_lote`.
