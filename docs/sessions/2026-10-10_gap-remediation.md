# Sesión 2026-10-10 — Remediación de brechas AC-001..AC-014 (suite 999 + analyze limpio + build web OK)

HEAD de partida: rama `main`, base **`57f218c`**. **Sin commit/push** (falta verbo explícito).

## Contexto

Directiva del usuario: «corrígelo todo» sobre la revisión estática de la app.
El PRD `docs/prds/2026-10-10_1600-gap-remediation.prd.md` (plan
`docs/plans/2026-10-10_1615-gap-remediation.plan.md`) define 14 criterios.
Trabajo con tests primero (TDD); sin cambiar decisiones legales/comerciales ni
inventar configuración externa. Un subagente previo fue abortado dejando
cambios parciales que se revisaron, completaron y verificaron en esta sesión.

## Hecho (14/14)

Reporte: `docs/reports/2026-10-10_gap-remediation.report.md` ·
Auditoría: `docs/audits/2026-10-10_gap-remediation.audit.md`.

- **AC-001** `setQuantity` clamp `1..kMaxQuantity`; input normalizado y `+`
  deshabilitado en el tope (`calculator_notifier.dart`, `result_sheet.dart`).
- **AC-002** validator de gramos entero >0 + `Decimal.parse` en try/finally;
  clave `filamentGramsPositiveInteger` ×6 (`initial_config_page.dart`).
- **AC-003** `CalculationDraft.partialId` (identidad persistida,
  backward-compatible); el guardado definitivo promueve la MISMA fila
  (`calculation_draft.dart`, `calculator_page.dart`).
- **AC-004** **nuevo** `lib/core/storage/local_data_wipe_service.dart` +
  sección «Borrar datos de trabajo» en `settings_page.dart` con confirmación,
  disable en operación, snackbar éxito→`/language`, snackbar error si falla.
- **AC-005/006/007/009** 10 claves l10n nuevas + refuerzos ×6 y test de copy.
- **AC-008** `web/manifest.json` sin descripción/color de template; identidad
  3dCalc + seed `#0B5394`.
- **AC-010** **nuevo** `.github/workflows/ci.yml` (PR: analyze+test+build web,
  sin secrets).
- **AC-011** **nuevo** `test/integration/migration_v1_to_v17_test.dart` (v1/v2/v3).
- **AC-012** **nuevo** `docs/notes/play-sandbox-checklist.md`.
- **AC-013/014** `README.md` Android-only Pro; URLs legales intactas + acción
  externa en `docs/notes/store-compliance.md`.

## Verificación

- `flutter test` → **999/999** (`All tests passed!`).
- `flutter analyze` → **No issues found!** (0 issues).
- `flutter build web` → **√ Built build\web**.
- `dart format` sobre 21 archivos tocados (80 cols, default; NO `--line-length`).
- `git diff --check` → sin errores de whitespace (solo aviso LF→CRLF).

## Gotchas de código

- **Widget tests que guardan cotizaciones** DEBEN override
  `pieceImageDownscalerProvider.overrideWithValue((bytes) async =>
  downscalePieceImage(bytes))`; su `Isolate.run` nunca resuelve en fake-async y
  `notifier.save()` se cuelga.
- **Fallo determinista en DB**: `db.close()` en `NativeDatabase.memory` NO lanza;
  usar `CREATE TRIGGER ... BEFORE DELETE ... SELECT RAISE(ABORT, 'boom')` para
  provocar aborto de transacción + rollback.
- **`db.tabla.count()`** no existe en este entorno → usar
  `(await db.select(db.tabla).get()).length`.
- **`onboarding_done`/`active_printer_id`/`form_draft`** son claves de
  SharedPreferences, NO filas de la tabla `settings`.
- **AC-004 alcance**: el PRD (línea 18) es literal → se borra la tabla `settings`
  COMPLETA; `entitlements` excluido; nunca `SharedPreferences.clear()`.
- **glob tool no ve dot-folders** → usar `Get-ChildItem -Force .github`.
- **`.github/` está en `.gitignore` (línea 120)** → `.github/workflows/ci.yml`
  (nuevo) requiere `git add -f`; `git add -A` NO lo incluye. Mismo caso que
  `deploy.yml` (ya trackeado por force-add).
- **`data_deletion_test.dart` es untracked** → `git grep` no lo ve; usar el tool
  grep.
- Lint: `prefer_initializing_formals` con campos privados y params nombrados no
  se satisface (Dart prohíbe `this._x` nombrado) → campos públicos en el servicio.

## Pendiente (próxima sesión)

1. **Commit/push** — solo con verbo explícito. Working tree: 7 archivos nuevos
   (servicio, 3 tests, workflow CI, nota sandbox, PRD/plan) + ~21 modificados
   (ver reporte).
2. Ejecutar `/audit-report` (o report-auditor) sobre el reporte para inyectar la
   sección `## Auditoria` (el reporte ya tiene `Status: COMPLETADO` + ref PRD).
3. Smoke manual de la CI en un PR real (no ejecutable en este entorno).
4. Acciones externas del dueño: Términos separados en Play Console, sandbox
   reproducible, Data Safety/audiencia.

## Notas de ambiente

- PowerShell 5.1 mojibake en consola (bytes correctos) — editar con tool `edit`.
- `rg` no existe; no correr 2 `flutter test` en paralelo.
- No correr `dart format --line-length 100` (el repo va a 80).
