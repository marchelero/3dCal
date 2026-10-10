# Auditoría — Corrección de brechas 2026-10-10

**Fecha**: 2026-10-10 · **Rama**: `main` (base `57f218c`) · **Status**: COMPLETADO
**Reporte auditado**: `docs/reports/2026-10-10_gap-remediation.report.md`
**PRD**: `docs/prds/2026-10-10_1600-gap-remediation.prd.md`
**Alcance**: verificación independiente de AC-001..AC-014 contra el código y los
tests del working tree.

## Veredicto

**PASS** — 14/14 criterios implementados con evidencia verificable (código +
tests). Suite global **999/999**, `flutter analyze` **0 issues**, `flutter build
web` **OK**. Sin FAIL; sin NIT.

## Verificación por criterio

| AC | Estado | Evidencia |
|---|---|---|
| AC-001 | PASS | `calculator_notifier.dart` `setQuantity` → `clamp(1, kMaxQuantity)`; `result_sheet.dart` normaliza input y deshabilita `+` en el tope; `calculator_notifier_test` 57/57, `result_sheet_test` 27/27 |
| AC-002 | PASS | `initial_config_page.dart` validator entero >0 + `Decimal.parse` en try/finally; clave `filamentGramsPositiveInteger` ×6; `initial_config_stepper_test` 17/17 |
| AC-003 | PASS | `calculation_draft.dart` `partialId` (backward-compatible); `calculator_page.dart` persiste y promueve la misma fila; `draft_recovery_test` 6/6 |
| AC-004 | PASS | `local_data_wipe_service.dart` (transacción + prefs, sin `clear()`, entitlements excluido); sección UI con confirmación; `data_deletion_test` 3/3, `settings_page_test` +3 |
| AC-005 | PASS | `configFilamentOptional`/`configFilamentSectionHelper` «(requerido)» ×5; `gap_remediation_l10n_test` 5/5 |
| AC-006 | PASS | `settingsBackupDisclosure` (manual, sin sync, sin cifrado, HMAC=integridad) ×5; test l10n |
| AC-007 | PASS | `legalPrivacyDocument` ×5 declara borrado manual de backups; test l10n |
| AC-008 | PASS | `web/manifest.json` sin descripción/color de template; usa identidad 3dCalc + seed `#0B5394` |
| AC-009 | PASS | `settingsCurrencyHelper` (sin conversión ni tasas) ×5; test l10n |
| AC-010 | PASS | `.github/workflows/ci.yml` en `pull_request`, analyze+test+build web, sin secrets |
| AC-011 | PASS | `migration_v1_to_v17_test.dart` 9/9 (v1/v2/v3 × migración/columnas/idempotencia) |
| AC-012 | PASS | `docs/notes/play-sandbox-checklist.md` (compra/restore/cancelación/revocación + nota de cuentas externas) |
| AC-013 | PASS | `README.md` aclara Android como plataforma de pagos; iOS/web sin Pro |
| AC-014 | PASS | URLs legales intactas; acción externa registrada en `docs/notes/store-compliance.md` |

## Revisión técnica de las decisiones críticas

- **Aislamiento del borrado**: `wipeWorkData()` corre en `db.transaction` (DB
  primero, atómica) y borra prefs después (idempotente). Nunca toca la tabla
  `entitlements` ni usa `SharedPreferences.clear()`. Preserva locale (`locale`),
  tema (`theme_mode`), cache Pro (`is_pro`/`entitlement_source`/
  `entitlement_validated_at`) y claves HMAC (`backup_hmac_key_v1`/
  `install_id_v1`). Verificado por el test de preservación y por el test de
  fallo con trigger (rollback completo).
- **Sin éxito falso**: la UI envuelve la operación en try/catch; ante error de
  DB emite `settingsWipeError` y NO navega. Cubierto por
  `settings_page_test` «fallo de DB nunca reporta éxito».
- **Idempotencia**: segundo wipe sobre base vacía no lanza (test dedicado).
- **Regresión de identidad (AC-003)**: draft legacy sin `partialId` sigue
  decodificando (`partialId: null`) sin heurística de match; el guardado
  definitivo usa `updateCalculation`, no insert → una sola fila.
- **Lint/format**: 0 issues tras `dart format` (80 cols) y reorden de imports.

## Observaciones (no bloqueantes)

- **Ruido legacy en `dispose`**: `_persistPartialSync` degrada a
  `stateToPartialDto` sin tasas y `savePartial` registra
  `[PartialSave] onExit ERROR`. Pre-existente, capturado, no bloqueante.
- **`company_name`/`company_logo`/`currency_code`** se borran con el wipe por
  alcance literal del PRD (tabla `settings` completa). Reconfirma que el aviso
  al usuario debe mencionar «ajustes de cálculo» y reinicio de onboarding; el
  diálogo lo hace.
- **CI**: no se ejecutó en este entorno (requiere push/PR); sintaxis y pasos
  revisados manualmente, sin secretos ni firma.

## Estado

Sin commit/push (pendiente verbo explícito del usuario). No hay hallazgos que
bloqueen el cierre de la iteración.
