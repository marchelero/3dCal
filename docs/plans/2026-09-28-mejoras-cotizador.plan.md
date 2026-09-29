---
prd: docs/prds/2026-09-28-mejoras-cotizador-quick-actions-guardado-parcial.prd.md
status: DRAFT
created: 2026-09-28
---

# Plan de Implementación: Mejoras del Cotizador (BUG Nueva + Guardado parcial + Reset visible + Quick Actions + Header Print Settings)

## Overview

PRD `2026-09-28-mejoras-cotizador-quick-actions-guardado-parcial` agrupa **5 cambios
independientes** con afinidad funcional en el cotizador: BUG del flujo "Nueva cotización"
(restauraba draft fantasma), **guardado parcial automático** (cotización rápida al pasar
a form válido), Reset siempre visible en AppBar con confirmación inteligente, acceso
rápido a Settings + Print Settings desde el overflow, y rediseño visual del header de
Print Settings para igualar la jerarquía del de Ajustes. Cambios son **aditivos en
schema** (drift v13→v14 columna `is_partial`) y **aditivos en l10n** (10 keys nuevas en 5
idiomas). No se reescribe el motor de cálculo ni se cambia el modelo de dinero.

## Requirements

- **F1 (BUG)**: tap "Nueva cotización" en Home → calculator con form vacío + draft local
  borrado. "Continuar borrador" y "Reusar" desde historial siguen funcionando sin regresión.
- **F2 (Guardado parcial)**: form válido (output ≠ null) o imagen adjunta → fila en
  `calculations` con `is_partial = true`, `name = ''`, `client_name = ''`. Cambios
  posteriores actualizan la misma fila (upsert por minuto). Save completo la completa;
  Reset la elimina. Migración v13 → v14 aditiva preserva datos existentes.
- **F3 (Reset visible)**: `IconButton` primario en AppBar con `Icons.refresh_rounded` +
  tooltip l10n. Confirmación solo si hay contenido (peso/horas/filamento no vacíos); vacío
  = reset silencioso.
- **F4 (Quick actions)**: Print Settings accesible desde overflow menu del calculator
  (junto a Settings, Ayuda, Plantillas). Settings sin duplicar.
- **F5 (Visual Print Settings header)**: heredar patrón `_SettingsHeader` (color
  `tertiary`, icono `printer3d`): tagline `appName · v$kAppVersion`, fila privacidad
  `Icons.lock_outline_rounded` + `EsBO.settingsPrivacy`, slot `ProActiveBadge` a la derecha.
- **l10n**: 10 keys nuevas × 5 idiomas (es_BO/en/de/fr/pt) — `calcActionReset` ya existe y se reusa.
- **No backend, no doubles en dinero, no setState en vistas de negocio** (reglas del proyecto).

## Architecture Changes

**Modifica:**

- `lib/core/database/app_database.dart` — `schemaVersion = 14`, migración aditiva `from < 14`.
- `lib/features/calculation/data/tables/calculations_table.dart` — columna
  `isPartial: boolean().withDefault(const Constant(false))()`.
- `lib/core/router/app_router.dart` — nueva ruta `/calculator/new` (o query param
  `?new=true` en `/calculator`); verificar ruta exacta de Print Settings (ver Open Q-A).
- `lib/features/calculation/presentation/pages/home_page.dart` — quick action "Nueva
  cotización" navega a la ruta con flag `newMode`.
- `lib/features/calculation/presentation/pages/calculator_page.dart` — ctor `newMode`,
  mover Reset a AppBar primario, agregar Print Settings al overflow, listener de
  auto-save parcial + debounce 1.5 s, `_resetAll()` limpia la parcial activa.
- `lib/features/calculation/presentation/widgets/result_sheet.dart` — exponer
  `_pieceImageBytes` vía callback `onImageAttached(Uint8List?)` para que el page
  dispare el partial-save.
- `lib/features/calculation/data/calculation_repository.dart` — métodos `savePartial`,
  `updatePartial`, `deletePartial`, `findLatestPartialForMinute`.
- `lib/features/calculation/presentation/state/calculator_notifier.dart` — selector
  derivado `isValidProvider` + helper `stateToPartialDto`.
- `lib/features/calculation/presentation/pages/calculations_list_page.dart` — chip
  "Borrador" cuando `isPartial`.
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart` — banner +
  CTA "Completar" cuando `isPartial`.
- `lib/features/settings/presentation/pages/print_settings_page.dart` — header con 3
  piezas faltantes (tagline versión, fila privacidad, `ProActiveBadge`).
- `lib/l10n/app_strings.dart` + facade `EsBO` + 5 impls (`es_bo.dart`, `en_us.dart`,
  `de_de.dart`, `fr_fr.dart`, `pt_br.dart`) — 10 keys nuevas.

**Crea:**

- `lib/core/widgets/partial_save_badge.dart` — chip "Borrador" reutilizable (lista +
  opcionalmente detail).
- `test/integration/migration_v13_to_v14_test.dart` — preserva filas + agrega columna.
- `test/unit/partial_save_notifier_test.dart` — transición válido/inválido + debounce.
- `test/unit/partial_save_repository_test.dart` — CRUD parcial + upsert por minuto.
- `test/integration/partial_save_integration_test.dart` — flujo end-to-end.
- `test/widget/new_quotation_empty_form_test.dart` — F1.
- `test/widget/reset_confirm_dialog_test.dart` — F3.
- `test/widget/print_settings_header_test.dart` — F5.

---

## Implementation Steps — DAG de Tasks

```
T1 ──┐
     ├──► T6 (parcial)
T2 ──┼──► T3 (BUG Nueva)
     ├──► T4 (Reset AppBar)
     ├──► T5 (overflow Print Settings)
     └──► T7 (visual header)
              │
              ▼
            T8 (tests)
              │
              ▼
            T9 (verify + report)
```

| Task | Title | Effort | Deps |
|---|---|---|---|
| T1 | Schema drift v13 → v14 (`is_partial`) | S | — |
| T2 | L10n: 10 keys × 5 idiomas | S | — |
| T3 | BUG: `newMode` en CalculatorPage + ruta | S | T2 |
| T4 | Reset IconButton en AppBar + dialog gating | S | T2 |
| T5 | Print Settings en overflow menu | XS | T2 |
| T6 | Guardado parcial automático + upsert + badge | L | T1, T2 |
| T7 | Visual header Print Settings (3 piezas) | S | — |
| T8 | Tests (unit + widget + integration) | M | T3, T4, T5, T6, T7 |
| T9 | Verificación final + reporte | S | T8 |

Effort key: XS ≤ 30 min · S ≤ 2 h · M ≤ 4 h · L ≤ 8 h.

---

### T1 — Schema drift v13 → v14 (columna `is_partial`)

- **Files (read)**: `lib/core/database/app_database.dart`, `lib/features/calculation/data/tables/calculations_table.dart`, `lib/core/database/app_database.g.dart` (generado, no editar).
- **Files (modify)**:
  - `lib/features/calculation/data/tables/calculations_table.dart` — agregar `BoolColumn get isPartial => boolean().withDefault(const Constant(false))();` junto a `isTemplate` (~l. 82). Comentario: F2 del PRD — parcial = cotización persistida con flag.
  - `lib/core/database/app_database.dart` — `schemaVersion = 14`; nuevo bloque `if (from < 14) { await m.addColumn(calculations, calculations.isPartial); }` siguiendo patrón de líneas 142-147 (v12→v13). Migración aditiva; registros viejos quedan `isPartial = false` (comportamiento idéntico).
- **Files (create)**: ninguno (código drift se regenera con `dart run build_runner build -d`).
- **Steps**:
  1. Editar `calculations_table.dart`: agregar `isPartial` con `withDefault(const Constant(false))`.
  2. Editar `app_database.dart`: bumpear `schemaVersion` a 14; agregar bloque `if (from < 14)` aditivo.
  3. Regenerar código drift: `dart run build_runner build --delete-conflicting-outputs` (commit solo de `.g.dart` regenerado, sin diffs manuales).
  4. Verificar compilación: `flutter analyze` sin warnings nuevos.
- **Acceptance**:
  - `flutter analyze` limpio.
  - Drift genera nueva columna `isPartial` en `Calculations` (verificar con `pragma_table_info('calculations')` en test).
- **Effort**: S (1 h).
- **Deps**: ninguna.
- **Risk**: bajo — migración aditiva, default `false` preserva comportamiento actual (regla 95 %).
- **Notes**: regenerar `.g.dart` ANTES de tocar consumidores para evitar errores de compilación por tipo inexistente.

---

### T2 — L10n: 10 keys × 5 idiomas

- **Files (modify)**:
  - `lib/l10n/app_strings.dart` — agregar 9 getters abstractos (10 menos `calcActionReset` que ya existe): `calcActionPrintSettings`, `calcResetConfirmTitle`, `calcResetConfirmBody`, `calcResetConfirmCancel`, `calcResetConfirmOk`, `calcPartialBadge`, `calcPartialAutoSaved`, `calcPartialCompleteHint`, `printSettingsVersionSuffix`.
  - `lib/l10n/es_bo.dart` — implementación en `EsImpl` (~l. 1445) + facade estático en `EsBO` (~l. 373).
  - `lib/l10n/en_us.dart` — `EnImpl` (~l. 595).
  - `lib/l10n/de_de.dart` — `DeImpl` (~l. 604).
  - `lib/l10n/fr_fr.dart` — `FrImpl` (~l. 578).
  - `lib/l10n/pt_br.dart` — `PtBrImpl` (~l. 603).
- **Steps**:
  1. En `app_strings.dart`, agregar bloque `// === Hito: mejoras cotizador 2026-09-28 (T2) ===` con los 9 getters abstractos.
  2. En cada impl (5), agregar implementaciones con los textos del PRD §"L10n catalog".
  3. En `EsBO` facade (es_bo.dart), agregar `static String get x => _impl.x;` por cada key.
  4. Verificar compilación: `flutter analyze` (las 5 impls son exigidas por el abstract).
  5. Verificar paridad (si existe `tools/check_l10n.dart`, correrlo; si no, inspección manual de las 5).
- **Acceptance**:
  - Build sin errores por getters abstractos no implementados.
  - Cada una de las 10 keys (incluida `calcActionReset` reusada) tiene valor en es_BO, en, de, fr, pt.
- **Effort**: S (1.5 h).
- **Deps**: ninguna.
- **Risk**: bajo — trabajo mecánico; riesgo típico = olvidar una impl y romper el build (mitigado por `flutter analyze`).
- **Notes**: `printSettingsVersionSuffix` lleva placeholder `{0}` para formato `String.format` — usar `EsBO.printSettingsVersionSuffix.format([kAppVersion])` (verificar helper existente en `es_bo.dart`, ej. `calcDetailBatchDiscount`).

---

### T3 — BUG: flag `newMode` en CalculatorPage + ruta dedicada

- **Files (read)**: `lib/features/calculation/presentation/pages/calculator_page.dart:122-247` (`initState`, restore), `lib/core/router/app_router.dart:128-153` (rutas calculator).
- **Files (modify)**:
  - `lib/features/calculation/presentation/pages/calculator_page.dart`:
    - Ctor: `CalculatorPage({super.key, this.prefillCalc, this.newMode = false})`.
    - `initState` (~l. 122-247): `if (widget.newMode) { await ref.read(draftStorageProvider).clear(); if (!mounted) return; ref.read(calculatorNotifierProvider.notifier).reset(); /* skip storage.load + restoreFromDraft + loadFilamentDefaults + manual clear controllers */ } else { /* bloque actual */ }`.
  - `lib/core/router/app_router.dart`: nueva ruta `/calculator/new` que monta `CalculatorPage(newMode: true)`.
  - `lib/features/calculation/presentation/pages/home_page.dart:311` — cambiar `onTap: () => context.push('/calculator')` a `onTap: () => context.push('/calculator/new')` para la acción "Nueva cotización".
- **Files (create)**: ninguno.
- **Steps**:
  1. Modificar `CalculatorPage` ctor + `initState`: agregar branch temprano `if (widget.newMode)`.
  2. Registrar `GoRoute(path: '/calculator/new', pageBuilder: (_, __) => _slideRight(const CalculatorPage(newMode: true)))` en `app_router.dart`.
  3. Cambiar navegación de Home `home_page.dart:311` a `/calculator/new`.
  4. Verificar que "Continuar borrador" (`/calculator`, ~`:535` y `:700`) y "Reusar" (`/calculator/prefill`, ~`:938`) sigan apuntando a sus rutas sin cambio (sin regresión).
- **Acceptance**:
  - Home con draft previo → tap "Nueva cotización" → calculator abre con controllers vacíos y `draftStorageProvider.clear()` invocado.
  - "Continuar borrador" y "Reusar" sin cambios (test existente sigue verde).
- **Effort**: S (1 h).
- **Deps**: T2 (tooltip y mensajes nuevos se referencian en reset; no en newMode directo, pero se agrupan por fase).
- **Risk**: medio — riesgo de regresión en flujos restore (mitigado por branch explícito y tests de no-regresión).
- **Notes**: NO contaminar `Home` con `draftStorage.clear()` (decisión explícita del PRD); el flag viaja por la ruta.

---

### T4 — Reset IconButton en AppBar + dialog de confirmación con gating

- **Files (modify)**:
  - `lib/features/calculation/presentation/pages/calculator_page.dart`:
    - Slot `actions` del AppBar (~l. 815-851): insertar `IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: EsBO.calcActionReset, onPressed: _handleResetTap)` antes del `menuActions`.
    - Quitar la entrada Reset de `menuActions` (líneas 838-842).
    - Nuevo método `_handleResetTap()`: si hay contenido (cualquier controller entre `_weightCtrl`, `_hoursCtrl`, `_minutesCtrl`, `_priceCtrl`, `_gramsCtrl`, `_extraLaborRateCtrl`, `_extraPostProcessRateCtrl`, `_extraFailureRateCtrl`, `_extraMarkupOnMaterialsCtrl` no vacío) → `showConfirmDialog(...)` con título `EsBO.calcResetConfirmTitle`, body `EsBO.calcResetConfirmBody`, confirmLabel `EsBO.calcResetConfirmOk`, cancelLabel `EsBO.calcResetConfirmCancel`, `destructive: false`. Si confirma → `_resetAll()` + `deletePartial()` (T6).
    - `_resetAll()` (~l. 405): agregar al inicio `await ref.read(calculationRepositoryProvider).deletePartialForSession(currentPartialId)` (id inyectado por T6 al setear la fila; si null → no-op).
- **Files (create)**: ninguno.
- **Steps**:
  1. Quitar Reset de `menuActions`.
  2. Agregar `IconButton` primario en `actions` (después del chip de total, antes del overflow menu).
  3. Implementar `_handleResetTap()` con gating (helper `_hasContent()` privado).
  4. Reusar `showConfirmDialog` de `lib/shared/widgets/confirm_dialog.dart` (sin cambios).
  5. Integrar con T6: hook para borrar la parcial activa al confirmar reset.
- **Acceptance**:
  - Reset visible en TODOS los pasos (1, 2, 3) y desde result sheet.
  - Form vacío → reset silencioso (sin diálogo).
  - Form con contenido → diálogo → cancelar = no-op; confirmar = form limpio + parcial eliminada.
- **Effort**: S (1.5 h).
- **Deps**: T2 (claves de diálogo).
- **Risk**: medio — mover acción primaria cambia affordance para usuarios acostumbrados al menú.
- **Notes**: el PRD permite reutilizar el `_resetAll` existente (línea 405); solo se le agrega el hook de borrado de parcial cuando T6 esté listo.

---

### T5 — Print Settings en overflow menu del calculator

- **Files (modify)**:
  - `lib/features/calculation/presentation/pages/calculator_page.dart:827-848` — agregar entrada en `menuActions` debajo de Settings (líneas 843-847):
    ```dart
    (
      icon: Icon(MdiIcons.printer3d),
      label: EsBO.calcActionPrintSettings,
      onTap: () => context.push('/print'), // ver Open Q-A
    ),
    ```
- **Files (create)**: ninguno.
- **Steps**:
  1. Insertar nueva entrada en `menuActions` con icono `MdiIcons.printer3d` y label l10n.
  2. Verificar ruta de Print Settings: en `app_router.dart:102-105` está registrada como `/print` (rama shell). Usar esa ruta (NO `/config/print-settings` que NO existe — Open Q-A).
  3. Verificar que `flutter analyze` siga limpio.
- **Acceptance**:
  - Overflow → tap "Config. impresión" → navega a Print Settings sin 404.
  - Settings sigue funcionando exactamente igual (test de no-regresión).
- **Effort**: XS (20 min).
- **Deps**: T2.
- **Risk**: bajo.
- **Notes**: ruta `/print` está dentro del shell (StatefulShellBranch), se muestra como tab inferior. Alternativa: ruta dedicada `/config/print-settings` con `_slideRight` — evaluar UX en implementación (Open Q-A).

---

### T6 — Guardado parcial automático (cotización rápida)

- **Files (read)**: `lib/features/calculation/presentation/state/calculator_notifier.dart`, `lib/features/calculation/data/calculation_repository.dart`, `lib/features/calculation/presentation/widgets/result_sheet.dart:417-444` (`_handlePickImage`).
- **Files (modify)**:
  - `lib/features/calculation/presentation/state/calculator_notifier.dart`: agregar selector `isValidProvider` (`Provider<bool>((ref) => ref.watch(calculatorNotifierProvider.select((s) => s.output != null)))`) en mismo archivo, y helper estático `stateToPartialDto(CalculatorState s, Uint8List? image) → CalculationsCompanion` (mapea `weight/printMinutes/discountPct/filamentPrice/filamentGrams/label/quantity` + `pieceImageBlob` + `isPartial = true` + `createdAt = DateTime.now()`).
  - `lib/features/calculation/data/calculation_repository.dart`: agregar `savePartial({CalculatorState state, Uint8List? image})` (upsert por minuto vía `findLatestPartialForMinute` → si existe, `updatePartial`; si no, `insert`), `updatePartial(int id, CalculationsCompanion patch)`, `deletePartial(int id)`, `findLatestPartialForMinute(DateTime bucket) → Calculation?`. Campo `currentPartialIdProvider` (StateProvider<int?>) para coordinar reset/save/delete.
  - `lib/features/calculation/presentation/pages/calculator_page.dart`:
    - `build` (o `initState` ya consumido) → `ref.listen(isValidProvider, (prev, next) { if (prev == false && next == true) _schedulePartialSave(); })`.
    - `_schedulePartialSave()`: cancela timer pendiente, `Timer(Duration(milliseconds: 1500), _persistPartial)`.
    - `_persistPartial()`: lee state, llama `repo.savePartial(...)`, guarda id en `currentPartialIdProvider`.
    - Recibir callback de result sheet: `showResultSheet(... onImageAttached: (bytes) { if (state.isValid) _schedulePartialSave(); }, ...)`.
  - `lib/features/calculation/presentation/widgets/result_sheet.dart`: ctor acepta `onImageAttached(Uint8List? bytes)`; invocar en `_handlePickImage` línea ~430 (después de `setState(() => _pieceImageBytes = cropped)`). Mantener `_pieceImageBytes` local (no migrar a state — Non-Negotiables: image bytes es UI efímero).
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart`: al renderizar cada item (~l. 600+, donde se muestra `pieceName`), si `calc.isPartial == true` envolver el nombre con `PartialSaveBadge()`.
  - `lib/features/calculation/presentation/pages/calculation_detail_page.dart`: si `calc.isPartial`, banner arriba con `EsBO.calcPartialAutoSaved` + `EsBO.calcPartialCompleteHint` + botón `EsBO.calculatorGoProAction` que navega a save dialog (reusar `_showSaveDialog` del calculator, abriendolo con prefill).
  - `lib/features/calculation/presentation/pages/calculator_page.dart:_handleSave` (~l. 615-674): tras insert exitoso, si existía `currentPartialIdProvider != null`, llamar `repo.deletePartial(partialId)` (la fila guardada es la nueva, no necesita update).
- **Files (create)**:
  - `lib/core/widgets/partial_save_badge.dart` — `PartialSaveBadge` widget: `Chip` con `Icons.edit_note_rounded`, color `colorScheme.tertiary` (o `outline`), label `EsBO.calcPartialBadge`.
- **Steps**:
  1. Crear widget `PartialSaveBadge`.
  2. Extender `CalculatorNotifier`: selector + helper estático.
  3. Extender `CalculationRepository`: 4 métodos nuevos + `currentPartialIdProvider` (en `core/providers.dart` o nuevo archivo de presentation).
  4. En `calculator_page.dart`: agregar `ref.listen` en `build`, `_schedulePartialSave` (debounce 1500 ms), `_persistPartial`.
  5. En `result_sheet.dart`: ctor `onImageAttached` + invocación post `_handlePickImage`.
  6. En `calculations_list_page.dart`: badge en cada item con `isPartial`.
  7. En `calculation_detail_page.dart`: banner + CTA "Completar".
  8. Wire `currentPartialIdProvider` en `_resetAll` (T4) y en `_handleSave` (borrar parcial tras insert).
- **Acceptance**:
  - Form inválido → válido → 1.5 s después, fila en `calculations` con `isPartial=true, name='', client_name=''`.
  - Cambio posterior en form válido → MISMA fila actualizada (no duplicado).
  - Imagen adjunta → fila gana `pieceImageBlob` no nulo.
  - Save completo con parcial existente → fila actualizada a `isPartial=false` con name/client (NO nueva fila).
  - Reset con parcial existente → fila eliminada.
  - Lista: parciales muestran badge "Borrador"; completas no.
  - Detalle: parcial muestra banner + CTA.
  - Dashboard excluye parciales (sin cambios si query ya filtra por `isTemplate=false`; verificar que NO filtre también por `isPartial` — agregar `isPartial = false` en where del dashboard si hoy no lo hace — ver Open Q-B).
- **Effort**: L (6 h).
- **Deps**: T1, T2.
- **Risk**: alto — múltiples archivos, lifecycle del partial id (debe limpiarse en dispose), race entre debounce y dispose, ensure idempotencia del upsert.
- **Notes**:
  - Upsert por minuto: `createdAt` truncado a minuto (`DateTime(year, month, day, hour, minute)`). Borde de minuto = dos filas posibles; documentado en Open Q-C.
  - Limpiar `currentPartialIdProvider` en `dispose()` del calculator page.
  - `_pieceImageBytes` sigue viviendo en `_ResultSheetContentState`; el page la recibe solo como callback post-adjuntar (no se mueve a Riverpod).

---

### T7 — Visual: Print Settings header con 3 piezas faltantes

- **Files (modify)**:
  - `lib/features/settings/presentation/pages/print_settings_page.dart:259-372` (`_PrintSettingsHeader`).
  - `lib/core/constants/app_constants.dart` (verificar visibilidad de `kAppVersion` — si privado, exponer o importar).
- **Steps**:
  1. En `_PrintSettingsHeader.build`, después del `Text` del subtitle (~l. 360), agregar:
     ```dart
     const SizedBox(height: 2),
     Text(
       EsBO.printSettingsVersionSuffix.format([kAppVersion]),
       style: theme.textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
     ),
     const SizedBox(height: AppSpacing.sm),
     Row(children: [
       Icon(Icons.lock_outline_rounded, size: 14, color: color.onSurfaceVariant),
       const SizedBox(width: 6),
       Expanded(child: Text(EsBO.settingsPrivacy, style: theme.textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant))),
     ]),
     ```
  2. Al final del `Row` principal (~l. 364, antes del cierre), agregar slot ProActiveBadge:
     ```dart
     const SizedBox(width: AppSpacing.sm),
     const ProActiveBadge(),
     ```
  3. NO cambiar banda superior (sigue `color.tertiary`), sello, icono, padding, radius, shadow.
  4. Verificar `kAppVersion` accesible (importar de `app_constants.dart`).
- **Acceptance**:
  - Header tiene: sello gradient (tertiary) + título + subtitle + tagline versión + fila privacidad + `ProActiveBadge` (slot derecho).
  - Mismo padding `xxl/xl/xxl/xxl`, `AppRadii.lg`, shadow, banda 4 px.
  - En free, badge no aparece (es `const ProActiveBadge()` que internamente decide renderizar).
- **Effort**: S (1 h).
- **Deps**: ninguna (paralela con T1/T2).
- **Risk**: bajo — reuso de patrón conocido.
- **Notes**: usa el helper `.format([kAppVersion])` — verificar firma exacta en `es_bo.dart` (puede ser `String format([List<Object?> args])` o `sprintf`-style).

---

### T8 — Tests (unit + widget + integration)

- **Files (create)**:
  - `test/integration/migration_v13_to_v14_test.dart` — patrón `migration_v11_to_v12_test.dart`: seed raw schema v13 (incluye `discount_tiers`, `current_hours`), `PRAGMA user_version = 13`, abrir con `AppDatabase.forTesting`, verificar:
    - `pragma_table_info('calculations')` incluye columna `is_partial` con default `0`.
    - Filas pre-existentes intactas.
    - `user_version = 14`.
    - Re-open idempotente.
  - `test/unit/partial_save_notifier_test.dart`:
    - `isValidProvider` devuelve `false` con state inválido, `true` con state válido.
    - `stateToPartialDto` mapea campos correctos + `isPartial = true`.
  - `test/unit/partial_save_repository_test.dart`:
    - `savePartial` con bucket nuevo → insert.
    - `savePartial` con bucket existente → update (no duplicado).
    - `deletePartial(id)` borra.
    - `findLatestPartialForMinute` filtra correctamente por timestamp truncado.
  - `test/integration/partial_save_integration_test.dart`:
    - Flujo: form vacío → llenar → parcial creada → editar → misma fila → guardar completo → `isPartial = false` → reset → fila eliminada.
  - `test/widget/new_quotation_empty_form_test.dart`:
    - Stub `SharedPreferences` con draft previo.
    - Navega a `/calculator/new`.
    - Verifica controllers vacíos + `draftStorageProvider.clear()` invocado (mock).
  - `test/widget/reset_confirm_dialog_test.dart`:
    - Tap con contenido → diálogo aparece.
    - Cancelar = no-op.
    - Confirmar = form vacío + parcial eliminada (mock repo).
    - Tap sin contenido → reset silencioso (sin diálogo).
  - `test/widget/print_settings_header_test.dart`:
    - Estructura del header: `ProActiveBadge`, `EsBO.printSettingsVersionSuffix`, `EsBO.settingsPrivacy`, icono `lock_outline_rounded` presentes en árbol.
    - En free: badge ausente o invisible según `ProActiveBadge`.
- **Files (modify)**:
  - `test/widget/calculator_page_test.dart` — actualizar aserciones: Reset ahora es `IconButton` primario en AppBar, NO item del menú. Overflow menu ahora tiene 4 entradas (ayuda, plantillas, ajustes, print settings) sin Reset.
  - `test/widget/calculations_list_page_test.dart` — badge "Borrador" en items con `isPartial=true`.
  - `test/widget/calculation_detail_page_test.dart` — banner + CTA en detalle parcial.
  - `test/integration/calculator_restore_flow_test.dart` (o equivalente) — branch `newMode == false` sigue trayendo draft (no regresión F1).
- **Steps**:
  1. Crear migración test (patrón existente) → AC-206.
  2. Crear unit tests notifier + repo → AC-201, AC-202, AC-205.
  3. Crear integration test flujo completo → AC-201..AC-205, AC-209.
  4. Crear widget test nueva cotización → AC-101..AC-104.
  5. Crear widget test reset dialog → AC-301..AC-304.
  6. Crear widget test print settings header → AC-501..AC-504.
  7. Ajustar tests existentes para AppBar Reset + Print Settings + badge + banner.
- **Acceptance**:
  - Todos los AC del PRD cubiertos.
  - `flutter test` verde.
  - Coverage targets: `calculator_notifier.dart` ≥ 80 % (sin cambios), `calculation_repository.dart` ≥ 80 %, `partial_save_badge.dart` ≥ 90 %.
- **Effort**: M (4 h).
- **Deps**: T3, T4, T5, T6, T7.
- **Risk**: medio — tests de debounce asíncrono (1.5 s) pueden ser flaky; usar `fakeAsync` o `pumpAndSettle` con timeout.
- **Notes**: patrón de tests ya existe en `test/integration/migration_v11_to_v12_test.dart` (referencia).

---

### T9 — Verificación final + reporte

- **Files (modify)**:
  - `docs/reports/2026-09-28-mejoras-cotizador.report.md` — nuevo reporte (post-implementación).
  - `docs/audits/2026-09-28-mejoras-cotizador.audit.md` — artefacto de auditoría con checks ejecutados.
- **Steps**:
  1. `dart format --set-exit-if-changed lib/ test/`.
  2. `flutter analyze` → 0 warnings.
  3. `flutter test` → 100 % verde.
  4. `flutter test --coverage` → verificar thresholds (opcional).
  5. Smoke manual: AC-101..AC-105, AC-201..AC-210, AC-301..AC-305, AC-401..AC-403, AC-501..AC-505.
  6. Documentar en `docs/reports/` siguiendo plantilla existente (verificar `docs/reports/` por ejemplos previos).
  7. Generar artefacto `docs/audits/` con resultados de checks.
- **Acceptance**:
  - SC1..SC7 del PRD cumplidos (ver §"Criterios de éxito" del PRD).
  - Reporte y auditoría commiteados.
- **Effort**: S (1 h).
- **Deps**: T8.
- **Risk**: bajo.
- **Notes**: NO commitear sin consentimiento explícito del usuario ese turno (regla core: `git consent`).

---

## Execution Order

### Phase 1 — Foundations (paralelas) · T1 + T2 + T7

Ejecutar en paralelo si hay capacidad (3 sub-agentes). Sin dependencias cruzadas.

- **T1** (schema): regenerar `.g.dart` antes de cualquier consumer que referencie `isPartial`.
- **T2** (l10n): habilitar consumidores con `EsBO.calcXxx` desde ya.
- **T7** (visual header): independiente, baja prioridad dentro de la fase.

**Checkpoint**: `flutter analyze` limpio; `flutter test` (suite existente) verde.

### Phase 2 — Quick wins · T3 + T4 + T5

Dependen de T2. T3, T4 y T5 independientes entre sí.

- **T3** (BUG nueva cotización): crítica para demo.
- **T4** (Reset AppBar): depende solo de T2; integrar con T6 en iteración posterior.
- **T5** (Print Settings en overflow): XS, segundos cambios.

**Checkpoint**: tests de no-regresión verdes; smoke manual de flujos Restore / Reset / Print Settings nav.

### Phase 3 — Feature grande · T6

Depende de T1 + T2. Coordina el lifecycle del `currentPartialIdProvider` con T4.

- **T6a**: notifier + repo (sin listeners) → unit tests.
- **T6b**: listener en calculator_page + debounce → integration test.
- **T6c**: image callback desde result sheet → widget test.
- **T6d**: badge lista + banner detalle → widget tests.
- **T6e**: hook reset/save → integration tests AC-204, AC-205.

**Checkpoint**: suite completa verde; smoke manual "editar form válido, salir, volver, ver fila en historial".

### Phase 4 — Cierre · T8 + T9

- **T8**: tests nuevos + ajustes.
- **T9**: verificación + reporte + auditoría.

---

## Testing Strategy

- **Unit (dominio puro + repo + notifier)**:
  - `partial_save_notifier_test.dart` (nuevo) — `isValidProvider`, `stateToPartialDto`.
  - `partial_save_repository_test.dart` (nuevo) — CRUD + upsert minuto.
- **Integración**:
  - `migration_v13_to_v14_test.dart` (nuevo, patrón `migration_v11_to_v12_test.dart`) — preserva filas + agrega columna.
  - `partial_save_integration_test.dart` (nuevo) — flujo end-to-end.
- **Widget**:
  - `new_quotation_empty_form_test.dart` (nuevo).
  - `reset_confirm_dialog_test.dart` (nuevo).
  - `print_settings_header_test.dart` (nuevo).
  - `calculator_page_test.dart` (ajustar) — AppBar Reset primario, overflow 4 entradas.
  - `calculations_list_page_test.dart` (ajustar) — badge.
  - `calculation_detail_page_test.dart` (ajustar) — banner + CTA.
- **Regresiones (deben pasar sin cambios donde aplica)**:
  - `calculator_notifier_test.dart` (motor intacto).
  - `calculation_engine_test.dart`.
  - `history_cap_test.dart` (AC-210 — cap free cuenta completas + parciales igual).
  - `dashboard_stats_test.dart` (AC-209 — dashboard excluye parciales).
- **Cobertura objetivo**:
  - `partial_save_badge.dart` ≥ 90 %.
  - `calculation_repository.dart` (métodos parcial) ≥ 80 %.
  - `calculator_notifier.dart` (selector nuevo) ≥ 80 %.

---

## Risks & Mitigations

| # | Riesgo | Likelihood | Impact | Mitigación |
|---|--------|-----------|--------|------------|
| R1 | Race entre debounce 1.5 s y dispose de CalculatorPage (usuario sale antes de persistir) | Med | Med | Cancelar timer en `dispose()` + flag `_disposed` para evitar llamada post-frame. |
| R2 | Upsert por minuto produce duplicados en borde de segundo 59→00 | Baja | Med | Documentado como Open Q-C; tests AC-202 cubren caso normal. Si molesta, migrar a hash de state o sessionId (cambio en T6 1-line). |
| R3 | Migración v13→v14 rompe installs viejos si `addColumn` falla en web (WasmDatabase) | Baja | Alto | Migración aditiva, default `false`; test de migración cubre native + web (si hay infra). |
| R4 | Imagen adjunta dispara partial-save sin form válido (solo imagen) | Med | Med | Listener de imagen verifica `isValidProvider == true` antes de agendar. Si form inválido, NO save. |
| R5 | Mover Reset a AppBar primario quita accesibilidad a usuarios con una mano | Baja | Bajo | Reset sigue accesible desde overflow del result sheet (acción del footer); plan UX posterior. |
| R6 | `currentPartialIdProvider` queda stale entre sesiones (usuario sale, vuelve, ve ID viejo) | Med | Med | Limpiar en `dispose()` del calculator page + en `_resetAll()`. Test explícito. |
| R7 | l10n incompleto en algún idioma rompe build | Baja | Med | `flutter analyze` exige las 5 impls (abstract); CI check de paridad si existe `tools/check_l10n.dart`. |
| R8 | Dashboard excluye parciales (AC-209) — query actual puede no filtrar por `isPartial` | Med | Med | Auditar query del dashboard antes de merge; agregar `isPartial = false` al where si falta (Open Q-B). |
| R9 | Ruta de Print Settings incorrecta → 404 | Med | Med | Open Q-A; verificar ruta `/print` en `app_router.dart:102-105` antes de merge. |
| R10 | Tests de debounce 1.5 s flaky (timeout en CI) | Med | Bajo | Usar `fakeAsync` de `package:fake_async` o `pumpAndSettle(Duration(seconds: 2))`. |

---

## Open Questions (decidir durante implementación)

- **[Open Q-A]** Ruta exacta de Print Settings desde el cotizador: `app_router.dart:102-105` registra `/print` dentro del shell (aparece como tab inferior). PRD sugiere `/config/print-settings`. Decisión:
  - Opción 1: `context.push('/print')` — va a la tab de Print dentro del shell, comportamiento "tab nav".
  - Opción 2: agregar nueva ruta full-screen `/config/print-settings` con `_slideRight` — comportamiento "push overlay".
  - Recomendación: **Opción 2** (consistente con `/calculator`, `/settings/standalone`, `/paywall` como full-screen push). Requiere agregar entry en `app_router.dart` y mover `PrintSettingsPage` del shell branch a top-level. Resolver en implementación.

- **[Open Q-B]** Dashboard stats: ¿la query del dashboard filtra por `isPartial = false`? Verificar en `lib/features/dashboard/` antes de merge. Si no filtra, agregar AND al WHERE para excluir parciales (AC-209).

- **[Open Q-C]** Heurística de upsert por minuto: confirmada por PRD (`createdAt` truncado). Documentar bordes (segundo 59 → 2 filas). Si en testing aparece el problema, migrar a hash de state completo (costo: 1 línea + tests).

- **[Open Q-D]** Tagline versión: PRD sugiere `EsBO.printSettingsVersionSuffix` como helper l10n (placeholder `{0}`). Verificar firma del helper `format(...)` en `es_bo.dart` antes de usar; alternativa: concatenar `EsBO.appName + ' · v' + kAppVersion` directo (estilo actual `_SettingsHeader:363`).

- **[Open Q-E]** Callback de imagen desde `result_sheet` al calculator_page: ¿pasa `Uint8List?` directo o void (el calculator ya tiene acceso a state.isValid, no necesita bytes)? Decisión: **void** (más simple, mantiene bytes locales en result_sheet como UI efímero).

- **[Open Q-F]** Filtro opcional "Solo rápidos / Solo completas / Todas" en historial (PRD §2 Open Question). Status: **nice-to-have, NO bloquea**. Evaluar tras entrega.

---

## Rollback Plan

Si algo sale mal post-merge, el orden de reversibilidad es:

1. **T6 (guardado parcial)** — feature nueva, reversión limpia: borrar `is_partial` de queries, deshabilitar `ref.listen` en calculator_page, rollback del schema es delicado (ver punto 4).
2. **T4 + T5 (Reset AppBar + overflow)** — cambios solo de UI, reversión con revert del commit.
3. **T3 (BUG Nueva)** — flag `newMode` y ruta dedicada; remover flag y revertir Home a `/calculator`.
4. **T1 (schema v13→v14)** — **CRÍTICO**: una vez publicado, NO se puede borrar la columna `is_partial` sin migración destructiva. Plan de rollback:
   - App desplegada con v14 → usuario hace downgrade a v13 → schema inconsistente.
   - Mitigación: NO bumpear schema hasta último momento; merge del código condicional a un feature flag remoto (`kIsPartialFeatureEnabled = false`).
   - Si ya está publicado y hay bug: hotfix con migración `v13→v14` corregida + nueva versión `v15` aditiva (no destructiva).
5. **T7 (visual header)** — cambio cosmético, revert directo.
6. **T2 (l10n)** — agregar getters abstractos es no destructivo; las 10 keys quedan aunque no se usen (cero impacto en runtime si no se referencian).

**Estrategia preventiva**:

- Merge de T1 + T2 + T7 en PR-1 (foundations, no rompe nada).
- PR-2 = T3 + T4 + T5 (UX quick wins, independientes).
- PR-3 = T6 (feature grande, schema bump).
- PR-4 = T8 + T9 (tests + verificación).

Si PR-3 falla, rollback de T6 sin tocar schema: `git revert` del commit, pero conservar `schemaVersion = 14` y la columna (datos default `false` son inertes).

---

## Verificación (comandos)

```powershell
# Format
dart format --set-exit-if-changed lib/ test/

# Analyze
flutter analyze

# Test unit + widget + integration
flutter test

# Migration test (patrón)
flutter test test/integration/migration_v13_to_v14_test.dart

# Coverage
flutter test --coverage
# (revisar coverage/lcov.info para thresholds de partial_save_*)

# Build smoke (web)
flutter build web --release
```

---

## Estimación

| Task | Effort | h |
|------|--------|---|
| T1 | S | 1 |
| T2 | S | 1.5 |
| T3 | S | 1 |
| T4 | S | 1.5 |
| T5 | XS | 0.3 |
| T6 | L | 6 |
| T7 | S | 1 |
| T8 | M | 4 |
| T9 | S | 1 |
| **Total** | | **≈ 16.3 h** (~2 sesiones largas de trabajo enfocado) |

---

## Success Criteria (verificación post-implementación)

- [ ] **SC1 (F1 — BUG)**: "Nueva cotización" abre form limpio + limpia draft. "Continuar" y "Reusar" sin regresión.
- [ ] **SC2 (F2 — Parcial)**: form válido → fila parcial persistida (upsert). Imagen adjunta → actualiza. Save completo → completa. Reset → elimina. Migración v13→v14 preserva datos. Badge en lista. Banner + CTA en detalle.
- [ ] **SC3 (F3 — Reset visible)**: Reset como `IconButton` primario en AppBar; confirmación solo si hay contenido; silencioso si vacío.
- [ ] **SC4 (F4 — Quick actions)**: Print Settings accesible desde overflow del calculator; Settings sin duplicar.
- [ ] **SC5 (F5 — Header Print Settings)**: misma jerarquía visual que Settings (mismo árbol, color `tertiary`, icono `printer3d`).
- [ ] **SC6**: `flutter analyze` sin warnings nuevos; `dart format` limpio; suite verde.
- [ ] **SC7**: l10n 5 idiomas completo (10 keys presentes en `app_strings.dart` + facade `EsBO` + 5 impls).
- [ ] **SC8**: reporte en `docs/reports/2026-09-28-mejoras-cotizador.report.md` + auditoría en `docs/audits/2026-09-28-mejoras-cotizador.audit.md`.
