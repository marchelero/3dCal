# Ultima sesion

**2026-09-07 (tarde)**: Implementadas **F7-FIX (backup restaura fotos)** + **F5 (amortizacion de impresora)** del roadmap v2. Suite **517/517 verde** (antes 497), analyze solo 3 warnings pre-existentes.

## F7-FIX — Backup ahora restaura pieceImageBlob
Bug real (intuicion del usuario): el export SI serializaba `pieceImageBlob` (base64 via `toJson()` de drift), pero `_insertCalculations` lo ignoraba → las fotos de piezas se PERDIAN al restaurar. Fix:
- `backup_service.dart`: `_decodePieceImage()` (base64→Uint8List con try/catch; corrupto → `FormatException` → rollback transaccional, DB intacta).
- `backup_models.dart`: `kBackupMaxImageBase64Length` (2MB/foto) + `_checkPieceImage` en `validate()`.
- `kBackupMaxFileBytes` 50MB→128MB (con fotos ~100-400KB c/u, 50MB se rompia con ~100-370 fotos).
- Test nuevo `test/unit/backup_roundtrip_test.dart` (6): round-trip foto byte-a-byte, sin foto, base64 corrupto + rollback, no-String, oversize, valido.

## F5 — Amortizacion de impresora por hora (PRD v2)
- **Motor**: `CalculationEngine.amortizationPerHour(costo, vida_util)` → `Decimal?` (escala 6, null si vida ≤ 0 o costo ≤ 0 → sin linea, sin div/0). `amortizationCost` en output (default 0), entra a `baseCost` (fluye por failure% y profit%), linea entre energia y mano de obra.
- **Schema v10** (migracion aditiva v9→v10): `printers.purchase_cost` (REAL null), `printers.useful_life_hours` (INTEGER null), `calculations.amortization_cost_snapshot` (REAL default 0). Test nuevo `test/integration/migration_v9_to_v10_test.dart` (3); actualizados v4→v5/v5→v6/v8→v9 a user_version=10.
- **CRUD impresora**: 2 campos opcionales "Costo (Bs)" + "Vida útil (horas)"; validator "vida ≥ 1 si hay costo"; `setAsDefault` preserva campos.
- **UI desglose**: `DetailSection` + `QuoteImageTemplate` + `result_sheet` + `calculation_detail_page._recomputeOutput` (lee snapshot persistido — la impresora original pudo editarse) + `pdf_export` linea.
- **Repo**: `create`/`update` persisten campos; `_insertInTransaction` y `_duplicateInTransaction` persisten/copian snapshot.
- **l10n**: 6 claves nuevas en 6 locales (es/en/pt/de/fr).
- Tests: engine 5 (AC1 3500/4000h→2h=1.75, AC2 sin costo→sin linea, AC3 vida 0→null, costo≤0, flujo por profit%), repo 2, form 5.

## Pendientes
- Commit de este working tree (33 archivos, +940/−32; requiere consentimiento).
- Probar en Android real (crop+rotar, migracion v8→v9/v9→v10 sobre BD existente, backup con fotos round-trip, amortizacion en calculadora).
- Push a origin/main.

Ver: [2026-09-05-mejoras-pro-historial-crop-snackbar.md](2026-09-05-mejoras-pro-historial-crop-snackbar.md) · [PRD-v2-features-taller.md](../prds/PRD-v2-features-taller.md) · [PRD](../prds/2026-09-05_2353-mejoras-pro-historial-crop-snackbar.prd.md)