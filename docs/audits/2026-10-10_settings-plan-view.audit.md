# Auditoría — Vista comparativa de plan (Gratis / Pro) en Settings (v2)

**Fecha**: 2026-10-10 · **Rama**: `main` · **Status**: COMPLETADO
**Reporte auditado**: `docs/reports/2026-10-10_settings-plan-view.report.md`
**PRD**: `docs/prds/2026-10-10_2313-settings-plan-view.prd.md` (rev v2)
**Plan**: `docs/plans/2026-10-10_2313-settings-plan-view.plan.md` (rev v2)
**Alcance**: verificación independiente de AC-001..AC-008 contra el código y los
tests del working tree.

## Veredicto

**PASS** — 8/8 criterios implementados con evidencia verificable (código +
tests). Suite global **1004/1004**, `flutter analyze` **0 issues**, `flutter
build web` **OK**, `dart format` (80 cols) sin cambios, `git diff --check`
limpio. Sin FAIL. Sin observaciones bloqueantes.

## Verificación por criterio

| AC | Estado | Evidencia |
|---|---|---|
| AC-001 | PASS | `settings_page.dart`: `SettingsCard(children: const [_PlanTile()])` **antes** de Empresa; `_PlanTile` = `ListTile` (`key: ValueKey('settingsPlanTile')`); test de orden (`getTopLeft().dy`) y de presencia; ocupa 1 línea (SC8) |
| AC-002 | PASS | Fila: subtítulo = `settingsPlanStatusPro`/`settingsPlanStatusFree` si `resolved`; sheet: `_PlanStatusBadge` (`ValueKey('settingsPlanStatusBadge')`); sin estado si `ent.isLoading`; tests free/pro |
| AC-003 | PASS | `_PlanTile.onTap → _showPlanSheet → showModalBottomSheet(_PlanSheetBody)`; CTA `settingsPlanUnlockCta` (key) solo si `resolved && !isPro` → `Navigator.pop()` + `context.push('/paywall')`; Pro → `settingsPlanAlreadyPro`; tests free/pro + «CTA del sheet navega a /paywall» |
| AC-004 | PASS | `settingsPlanFreeFeatures` + `settingsPlanProIncludes` + `settingsPlanProFeatures`; copy alineado a la matriz del PRD; test free verifica ambas listas |
| AC-005 | PASS | 10 claves en `app_strings.dart` + 5 impls; `l10n_parity_test` 6/6 |
| AC-006 | PASS | `flutter test` 1004/1004; `flutter analyze` 0 |
| AC-007 | PASS | `resolved = !ent.isLoading`; en `loading` fila sin estado y sheet sin badge/CTA; test dedicado |
| AC-008 | PASS | `Semantics(label)` en el badge; filas `Icon`+`Text` |

## Revisión técnica de las decisiones críticas

- **Aislamiento:** la fila y el sheet solo **leen** `isProProvider` y
  `entitlementNotifierProvider`; no escriben ni alteran gates.
- **Sheet consistente:** `showModalBottomSheet(isScrollControlled: true,
  useSafeArea: true, showDragHandle: true)` es el mismo patrón que
  `showProSheet`/`ProSheetBody` (`pro_active_badge.dart`), sin tocar esa hoja.
- **Cierre correcto al pagar:** el CTA hace `Navigator.pop()` (cierra el sheet)
  y luego `context.push('/paywall')`, evitando un sheet obsoleto al volver.
- **Paridad l10n:** enforced por `l10n_parity_test` (verde).
- **Regresión por colisión de copy (resuelta):** `settingsPlanUnlockCta` y
  `settingsPlanStatusPro` usan copy distinta a `settingsGoProAction`
  ("Desbloquear PRO") y `proBadgeLabel` ("PRO") para no duplicar strings; sin
  esto, 6 tests de `settings_page_test` fallaban por `findsOneWidget`. Ahora
  `settings_page_test` pasa sin cambios.
- **Sin cruft:** al migrar v1→v2 se eliminó el card `_PlanSection`; se
  conservan `_PlanStatusBadge`/`_PlanFeatureRow` (reutilizados por el sheet).

## Observaciones (no bloqueantes)

- **Descubrimiento:** la fila muestra el estado en el subtítulo; los detalles
  quedan en el sheet (un tap adicional). Es la decisión del dueño (compacto >
  todo visible). No bloqueante.
- **Pago externo:** IAP `tresdcal_pro_lifetime` + RevenueCat siguen pendientes
  del dueño (fuera de repo).

## Estado

Sin commit/push (pendiente verbo explícito del usuario). No hay hallazgos que
bloqueen el cierre de la iteración.
