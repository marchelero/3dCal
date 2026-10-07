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

## Ronda 2 — los 7 MED resueltos (2026-10-05)

Reafirmada la decisión F4 (borradores cuentan en TODAS las métricas del
dashboard; solo `countAll` del cap Free los excluye):

- **MED-04 (dashboard vs borradores)** — `calculation_repository.dart`:
  `countSold()` ahora usa `excludeTemplatesFilter()` (incluye borradores: el
  numerador de `totalSold` ya los contaba); nuevo
  `countAllIncludingDrafts({since})` usado por `dashboard_stats.dart`
  (`avgTicketQuoted` divide universos iguales); `countAll()` conserva la
  semántica de cap Free; `topClients` sin `AND is_partial = 0`.
  (`recentClientNames` NO se tocó: es diálogo de guardado, no dashboard.)
- **MED-05 (autosave sin escalón)** — `stateToPartialDto` escribe
  `batchDiscountPercent: Value(state.batchAppliedPercent?.toString())` y
  `batchDiscountAmount: Value(state.batchDiscountAmount.toString())`
  (null explícito cuando no hay tier ≠ campo ausente en el upsert).
- **MED-06 (backup perdía los modos)** — restore v17 con claves ausentes →
  `?? 'auto'` (modelingMode/postprocMode) y `?? 'off'` (extraMode); respeta
  los defaults de columna (`calculations_table.dart:142/149/157`).
- **MED-07 (printMinutes abortaba restore)** — `_checkOptionalInt` en
  `backup_models.dart`; el insert usa `row['printMinutes'] as int? ?? 0`.
- **MED-08 (Pro caía a Free con storage lento/caído)** — `resolveIsPro`
  degrada a la CACHE (`entitlementCacheProvider.isPro || isProProvider`) en
  TimeoutException Y en catch. **Detalle posterior**: `degradedToCache` envió
  la lectura del cache en try/catch — en contextos sin override de
  `sharedPreferencesProvider` (tests) el cache lanza `UnimplementedError` y el
  error escapaba del catch rompiendo 12 tests de `calculator_notifier`; ahora
  degrada solo al notifier en ese caso (misma semántica pre-fix, fail-safe).
- **MED-09 (string hardcodeado)** — clave `settingsMinimumChargeRange` en
  `app_strings.dart` + los 5 impls ("Range/Faixa/Plage/Bereich: 0-100000");
  `print_settings_page.dart:194` la usa en el validator.
- **MED-10 (labels de material stale)** — el listener de drift en
  `calculations_notifier.dart` marca `_materialLabelsLoaded = false` y
  refresca con `unawaited(_refreshMaterialLabels())` (guard `ref.mounted`):
  buscar por material encuentra lo recién guardado sin repetir `search()`.

**Tests de regresión MED (nuevos, verdes):** `audit_regression_test` +5
(3 × MED-04: cap vs dashboard / countSold con borrador vendido / topClients;
2 × MED-05: persiste percent+amount, null explícito) · `backup_roundtrip_test`
+1 (MED-06/07: backup pre-v17 sin printMinutes/modos → restore ok + defaults)
· `calculations_notifier_test` +1 (MED-10) · `entitlement_service_test` +1
(MED-08: notifier en error + cache Pro → true; diseño con
`getActiveError`, no `blockGetActive` — con cache Pro el build retorna Pro al
instante y no ejercita el fallback) · `l10n_parity` cubre MED-09 por paridad
genérica.

**Verificación final (corrida completa, excluidos los 4 archivos con hang):**
`flutter analyze` **0 errores** (24 issues pre-existentes) · unit+integration
**+617 −14** · widget **+194 −10** · **cero rojos nuevos**: los 24 rojos son
los diagnosticados (result_sheet ×9, printer_catalog ×2, partial_save ×3,
discount_tiers ×2, settings_page ×4, sprint0 ×2 —mismo bug de Timer pending
del hallazgo #12—, quote_save_flow ×1, printer_form_page ×1) + 4 hangs de
deuda. Nota: los 12 rojos que aparecieron en `calculator_notifier` durante la
corrida eran del MED-08 (ver arriba) y quedaron en verde (56/56).

## Ronda 2 — los 7 LOW resueltos (2026-10-05, posterior)

Verificación: `flutter analyze --no-pub` **0 errores / 24 issues = baseline**.
No se re-corrieron tests (directiva de la sesión: solo analyze).

- **LOW-11 (valor monetario se salía de la fila)** — `money_row.dart`: label en
  `Flexible(maxLines: 1, ellipsis)` + valor envuelto en `FittedBox(scaleDown)`.
- **LOW-12 (monto largo en `_Row` del detalle)** — `calculation_detail_page.dart`:
  valor monetario en `Flexible(child: FittedBox(scaleDown))`.
- **LOW-13 (IconButtons sin tooltip)** — clave `commonClearSearch` en
  `app_strings.dart` + los 5 impls ("Limpiar búsqueda / Clear search / Limpar
  busca / Effacer la recherche / Suche löschen") y `tooltip:` en los 4 clear
  buttons (calculations_list_page, settings_page, filaments_page,
  printers_page).
- **LOW-14 (errores de backup hardcodeados en ES)** — nuevo `BackupErrorCodes`
  (6 códigos ASCII: `size_too_large`, `invalid_file`, `read_failed`,
  `invalid_data`, `future_version`, `restore_failed`) en `backup_service.dart`;
  todos los `return '...'` con mensaje en español ahora devuelven códigos y
  mandan el detalle a `debugPrint`; `settings_page` los traduce con
  `_backupErrorText()` → `EsBO.settingsBackupImport{SizeError, InvalidFile,
  FutureVersion, Error}`; el detalle de `BackupData.validate()` (español) quedó
  como diagnóstico de log — el snackbar muestra el genérico localizado; y
  `BackupSummary.describe()` se movió a l10n como
  `settingsBackupImportSummary(calcs, filaments, printers, tiers)` (5 impls,
  mismo orden y textos que `describe()` para no cambiar el diálogo es-BO).
- **LOW-15 (`effectiveTotalSnapshot` write-only / nombre contradictorio)** —
  documentado en la columna: escribe `totalFinal` pre-descuento y no se lee en
  ninguna query de negocio (solo se copia al duplicar); candidata a drop en una
  migración futura.
- **LOW-16 (tasas pisadas con 0 sin input)** — `stateToPartialDto` usa
  `rateSnap()`: con `input == null` las 7 tasas van `Value.absent()` (en UPDATE
  conservan las tasas reales del borrador; en INSERT caen al default 0). El
  autosave de salida ya no borra las tasas de un borrador.
- **LOW-17 (migración v2→v3 agregaba 11 columnas NOT NULL sin DEFAULT)** — las
  11 columnas F1 de `calculations_table.dart` ahora tienen
  `withDefault(Constant(0))`; `build_runner` regeneró `app_database.g.dart`, de
  modo que el `m.addColumn` de la migración emite `DEFAULT 0`. Efecto en
  callers: el `.insert()` de drift pasa a aceptar `Value<double>` para columnas
  con default → adaptados 44 call sites de tests (`backup_roundtrip` ×22,
  `migration_v5_to_v6` ×11, `migration_v8_to_v9` ×11) y el `duplicate()` del
  repository ahora copia con `Value(source.x)` (arrastra los valores reales, no
  los resetea al default). Sinergia con LOW-16: el default es lo que hace
  seguro el `absent` en INSERT.

**Deuda restante (sesión propia, pendiente):** ~24 rojos + 4 hangs de tests y
la limpieza/consolidación de la suite (~843 tests en 86 archivos) que el
usuario pidió revisar "luego".

