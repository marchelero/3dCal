# Reporte — Tier 0: 8 bugs verificados (corrección + tests)

**Fecha:** 2026-10-08
**Rama:** `main`
**Alcance:** 8 hallazgos VERIFICADOS contra el fuente (Tier 0). No incluye hallazgos no verificados.
**Estado:** 8/8 corregidos. `flutter analyze` → 0 issues. `flutter test` → **838 pasan** (baseline 833 + 5 nuevos).
**Commit:** NO realizado (pendiente de consentimiento explícito).

---

## Contexto de verificación

Antes de tocar nada se descartó un lote de hallazgos de un subagente `database-reviewer`
por ser **inválidos/stale**: afirmaba `schemaVersion 5` y tablas inexistentes
(`calculation_items`, `calculation_pieces`), y un FK sin cascade que en el fuente
(`calculation_materials_table.dart`) sí es `KeyAction.cascade`. Verificado contra:
`printers_table.dart`, `filaments_table.dart`, `calculations_table.dart`,
`calculation_materials_table.dart`, `settings_table.dart`, `entitlements_table.dart`,
`settings/data/tables/discount_tiers_table.dart` (schema real v17).

Baseline sano previo: `flutter analyze` 0 issues, `flutter test` 833/833.

---

## Fixes aplicados

### Fix 1 — Bypass Pro en cantidad desde `result_sheet` (result_sheet.dart)
- **Causa:** el `onChanged` del campo cantidad no chequeaba `locked`; un usuario free
  podía editar el campo bloqueado y esquivar el paywall.
- **Cambio:** guard `locked` en el `onChanged` (~893-905): revierte `_quantityCtrl.text`,
  `Navigator.of(ctx).pop()`, `GoRouter.of(ctx).push('/paywall')` y retorna.
  `locked` definido ~820; `ctx`/`GoRouter` en scope.

### Fix 2 — `saveAsTemplate` perdía campos v17 (calculator_notifier.dart)
- **Causa:** la plantilla se guardaba sin `modelingMode/Value`, `postprocMode/Value`,
  `extraCostMode/Value`, `extraCostLabel`; al reusarla se perdía el modo `%`/fijo.
- **Cambio:** `saveAsTemplate` (~743-753) ahora pasa los 7 campos v17 vía
  `_normalizeServiceMode(...)` / `_textToDouble(...)`, igual que `stateToPartialDto`.
  Confirmado ~688-694.

### Fix 3 — `kIsWeb` forzaba Pro=true (main.dart / app_constants.dart)
- **Causa:** en web se inyectaba `isProProvider.overrideWithValue(true)` sin condición.
- **Cambio:** `app_constants.dart` agrega `kWebUnlockAll = bool.fromEnvironment('WEB_UNLOCK_ALL', defaultValue: true)`.
  `main.dart` cambia a `if (kIsWeb && kWebUnlockAll) { overrides.add(...); }`.

### Fix 4 — Unidad de amortización en el audit del reporte (calculator_notifier.dart)
- **Causa:** se pasaba `input.amortizationPerHour` (Bs/h) a `ResolvedRates.amortizationCost`,
  cuyo contrato es el costo ACUMULADO (Bs); `PdfRateAudit.fromRates` volvía a dividir por
  `totalHours` → la fila de amortización del PDF/PNG quedaba dividida por horas de más.
- **Cambio:** `_recompute` ~830 usa `amortizationCost: output.amortizationCost` con comentario.

### Fix 5 — `savePartial` sin transacción (calculation_repository.dart)
- **Causa:** el chequeo de existencia + `updatePartial`/insert + `_replaceMaterials` no eran
  atómicos; un fallo a mitad dejaba cotización parcial inconsistente.
- **Cambio:** `savePartial` devuelve `_db.transaction(() async { ... })` envolviendo
  existe-check + update/insert + `_replaceMaterials`.

### Fix 6 — Validación de `discountTiers` en backup (backup_models.dart)
- **Causa:** `percent` se validaba solo como string y `minQty` como int genérico. Un backup
  con `percent: "abc"` reventaba `Decimal.parse` al leer los tiers; uno con `"99999"`
  trucaba los totales.
- **Cambio:** import `package:decimal/decimal.dart`; nuevos helpers `_checkMinQty`
  (int ≥ 1) y `_checkPercent` (`Decimal.tryParse` y rango `(0, 100]`). Reemplazan
  `_checkString(row,'percent')` y `_checkInt(row,'minQty')` en el loop de tiers (~330-331).

### Fix 7 — Snackbar "Guardado" falso en Ajustes (settings_page.dart / print_settings_page.dart)
- **Causa:** `unawaited(updateX(...)); _showSavedSnack(context)` mostraba "Guardado"
  aunque la persistencia fallara, y tragaba el error async.
- **Cambio:** helper `_persistAndNotify(context, action)` que hace `await`, muestra el
  éxito solo si termina bien, y ante excepción `debugPrint` + `AppSnackBar.error(EsBO.commonErrorGeneric)`.
  - `settings_page.dart`: 4 call sites (companyName, `_pickLogo`, `_removeLogo`, `_showCurrencySearch`).
    Se eliminó el `_showSavedSnack` de `_LogoPicker` (quedó sin uso).
  - `print_settings_page.dart`: 3 call sites (`updateProfitBase`, `updateKwhRate`,
    `updateMinimumCharge`) + `import 'dart:async'`.

### Fix 8 — `_handleDelete` sin manejo de error (calculation_detail_page.dart:972)
- **Causa:** `unawaited(_handleDelete())`; si `delete` fallaba, el usuario tocaba
  "Eliminar", no pasaba nada y no volvía, sin feedback.
- **Cambio:** try/catch alrededor de `delete` + `context.pop()`; en fallo
  `debugPrint` + `AppSnackBar.error(EsBO.commonErrorGeneric)`. Import
  `flutter/foundation.dart` ampliado con `debugPrint`.

---

## Tests

- **Nuevos (Fix 6):** `test/unit/backup_validation_test.dart` — 5 casos:
  tier válido pasa; `percent` no numérico rechazado; `percent` fuera de `(0,100]`
  rechazado (99999 y 0); `percent` no-String rechazado; `minQty < 1` rechazado.
- **Existentes relevantes:** amortización y su contrato de audit ya cubiertos por
  `test/unit/quote_report_variant_test.dart` (`audit.amortizationPerHour == 2.5`) y
  `test/unit/database_repositories_test.dart` (F5 snapshot de amortización).
- **Resultado:** `flutter test` → **838 pass / 0 fail**. `flutter analyze` → **No issues found**.

---

## Archivos modificados

```
lib/core/backup/backup_models.dart
lib/core/constants/app_constants.dart
lib/features/calculation/data/calculation_repository.dart
lib/features/calculation/presentation/pages/calculation_detail_page.dart
lib/features/calculation/presentation/state/calculator_notifier.dart
lib/features/calculation/presentation/widgets/result_sheet.dart
lib/features/settings/presentation/pages/print_settings_page.dart
lib/features/settings/presentation/pages/settings_page.dart
lib/main.dart
test/unit/backup_validation_test.dart
```

---

## Pendientes (NO tocados — Tier 1/2, requieren decisión)

- God widgets (`result_sheet.dart build` ~475 líneas; descomposición).
- `setState` para estado de negocio en `calculation_detail_page.dart` (~122/128).
- Fórmula de descuento duplicada (extraer a dominio compartido).
- Índices de DB (hallazgo **no verificado** — descartado junto al lote inválido).
- a11y: 74 `Color(0x` hardcoded, sin manejo de text-scale, contraste.
- Paywall hardening (SEC-01); firma de backups (SEC-03); URLs legales placeholder
  (`app_constants.dart` ~146-152, SEC-12); guard de `base64Decode` en `pdf_export.dart:1146`.
- Docs stale: `README.md` (dice 118 tests, MVP 1.0.0), `docs/PROJECT.md`, `docs/PRODUCT.md`.
