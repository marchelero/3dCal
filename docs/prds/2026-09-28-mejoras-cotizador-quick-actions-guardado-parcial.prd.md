# PRD — Mejoras del Cotizador: bug "Nueva" + Guardado parcial + Reset siempre visible + Quick Actions + Visual Print Settings

- **Fecha**: 2026-09-28
- **Estado**: DRAFT — confirmado por el usuario (Q1-Q5 cerradas), listo para `/plan`
- **Origen**: refino del PRD draft generado el mismo día; 5 decisiones pendientes resueltas.
- **Componentes principales**:
  - `lib/features/calculation/presentation/pages/home_page.dart` (lanzador "Nueva cotización")
  - `lib/features/calculation/presentation/pages/calculator_page.dart` (initState, AppBar, `_saveDraft`/`_resetAll`, overflow menu, listeners de auto-save parcial)
  - `lib/features/calculation/presentation/widgets/result_sheet.dart` (listener de imagen adjunta dispara partial-save)
  - `lib/features/calculation/data/calculation_repository.dart` (persistencia + upsert de parciales)
  - `lib/features/calculation/presentation/state/calculator_notifier.dart` (selector derivado `isValidProvider`, helper `stateToPartialDto`)
  - `lib/core/database/app_database.dart` (schema drift v13 → v14, columna `isPartial`)
  - `lib/core/storage/draft_storage.dart` (sesión local, sin cambios funcionales)
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart` (badge "Borrador")
  - `lib/features/calculation/presentation/pages/calculation_detail_page.dart` (banner + CTA completar)
  - `lib/features/settings/presentation/pages/print_settings_page.dart` (`_PrintSettingsHeader` completa)
  - `lib/features/settings/presentation/pages/settings_page.dart` (`_SettingsHeader` como referencia de patrón)
  - `lib/shared/widgets/confirm_dialog.dart` (reusado por confirmación de Reset)

## Problema

Cinco mejoras independientes agrupadas por afinidad (todas viven en el cotizador o muy cerca):

1. **BUG** "Nueva cotización" restaura el draft anterior: el usuario espera formulario vacío, recibe datos viejos.
2. **FEATURE** Falta guardado parcial automático: si el usuario sale sin tocar "Guardar", pierde el trabajo aunque ya haya completado peso/horas/filamento.
3. **FEATURE** "Restablecer" vive dentro del result sheet — el usuario no lo encuentra desde los pasos 1/2 del wizard.
4. **FEATURE** Faltan accesos rápidos desde el cotizador a Ajustes generales y a Configuración de impresión.
5. **MEJORA VISUAL** Header de "Configuración de impresión" se ve peor que el de "Ajustes" porque le faltan 3 piezas del patrón compartido (tagline versión, fila privacidad, slot para `ProActiveBadge`).

## Decisiones del usuario (explícitas en su mensaje)

- **Item 1 (BUG)**: ruta nueva `/calculator/new` (o `?new=true`) — NO contaminar Home con side-effects de `draftStorage.clear()`.
- **Item 3 (Reset visible)**: IconButton en AppBar del calculator, NO en el footer del wizard.
- **Item 4 (Quick actions)**: overflow menu (3 puntos) en AppBar; agrupar accesos rápidos; Reset/Guardar según patrón actual.
- **l10n 5 idiomas** (es_BO/en/de/fr/pt): cada string nueva debe aparecer en `AppStrings` + facade `EsBO` + 5 impls (`es_bo.dart`, `en_us.dart`, `de_de.dart`, `fr_fr.dart`, `pt_br.dart`).
- **No doubles en dinero**: motor se mantiene con `decimal`.
- **No setState en vistas dinámicas**: Riverpod para estado de negocio; setState solo para UI efímero (p. ej. page index del stepper).

## Decisiones confirmadas (Q1-Q5, ✅ resueltas)

| # | Decisión | Resolución | Referencia de implementación |
|---|----------|------------|------------------------------|
| ✅ **Q1** | Modelo del guardado parcial | **Nueva columna `is_partial: bool NOT NULL DEFAULT 0` en tabla `calculations`** (drift schema v13 → v14, migración aditiva en `onUpgrade`). NO tabla nueva separada. NO se mergea con `CalculationDraft` — entidades distintas: **draft = session restore local** (SharedPreferences, `core/storage/draft_storage.dart`); **parcial = cotización persistida en drift con flag**. | `lib/core/database/app_database.dart:45` (`schemaVersion = 13` → 14), `lib/core/storage/calculation_draft.dart:9` (entidad local sin cambios). |
| ✅ **Q2** | Trigger del auto-save parcial | **Transición inválido → válido** (`output == null` → `output != null`), debounce 1.5 s. **NO** save por keystroke. **NO** timer fijo. También se dispara al **adjuntar imagen** en el result sheet (mismo entry point). | `CalculatorNotifier` selector derivado `isValidProvider` + `ref.listen` en `_CalculatorPageState`; `_handlePickImage`/`_handleConfirmCrop` en `result_sheet.dart`. |
| ✅ **Q3** | Confirmación del Reset | **Diálogo "¿Restablecer?…" SOLO si hay contenido** (peso/horas/filamento no vacíos). Si vacío, **reset silencioso directo**. Reusar `confirm_dialog.dart` existente. | `lib/shared/widgets/confirm_dialog.dart`; lógica de gating en el handler del IconButton primario del AppBar. |
| ✅ **Q4** | Ubicación del Reset en AppBar | **IconButton primario** `Icons.refresh_rounded` en AppBar del calculator (junto al chip de total), tooltip `EsBO.calcActionReset`. Settings y Print Settings **permanecen en overflow menu** (3 puntos). Settings ya existe; se **agrega Print Settings** como nuevo item. | `lib/features/calculation/presentation/pages/calculator_page.dart:839-848` (overflow actual) + nueva acción primaria. |
| ✅ **Q5** | Header visual de Print Settings | **Mantener color `tertiary`** (diferenciación con Ajustes/`primary`). Heredar patrón de `_SettingsHeader`. **Agregar las 3 piezas que faltan**: (1) tagline `${EsBO.appName} · v$kAppVersion`, (2) fila `Icons.lock_outline_rounded` + `EsBO.settingsPrivacy`, (3) slot para `ProActiveBadge` (extremo derecho). | `lib/features/settings/presentation/pages/print_settings_page.dart:259-372` (`_PrintSettingsHeader`); referencia `lib/features/settings/presentation/pages/settings_page.dart:260-401` (`_SettingsHeader`). |

---

## Feature 1 — BUG: "Nueva cotización" abre formulario vacío

### Objetivo

Tap en "Nueva cotización" desde Home abre la calculadora con formulario VACÍO (sin datos del draft anterior). El draft persistido se elimina para evitar restauraciones fantasma. "Continuar borrador" y "Reusar" desde historial siguen restaurando normalmente (sin regresión).

### Diseño

**Cambio A — query param `?new=true` en la ruta `/calculator`:**

- `app_router.dart`: registrar `/calculator/new` como alias que monta `CalculatorPage(newMode: true)`, o bien aceptar query param `?new=true` en `/calculator` y propagarlo. Verificar el patrón actual del router para elegir el path menos invasivo.
- `CalculatorPage`: agregar `final bool newMode` al widget (default `false`). En `initState`:
  - Si `newMode == true`: saltar el bloque de `storage.load()` + `notifier.restoreFromDraft()` + `loadFilamentDefaults()`. Llamar `notifier.reset()` directo y `await ref.read(draftStorageProvider).clear()` antes del reset (sin esto, el siguiente restore traería de nuevo los datos).
  - Si `newMode == false`: comportamiento actual sin cambios.
- `home_page.dart:311` (lanzador "Nueva cotización"): cambiar `onTap: () => context.push('/calculator/new')` (o equivalente con query param).
- Banner "Continuar borrador" (`home_page.dart` ~`:469`, `:700`) **NO se toca** — sigue restaurando.
- Botón "Reusar" desde historial → `/calculator/prefill`, sin distinción (carga `prefillCalc`, no usa `newMode`).

### Acceptance Criteria

- **AC-101 (Required)**: Home con draft persistido → tap "Nueva cotización" → calculator abre con peso, horas, minutos, descuento, filamento (precio/gramos/label), pieza label y TODOS los costos extra en blanco. Verificación: widget test + manual.
- **AC-102 (Required)**: Tras AC-101, `draftStatusProvider` ya no muestra contenido (banner "Continuar" desaparece en Home). Verificación: integración.
- **AC-103 (Required)**: Tap "Continuar borrador" desde Home sigue restaurando EXACTAMENTE como hoy (sin regresión). Verificación: tests existentes pasan.
- **AC-104 (Required)**: Tap "Reusar" desde historial (ruta `/calculator/prefill`) sigue funcionando (carga `prefillCalc`, no usa `newMode`). Verificación: tests existentes.
- **AC-105 (Required)**: `flutter analyze` + suite verde.

### Test plan

- `test/widget/`: nuevo `new_quotation_empty_form_test.dart` — stub `SharedPreferences` con draft previo, navega a `/calculator/new`, verifica controllers vacíos + `draftStorageProvider.clear()` llamado.
- Ajustar `test/widget/calculator_page_test.dart` (rama `newMode == false` debe seguir trayendo el draft).

---

## Feature 2 — Guardado parcial automático ("Cotización rápida" / borrador persistido)

### Objetivo

Cuando el form de la calculadora pasa a válido (output visible) o se adjunta una imagen, la cotización se persiste automáticamente como **cotización rápida (parcial)**. El usuario puede salir y volver desde el historial. El botón "Guardar" completo sigue existiendo para finalizar (nombre, cliente) → cotización completa.

### Diseño

**Modelo de datos — schema drift v13 → v14 (aditiva, Q1 confirmada):**

```dart
// En app_database.dart, tabla Calculations:
TableColumn get isPartial => boolean().withDefault(const Constant(0))();
// Nombre Dart: isPartial (snake en SQL: is_partial)
```

- Migración aditiva `onUpgrade` desde v13 → v14: `m.addColumn(calculations, calculations.isPartial);` con default `0` (las filas existentes son completas por definición).
- `Calculation` entity (data class generada por drift) gana `bool isPartial`. `asDto`/serialización: incluir.
- `CalculationDraft` (local) **NO se modifica**: sigue siendo lo que es (session restore efímero).

**Repositorio:**

- `calculation_repository.dart`: nuevo método `Future<int> savePartial({required CalculatorState state, required Uint8List? pieceImage})` que crea una `Calculation` con `isPartial = true`, `name = ''`, `clientName = ''`, timestamps actuales, `pieceImageBlob` si hay imagen (reusar downscale RF2-3 del PRD 2026-09-05: máx 1200 px lado mayor + JPEG q85 con paquete `image`). Si ya existe una parcial "en progreso" para la misma sesión, **actualiza** en lugar de duplicar (upsert por heurística de `createdAt` truncado a minuto — misma ventana = misma fila). Heurística documentada en Open Questions.
- `updatePartial(int id, …)` para refrescar la parcial sin crear duplicados.
- `findLatestPartialForMinute(DateTime minuteBucket)` helper del upsert.

**Trigger de auto-save (Q2 confirmada):**

- Extender `CalculatorNotifier` con selector derivado `isValidProvider`: `ref.watch(calculatorNotifierProvider.select((s) => s.output != null))`.
- En `_CalculatorPageState` (vía `ref.listen`): detectar transición `false → true`. Debounce 1.5 s → llamar `repository.savePartial(...)` con el estado actual y `_pieceImageBytes` (si existe; requiere mover esa imagen al state o exponerla vía callback — hoy vive en `_ResultSheetContentState`, ver punto F-3).
- **Imagen adjunta → auto-save**: en `_handlePickImage` / `_handleConfirmCrop` del result sheet, tras `setState(bytes != null)`, disparar también el partial-save (mismo entry point).
- **Reset y Save completo limpian la parcial**: en `_resetAll()` → si existe parcial de la sesión, borrarla (`repository.delete(id)`). En `_handleSave` (calculator_page.dart:~615-674) → actualizar la fila existente parcial a `isPartial = false` + name/client poblados, en vez de insert duplicado.

**UX — Home y detalle:**

- Home no necesita cambios estructurales: el historial ya lista todas las cotizaciones; las parciales aparecen mezcladas.
- `calculations_list_page.dart` (lista): cuando `isPartial == true`, mostrar **badge "Borrador"** (chip pequeño con `Icons.edit_note_rounded`, alpha) al lado del nombre. Color: `colorScheme.tertiary` o `outline` (a afinar en implementación).
- `calculation_detail_page.dart` (detalle): si `isPartial`, banner arriba con `EsBO.calcPartialAutoSaved` + `EsBO.calcPartialCompleteHint`, CTA "Completar" que abre el save sheet con la cotización prefillada → al confirmar, `isPartial = false`.
- Al reusar desde historial (botón existente "Reusar"): misma ruta `/calculator/prefill`, sin distinción (el prefill funciona igual).

**Visibilidad opcional `[opcional]`** — filtro por tipo en historial:

- Toggle "Solo rápidos" / "Solo completas" / "Todas" (default: Todas). NO requerido si el badge basta; queda como nice-to-have.

### Acceptance Criteria

- **AC-201 (Required)**: Form pasa de inválido → válido → 1.5 s después hay una fila nueva en `calculations` con `isPartial = true`, `name = ''`, `clientName = ''`. Verificación: unit test del notifier + integración DB.
- **AC-202 (Required)**: Cambios posteriores al form válido (peso, horas, descuento) actualizan la MISMA fila parcial (no se duplica). Verificación: integración.
- **AC-203 (Required)**: Adjuntar imagen tras form válida → la fila parcial gana `pieceImageBlob` no nulo. Verificación: integración.
- **AC-204 (Required)**: Tap "Guardar" completo con parcial existente → fila actualizada a `isPartial = false` con name/client; NO se crea fila nueva. Verificación: integración.
- **AC-205 (Required)**: `_resetAll()` con parcial existente → la fila se elimina. Verificación: integración.
- **AC-206 (Required)**: Migración v13 → v14: las cotizaciones existentes quedan con `isPartial = false`. Verificación: `migration_v13_to_v14_test.dart`.
- **AC-207 (Required)**: Lista de historial muestra badge "Borrador" en parciales; sin badge en completas. Verificación: widget test.
- **AC-208 (Required)**: Detalle de parcial muestra banner + CTA para completar. Verificación: widget test.
- **AC-209 (Required)**: Dashboard sigue mostrando solo completas para "Ganancias reales vs cotizadas" (parciales excluidas). Verificación: tests existentes.
- **AC-210 (Required)**: History cap gratis (10) cuenta completas + parciales igual que hoy. Verificación: `history_cap_test.dart`.

### Test plan

- `test/unit/`: nuevo `partial_save_notifier_test.dart` (transición válido/inválido, debounce, upsert), `partial_save_repository_test.dart` (CRUD parcial + migración).
- `test/integration/`: nuevo `partial_save_integration_test.dart` (flujo: form vacío → llenar → parcial creada → editar → misma fila → guardar completo → `isPartial=false`).
- `test/widget/`: ajustes a `calculations_list_page_test.dart` (badge) y `calculation_detail_page_test.dart` (banner).

---

## Feature 3 — "Restablecer" siempre visible en el cotizador

### Objetivo

Botón "Restablecer" accesible en TODOS los pasos del wizard sin abrir ningún bottom sheet, con confirmación inteligente (solo si hay contenido).

### Diseño (Q3 y Q4 confirmadas)

- Mover `Icons.refresh_rounded` desde el overflow menu (calculator_page.dart:839-842) a un **IconButton primario en el AppBar** (slot estándar de acciones), al lado del chip de total o como última acción antes del overflow.
- Tooltip: `EsBO.calcActionReset` (ya existe en los 5 locales).
- onPressed:
  - Si hay contenido (peso/horas/filamento no vacíos): mostrar `confirm_dialog.dart` con título `EsBO.calcResetConfirmTitle` y body `EsBO.calcResetConfirmBody` (ambos nuevos, ver sección l10n). Confirmar → `_resetAll()` (ya existe, calculator_page.dart:~630). Cancelar → no-op.
  - Si vacío: reset silencioso directo, sin diálogo.
- Settings/Print Settings permanecen en el overflow menu (no se duplica nada).
- `_resetAll()` además limpia la parcial activa si existe (Feature 2, AC-205).

### Acceptance Criteria

- **AC-301 (Required)**: Botón "Restablecer" visible en TODOS los pasos del wizard (1, 2, 3) y desde el result sheet. Verificación: widget test + manual en cada paso.
- **AC-302 (Required)**: Tap con contenido → diálogo de confirmación aparece; cancelar = no-op; confirmar = form vacío + draft limpio + paso 1 + parcial eliminada. Verificación: widget test + integración.
- **AC-303 (Required)**: Tap sin contenido → reset silencioso, sin diálogo. Verificación: widget test.
- **AC-304 (Required)**: Tras reset, "Nueva cotización" sigue funcionando igual (sin doble limpieza). Verificación: integración.
- **AC-305 (Required)**: El overflow menu ya no contiene "Restablecer" (se sacó del grupo); Settings sí permanece y Print Settings se agregó (Feature 4). Verificación: widget test del AppBar.

### Test plan

- `test/widget/`: ajustar `calculator_page_test.dart` (Reset ahora es acción primaria, no item del menú) + nuevo `reset_confirm_dialog_test.dart` (gating contenido vs vacío, cancelar, confirmar).

---

## Feature 4 — Quick actions a Settings y Print Settings desde el cotizador

### Objetivo

Acceso permanente desde el cotizador a Ajustes generales y a Configuración de impresión (Print Settings), agrupados en el overflow menu del AppBar.

- **Settings**: YA EXISTE en el overflow menu (calculator_page.dart:843-847). Mantener — no duplicar.
- **Print Settings**: NO EXISTE. Agregar (Q4 confirmada).

### Diseño (Q4 confirmada)

- En el overflow menu del `CalculatorPage` (calculator_page.dart:827-848), agregar una nueva entrada entre Settings y el final:
  ```
  PopupMenuItem(
    icon: const Icon(MdiIcons.printer3d),
    label: EsBO.calcActionPrintSettings,
    onTap: () => context.push('/config/print-settings'),
  ),
  ```
- Ruta `/config/print-settings`: verificar en `app_router.dart` cuál está registrada para impresoras (puede ser `/settings/print-settings`); usar la que ya exista para no abrir rutas 404.
- Icono: `MdiIcons.printer3d` (consistente con el sello del `_PrintSettingsHeader`).
- Tooltip/long-press: heredado del `SmartAppBarActions` (ya muestra label).
- Posición recomendada en el menú: debajo de "Ajustes" (Settings), agrupando settings. Si se prefiere alfabético/por flujo, ajustar en implementación.

### Acceptance Criteria

- **AC-401 (Required)**: Desde el cotizador, overflow → tap "Config. impresión" → navega a la ruta correcta registrada para Print Settings (sin 404). Verificación: widget test de navegación + manual.
- **AC-402 (Required)**: "Ajustes" sigue funcionando exactamente como hoy (sin regresión, sin doble entrada). Verificación: tests existentes.
- **AC-403 (Required)**: En la ruta abierta, el header se ve según el fix del Feature 5 (entrega coordinada). Verificación: integración visual.

### Test plan

- `test/widget/`: ajustar `calculator_page_test.dart` (overflow menu ahora tiene 4 entradas: ayuda, plantillas, ajustes, print settings).

---

## Mejora 5 — Visual: header "Configuración de impresión" hereda el balance de "Ajustes"

### Objetivo

El header de Configuración de impresión (Print Settings) se ve peor que el de Ajustes porque le faltan 3 piezas del patrón compartido. Agregarlas para igualar la jerarquía visual, manteniendo el color `tertiary` para diferenciar módulos (Q5 confirmada).

### Diseño (Q5 confirmada)

Editar `_PrintSettingsHeader` en `lib/features/settings/presentation/pages/print_settings_page.dart:259-372`. Agregar entre el bloque de título/subtitle y el cierre del `Column` interno, mismo orden que `_SettingsHeader`:

1. **Tagline de versión**: igual que `_SettingsHeader:363` → `'${EsBO.appName} · v$kAppVersion'`. Estilo: `theme.textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)`. Usar `EsBO.printSettingsVersionSuffix` como helper si se prefiere l10n pura.
2. **Fila de privacidad**: igual que `_SettingsHeader:369-386` → `Icons.lock_outline_rounded` (size 14) + `EsBO.settingsPrivacy` en `bodySmall`.
3. **Slot para `ProActiveBadge`**: igual que `_SettingsHeader:391-392` → `const ProActiveBadge()` en una `SizedBox(width: AppSpacing.sm)` antes del badge, extremo derecho del Row.

**NO se cambia:**

- Banda superior (`color.tertiary`).
- Sello (gradiente `tertiary`).
- `MdiIcons.printer3d` (icono correcto del módulo).

**Reutilizar** `kAppVersion` que ya se usa en `_SettingsHeader` (importar o exponer si hoy es privado — verificar en implementación).

### Acceptance Criteria

- **AC-501 (Required)**: Header de Print Settings tiene, en este orden: sello gradient + title + tagline versión + fila privacidad + `ProActiveBadge`. Verificación: widget test comparando estructura con `_SettingsHeader` (mismo árbol de widgets, solo cambian color/icono/textos).
- **AC-502 (Required)**: Mismo padding (`xxl/xl/xxl/xxl`), mismo `borderRadius` (`AppRadii.lg`), mismo shadow (`blurRadius: 12, offset: (0,3), alpha 0.06`), misma banda superior 4 px. Verificación: widget test.
- **AC-503 (Required)**: Título NO se recorta ni aplica con headfuls en viewports ≥ 600 px. Verificación: visual + golden test (opcional).
- **AC-504 (Required)**: En Pro (con `ProActiveBadge`), el badge aparece; en free, no. Verificación: widget test con `isProProvider` mock.
- **AC-505 (Required)**: `flutter analyze` + suite verde.

### Test plan

- `test/widget/`: nuevo `print_settings_header_test.dart` — estructura del header coincide con `_SettingsHeader` excepto color/icono/textos.

---

## Fuera de alcance

- Reescribir el motor de cálculo (`CalculationEngine`) o cambiar el modelo de dinero (`decimal`).
- Eliminar o fusionar modos Express/Advanced.
- Cambiar la lógica del wizard (3 pasos + barra de total + footer).
- Cambios en PDF / exportación de cotización / templates.
- Sync cloud de cotizaciones (incluyendo parciales) — no-backend por Non-Negotiables.
- iOS-specific testing (mismo código, no se valida separado en este PRD).
- Editor completo de imagen (brillo, filtros) — solo se reusa el crop existente del PRD 2026-09-05.
- Cambiar el redirect web `/paywall` → `/settings`.
- Fusionar `CalculationDraft` (local) con `Calculation` (drift) — entidades distintas por diseño (Q1).

## Impacto técnico (consolidado)

### Archivos a crear / modificar

**Modificar:**

- `lib/features/calculation/presentation/pages/home_page.dart` — cambio de ruta del quick action "Nueva cotización" (~l. 311).
- `lib/features/calculation/presentation/pages/calculator_page.dart` — agregar flag `newMode`, mover Reset a IconButton primario, agregar Print Settings al overflow, integrar auto-save parcial (listener + debounce), reset limpia parcial.
- `lib/features/calculation/data/calculation_repository.dart` — métodos `savePartial`, `updatePartial`, `deletePartial`, `findLatestPartialForMinute` (upsert por heurística de minuto).
- `lib/features/calculation/presentation/state/calculator_notifier.dart` — selector `isValidProvider`, helper `stateToPartialDto`.
- `lib/core/database/app_database.dart` — agregar columna `isPartial` a tabla `Calculations`, migración v13 → v14.
- `lib/features/calculation/presentation/widgets/result_sheet.dart` — listener de imagen adjunta dispara partial-save.
- `lib/features/calculation/presentation/pages/calculations_list_page.dart` — badge "Borrador" cuando `isPartial`.
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart` — banner + CTA completar.
- `lib/features/settings/presentation/pages/print_settings_page.dart` — header con 3 piezas faltantes.

**Crear (probable):**

- `lib/core/widgets/build/partial_save_indicator.dart` (o donde encaje por convención) — chip "Borrador" reutilizable.
- `lib/core/database/migrations/v13_to_v14.dart` (si el proyecto separa migraciones; si no, inline en `app_database.dart`).

### Notifiers / providers a extender

- `calculatorNotifierProvider`: ya existe — agregar selector derivado.
- `calculationsListProvider` (o el equivalente en history): filtrar/etiquetar parciales.
- `draftStorageProvider`: ya existe — sin cambios funcionales; solo se invoca `clear()` extra en `newMode`.

### Migración drift v13 → v14 (snippet de referencia)

```dart
// En app_database.dart onUpgrade, switch case 13:
m.addColumn(calculations, calculations.isPartial);
```

Aditiva, no destructiva. Datos existentes intactos (`isPartial = false` por default).

---

## L10n catalog (5 idiomas × 10 keys nuevas)

Convención: alta en `lib/l10n/app_strings.dart` (abstract getter) + facade `EsBO` (estático `get`) + 5 impls (`es_bo.dart`, `en_us.dart`, `de_de.dart`, `fr_fr.dart`, `pt_br.dart`).

| Key | es_BO | en | de | fr | pt |
|-----|-------|-----|-----|-----|-----|
| `calcActionReset` | Restablecer | Reset | Zurücksetzen | Réinitialiser | Redefinir |
| `calcActionPrintSettings` | Config. impresión | Print settings | Druckeinstellungen | Réglages d'impression | Config. impressão |
| `calcResetConfirmTitle` | ¿Restablecer? | Reset? | Zurücksetzen? | Réinitialiser ? | Redefinir? |
| `calcResetConfirmBody` | Se perderán los datos no guardados. | Unsaved data will be lost. | Nicht gespeicherte Daten gehen verloren. | Les données non sauvegardées seront perdues. | Os dados não salvos serão perdidos. |
| `calcResetConfirmCancel` | Cancelar | Cancel | Abbrechen | Annuler | Cancelar |
| `calcResetConfirmOk` | Restablecer | Reset | Zurücksetzen | Réinitialiser | Redefinir |
| `calcPartialBadge` | Borrador | Draft | Entwurf | Brouillon | Rascunho |
| `calcPartialAutoSaved` | Cotización rápida guardada | Quick quote saved | Schnelles Angebot gespeichert | Devis rapide enregistré | Cotização rápida salva |
| `calcPartialCompleteHint` | Completa los datos para guardar como cotización | Fill in the data to save as a quote | Fülle die Daten aus, um sie als Angebot zu speichern | Remplissez les données pour enregistrer comme devis | Preencha os dados para salvar como cotação |
| `printSettingsVersionSuffix` | ` · v{0}` | ` · v{0}` | ` · v{0}` | ` · v{0}` | ` · v{0}` |

> Nota: `calcActionReset` ya existe en los 5 locales (`lib/l10n/es_bo.dart:1445`, `en_us.dart:595`, `de_de.dart:604`, `fr_fr.dart:578`, `pt_br.dart:603`) — se reutiliza tal cual, sin alta nueva. El resto son altas nuevas en `app_strings.dart` + facade + 5 impls.

---

## Criterios de éxito (consolidados)

El trabajo está completo cuando TODOS los siguientes son verdaderos:

- [ ] **SC1 (Feature 1 — BUG)**: "Nueva cotización" abre formulario limpio + limpia draft. "Continuar" y "Reusar" sin regresión.
- [ ] **SC2 (Feature 2 — Parcial)**: Form válido → fila parcial persistida (upsert). Imagen adjunta → actualiza. Save completo → completa. Reset → elimina. Migración v13 → v14 preserva datos. Badge "Borrador" en lista. Banner + CTA en detalle.
- [ ] **SC3 (Feature 3 — Reset visible)**: Reset como IconButton primario en AppBar; confirmación solo si hay contenido; reset silencioso si vacío.
- [ ] **SC4 (Feature 4 — Quick actions)**: Print Settings accesible desde overflow del calculator; Settings sin duplicar.
- [ ] **SC5 (Mejora 5 — Header Print Settings)**: Misma jerarquía visual que Settings (mismo árbol, solo color `tertiary`/icono `printer3d`/textos).
- [ ] **SC6**: `flutter analyze` sin nuevos warnings; `dart format` limpio; suite de tests verde.
- [ ] **SC7**: l10n 5 idiomas completo (es_BO, en, de, fr, pt) — 10 keys nuevas (9 textos + 1 placeholder `printSettingsVersionSuffix`) presentes en `app_strings.dart` + facade `EsBO` + 5 impls.

## Test plan (consolidado)

**Unit (motor + repo + notifier):**

- `partial_save_notifier_test.dart` (nuevo) — transición válido/inválido, debounce 1.5 s, upsert por minuto.
- `partial_save_repository_test.dart` (nuevo) — CRUD parcial + migración.
- Ajustar `calculator_notifier_test.dart` (existente) — selector `isValidProvider`.

**Widget:**

- `new_quotation_empty_form_test.dart` (nuevo) — Feature 1.
- `reset_confirm_dialog_test.dart` (nuevo) — Feature 3.
- `print_settings_header_test.dart` (nuevo) — Mejora 5.
- Ajustes a:
  - `calculator_page_test.dart` — `newMode`, AppBar Reset primario, overflow menu con Print Settings (4 entradas).
  - `calculations_list_page_test.dart` — badge "Borrador".
  - `calculation_detail_page_test.dart` — banner parcial + CTA.

**Integración:**

- `partial_save_integration_test.dart` (nuevo) — flujo end-to-end del Feature 2.
- `migration_v13_to_v14_test.dart` (nuevo) — preserva filas, agrega columna con default.

---

## Riesgos

| Riesgo | Likelihood | Impact | Mitigación |
|---|---|---|---|
| Auto-save parcial genera spam de filas (upsert falla) | Med | Alto | Upsert por heurística de minuto + debounce 1.5 s; tests explícitos AC-202. |
| Migración v13 → v14 rompe builds viejos (usuarios con app previa) | Baja | Alto | Migración aditiva, default `0`; test de migración cubre down/up-grade AC-206. |
| Mover Reset a AppBar primario quita accesibilidad rápida para usuarios con una mano | Baja | Bajo | Reset se mantiene accesible desde el footer del wizard como fallback en planes UX posteriores. |
| Color `tertiary` para Print Settings sigue diferenciándolo de Settings y al usuario le disgusta | Baja | Bajo | Q5 cerrado; decisión reversible sin refactor (cambiar `primary` por `tertiary`). |
| l10n incompleto en algún idioma | Baja | Med | CI con check de paridad (verificar si existe `tools/check_l10n.dart`; si no, agregar). |
| Heurística de upsert por minuto produce colisiones entre sesiones distintas | Baja | Med | Test explícito AC-202 cubre upsert; si se observa conflicto, migrar a hash de state o id de sesión (Open Questions). |

## Open Questions

- [ ] **Ruta exacta** para Print Settings desde el cotizador: `/config/print-settings` vs `/settings/print-settings` — verificar en `app_router.dart` cuál está registrada para impresoras antes de hacer push.
- [ ] **Heurística de upsert** de la fila parcial: confirmado por minuto (`createdAt` truncado). ¿Bordes de minuto con cambios a último segundo? Si molesta en testing, migrar a hash de state.
- [ ] **Auto-save parcial vs imagen adjunta**: confirmado — la imagen adjunta dispara su propio partial-save (mismo entry point). No se excluye imagen.
- [ ] **Tagline versión en Print Settings**: ¿usar `EsBO.appName + kAppVersion` directo (estilo actual de `_SettingsHeader:363`) o pasar por nueva key l10n `printSettingsVersionSuffix`? Recomendación: l10n pura (helper key en 5 idiomas con placeholder `{0}`) — ya incluida en el catálogo. Confirmar preferencia en implementación.
- [ ] **Filtro opcional "Solo rápidos / Solo completas / Todas"** en lista de historial — `[opcional]`, no bloquea. Evaluar tras entrega.

---

*Status: DRAFT — Q1-Q5 confirmadas, listo para `/plan docs/prds/2026-09-28-mejoras-cotizador-quick-actions-guardado-parcial.prd.md`.*
