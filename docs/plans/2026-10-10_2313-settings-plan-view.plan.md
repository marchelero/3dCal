# Plan — Plan (Gratis / Pro) en Settings — v2 (fila compacta + bottom sheet)

**PRD:** `docs/prds/2026-10-10_2313-settings-plan-view.prd.md` (rev. v2).
**Base:** `main` @ `f5fb310` · **Modo:** TDD, sin commits ni pushes sin
autorización explícita.

> **Cambio de diseño v2 (feedback del dueño 2026-10-10):** la primera iteración
> usó un card comparativo **inline** en Settings, pero ocupaba toda la pantalla
> y tapaba el resto. El dueño pidió una **fila compacta clickeable** que abra el
> detalle. Se pivotó a: **fila "Plan" (ListTile) → bottom sheet** con el
> comparador (ambas listas) dentro del sheet.

## Contratos de datos

- Sin cambios de esquema Drift ni de lógica de entitlement. La vista solo
  **lee** `isProProvider` y `entitlementNotifierProvider`.
- UI nueva en `settings_page.dart` (fila `_PlanTile`, sheet `_PlanSheetBody`,
  helpers `_PlanStatusBadge`/`_PlanFeatureRow`, `_showPlanSheet`). Reutiliza
  `SettingsCard`, `CardDivider`, `IconBadge` de `settings_widgets.dart`.
- No se modifica el paywall ni `ProSheetBody`.

## Copy nuevo (claves l10n) — 5 idiomas

Claves implementadas en `app_strings.dart` (abstract) + `EsImpl`/facade `EsBO`,
`EnImpl`, `PtBrImpl`, `FrImpl`, `DeImpl`:

- `settingsPlanSectionTitle` — título de la fila y del sheet ("Plan").
- `settingsPlanStatusFree` — estado free ("Gratis").
- `settingsPlanStatusPro` — estado pro ("Plan PRO" / "PRO plan" / …).
- `settingsPlanFreeHeading` — encabezado lista gratis ("Gratis").
- `settingsPlanProHeading` — encabezado subsección pro ("Pro").
- `settingsPlanProIncludes` — "Todo lo de Gratis, y además:".
- `settingsPlanUnlockCta` — "Hazte PRO" / "Go PRO" / … (CTA del sheet).
- `settingsPlanAlreadyPro` — "Ya tienes PRO".
- `settingsPlanFreeFeatures` (`List<String>`) — lista gratis.
- `settingsPlanProFeatures` (`List<String>`) — lista pro-only.

> Nota: `settingsPlanUnlockCta` y `settingsPlanStatusPro` usan copy **distinta**
> a `settingsGoProAction`/`proBadgeLabel` para no duplicar strings en pantalla
> (evita regresiones por `findsOneWidget`). `l10n_parity_test.dart` enforcea
> paridad exacta de miembros en las 5 impls.

## DAG de trabajo

### Etapa 0 — captura y contratos
1. Confirmar patrón `locked`/`ent.isLoading` y ubicación (arriba de Empresa).
2. Escribir primero los tests (widget + l10n); documentar evidencia RED.

### Etapa 1 — fila compacta + sheet (TDD)
3. **AC-001:** widget test: fila "Plan" presente y **antes** de Empresa;
   subtítulo con el estado actual.
4. **AC-002/003:** tocar la fila abre el sheet; badge correcto (free/pro);
   CTA solo en free; en pro "Ya tienes PRO" y sin CTA.
5. **AC-004:** dentro del sheet, lista Gratis + subsección Pro con
   "Todo lo de Gratis, y además:".
6. **AC-007:** en `loading` la fila no muestra estado y el sheet no muestra
   badge ni CTA.
7. Implementar `_PlanTile` (ListTile) + `_showPlanSheet` +
   `_PlanSheetBody` (ConsumerWidget) con la cabecera de estado y las listas.

### Etapa 2 — l10n ×5
8. **AC-005:** claves en `app_strings.dart` + 5 impls; test de paridad.

### Etapa 3 — verificación/cierre
9. `dart format` (80 cols) solo archivos tocados, `flutter analyze`, suite
   completa, `flutter build web`, `git diff --check`.
10. Revisión especializada; resolver findings; actualizar reporte y auditoría
    con estado por AC. No commit/push salvo verbo explícito.

## Riesgos y mitigaciones
- **Regresión en gates:** la vista solo lee estado; `settings_page_test.dart`
  debe seguir verde. Mitigado: copy distinto para no colisionar con
  `settingsGoProAction`/`proBadgeLabel` (se detectó y corrigió una colisión).
- **Falso "Gratis" en cold start:** no mostrar estado ni badge durante
  `isLoading` (AC-007).
- **Paridad l10n:** añadir a las 6 ubicaciones a la vez.
- **Cierre del sheet al ir al paywall:** el CTA hace `pop()` del sheet y luego
  `push('/paywall')` (evita sheet obsoleto al volver).
- **`showModalBottomSheet` + navegación:** el sheet vive en el mismo Navigator
  (`useSafeArea: true, isScrollControlled: true`), patrón de `ProSheetBody`.

## Comandos de validación

```text
flutter test test/widget/settings_plan_test.dart
flutter test test/widget/settings_page_test.dart
flutter test test/unit/l10n_parity_test.dart
flutter test
flutter analyze
flutter build web
dart format --output=none --set-exit-if-changed <modified Dart files>
git diff --check
```

Ejecutar tests en serie, no en paralelo.
