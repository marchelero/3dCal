# PRD: Color por filamento — paleta + color específico, visible en catálogo y cotización

> Generated 2026-09-08 desde petición del usuario:
> "necesito una mejora en este proyecto cuando registra filamentos ya se en la primera vez o en settings debería permitirme también registrar un color de forma dinámica intuitiva de una paleta de colores o un color específico.. agregalo a ambos lados o un color específico.. y en la cotización cuando selecciona el filamento que también aparezca el color"

## Status

IMPLEMENTED 2026-09-08. `flutter analyze`: solo 3 warnings pre-existentes (`calculator_page.dart`). `flutter test`: **534/535 verde** (1 fallo pre-existente no relacionado: microcopy mismatch en `initial_config_stepper_test.dart` línea 1 — el test busca string viejo que ya no existe). +25 tests nuevos en este PRD.

## Decisiones confirmadas con el usuario

- Picker HSV: **simple** (slider de matiz + campo hex editable, sin sliders de S/V).
- Color en PDF/PNG: **no** (fuera de alcance; el dato queda persistido para futuro).

## Context

3dCal es una calculadora de precios para impresión 3D, 100% local (Flutter + Riverpod + drift, `schemaVersion: 10`). Hallazgos verificados en codebase:

1. **Tabla `filaments`** (`lib/features/catalog/filaments/data/filaments_table.dart`): tiene `name`, `brand`, `pricePerBobbin`, `gramsPerBobbin`, `isDefault`, `createdAt`. **No hay columna de color**.
2. **Form de filamento** (`lib/features/catalog/filaments/presentation/pages/filament_form_page.dart`): 4 campos (brand, name, price, grams) + switch default. Sin selector de color.
3. **Onboarding inicial** (`lib/features/onboarding/presentation/pages/initial_config_page.dart` líneas 459-531): bloque "Filamento" espeja los mismos 4 campos, también sin color.
4. **Lista de filamentos** (`lib/features/catalog/filaments/presentation/pages/filaments_page.dart` líneas 161-251 `_FilamentTile`): leading icon = `DefaultBadge` o `Icons.label_outline` (sin color de filamento).
5. **Selector del cotizador** (`lib/features/calculation/presentation/widgets/filament_selector_dialog.dart` líneas 50-69 `itemBuilder`): `AvatarIcon` con icono etiqueta y subtítulo `precio sym · X g`. Sin indicador de color.
6. **i18n** (`lib/l10n/app_strings.dart` + 6 locales `es_bo.dart`, `en_us.dart`, `pt_br.dart`, `de_de.dart`, `fr_fr.dart`): no hay strings de "color"; se agregan en este PRD.
7. **Backup**: `lib/features/calculation/data/backup_service.dart` + `backup_models.dart` serializa filamentos via drift `toJson()`. Una nueva columna nullable fluye automáticamente al JSON; sin cambios necesarios en backup.

## Decisiones tomadas

- **Almacenamiento**: `color` como `TEXT NULL` en drift (hex en mayúsculas `#RRGGBB`, ej. `#FF8800`). NULL = "sin color definido". Evita dependencia nueva (drift ya soporta TEXT).
- **Sin nueva dependencia**: la paleta usa `Colors.accents`/`Colors.primaries` (Material built-in). El picker específico se construye inline con un `Slider` HSV + vista previa (sin `flutter_colorpicker`). Cero dependencias añadidas, mantiene bundle pequeño.
- **Color opcional**: si el usuario no elige ninguno, el filamento funciona idéntico al actual (sin swatch en lista/selector, leading icon = etiqueta como hoy).
- **Edición**: al editar un filamento existente, el color preselecciona el swatch activo.
- **UX**: en el form, el campo va **después del nombre** (es lo más identificable visualmente) y **antes del precio/gramos** (datos de negocio al final).
- **Mostrar color en cotizador**: como un dot/círculo pequeño junto al nombre en el `ListTile` del selector y como dot en el leading del `_FilamentTile` (reemplaza el `Icons.label_outline` actual cuando hay color). El `DefaultBadge` (estrella dorada) sigue siendo prioridad visual — el dot va a la derecha del badge o como parte del avatar.

## Feature 1 — Registro de color en filamentos (form + onboarding)

### Objetivo

El usuario puede asignar un color a cada filamento de forma visual e intuitiva: desde una paleta rápida o un picker HSV para un color específico. Opcional.

### RF

- **RF1-1**: Migración drift **schemaVersion 10 → 11**: columna `color` (`TEXT NULL`) en `filaments`. Aditiva; filamentos viejos quedan `NULL` (sin color).
- **RF1-2**: Nuevo widget `FilamentColorField` (`lib/shared/widgets/filament_color_field.dart`) reusable:
  - Label "Color" + helper "Opcional. Identifica visualmente el filamento".
  - Estado interno: `Color? selected`.
  - Fila 1 — **paleta rápida**: 16 swatches circulares (24×24 dp) en `SingleChildScrollView` horizontal. Incluir el "rainbow": rojo, naranja, ámbar, amarillo, lima, verde, teal, cian, azul, índigo, púrpura, magenta, rosa, marrón, gris, negro + blanco. Borde de 2 dp cuando está seleccionado (usa `colorScheme.primary`). Al centro del swatch blanco, un dot oscuro (para que sea visible sobre fondo claro).
  - Fila 2 — **picker específico**: tile "Personalizado" con icono `Icons.colorize_rounded` + vista previa del color actual. Tap abre `showDialog` con:
    - HSV sliders (`Slider` × 3: H 0-360, S 0-1, V 0-1) o un único slider H + checkboxes de S/V (decisión fina en implementación).
    - TextField con hex (`#RRGGBB`) editable; valida con `RegExp(r'^#?[0-9A-Fa-f]{6}$')`.
    - Preview grande (60×60 dp).
    - Botones "Cancelar" / "Aplicar".
  - Botón "Quitar color" (visible solo si hay color seleccionado): restaura a `null`.
- **RF1-3**: `FilamentRepository.create()`/`update()` aceptan `String? color` (hex normalizado a `#RRGGBB` mayúsculas o `null`).
- **RF1-4**: `FilamentsNotifier.create()`/`updateFilament()` propagan `color`.
- **RF1-5**: `filament_form_page.dart`: integra `FilamentColorField` después del campo Nombre (orden: Marca → Nombre → **Color** → Precio → Gramos → Switch default). Pasa `_color` al notifier en `_save()`. `_color` se inicializa desde `widget.existing?.color`.
- **RF1-6**: `initial_config_page.dart` (líneas 459-531): mismo campo integrado después del Nombre, mismo orden. Persiste en `_saveFilament()`.

### AC (Acceptance Criteria)

- **AC-101**: Crear filamento con color desde paleta → al guardar y volver a la lista, el filamento muestra el swatch del color elegido en el leading. Verificación: widget test + manual. Prioridad: Required.
- **AC-102**: Crear filamento con color específico (HSV) → guardado con hex correcto (formato `#RRGGBB`). Verificación: unit test sobre `FilamentRepository` + widget test del dialog. Prioridad: Required.
- **AC-103**: Crear filamento sin color → se guarda con `color=NULL`, la UI no muestra swatch (igual a hoy, comportamiento por defecto). Verificación: widget test. Prioridad: Required.
- **AC-104**: Editar filamento existente → el campo pre-muestra el color actual (sea de paleta o custom); "Quitar color" lo devuelve a NULL. Verificación: widget test. Prioridad: Required.
- **AC-105**: Hex inválido en el textfield del picker custom → SnackBar/InlineError "Color inválido, formato #RRGGBB", no se cierra hasta corregir. Verificación: widget test. Prioridad: Required.
- **AC-106**: Migración 10→11 preserva todos los filamentos existentes con `color=NULL`. Verificación: `test/integration/migration_v10_to_v11_test.dart` (sigue patrón de `migration_v9_to_v10_test.dart`). Prioridad: Required.
- **AC-107**: Onboarding (initial config) acepta color en el primer filamento (mismo widget, misma lógica). Verificación: widget test del flujo onboarding con mock del notifier. Prioridad: Required.

## Feature 2 — Color visible en catálogo y selector de cotización

### Objetivo

El color del filamento aparece de forma clara y consistente en: lista de filamentos (settings) y selector de filamento (cotizador). Refuerza identificación visual rápida.

### RF

- **RF2-1**: `_FilamentTile` (`filaments_page.dart`): cuando `filament.color != null`, el leading es un **avatar circular 40×40 dp** con el color de fondo (border 1 dp `outlineVariant`); si `isDefault`, conserva la `DefaultBadge` (estrella) dentro del avatar (stack). Si `color == null`, comportamiento actual intacto (DefaultBadge o `Icons.label_outline`).
- **RF2-2**: Subtitle de `_FilamentTile` añade el nombre legible del color entre paréntesis cuando hay color, ej. `eSun · Bs 89.00 · 1000 g · Naranja`. Helper `kColorNameForHex(String hex)` mapea los 16+1 de la paleta a su nombre legible en el idioma activo (es/en/pt/de/fr); cualquier hex fuera del set devuelve `null` (no se añade al subtitle).
- **RF2-3**: `FilamentSelectorDialog` (`filament_selector_dialog.dart`): el `AvatarIcon` del `ListTile` gana un dot interior del color cuando `filament.color != null` (size 16 dp, posicionado con `Positioned` o `Stack`). El icono de etiqueta queda visible como en la versión actual. Sin color → idéntico a hoy.
- **RF2-4**: Búsqueda en `FilamentsPage` y selector: el campo de búsqueda matchea también por nombre del color (ej. buscar "rojo" filtra filamentos cuyo color pertenezca al bucket rojo). Reutiliza `kColorNameForHex`.

### AC

- **AC-201**: Filamento con color en la lista de settings → avatar circular con ese color visible (40×40 dp, border). Verificación: widget test (golden para un par de casos). Prioridad: Required.
- **AC-202**: Filamento con color + `isDefault=true` → badge estrella dorada visible junto al swatch (no se pierde identidad). Verificación: widget test. Prioridad: Required.
- **AC-203**: Filamento sin color → UI idéntica a la versión actual (no regresión). Verificación: test existente de la página pasa; widget test de no-color. Prioridad: Required.
- **AC-204**: Selector del cotizador: filamento con color → dot interior del color en el `AvatarIcon`. Sin color → idéntico a hoy. Verificación: widget test. Prioridad: Required.
- **AC-205**: Buscar "rojo" en lista/selector filtra correctamente los filamentos cuyo color es el bucket rojo (mapeado por `kColorNameForHex`). Verificación: unit test sobre la función `matches` del dialog. Prioridad: Required.
- **AC-206**: Subtitle en lista muestra nombre legible del color cuando aplica (paleta reconocida); no muestra nada para hex custom fuera del set. Verificación: widget test. Prioridad: Required.

## Requerimientos No Funcionales

- **RNF-1 — Storage**: `color` en `TEXT` (hex `#RRGGBB` mayúsculas) o NULL. Sin overhead perceptible en BD (un TEXT nullable por fila).
- **RNF-2 — Sin nuevas dependencias**: paleta usa `Colors.accents`/`Colors.primaries` (Material built-in); picker específico es custom widget con `Slider` + `TextField` (sin `flutter_colorpicker`).
- **RNF-3 — i18n**: agregar claves en `app_strings.dart` (abstract) + 5 implementaciones (`es_bo.dart`, `en_us.dart`, `pt_br.dart`, `de_de.dart`, `fr_fr.dart`). Claves nuevas: `filamentColorLabel`, `filamentColorHelper`, `filamentColorCustom`, `filamentColorClear`, `filamentColorPickerTitle`, `filamentColorHexHelper`, `filamentColorInvalid`, `filamentColorName({name})` para los nombres de paleta, y los 17 nombres de colores (`colorNameRed`, etc.).
- **RNF-4 — Backup**: el `toJson()` de drift ya incluye columnas nuevas; backup/restore cubre el color automáticamente. Test: añadir caso al round-trip existente `test/unit/backup_roundtrip_test.dart` (color en filamento).
- **RNF-5 — Tests**: unit (repo create/update con color + null, hex parsing/validación, `kColorNameForHex`), widget (form con paleta, form con custom, edit prefill, lista con/sin color, selector con/sin color), integración (migración v10→v11). `flutter analyze` + `flutter test` verdes. Suite actual: 517/517.
- **RNF-6 — Accesibilidad**: cada swatch de la paleta con `Semantics(label: 'Rojo', button: true)`; el color custom con `Semantics(label: 'Personalizado')` + el texto del hex.
- **RNF-7 — Performance**: la lista no decodifica hex para cada render (helper trivial); avatar es un `Container` con `BoxDecoration(color: …)` (sin blur, sin shader).
- **RNF-8 — iOS/Web**: mismo código Flutter; el HSV slider funciona idéntico. Web: el `Slider` Material 3 funciona sin cambios.

## Success Criteria

El trabajo está completo cuando TODOS los siguientes son verdaderos:

- [ ] **SC1**: Crear filamento con color (paleta o custom) en form de settings y en onboarding funciona; el color persiste y se muestra en la lista.
- [ ] **SC2**: Editar filamento pre-muestra el color; se puede cambiar o quitar.
- [ ] **SC3**: Selector de filamentos del cotizador muestra el color como dot interior del avatar cuando aplica.
- [ ] **SC4**: Búsqueda por nombre de color filtra correctamente en lista y selector.
- [ ] **SC5**: Migración v10→v11 aditiva, sin pérdida de datos, verificada por test.
- [ ] **SC6**: Backup/restore preserva el color (verificado por test de round-trip).
- [ ] **SC7**: `flutter analyze` sin issues y `flutter test` 100% verde.

## Fuera de alcance

- Guardar múltiples colores por filamento (multicolor real). Un color por filamento.
- Sugerir color automáticamente desde la marca o nombre (no hay fuente de verdad).
- Exportar el color al PDF/PNG de la cotización (no pedido).
- Color en el detalle de la cotización (la pieza, no el filamento).
- Selector de color para impresoras.

## Open Questions

- ¿El slider HSV es demasiado técnico para el usuario promedio? Alternativa: solo la paleta + un "Color personalizado…" que abre un único slider H (matiz) y mantiene S/V al máximo. Más intuitivo, menos control. Decisión fina en implementación.
- ¿Mostrar el color en el PDF de cotización? Fuera de alcance por ahora (no pedido), pero el dato ya está disponible para futuro.
- ¿Traducción de los 17 nombres de color en los 5 locales? Sí (RNF-3); todos los locales deben tener los nombres. Si algún locale no tiene traducción natural, usar el nombre en inglés como fallback documentado.