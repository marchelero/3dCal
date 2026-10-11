# Sesión 2026-10-10 — Vista comparativa de plan (Gratis / Pro) en Settings

**Estado**: CERRADO (sin commit/push — falta verbo).
**Base**: `main` @ `f5fb310` (gap-remediation ya commiteado y pusheado).
**PRD**: `docs/prds/2026-10-10_2313-settings-plan-view.prd.md` (rev v2).
**Plan**: `docs/plans/2026-10-10_2313-settings-plan-view.plan.md` (rev v2).
**Reporte**: `docs/reports/2026-10-10_settings-plan-view.report.md`.
**Auditoría**: `docs/audits/2026-10-10_settings-plan-view.audit.md`.

## Qué se hizo

Se agregó una **fila compacta "Plan"** al inicio de Settings que abre un
**bottom sheet** con el comparador Gratis vs Pro, en los 5 idiomas.

- **v1 (descartada):** card comparativo embebido → quedo muy largo, tapaba el
  resto de Settings.
- **v2 (entregado)** — tras feedback del dueño: **fila compacta** (`ListTile`:
  icono + "Plan" + estado actual + chevron) que abre un **bottom sheet** con
  badge de estado, CTA "→ /paywall" (solo free), lista Gratis y subsección Pro
  ("Todo lo de Gratis, y además:"). Detalle con **ambas listas** (acordado).
- **Ubicación**: `settings_page.dart`, antes de Empresa.
- **Widgets** (privados en `settings_page.dart`): `_PlanTile`, `_showPlanSheet`,
  `_PlanSheetBody`, `_PlanStatusBadge`, `_PlanFeatureRow`. Reutiliza
  `SettingsCard`/`CardDivider`/`IconBadge`.
- **l10n**: 10 claves nuevas en abstract + 5 impls (paridad forzada).
- TDD: `test/widget/settings_plan_test.dart` (5 tests) primero (RED), luego
  implementación (GREEN).

## Verificación

- `flutter test`: **1004/1004**.
- `settings_page_test`: regresión OK.
- `l10n_parity_test`: **6/6**.
- `flutter analyze`: **0 issues**.
- `flutter build web`: **OK**.
- `dart format` (80 cols) sin cambios; `git diff --check` limpio.

## Incidencias resueltas

1. **Subagente `prd-agent` no disponible** (free tier) → PRD/plan los escribió
   el agente.
2. **`<Override>` no es tipo en este Riverpod** → el test usa lista inferida
   (patrón de `history_cap_test.dart`).
3. **`currentConfiguration.uri` da la base con `push`** → se asserta
   `matches.last.matchedLocation`.
4. **Colisión de copy** con `settingsGoProAction` ("Desbloquear PRO") y
   `proBadgeLabel` ("PRO") que rompía 6 tests de regresión → copy distinta
   ("Hazte PRO"/"Plan PRO"). Documentado como desviación consciente.
5. **Pivote de diseño v1→v2** (card → fila + sheet) por feedback del dueño.

## Pendiente

- Commit + push: **solo con verbo explícito** del dueño.
- Al commitear CI (si aplica): `git add -f .github/workflows/ci.yml`
  (`.github/` está en `.gitignore`).
- Acciones externas del dueño: IAP `tresdcal_pro_lifetime` + RevenueCat.

## Archivos tocados

- `lib/features/settings/presentation/pages/settings_page.dart` (fila + sheet)
- `lib/l10n/app_strings.dart`, `es_bo.dart`, `en_us.dart`, `pt_br.dart`,
  `fr_fr.dart`, `de_de.dart` (10 claves ×6)
- `test/widget/settings_plan_test.dart` (nuevo, 5 tests)
- `docs/prds/…`, `docs/plans/…`, `docs/reports/…`, `docs/audits/…` (nuevos)
