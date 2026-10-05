# Fixes de la auditoría externa 2026-10-04 — implementación

**Fecha:** 2026-10-05 · **Alcance:** F1-F3, F5-F9 (F4 excluido por decisión del
dueño: los borradores cuentan en TODAS las métricas del dashboard, es intencional)

## Verificación de la auditoría (16/17 reales)

Se revisó cada hallazgo contra el código de este repo (mismo commit `0698282`,
v0.6.0+13): **16 reales**, 1 falso positivo (LOW-14: "optional" es adjetivo
alemán válido) y LOW-17 parcial (clave literal coincide con DraftStorage; solo
riesgo de drift). Las 16 se arreglaron.

## Qué se cambió (por hallazgo)

- **HIGH-01/02** — Fuente única de total de lote: nuevo `LotTotals` (domain),
  `CalculationListItem.effectiveTotal` ahora resta el escalón mayorista y pisa
  con `minimumCharge×N`; mismo cálculo en hero/desglose/imagen/PDF del detalle,
  CSV y las 6 queries SQL del dashboard (`MAX(unit×qty − batch, mc×qty)`).
- **HIGH-03** — `computeFromSnapshot` aplica el piso `minimumCharge`
  (snapshot > 0 gana, si no Settings); las tasas reales (kWh/labor/falla/
  markup/profitBase/mínimo) e impresora (id/nombre/watts) AHORA se persisten
  en `_snapshotColumns` y en el autoguardado parcial (`buildPartialDto`).
  Se cableó el widget de Cargo Mínimo en Settings (Print) — el setter y el
  string l10n ya existían huérfanos.
- **HIGH-04** — Quitado el gate Pro del "Compartir PDF" del detalle (PRD dice
  PDF gratis); el redirect web `/paywall → /settings` ahora lleva `?from=paywall`
  y SettingsPage explica con SnackBar (`paywallUnavailable`).
- **MED-06** — resuelto por F2 (persistir impresora real).
- **MED-07** — `CalculationDraft` (sesión) persiste `quantity` (roundtrip
  tolerante: falta/corrupto → 1).
- **MED-08** — `filamentGrams` "0"/negativo se normaliza a 1000 g (antes:
  assert en debug tragado por catch / material = 0 en release).
- **MED-09** — Router: type-checks en `extra` + `int.tryParse`; refresh/deep
  link web degrada a formulario nuevo o página de error (no pantalla blanca).
- **MED-10** — Gate Pro también en `onChanged` del teclado; al editar cantidad
  el escalón se re-resuelve contra la N nueva (no queda congelado).
- **MED-11** — 4 strings hardcodeados → claves l10n (`commonCreateNew`,
  `commonAddToCatalog` existentes + 4 nuevas: `filamentFreeLimitTooltip`,
  `filamentFreeLimitHint`, `filamentFreeLimitSnack`, `quoteImageAddPiece`) en
  los 5 idiomas.
- **MED-12** — tests nuevos de regresión (ver abajo).
- **LOW-15** — orden de migraciones `from<15`/`from<16` corregido.
- **LOW-16** — `revokeObjectURL` diferido 10 s (Safari/Firefox).
- **LOW-17** — `DraftStorage.key` público, sin literal duplicado.
- **LOW-13** — NO se tocó (Key de locale en MaterialApp es intencional para
  el rebuild de `EsBO` estático; riesgo documentado de pérdida de state).

## Tests

**Nuevos (32/32 verdes):**
- `test/unit/audit_regression_test.dart` — 22: LotTotals, piso snapshot,
  paridad live↔snapshot, getter==SQL en DB en memoria, draft quantity.
- `test/unit/l10n_parity_test.dart` — 7: paridad mecánica 5 impls × ~680 claves.
- `test/widget/router_guards_test.dart` — 3: refresh sin `extra` / id no numérico.

**Pre-existentes rotos en HEAD que se repararon de paso (4):**
- `calculations_notifier_test` (2 de search: race con carga lazy de labels →
  `search()` ahora es awaitable), `calculator_notifier_test` (save ya no
  invalida; el test leía cache → `refreshQuiet()`), `full_flow_test` tab switch
  (UnmountedRefException → guard `ref.mounted` en `_reload`).

**Rotos ANTES y SIGUEN rotos (NO causados por este trabajo): 26 tests** — mismos
en HEAD y con mis cambios (verificado corriendo el subset con y sin stash).
Incluye `pro_badge_navigation` (además CUELGA la suite en HEAD igual),
`printer_catalog` (29 marcas/174 modelos), foto de pieza en `result_sheet`,
parciales (`partial_*`), `settings_page`, `discount_tiers_section`,
`calculator_settings_navigation`, `sprint0_smoke`. Son deuda previa
(posiblemente del upgrade Riverpod/drift) y quedan fuera de alcance.

## Pendiente fuera de alcance

- F4 (filtro de borradores en dashboard): NO aplicar — decisión del dueño.
- Los 26 tests rojos + hang de `pro_badge_navigation` requieren sesión propia.
- README "118/118" desactualizado.

## Ronda 2 — revisión completa post-fixes (2026-10-05): 17 hallazgos, 3 HIGH resueltos

Segunda revisión (agente, sobre el working tree con la ronda 1): veredicto FAIL
(3 HIGH / 7 MED / 7 LOW). Los fixes de la ronda 1 se verificaron intactos; los 3
HIGH se resolvieron en esta ronda:

- **HIGH-01 (CSV desalineado)** — `calculations_list_page.dart` +
  `csvExportHeader`: el header traía **14 columnas** con una "Materiales" que el
  writer **nunca emitía** (13) → todas las celdas corridas una posición desde
  "Horas" (pre-existente, igual en HEAD). Además `formatRaw` convertía `.`→`,`
  sin escapar y la coma partía la fila en 2 campos. Fix: columna eliminada en
  los 5 idiomas (13 en todos), `formatRaw` pasa por `_escapeCsv`, y
  `assert(cells.length == header.length)` como guardia de regresión. Test
  nuevo: `l10n_parity_test` valida 13 columnas × 5 idiomas.
- **HIGH-02 (duplicate pierde el escalón)** — `duplicate()` copiaba quantity y
  los modos v17 pero omitía `batchDiscountPercent/Amount` → la copia de un lote
  N>1 sumaba unit×N sin descuento en lista/CSV/dashboard/PDF. Fix: 2 líneas en
  el Companion. Test nuevo: copia = 900 (no 1000), `totalQuoted` = 1800.
- **HIGH-03 (dos totales por fila: piso de cargo mínimo)** — el detalle/PDF ya
  aplicaban `snapshot > 0 ? snapshot : Settings` (ronda 1), pero
  `CalculationListItem.effectiveTotal` y las 6 queries SQL usaban SOLO el
  snapshot — que en filas pre-F2 es 0 → la misma cotización mostraba 2 totales
  (tarjeta/CSV/dashboard vs hero/PDF). Fix: MISMA política en las 3 rutas:
  `fallbackMinimumCharge` inyectado por `watchItems` en el getter, y subquery
  `_minChargeFallbackSql` a la tabla `settings` (`key = 'minimum_charge'`) en
  `_effectiveTotalSqlExpr`. Test nuevo: fila legacy + settings=150 →
  getter == SQL == 300.

**Verificación ronda 2:** `flutter analyze` **0 errores** · unit+integration
**563 verdes** (49 archivos, excluidos los 4 clusters pre-rojos) · widget sanos
**145 verdes** · 1 roto NO causado: `printer_form_page` F5 "costo sin vida
util" — verificado pre-existente corriéndolo en HEAD con stash. Deuda roja total
ahora: 27 tests + los hangs conocidos.

**Queda pendiente (MED/LOW de la ronda 2):** MED-04 (dashboard: numerador con
borradores / denominador sin ellos — contradice la decisión del dueño),
MED-05 (autoguardado no persiste el escalón mayorista), LOW-16 (fallback del DTO
pisa tasas con 0 explícito), LOW-17 (migración v2→v3 `NOT NULL` sin `DEFAULT`),
más los LOW de tooltips/i18n de backup. Los 26+1 tests rojos son deuda previa.

