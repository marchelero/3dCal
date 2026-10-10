# Reporte — Corrección de brechas de la revisión 2026-10-10 (14/14)

**Fecha**: 2026-10-10 · **Rama**: `main` (base `57f218c`) · **Status**: COMPLETADO
**PRD origen**: `docs/prds/2026-10-10_1600-gap-remediation.prd.md`
**Plan**: `docs/plans/2026-10-10_1615-gap-remediation.plan.md`
**Suite**: **999/999** · **Analyze**: **0 issues** · **Build web**: **OK**

## Scope

Implementar los 14 criterios de aceptación del PRD de remediación de brechas
(AC-001..AC-014), con tests primero (TDD), sin cambiar decisiones
legales/comerciales ni inventar configuración externa. Sin commit/push.

## Resumen

| AC | Prioridad | Hallazgo | Acción | Verificación |
|---|---|---|---|---|
| AC-001 | P1 | Cantidad podía superar `kMaxQuantity` (9999) | `setQuantity` clamp `1..kMaxQuantity`; input normalizado; `+` deshabilitado en el máximo | `calculator_notifier_test` 57/57, `result_sheet_test` 27/27 |
| AC-002 | P1 | Gramos/precio de filamento no validados antes de `Decimal.parse` | Validator entero positivo en onboarding; `Decimal.parse` en try/finally (loading nunca queda pegado) | `initial_config_stepper_test` 17/17 |
| AC-003 | P1 | Reabrir borrador recuperado duplicaba el parcial | `CalculationDraft.partialId` (identidad persitida); promoción transaccional del parcial a definitivo | `draft_recovery_test` 6/6 |
| AC-004 | P2 | No había forma de borrar datos de trabajo locales | `LocalDataWipeService` + sección «Borrar datos» en Settings con confirmación | `data_deletion_test` 3/3, `settings_page_test` 26/26 (+3) |
| AC-005 | P2 | Onboarding no marcaba filamento/gramos como requeridos en los 5 idiomas | `configFilamentOptional` + `configFilamentSectionHelper` con «(requerido)» ×5 | `gap_remediation_l10n_test` 5/5 |
| AC-006 | P2 | No se avisaba que el backup es manual/no cifrado | `settingsBackupDisclosure` ×5 | `gap_remediation_l10n_test` |
| AC-007 | P2 | Copy de privacidad vs borrado local | Verificado coherente (ya decía que los `.3dcal` se borran manualmente) | `gap_remediation_l10n_test` |
| AC-008 | P3 | Manifest PWA con descripción/color de Flutter template | `description` + `theme_color`/`background_color` = identidad 3dCalc | revisión `web/manifest.json` |
| AC-009 | P3 | Ayuda de moneda no aclaraba que no convierte | `settingsCurrencyHelper` reforzado (sin conversión ni tasas) ×5 | `gap_remediation_l10n_test` |
| AC-010 | P2 | CI solo desplegaba en push, sin gates en PR | `.github/workflows/ci.yml` (analyze+test+build web, sin secrets) | revisión workflow |
| AC-011 | P2 | Sin tests de migración desde v1/v2/v3 | `migration_v1_to_v17_test.dart` (3 esquemas × 3 pruebas) | 9/9 |
| AC-012 | P2 | Sin checklist reproducible de sandbox | `docs/notes/play-sandbox-checklist.md` | revisión doc |
| AC-013 | P2 | README prometía Pro iOS | README aclara Android como plataforma de pagos | revisión README |
| AC-014 | — | URLs legales temporales | Intactas; registro de acción externa en `store-compliance.md` | revisión doc |

## Detalle

### AC-001 — Tope de cantidad (P1) ✅
- `calculator_notifier.dart`: `setQuantity` aplica `value.clamp(1, kMaxQuantity)`.
- `result_sheet.dart`: el input de texto se normaliza al valor acotado
  (`if (val != '$clamped') controller.text = '$clamped'`); el botón `+`
  (tooltip `EsBO.calcQuantityIncrease`) queda `onPressed: null` en el máximo.
- Tests: `test/unit/calculator_notifier_test.dart` (57/57),
  `test/unit/result_sheet_test.dart` (27/27).

### AC-002 — Validación de filamento en onboarding (P1) ✅
- `initial_config_page.dart`: validator exige gramos entero > 0; clave l10n
  nueva `filamentGramsPositiveInteger` en las 6 implementaciones.
- `Decimal.parse` envuelto en try/finally → `_filamentSaving` nunca queda `true`;
  feedback localizado y botón re-habilitado ante error de persistencia.
- Tests: `test/widget/initial_config_stepper_test.dart` (17/17) incluye vacío,
  `['100.5','0','-5']`, `'750'` válido y fallo de persistencia (trigger RAISE).

### AC-003 — Identidad del borrador recuperado (P1) ✅
- `CalculationDraft` gana `partialId` nullable (serializado
  `json['partialId']`, backward-compatible: draft legacy → `partialId: null`).
- `calculator_page.dart`: `_buildSessionDraft()` incluye el id del parcial;
  al restaurar se setea `currentPartialIdProvider`; el autosave persiste el
  draft; el guardado definitivo promueve la MISMA fila
  (`repo.updateCalculation` con `columns.copyWith(isPartial: Value(false))`).
- Tests: `test/widget/draft_recovery_test.dart` (6/6). Hallazgo: los widget
  tests que guardan deben override `pieceImageDownscalerProvider`
  (`Isolate.run` nunca resuelve en fake-async).

### AC-004 — Borrado local de datos (P2) ✅
- **Nuevo** `lib/core/storage/local_data_wipe_service.dart`
  (`LocalDataWipeService.wipeWorkData()`): transacción Drift que borra
  `calculation_materials`→`calculations`→`filaments`→`printers`→`settings`→
  `discount_tiers` (NUNCA `entitlements`); luego borra prefs de sesión
  `form_draft`, `active_printer_id` y `onboarding_done`. Sin
  `SharedPreferences.clear()`. Proveedor `localDataWipeServiceProvider`.
- `settings_page.dart`: sección «Borrar datos de trabajo» con diálogo de
  confirmación localizado, disable durante la operación, snackbar de éxito →
  `/language`, snackbar de error si falla (nunca alto falso éxito), invalidación
  de notifiers tras éxito.
- Tests: `test/unit/data_deletion_test.dart` (3/3: borra+preserva, idempotente,
  fallo con rollback) y `test/widget/settings_page_test.dart` (26/26, +3:
  cancelar no borra, confirmar borra+preserva+reinicia, fallo no reporta éxito).

### AC-005/006/007/009 — l10n y copy (P2/P3) ✅
- 10 claves nuevas + refuerzos en los 6 archivos l10n (`app_strings.dart` abstract
  + `es_bo`/`en_us`/`pt_br`/`de_de`/`fr_fr`).
- AC-006 `settingsBackupDisclosure`: backup manual, sin sync, `.3dcal` sin
  cifrar, HMAC = integridad.
- AC-007 ya satisfecho: `legalPrivacyDocument` de los 5 idiomas dice que los
  backups exportados se eliminan manualmente.
- AC-009 `settingsCurrencyHelper`: moneda cambia presentación, sin conversión
  ni tasas.
- Test: `test/unit/gap_remediation_l10n_test.dart` (5/5).

### AC-008 — Manifest PWA (P3) ✅
- `web/manifest.json`: `description` de Flutter template → identidad 3dCalc;
  `theme_color`/`background_color` `#0175C2` → `#0B5394` (seed real de
  `AppTheme.seedColor`). `name`/`short_name` se mantienen «3dCalc» (identidad
  real en toda la app; PRODUCT.md usa «3dCal» pero la app es «3dCalc»).

### AC-010 — CI en pull requests (P2) ✅
- **Nuevo** `.github/workflows/ci.yml`: trigger `pull_request` a `main`,
  `permissions: contents: read`, job `check` (checkout → flutter-action →
  cache → pub get → build_runner → analyze → test → build web). Sin secrets ni
  firma. El `deploy.yml` existente (push a main → pages) queda intacto.

### AC-011 — Fixtures de migración v1/v2/v3 → 17 (P2) ✅
- **Nuevo** `test/integration/migration_v1_to_v17_test.dart` (9/9):
  3 esquemas representativos (v1 sin `printers.brand`; v2 + brand; v3 + las 11
  columnas de costos F1) × 3 pruebas (migra preservando datos y defaults,
  columnas v17 presentes, re-open idempotente). Patrón `sqlite3.openInMemory()` +
  `PRAGMA user_version` + `AppDatabase.forTesting(NativeDatabase.opened(rawDb))`.

### AC-012/013/014 — Release/soporte (P2) ✅
- **Nuevo** `docs/notes/play-sandbox-checklist.md`: checklist reproducible
  (compra, restore, cancelación, revocación/refund) con declaración de que
  requiere track/cuentas externas.
- `README.md`: Android como plataforma de pagos soportada; iOS/web sin Pro.
- AC-014: URLs de Privacy/ToS intactas; sección «Acciones externas pendientes»
  añadida a `docs/notes/store-compliance.md`.
- `docs/README.md`: tabla ampliada con las dos notas nuevas.

## Verificación

- `flutter test`: **999/999** (`All tests passed!`).
- `flutter analyze`: **No issues found!** (0 issues).
- `flutter build web`: **√ Built build\web** (Wasm dry run OK).
- `dart format` sobre los 21 archivos tocados (80 cols, default; sin
  `--line-length`).
- `git diff --check`: sin errores de whitespace (solo aviso LF→CRLF).

## Desvios / Incidentes

- **AC-004 alcance `settings`**: el PRD (línea 18) es literal → se borra la
  tabla `settings` COMPLETA (incluye `company_name`/`company_logo`/
  `currency_code`), no solo «ajustes de cálculo». Documentado y decidido antes
  de implementar.
- **`onboarding_done`/`active_printer_id`/`form_draft` NO son filas de
  `settings`** sino claves de SharedPreferences → borradas explícitamente
  (sin `SharedPreferences.clear()`), preservando locale/tema/entitlement/HMAC.
- **Ruido pre-existente**: en `dispose`, `_persistPartialSync` degrada a
  `stateToPartialDto` sin tasas y `savePartial` lanza `InvalidDataException`
  capturada con `debugPrint('[PartialSave] onExit ERROR')`. Comportamiento
  legacy conocido, no bloqueante, no introducido por esta ronda.
- **Nombre de producto**: `docs/PROJECT.md` dice «3dCal», pero toda la app usa
  «3dCalc»; se respetó «3dCalc» para el manifest.

## Estado de commit

**SIN COMMIT** — pendiente verbo explícito. Archivos nuevos: `lib/core/storage/
local_data_wipe_service.dart`, `test/unit/data_deletion_test.dart`,
`test/unit/gap_remediation_l10n_test.dart`,
`test/integration/migration_v1_to_v17_test.dart`, `.github/workflows/ci.yml`,
`docs/notes/play-sandbox-checklist.md`, PRD y plan. Modificados:
`calculator_notifier.dart`, `result_sheet.dart`, `calculator_page.dart`,
`calculation_draft.dart`, `initial_config_page.dart`, `settings_page.dart`,
`app_strings.dart` + 5 l10n, 5 archivos de test, `README.md`, `docs/README.md`,
`docs/notes/store-compliance.md`, `web/manifest.json`.

> **OJO al commitear CI**: `.gitignore` (línea 120) ignora `.github/`. El
> `deploy.yml` existente está trackeado porque se añadió con `git add -f`, y
> `.github/workflows/ci.yml` (nuevo) **también requiere `git add -f`** —
> `git add -A` NO lo incluirá. Paso: `git add -f .github/workflows/ci.yml`.

## Fuera de alcance / deferred

- Contenido/hosting legal propio, pagos Apple (StoreKit), checkout web,
  cifrado del formato backup, sync cloud, conversión FX, publicación/deploy,
  configuración de Play Console/RevenueCat y gestión de credenciales: requieren
  decisión o acceso del dueño.
