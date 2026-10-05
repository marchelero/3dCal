# Sesión 2026-10-05 — Revisión ronda 2 (17 hallazgos) + fixes HIGH/MED

HEAD: `0698282` (sin commits nuevos; 36 archivos modificados en working tree, requieren consentimiento para commit).

## Contexto

Segunda ronda de revisión con agentes sobre 3dCal. Ronda 1 (F1–F9) ya estaba cerrada en sesión anterior y reporte `docs/audits/2026-10-05_code-review-fixes.md`.

**Decisión del usuario vigente (F4)**: los borradores (`is_partial`) cuentan en TODAS las métricas del dashboard; el cap Free (`countAll`) es el único que los excluye.

**Ambiente**: `flutter-reviewer` y `code-quality-analyzer` FALLAN como subagentes ("OpenCode's free tier can only be used from within OpenCode") → usar `subagent_type: "general"`. `rg` no existe → PowerShell `Select-String` o tool `glob`. NO correr 2 `flutter test` en paralelo; matar `dart`/`flutter_tester` huérfanos antes (bloquean `build\native_assets\windows\sqlite3.dll`).

## Hecho

### Ronda 2 — diagnóstico
- 2 agentes `general`: (a) review de código → 17 hallazgos (3 HIGH / 7 MED / 7 LOW), veredicto FAIL; (b) diagnóstico de los ~26 tests rojos pre-existentes → tabla por cluster (mayoría tests desactualizados; hang raíz = `addTearDown` LIFO: `db.close()` antes que `container.dispose()`).
- Reportes de agentes: `C:\Users\Marcelo\.local\share\opencode\tool-output\tool_10aaa8a8f001f0oovqetKBavYb` (review), `tool_10ad3faec001WuaQivkEHXqXfp` (tests).

### HIGH (los 3, fijados y verificados)
- **HIGH-01 CSV**: header de 14 col vs writer de 13 → columna "Materiales" quitada de los 5 idiomas (13 en todos); `formatRaw` envuelto por `_escapeCsv`; `assert(cells.length == EsBO.csvExportHeader.length)`.
- **HIGH-02 `duplicate()`**: `batchDiscountPercent/Amount: Value(source.…)` al Companion del insert en `calculation_repository.dart`.
- **HIGH-03 piso de cargo mínimo**: `CalculationListItem.fallbackMinimumCharge` + ternario en `effectiveTotal`; `watchItems()` `.asyncMap` con `_minimumChargeFallback()`; subquery `_minChargeFallbackSql` en `_effectiveTotalSqlExpr`.

### MED (los 7, código hecho)
- **MED-04**: `countSold()` usa `excludeTemplatesFilter()` (incluye borradores); nuevo `countAllIncludingDrafts({since})`; `countAll()` conserva cap Free; `topClients` sin `AND is_partial = 0`; `dashboard_stats.dart` usa el nuevo count. (`recentClientNames:837` NO tocado — diálogo de guardado, no dashboard.)
- **MED-05**: `stateToPartialDto` escribe `batchDiscountPercent: Value(state.batchAppliedPercent?.toString())` y `batchDiscountAmount: Value(state.batchDiscountAmount.toString())` (`calculator_notifier.dart` ~línea 1089).
- **MED-06**: restore v17 → `?? 'auto'` (modelingMode/postprocMode), `?? 'off'` (extraMode) en `backup_service.dart` (defaults de columna: `lib/features/calculation/data/tables/calculations_table.dart:142/149/157`).
- **MED-07**: `_checkOptionalInt` en `backup_models.dart`; insert usa `row['printMinutes'] as int? ?? 0`.
- **MED-08**: `resolveIsPro` con helper `degradedToCache()` = `ref.read(entitlementCacheProvider).isPro || ref.read(isProProvider)` en handlers TimeoutException/catch (`entitlement_providers.dart`).
- **MED-09**: clave `settingsMinimumChargeRange` en `app_strings.dart` + es_bo + en_us/pt_br/fr_fr/de_de; `print_settings_page.dart:194` la usa.
- **MED-10**: listener de drift en `calculations_notifier.dart` marca `_materialLabelsLoaded = false` + `unawaited(_refreshMaterialLabels())` (guard `ref.mounted`); import `dart:async`.

### Tests de regresión MED (todos en verde, verificados por archivo)
- `test/unit/audit_regression_test.dart`: +3 tests MED-04 (cap vs dashboard, countSold con borrador vendido, topClients) con helper `draft()`; +2 tests MED-05 (grupo `stateToPartialDto: escalón mayorista (R2-MED-05)`). Imports nuevos: `drift.dart show Value`, `calculator_notifier.dart`, `calculator_state.dart`.
- `test/unit/backup_roundtrip_test.dart`: +1 test `R2-MED-06/07` (fixture sin printMinutes ni modos → restore ok + defaults auto/auto/off/0).
- `test/unit/calculations_notifier_test.dart`: +1 test `R2-MED-10` (poll 2s hasta que 'Recien guardada' aparezca en search por material).
- `test/unit/entitlement_service_test.dart`: +1 test `R2-MED-08` **reescrito** — Diseño original (blockGetActive + cache Pro) NO ejercitaba el fallback porque con cache Pro `build()` retorna Pro al instante y, además, el teardown dispose-en-medio-crash-eaba ("Cannot use the Ref ... after it has been disposed" en `deactivate`). Diseño final: getActiveError → notifier en error → control `false` con cache vacía → `prefs.setBool(kIsProKey, true)` → segundo `FutureProvider<bool>(resolveIsPro)` nuevo (los FutureProvider cachean) → `true` = MED-08.
- `test/unit/l10n_parity_test.dart`: sin edits — es genérico (parsea miembros de `app_strings.dart` vs 5 impls); cubre MED-09 automáticamente.
- Corrida aislada: batch 1 = 94/95 (solo fallaba MED-08 viejo) → entitlement solo = **22/22 verde**.

### Verificación
- `flutter analyze --no-pub`: **0 errores** (24 issues = warnings/infos pre-existentes, mismo estilo del repo).
- Suite completa (82 archivos, excluidos los 4 hangs) CORRIDA PERO INCONCLUSA: abortada por timeout de 15 min. Parcial a las 12:48: `+799 -36`, todos los `[E]` vistos coinciden con la lista pre-existente (settings_page ×4, sprint0 ×1, etc.) + hubo un gap ~10 min entre 02:55 y 12:46 (posible otro hang/lento: revisar). **Ningún rojo atribuido a los cambios.**
- Lista roja pre-existente esperada (diagnóstico): printer_catalog ×2, discount_tiers_section ×2, result_sheet ×9, partial_save_notifier ×1, partial_save_repository ×2, quote_save_flow ×1, settings_page ×4, sprint0 ×1, printer_form_page ×1, + otros del cluster = ~27. HANGS (excluir): `test/widget/{pro_badge_navigation,partial_identity,partial_express_save,calculator_settings_navigation}_test.dart`.

## Pendiente (para próxima sesión)

1. **Confirmar suite completa en verde-alto** sin los 4 hangs: correr por lotes (unit+integration primero, widget después) o con timeout mayor; verificar = rojos solo los ~27 pre-existentes.
2. **Actualizar reporte** `docs/audits/2026-10-05_code-review-fixes.md` → sección MED (los HIGH ya están escritos; falta documentar MED-04..10 + tests).
3. **7 LOW de la ronda 2** sin tocar (ver reporte del agente en `tool_10aaa8a8f001f0oovqetKBavYb`).
4. **Deuda de tests** (~27 rojos + 4 hangs): tests desactualizados vs fixes reales; raíz hang = `addTearDown` LIFO. Sesión aparte.
5. **Commit**: NO hecho (no pedido). 36 archivos modificados.

## Notas de código (gotchas)

- drift `Value` tiene **`present`** (no `isPresent`/`isAbsent`): `expect(v.present, isTrue)`.
- `CalculatorState` tiene requireds: `mode, printHours, printMinutes, discountPct, weight, filamentPrice, filamentGrams, label, materials, output`.
- `FutureProvider` creado localmente en test **cachea** su future: para re-evaluar `resolveIsPro` crear otra instancia.
- `EntitlementNotifier.build()` con cache Pro no espera nada (fire&forget `_syncEntitlementWithStore` + `return EntitlementPro`); `deactivate()` corre en background y revienta si el container ya se dispuso.
- Test files pre-rojos: NO arreglarlos en esta línea de trabajo (deuda aparte); excluir `--plain-name` o correr por archivo.
