# Reporte — Vista comparativa de plan (Gratis / Pro) en Settings (v2)

**Fecha**: 2026-10-10 · **Rama**: `main` · **Status**: COMPLETADO
**PRD origen**: `docs/prds/2026-10-10_2313-settings-plan-view.prd.md` (rev v2)
**Plan**: `docs/plans/2026-10-10_2313-settings-plan-view.plan.md` (rev v2)
**Suite**: **1004/1004** · **Analyze**: **0 issues** · **Build web**: **OK**

## Scope

Mostrar el estado Gratis/Pro y las dos listas de features en un **bottom sheet**
abierto desde una **fila compacta "Plan"** al inicio de Settings, localizado en
los 5 idiomas, **sin** tocar entitlement ni gates. TDD:
`test/widget/settings_plan_test.dart` primero (RED), luego implementación
(GREEN). Sin commit/push (falta verbo).

## Pivote v1 → v2 (feedback del dueño)

- **v1**: card comparativo completo embebido en Settings (Grupo "Plan" + card
  con listas). Feedback: *"quedó muy largo, ocupa toda la pantalla y tapa el
  resto; quiero una opción clickeable que diga Plan y al tocarla vea el
  detalle"*.
- **v2 (entregado)**: **fila compacta** (`ListTile`, una línea) + **bottom
  sheet** con el comparador (ambas listas). Confirmado con el dueño
  (fila→sheet; detalle con ambas listas).

## Resumen

| AC | Prioridad | Requisito | Acción | Verificación |
|---|---|---|---|---|
| AC-001 | P1 | Fila "Plan" compacta antes de Empresa | `_PlanTile` (`ListTile`, key `settingsPlanTile`) en `SettingsCard` antes de Empresa | `settings_plan_test` orden + presencia |
| AC-002 | P1 | Estado Gratis/PRO según `isProProvider` | subtítulo de la fila + `_PlanStatusBadge` en el sheet; sin estado en `loading` | `settings_plan_test` free/pro |
| AC-003 | P1 | Sheet con CTA solo en free → `/paywall` | tocar fila → `showModalBottomSheet` (`_PlanSheetBody`); CTA `settingsPlanUnlockCta` (key) → `pop()` + `push('/paywall')`; Pro → "Ya tienes PRO" | `settings_plan_test` free/pro + navegación |
| AC-004 | P1 | Listas Gratis + subsección Pro en el sheet | `settingsPlanFreeFeatures` / `settingsPlanProFeatures` + `settingsPlanProIncludes` | `settings_plan_test` listas |
| AC-005 | P1 | Cadenas en abstract + 5 impls, paridad | 10 claves en `app_strings.dart`, `es_bo.dart` (`EsImpl`+facade), `en_us`, `pt_br`, `fr_fr`, `de_de` | `l10n_parity_test` (6/6) |
| AC-006 | P1 | Suite verde + analyze limpio | — | `flutter test` 1004/1004, `flutter analyze` 0 |
| AC-007 | P2 | `loading` sin estado/badge/CTA | `resolved = !ent.isLoading` en fila y sheet | `settings_plan_test` loading |
| AC-008 | P3 | Semántica legible | `Semantics(label: …)` en el badge; `Icon` + `Text` en listas | revisión + a11y patterns |

## Detalle

### AC-001 — Fila compacta (P1)
- `settings_page.dart`: dentro del `ListView` de `_SettingsBody`, **antes de
  Empresa**: `SettingsCard(accentColor: color.primary, children: const [_PlanTile()])`.
- `_PlanTile` (`ConsumerWidget`): `ListTile` con `IconBadge(workspace_premium)`,
  título `settingsPlanSectionTitle`, subtítulo = estado (`resolved`), y
  `chevron_right`; `key: ValueKey('settingsPlanTile')`; `onTap: _showPlanSheet`.
- Ocupa **una sola línea** (SC8): ya no tapa el resto de Settings.

### AC-002/003 — Estado + sheet (P1)
- `resolved = !ref.watch(entitlementNotifierProvider).isLoading`.
- Fila: subtítulo = `settingsPlanStatusPro` / `settingsPlanStatusFree` si
  `resolved`, si no `null` (sin estado).
- `_showPlanSheet(context)`: `showModalBottomSheet(isScrollControlled: true,
  useSafeArea: true, showDragHandle: true)` → `_PlanSheetBody` (patrón de
  `showProSheet`/`ProSheetBody`).
- `_PlanSheetBody`: cabecera (IconBadge + título de plan + `_PlanStatusBadge`);
  free → `FilledButton.icon` (key `settingsPlanUnlockCta`) que hace
  `Navigator.pop()` (cierra sheet) y `context.push('/paywall')`; Pro → texto
  `settingsPlanAlreadyPro` y sin CTA.

### AC-004 — Listas en el sheet (P1)
- Lista Gratis bajo `settingsPlanFreeHeading`; subsección Pro bajo
  `settingsPlanProHeading` + `settingsPlanProIncludes`, con
  `settingsPlanProFeatures`. Copy alineado a la matriz del PRD.

### AC-005 — l10n (P1)
- 10 claves nuevas en `app_strings.dart` + 5 impls:
  `settingsPlanSectionTitle`, `settingsPlanStatusFree`, `settingsPlanStatusPro`,
  `settingsPlanFreeHeading`, `settingsPlanProHeading`, `settingsPlanProIncludes`,
  `settingsPlanUnlockCta`, `settingsPlanAlreadyPro`,
  `settingsPlanFreeFeatures`, `settingsPlanProFeatures`.
- `l10n_parity_test` verde.

### AC-006 — Regresión (P1)
- `flutter test`: **1004/1004**; `flutter analyze`: **0 issues**;
  `flutter build web`: **OK**.

### AC-007 — Loading (P2)
- `loading`: ni la fila muestra estado, ni el sheet muestra badge/CTA.

### AC-008 — Accesibilidad (P3)
- `Semantics(label)` en el badge; filas de lista con `Icon` + `Text` (no color
  como única señal).

## Desviaciones conscientes respecto al PRD

1. **Formato v2.** El PRD original (v1) pedía un card embebido; se cambió a
   fila + bottom sheet por feedback del dueño (documentado en el PRD v2).
2. **Copy del CTA y del badge Pro.** Se usa copy **distinta** a
   `settingsGoProAction` ("Desbloquear PRO") y `proBadgeLabel` ("PRO") para no
   duplicar strings en pantalla (rompía tests de regresión por
   `findsOneWidget`): `settingsPlanUnlockCta` = "Hazte PRO"/"Go PRO"/…;
   `settingsPlanStatusPro` = "Plan PRO"/"PRO plan"/…

## Verificación

| Check | Resultado |
|---|---|
| `flutter test test/widget/settings_plan_test.dart` | 5/5 |
| `flutter test test/widget/settings_page_test.dart` | OK (regresión) |
| `flutter test test/unit/l10n_parity_test.dart` | 6/6 |
| `flutter test` | **1004/1004** |
| `flutter analyze` | **0 issues** |
| `flutter build web` | **OK** |
| `dart format` (80) / `git diff --check` | limpio |

## Pendiente

- Commit/push: **solo con verbo explícito** del dueño.
- Acciones externas del dueño: IAP `tresdcal_pro_lifetime` + RevenueCat.
