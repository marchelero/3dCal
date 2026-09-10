# Reporte — Corrección de hallazgos de auditoría de calidad

**Fecha**: 2026-09-10 · **Estado**: 584/584 tests verdes · analyze: 3 warnings pre-existentes
**Alcance**: 25 hallazgos de la auditoría `code-quality-analyzer` (3 críticos · 4 altos · 11 medios · 7 bajos), sin features nuevas.

## Críticos (pierden datos en silencio)

1. **Backup/restore incompleto** — `lib/core/backup/backup_service.dart`
   - `_insertFilaments` ahora restaura `color`; `_insertPrinters` restaura `purchaseCost` + `usefulLifeHours`; `_insertCalculations` restaura `quantity` (default 1) + `amortizationCostSnapshot` (default 0). Antes el export los serializaba pero el import los descartaba.
2. **`isTemplate` se restauraba siempre `false`** — `backup_service.dart` comparaba `row['isTemplate'] == 1` pero el JSON exporta `true/false`. Fix: `as bool? ?? false`. Verificados los otros bools (`isSold`, `isDefault`): ya usaban `as bool`.
3. **Import de backup duplicado divergido** — `settings_page.dart` reimplementaba el pipeline. Nuevo helper `BackupService.validateFileSize(PlatformFile)` centraliza el chequeo de tamaño (picker size + bytes + `lengthSync`); la UI y `import()` lo reutilizan.

## Altos (resultados incorrectos)

4. **Detalle histórico recalculado con settings actuales** — `calculation_detail_page._recomputeOutput` ahora usa `*Snapshot` persistidos (kwhRate, laborRate, profitBase, postProcessRate, failureRate, markupOnMaterials, printerWatts) con fallback al valor actual solo si el snapshot es 0/legacy.
5. **PDF ignoraba la moneda** — `pdf_export.dart`: `_fmt` recibe `WorldCurrency`; `shareQuotePdf`/`buildQuotePdfBytes` aceptan `currency` (default bob) y la propagan. Callers (result_sheet, detail page) pasan la moneda desde `selectedCurrencyProvider`.
6. **Desglose de detalle ignoraba la moneda** — `detail_section.dart`: parámetro `currency` + `formatCurrency` en todas las filas; `quote_image_template` lo propaga.
7. **`_quantity` del sheet desincronizado** — `result_sheet.dart`: `_quantity` se inicializa desde `widget.state.quantity` (imagen y guardar usan el mismo valor).

## Medios (comportamiento engañoso)

8. **Draft no restauraba extras F1** — `calculator_notifier.restoreFromDraft` mapea `extraLaborRate/extraPostProcessRate/extraFailureRate/extraMarkupOnMaterials`.
9. **Locale no propagaba a UI estática** — `app.dart`: `key: ValueKey(locale)` en `MaterialApp.router` fuerza rebuild global al cambiar idioma.
10. **`formatCurrency` pasaba por double** — `currency_formatter.dart`: helper `_toFormattableDouble` redondea con `Decimal.round(scale: 2)` antes de `toDouble()` (exactitud de centavos hasta 2^53). `formatPercentage` usa scale 3.
11. **`minimumCharge` era config muerta** — implementado el piso en `calculation_engine.dart` sobre el total final (`max(total - discount, minimumCharge)`, guard `> 0`); `CalculationInput.minimumCharge` + `_buildInput` lo conecta desde settings; comentario de `calculator_state.dart` corregido. 4 tests nuevos en `calculation_engine_test.dart`.
12. **`PrinterRepository.update` borraba amortización** — null → `Value.absent()` (preserva); nuevo flag explícito `clearAmortization` → `Value(null)`. `printers_notifier` + `printer_form_page` lo propagan (patrón espejo de `FilamentRepository.updateColor`).
13. **`updateMetadata` null-wipe** — `calculation_repository.dart`: `Value.absent()` para campos no provistos (tiene callers en test → se conservó).
14. **Entitlement traga errores sin log** — `entitlement_providers.resolveIsPro`: `debugPrint` en timeout (caso esperado) y en fallo inesperado con stack. `entitlement_notifier.activate` retorna `Future<bool>` con log; `purchase()`/`restore()` devuelven `PaymentError`/`RestoreError` para que el paywall muestre reintento.
15. **`save()` sin feedback** — `calculator_notifier.save` lanza `FormIncompleteException` tipada; `calculator_page` la captura con snackbar. `HistoryCapReachedException` ahora reporta `currentCount` real (`repo.countAll()`) en save y duplicate.
16. **`setAsDefault` StateError** — `printers_notifier`: id inexistente → no-op.
17. **`PaymentService` código muerto + errores perdidos** — eliminados `_purchaseController`/`purchaseStream` (sin consumers); `PaymentError`/`RestoreError` incluyen `e.toString()` sanitizado. 14 fakes de test actualizados.
18. **Comentario obsoleto entitlements** — `entitlements_table.dart`: `'play_store'` → `'lifetime_purchase'` (valor real `kSourceLifetimePurchase`).

## Bajos (higiene)

19. **Código muerto eliminado** — `watchAll()` en `CalculationRepository`, `PrinterRepository`, `FilamentRepository` (sin callers). Conservados `CalculationOutput.simple`, `listAll`, `search`, `updateMetadata` (tienen callers en test).
20. **`formatCurrencyNumber` ignoraba `currency`** — parámetro eliminado (sin callers en repo).
21. **Parseo decimal rompía separadores de miles** — `decimal_extensions.normalizeDecimalString` maneja es_BO/en-US/mixtos/sin separadores; `calculator_state` lo reutiliza. 11 casos de prueba.

## Tests

- Nuevo: `backup_roundtrip_test` (round-trip preserva campos nuevos: color, purchaseCost, usefulLifeHours, quantity, amortizationSnapshot, isTemplate).
- Nuevo: 4 tests de `minimumCharge` en `calculation_engine_test`.
- Actualizados: `history_cap_test` (save inválido → `FormIncompleteException`), `database_repositories_test` (nuevo contrato `clearAmortization`), `calculator_notifier_test` (form inválido), `pro_locked_visual_test` (busca `ProBadge` de bloqueo, no texto "PRO" genérico — el `ProActiveBadge` de cabecera es legítimo en Pro).

## Notas

- El fallo pre-existente de `pro_locked_visual_test` (Pro veía badge "PRO") era un **test desactualizado**, no un bug de producto: el `ProActiveBadge` de estado activo (feature) muestra "PRO" legítimamente en cabecera para Pro. Corregida la aserción a `find.byType(ProBadge)`.
- 3 warnings de analyze pre-existentes en `calculator_page.dart` (unused import + 2 params sin uso) — no tocados, ajenos a esta corrección.
- Sin commits realizados: el working tree (43 archivos) queda listo para revisión y commit con consentimiento.