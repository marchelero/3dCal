---
prd:
  - docs/PRD/2026-08-10-selectores-filamento-impresora.md
  - docs/PRD/2026-08-10-rediseno-configuracion-inicial.md
status: DRAFT
created: 2026-08-10_1530
---

# Plan de Implementación: FEATURE 1 (catálogo) + FEATURE 2 (onboarding) — 3dCal 2026-08-10

## Metadata

- **Plan ID**: `2026-08-10-implementation-plan-catalogo-onboarding`
- **PRDs origen**:
  - `docs/PRD/2026-08-10-selectores-filamento-impresora.md` — Feature ID `F-CAT-2026-08-10-A`
  - `docs/PRD/2026-08-10-rediseno-configuracion-inicial.md` — Feature ID `F-ONB-2026-08-10-A`
- **Stack**: Flutter 3.x, Riverpod 2.x (sin codegen, notifier manual), Drift SQLite (sin cambios de schema), Material 3, GoRouter, `package:decimal`, i18n custom `EsBO`/`EnImpl` singleton pattern, es_BO default.
- **Branch recomendada**: **una sola** `feat/catalog-and-onboarding-redesign`, con **dos PRs** secuenciales (`PR-1 catalog`, `PR-2 onboarding`). Razones:
  - FEATURE 1 phases son prerequisito estricto del paso 2 de FEATURE 2 (sub-secciones del stepper usan el nuevo `BrandSelectorField(domain: ...)`).
  - Mismo release, mismo QA cycle, mismas PR reviewers.
  - Si el repo exige atomicidad por PR, los commits se pueden reordenar con `git rebase -i` sin problemas.
- **Estimación rough**:
  - FEATURE 1 (Fases 1–4): **6–8 horas** (incluye tests).
  - FEATURE 2 (Fases 5–8): **10–14 horas** (incluye rediseño + 16 i18n keys + tests).
  - Verificación final + QA manual: **2 horas**.
  - **Total**: ~18–24 horas de trabajo enfocado (2 a 3 sesiones).
- **Coverage target global**:
  - `lib/shared/widgets/brand_selector_field.dart`: ≥80%
  - `lib/shared/widgets/k3d_brands.dart`: ≥80%
  - `lib/features/onboarding/presentation/pages/initial_config_page.dart`: ≥70%

---

## Orden de ejecución (Fases)

> FEATURE 1 fases van **primero** (prerequisito de FEATURE 2 paso 2).
> FEATURE 2 puede arrancar después de FASE 3 de FEATURE 1.
> El usuario autoriza merges parciales (cada fase mergeable independientemente).

### FASE 0 — Setup · 1 task

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 0.1 | Pre-flight: leer PRDs, leer este plan, leer archivos listados, verificar `flutter analyze` y `flutter test` limpios en `main`. | — | checkpoint |

### FASE 1 — FEATURE 1: Constantes de marca · 2 tasks

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 1.1 | Crear `lib/shared/widgets/k3d_brands.dart` con las dos constantes y el enum `BrandDomain`. | `lib/shared/widgets/k3d_brands.dart` | NUEVO |
| 1.2 | Tests unitarios de membresía, no-overlap (excepto Geeetech) y orden alfabético. | `test/unit/k3d_brands_test.dart` | NUEVO |

### FASE 2 — FEATURE 1: `BrandSelectorField` parametrizado · 2 tasks

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 2.1 | Refactor widget: agregar `BrandDomain domain` required, mover `kKnown3dBrands` a `k3d_brands.dart`, observar solo el notifier del dominio, deprecate `kKnown3dBrands`. | `lib/shared/widgets/brand_selector_field.dart` | MODIFICAR |
| 2.2 | Smoke widget tests (uno por dominio + caso "Otro..."). | `test/widget/brand_selector_field_test.dart` | NUEVO |

### FASE 3 — FEATURE 1: Forms reordenados + `initial_config_page` · 5 tasks

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 3.1 | `filament_form_page.dart`: mover `BrandSelectorField` a posición 0, pasar `domain: BrandDomain.filament`. | `lib/features/catalog/filaments/presentation/pages/filament_form_page.dart` | MODIFICAR |
| 3.2 | `printer_form_page.dart`: idem con `domain: BrandDomain.printer`. Label sigue `EsBO.filamentBrand` (decisión locked: no agregar `printerBrand` separado, mismo string "Marca"/"Brand"). | `lib/features/catalog/printers/presentation/pages/printer_form_page.dart` | MODIFICAR |
| 3.3 | `initial_config_page.dart`: las 2 invocaciones (`_printerBrandCtrl`, `_filamentBrandCtrl`) pasan `domain`. Sin otros cambios. | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 3.4 | Actualizar `filament_form_page_test.dart` para aserciones de orden (BrandSelectorField aparece ANTES del TextField Nombre). | `test/widget/filament_form_page_test.dart` | MODIFICAR |
| 3.5 | Extender `initial_config_stepper_test.dart` con 2 tests: dropdown impresora no muestra marcas exclusivas de filamento, dropdown filamento no muestra marcas exclusivas de impresora. | `test/widget/initial_config_stepper_test.dart` | MODIFICAR |

### FASE 4 — FEATURE 1: Final checks · 1 task

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 4.1 | `dart format --set-exit-if-changed lib/ test/`, `flutter analyze`, `flutter test`, smoke manual. | — | checkpoint |

### FASE 5 — FEATURE 2: 16 i18n keys · 3 tasks

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 5.1 | Agregar 16 getters abstractos a `AppStrings` (sección `// === Initial config redesign (T-F2) ===`). | `lib/l10n/app_strings.dart` | MODIFICAR |
| 5.2 | Implementar 16 strings en `EsImpl` (es_BO). | `lib/l10n/es_bo.dart` | MODIFICAR |
| 5.3 | Implementar 16 strings en `EnImpl` (en_US). | `lib/l10n/en_us.dart` | MODIFICAR |

### FASE 6 — FEATURE 2: Eliminar `OnboardingPage` · 3 tasks

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 6.1 | Eliminar archivo. | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | ELIMINAR |
| 6.2 | Limpiar router: remover ruta `/onboarding` y el import. | `lib/core/router/app_router.dart` | MODIFICAR |
| 6.3 | Eliminar 11 getters abstractos deprecated (`onboardingTitle1..4`, `onboardingDesc1..4`, `onboardingNext`, `onboardingSkip`, `onboardingStart`). También sus wrappers en `EsBO` y overrides en `EsImpl`/`EnImpl`. | `lib/l10n/app_strings.dart`, `lib/l10n/es_bo.dart`, `lib/l10n/en_us.dart` | MODIFICAR |

### FASE 7 — FEATURE 2: Rediseño `InitialConfigPage` · 9 tasks

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 7.1 | Reemplazar `_StepperIndicator` custom por `LinearProgressIndicator` M3. Eliminar las clases `_StepperIndicator` y `_StepCircle` completas (líneas 554–662 del archivo actual). | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.2 | Refactor `_Step1Content`: agregar helpers (`configLanguageHelper`, `configCurrencyHelper`). Subtítulo opcional del paso arriba. | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.3 | Refactor `_buildStep2`: agregar `configPrinterSectionHelper` y `configFilamentSectionHelper`. La sub-sección impresora ahora es `Brand → Modelo → Watts` (orden ya viene de FEATURE 1 — el form de impresora reordenado). Misma lógica para filamento. | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.4 | Refactor `_buildStep3`: agregar chip "Típico" al lado de los inputs de profit y kWh cuando el valor coincide con el default (`200` y `0.7`). | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.5 | Agregar bloque "Resumen" al final del paso 3: card `tertiaryContainer` con 6 filas (idioma, moneda, impresora, filamento, ganancia, kWh) usando los getters de `EsBO` existentes + la nueva `configSummaryImprint`. | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.6 | Agregar slide motivacional breve (`configSummaryImprint`) entre el bloque "Resumen" y el botón "Empezar a cotizar". Un solo Card con icono `celebration` y una frase. | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.7 | Cambiar `_finish()`: `GoRouter.of(context).go('/onboarding')` → `GoRouter.of(context).go('/')`. El flag `SettingsKeys.onboardingDone` se sigue seteando. | `lib/features/onboarding/presentation/pages/initial_config_page.dart` | MODIFICAR |
| 7.8 | Actualizar 4 tests existentes + agregar tests nuevos para: microcopy no-vacía, chip Típico aparece/desaparece, navegación final va a `/` (no `/onboarding`). | `test/widget/initial_config_stepper_test.dart` | MODIFICAR |
| 7.9 | Verificar con `grep -r "_StepperIndicator" lib/` retorna 0 resultados. | — | checkpoint |

### FASE 8 — Verificación final · 1 task

| # | Task | Archivo | Tipo |
|---|---|---|---|
| 8.1 | `dart format`, `flutter analyze`, `flutter test`, smoke manual en Android emulator, smoke en Web (opcional). | — | checkpoint |

**Total tasks: 26** (distribuidos en 9 fases).

---

## Implementation Steps (detallado)

### FASE 0 — Setup

#### Task 0.1 — Pre-flight checks

- **Acción**:
  - `cd /home/marcelo/dev/otro/3dCal && flutter pub get`
  - `flutter analyze` debe retornar 0 issues (excepto warnings pre-existentes documentados)
  - `flutter test --no-pub --reporter=compact` debe pasar todo
  - `git status` debe estar limpio o solo con cambios no relacionados
- **Why**: baseline limpio antes de empezar. Si hay errores pre-existentes, registrarlos como "pre-existing" para no atribuirlos a este PR.
- **Dependencies**: ninguna.
- **Risk**: Bajo. Si falla, abortar y reportar al usuario.

---

### FASE 1 — FEATURE 1: Constantes de marca

#### Task 1.1 — Crear `k3d_brands.dart`

- **Archivo**: `lib/shared/widgets/k3d_brands.dart` (NUEVO)
- **Snippet de la sección clave**:

```dart
/// Dominio del selector de marca.
///
/// Parametriza [BrandSelectorField] para que observe solo el notifier
/// correspondiente y muestre solo la lista de marcas de ese dominio.
enum BrandDomain {
  /// Marcas de filamentos (PLA, PETG, ABS, …).
  filament,

  /// Marcas de impresoras (FDM, resina, etc).
  printer,
}

/// Marcas conocidas de filamentos. Ordenadas alfabéticamente.
///
/// Lista cerrada. Para agregar una marca, agregar al final del array.
/// **No duales**: si una marca vende filamentos Y otra cosa (ej: Geeetech),
/// va SOLO en la lista donde es más conocida (ver decision A2 del PRD-1).
const List<String> kKnownFilamentBrands = [
  'Amolen',
  'Eryone',
  'eSun',
  'Geeetech',
  'Hatchbox',
  'Kingroon',
  'Overture',
  'Polymaker',
  'Prusament',
  'Sunlu',
];

/// Marcas conocidas de impresoras. Ordenadas alfabéticamente.
const List<String> kKnownPrinterBrands = [
  'Anycubic',
  'Artillery',
  'Bambu Lab',
  'Creality',
  'Elegoo',
  'Flashforge',
  'Geeetech',
  'Longer',
  'MakerBot',
  'Prusa',
  'Qidi',
  'Raise3D',
  'Snapmaker',
  'Sovol',
  'Tronxy',
  'Ultimaker',
  'Voxelab',
  'Voron',
  'FLSun',
];

/// Marcas clasificadas (auditoría).
///
/// Útil para tests y para futuro tooling (CLI, export).
const Map<String, BrandDomain> kBrandClassification = {
  // Filamentos
  'Amolen': BrandDomain.filament,
  'Eryone': BrandDomain.filament,
  'eSun': BrandDomain.filament,
  'Geeetech': BrandDomain.printer, // printer-only por decision A2 del PRD-1
  'Hatchbox': BrandDomain.filament,
  'Kingroon': BrandDomain.filament,
  'Overture': BrandDomain.filament,
  'Polymaker': BrandDomain.filament,
  'Prusament': BrandDomain.filament,
  'Sunlu': BrandDomain.filament,
  // Impresoras
  'Anycubic': BrandDomain.printer,
  'Artillery': BrandDomain.printer,
  'Bambu Lab': BrandDomain.printer,
  'Creality': BrandDomain.printer,
  'Elegoo': BrandDomain.printer,
  'Flashforge': BrandDomain.printer,
  'Longer': BrandDomain.printer,
  'MakerBot': BrandDomain.printer,
  'Prusa': BrandDomain.printer,
  'Qidi': BrandDomain.printer,
  'Raise3D': BrandDomain.printer,
  'Snapmaker': BrandDomain.printer,
  'Sovol': BrandDomain.printer,
  'Tronxy': BrandDomain.printer,
  'Ultimaker': BrandDomain.printer,
  'Voxelab': BrandDomain.printer,
  'Voron': BrandDomain.printer,
  'FLSun': BrandDomain.printer,
};
```

- **Acceptance criteria**:
  - Archivo compila (`dart analyze` clean).
  - Constantes exportadas (`kKnownFilamentBrands`, `kKnownPrinterBrands`, `kBrandClassification`).
  - Orden alfabético verificable con test (Task 1.2).
  - `Geeetech` aparece en **solo una** lista (la de impresoras) y el `Map` lo confirma.
- **Dependencies**: ninguna.
- **Risk**: Bajo. Sin imports externos (solo `enum` + `const`).
- **Out of scope** (mencionado para awareness): `kBrandClassification` se podría usar en el futuro para tooling. No se usa en runtime todavía — solo tests.

#### Task 1.2 — Tests de `k3d_brands`

- **Archivo**: `test/unit/k3d_brands_test.dart` (NUEVO)
- **Tests a incluir** (nombre + aserción clave):
  1. `kKnownFilamentBrands contiene exactamente 10 marcas`
     - `expect(kKnownFilamentBrands, hasLength(10))`
     - `expect(kKnownFilamentBrands, containsAll(['eSun', 'Hatchbox', 'Polymaker', 'Prusament', 'Sunlu', 'Eryone', 'Overture', 'Kingroon', 'Amolen', 'Geeetech']))`
  2. `kKnownPrinterBrands contiene exactamente 19 marcas`
     - `expect(kKnownPrinterBrands, hasLength(19))`
     - Verificar presencia de `Voron`, `Creality`, `Bambu Lab`, `Prusa`, `MakerBot`, `Tronxy`, `Longer`, `FLSun`, `Snapmaker`, `Geeetech`, etc.
  3. `no overlap entre listas excepto Geeetech`
     - `final intersection = kKnownFilamentBrands.toSet().intersection(kKnownPrinterBrands.toSet()); expect(intersection, {'Geeetech'});`
  4. `Geeetech no aparece en kKnownFilamentBrands`
     - `expect(kKnownFilamentBrands, isNot(contains('Geeetech')))`
     - (Este test es **REDUNDANTE** con el 3 pero defensivo.)
  5. `ambas listas están ordenadas alfabéticamente`
     - `final sortedFil = [...kKnownFilamentBrands]..sort(); expect(kKnownFilamentBrands, equals(sortedFil));`
     - Idem printer.
  6. `kBrandClassification es coherente con las listas`
     - Para cada marca en `kKnownFilamentBrands`, `kBrandClassification[m] == BrandDomain.filament`.
     - Idem printer (excepto Geeetech que es `printer`).
  7. `kBrandClassification tiene exactamente las marcas únicas`
     - `expect(kBrandClassification.keys.toSet().difference(kKnownFilamentBrands.toSet().union(kKnownPrinterBrands.toSet())), isEmpty);`
- **Acceptance criteria**: 7 tests pasan. Suite completa pasa.
- **Dependencies**: Task 1.1.
- **Risk**: Bajo.

---

### FASE 2 — FEATURE 1: `BrandSelectorField` parametrizado

#### Task 2.1 — Refactor del widget

- **Archivo**: `lib/shared/widgets/brand_selector_field.dart` (MODIFICAR)
- **Cambios concretos**:
  1. **Importar** `k3d_brands.dart` y remover la constante `kKnown3dBrands` local.
  2. **Agregar** `import 'package:tresdcal/shared/widgets/k3d_brands.dart';`
  3. **Agregar** enum `BrandDomain` (o importarlo desde `k3d_brands.dart`).
  4. **Modificar** constructor para aceptar `required this.domain`:
     ```dart
     const BrandSelectorField({
       super.key,
       required this.domain, // NUEVO: required
       required this.controller,
       this.validator,
       this.label,
       this.helperText,
       this.enabled = true,
     });

     final BrandDomain domain;
     ```
  5. **Modificar** `_registeredBrands(ref)` para observar SOLO el notifier del dominio:
     ```dart
     Set<String> _registeredBrands(WidgetRef ref) {
       final brands = <String>{};
       switch (widget.domain) {
         case BrandDomain.filament:
           final filaments = ref.watch(filamentsNotifierProvider).value;
           for (final f in filaments ?? const <Filament>[]) {
             final b = f.brand;
             if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
           }
           break;
         case BrandDomain.printer:
           final printers = ref.watch(printersNotifierProvider).value;
           for (final p in printers ?? const <PrinterProfile>[]) {
             final b = p.brand;
             if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
           }
           break;
       }
       return brands;
     }
     ```
  6. **Modificar** `_options(ref)` para usar la lista correcta según dominio:
     ```dart
     List<String> _options(WidgetRef ref) {
       final known = widget.domain == BrandDomain.filament
           ? kKnownFilamentBrands
           : kKnownPrinterBrands;
       final all = <String>{...known, ..._registeredBrands(ref)};
       return all.toList()..sort();
     }
     ```
  7. **Eliminar** la constante local `kKnown3dBrands` (líneas 15–37 actuales).
  8. **Verificar** que el resto del widget (modo manual "Otro...", `_forceOther`, etc.) sigue igual — sin cambios.
- **Acceptance criteria**:
  - Widget compila con firma actualizada.
  - `BrandSelectorField` con `domain: BrandDomain.filament` NO observa `printersNotifierProvider` (verificable con `ProviderObserver` o leyendo el código).
  - Idem en sentido inverso.
  - `kKnown3dBrands` ya no existe en este archivo (grep `kKnown3dBrands lib/shared/widgets/brand_selector_field.dart` retorna 0).
- **Dependencies**: Task 1.1.
- **Risk**: **Medio**. Cambio de firma → 4 call sites deben actualizarse al mismo tiempo (Tasks 3.1, 3.2, 3.3). Si se commitea esto sin actualizar los call sites, `flutter analyze` rompe.
- **Mitigación**: NO commitear Task 2.1 sin antes actualizar al menos un call site. Hacer el cambio como un solo commit lógico (o squash al final).

#### Task 2.2 — Tests del widget

- **Archivo**: `test/widget/brand_selector_field_test.dart` (NUEVO)
- **Tests a incluir** (nombre + aserción clave):
  1. `domain: filament, dropdown contiene marcas de filamentos`
     - Pump con `domain: BrandDomain.filament`.
     - Sembrar DB con `FilamentsCompanion.insert(brand: Value('eSun'))`.
     - Tap el dropdown.
     - `expect(find.text('eSun'), findsWidgets);`
     - `expect(find.text('Voron'), findsNothing);` (Voron es printer-only).
  2. `domain: printer, dropdown contiene marcas de impresoras`
     - Pump con `domain: BrandDomain.printer`.
     - Sembrar DB con `PrinterProfilesCompanion.insert(brand: Value('Voron'))`.
     - `expect(find.text('Voron'), findsWidgets);`
     - `expect(find.text('eSun'), findsNothing);` (eSun es filament-only).
  3. `domain: filament, no observa printersNotifierProvider`
     - Usar `ProviderObserver` (subclass en el test) que cuente `didAddProvider`.
     - Pump con `domain: filament`. Verificar que `printersNotifierProvider` no aparece en `addedProviders`.
     - Idem inverso para `domain: printer`.
  4. `modo Otro: aparece TextFormField manual con valor del controller`
     - Pump con `domain: filament`, `controller.text = 'MakerBot'`.
     - `expect(find.byType(TextFormField), findsOneWidget);` (no Dropdown porque MakerBot no está en la lista de filamentos).
     - `expect(find.text('MakerBot'), findsOneWidget);`
  5. `modo Otro: elegir del dropdown activa TextFormField manual`
     - Pump, tap el dropdown, tap "Otro...".
     - `expect(find.byType(TextFormField), findsOneWidget);` (dropdown reemplazado por TextFormField).
- **Acceptance criteria**: 5 tests pasan. `flutter analyze` clean.
- **Dependencies**: Task 2.1.
- **Risk**: Bajo. Patrón de pump ya existe (ver `filament_form_page_test.dart`).

---

### FASE 3 — FEATURE 1: Forms reordenados + `initial_config_page`

#### Task 3.1 — `filament_form_page.dart`

- **Archivo**: `lib/features/catalog/filaments/presentation/pages/filament_form_page.dart` (MODIFICAR)
- **Cambio concreto**: mover `BrandSelectorField` al **inicio** del `ListView`, ANTES del `TextFormField` de nombre. Pasar `domain: BrandDomain.filament`.

  - **Snippet del cambio** (estructura del `ListView` antes y después):

    **Antes** (líneas 156–165):
    ```dart
    children: [
      TextFormField(
        controller: _nameCtrl,
        decoration: InputDecoration(
          labelText: EsBO.filamentName,
          helperText: EsBO.filamentNameHelper,
        ),
        textInputAction: TextInputAction.next,
        validator: _requiredText,
      ),
      const SizedBox(height: AppSpacing.lg),
      BrandSelectorField(
        controller: _brandCtrl,
        label: EsBO.filamentBrand,
        helperText: EsBO.filamentBrandHelper,
        validator: _optionalText,
      ),
      // ... resto igual
    ]
    ```

    **Después**:
    ```dart
    children: [
      BrandSelectorField(
        domain: BrandDomain.filament, // NUEVO
        controller: _brandCtrl,
        label: EsBO.filamentBrand,
        helperText: EsBO.filamentBrandHelper,
        validator: _optionalText,
      ),
      const SizedBox(height: AppSpacing.lg),
      TextFormField(
        controller: _nameCtrl,
        decoration: InputDecoration(
          labelText: EsBO.filamentName,
          helperText: EsBO.filamentNameHelper,
        ),
        textInputAction: TextInputAction.next,
        validator: _requiredText,
      ),
      // ... resto igual (precio, gramos, switch, botón)
    ]
    ```

- **Acceptance criteria**:
  - `flutter analyze` clean.
  - El orden visual de campos en el form es: Marca → Nombre → Precio → Gramos → Switch default → Guardar.
  - `BrandSelectorField` aparece con `domain: BrandDomain.filament`.
  - Modo "Otro..." sigue funcionando (regresión).
- **Dependencies**: Task 2.1.
- **Risk**: Bajo. Cambio puramente cosmético de orden.

#### Task 3.2 — `printer_form_page.dart`

- **Archivo**: `lib/features/catalog/printers/presentation/pages/printer_form_page.dart` (MODIFICAR)
- **Cambio concreto**: análogo a Task 3.1. `BrandSelectorField` con `domain: BrandDomain.printer` va al inicio. Label sigue siendo `EsBO.filamentBrand` (mismo string "Marca"/"Brand" en ambos idiomas — **no agregar `printerBrand` separado** por decisión locked).
- **Acceptance criteria**: idem Task 3.1, pero para impresora.
- **Dependencies**: Task 2.1.
- **Risk**: Bajo.

#### Task 3.3 — `initial_config_page.dart` (solo 2 invocaciones)

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambios concretos**:
  - Importar `k3d_brands.dart`: `import '../../../../shared/widgets/k3d_brands.dart';`
  - En `_buildStep2` (línea ~372 del archivo actual, sub-sección impresora):
    ```dart
    BrandSelectorField(
      domain: BrandDomain.printer, // NUEVO
      controller: _printerBrandCtrl,
      label: EsBO.filamentBrand,
      helperText: EsBO.printerBrandHelper,
    ),
    ```
  - En `_buildStep2` (línea ~433 del archivo actual, sub-sección filamento):
    ```dart
    BrandSelectorField(
      domain: BrandDomain.filament, // NUEVO
      controller: _filamentBrandCtrl,
      label: EsBO.filamentBrand,
      helperText: EsBO.filamentBrandHelper,
    ),
    ```
- **NO hacer** otros cambios en este archivo durante FEATURE 1. El rediseño completo (LinearProgressIndicator, microcopy, chips, bloque Resumen) vive en FASE 7 de FEATURE 2.
- **Acceptance criteria**:
  - Las 2 invocaciones especifican `domain` correcto.
  - `flutter analyze` clean.
  - El resto del archivo (stepper, _StepperIndicator, _savePrinter, _saveFilament) **NO cambia** en esta fase.
- **Dependencies**: Task 2.1.
- **Risk**: Bajo.

#### Task 3.4 — Actualizar `filament_form_page_test.dart`

- **Archivo**: `test/widget/filament_form_page_test.dart` (MODIFICAR)
- **Cambios concretos**:
  1. Test `'muestra los 4 inputs numericos + switch default'` (línea 47–62): agregar aserción del ORDEN. Reemplazar:
     ```dart
     expect(find.widgetWithText(TextField, 'Nombre'), findsOneWidget);
     expect(find.byType(BrandSelectorField), findsOneWidget);
     ```
     por:
     ```dart
     // BrandSelectorField aparece ANTES del TextField de Nombre.
     final brandFinder = find.byType(BrandSelectorField);
     final nameFinder = find.widgetWithText(TextField, 'Nombre');
     expect(brandFinder, findsOneWidget);
     expect(nameFinder, findsOneWidget);
     final brandCenter = tester.getCenter(brandFinder);
     final nameCenter = tester.getCenter(nameFinder);
     expect(brandCenter.dy < nameCenter.dy, isTrue,
         reason: 'Marca debe aparecer arriba del campo Nombre');
     ```
  2. Test `'guardar valido crea y cierra'` (líneas 71–93): funciona tal cual (no cambia flujo, solo orden).
  3. Test `'guardar invalido muestra errores'`: sin cambios.
- **Acceptance criteria**: suite completa pasa.
- **Dependencies**: Task 3.1.
- **Risk**: Bajo.

#### Task 3.5 — Extender `initial_config_stepper_test.dart`

- **Archivo**: `test/widget/initial_config_stepper_test.dart` (MODIFICAR)
- **Cambios concretos**:
  1. Agregar 2 tests al final del `group` existente:
     ```dart
     testWidgets('paso 2: dropdown impresora solo muestra marcas de impresoras',
         (tester) async {
       final container = await _pumpStepper(tester);
       await tester.tap(find.text('Continuar'));
       await tester.pumpAndSettle();
       // Localizar el primer BrandSelectorField (es el de impresora).
       final brandFields = find.byType(BrandSelectorField);
       expect(brandFields, findsNWidgets(2));
       await tester.tap(brandFields.first);
       await tester.pumpAndSettle();
       // Voron y Creality deben estar; Hatchbox y Prusament NO.
       expect(find.text('Voron').evaluate().isNotEmpty, isTrue);
       expect(find.text('Creality').evaluate().isNotEmpty, isTrue);
       expect(find.text('Hatchbox'), findsNothing);
       expect(find.text('Prusament'), findsNothing);
       expect(find.text('eSun'), findsNothing);
     });

     testWidgets('paso 2: dropdown filamento solo muestra marcas de filamentos',
         (tester) async {
       final container = await _pumpStepper(tester);
       await tester.tap(find.text('Continuar'));
       await tester.pumpAndSettle();
       final brandFields = find.byType(BrandSelectorField);
       await tester.tap(brandFields.at(1)); // El segundo es filamento.
       await tester.pumpAndSettle();
       expect(find.text('Hatchbox').evaluate().isNotEmpty, isTrue);
       expect(find.text('Prusament').evaluate().isNotEmpty, isTrue);
       expect(find.text('Voron'), findsNothing);
       expect(find.text('Creality'), findsNothing);
       expect(find.text('Bambu Lab'), findsNothing);
     });
     ```
- **Acceptance criteria**: 6 tests en el group pasan (4 existentes + 2 nuevos).
- **Dependencies**: Task 3.3.
- **Risk**: Bajo. Patrón `pumpStepper` ya existe.

---

### FASE 4 — FEATURE 1: Final checks

#### Task 4.1 — Verificación pre-merge

- **Acciones**:
  - `dart format --set-exit-if-changed lib/ test/`
  - `flutter analyze` (esperado: 0 issues)
  - `flutter test --no-pub --reporter=expanded` (esperado: todos pasan)
  - Smoke manual: abrir la app, ir a Ajustes → Catálogos → Filamentos → FAB, verificar orden Marca → Nombre → Precio → Gramos → Switch.
  - Idem para Impresoras.
  - Verificar que el calculator picker (`filament_selector_dialog`, `printer_selector_dialog`) **NO cambió** (Q1: NO cambiar).
  - `grep -r "kKnown3dBrands" lib/` debe retornar 0 (la constante debe estar eliminada).
- **Acceptance criteria**: todo verde.
- **Dependencies**: Tasks 3.1–3.5.
- **Risk**: Bajo. Si falla, fix y re-run.

---

### FASE 5 — FEATURE 2: 16 i18n keys

#### Task 5.1 — Agregar getters abstractos

- **Archivo**: `lib/l10n/app_strings.dart` (MODIFICAR)
- **Acción**: agregar después de la línea 359 (después de `String get configFilamentSaved;`) una nueva sección:
  ```dart
  // === Initial config redesign (F2 — 2026-08-10) ===
  /// Subtítulo del paso 1.
  String get configStepSubtitle1;
  /// Subtítulo del paso 2.
  String get configStepSubtitle2;
  /// Subtítulo del paso 3.
  String get configStepSubtitle3;
  /// Contador visible: "Paso $step de $total" / "Step $step of $total".
  String configStepCounter(int step, int total);
  /// Helper del campo Idioma en paso 1.
  String get configLanguageHelper;
  /// Helper del campo Moneda en paso 1.
  String get configCurrencyHelper;
  /// Helper de la sección Impresora en paso 2.
  String get configPrinterSectionHelper;
  /// Helper de la sección Filamento en paso 2.
  String get configFilamentSectionHelper;
  /// Helper del campo Ganancia en paso 3.
  String get configProfitHelper;
  /// Helper del campo kWh en paso 3.
  String get configKwhHelper;
  /// Chip "Típico" junto a los defaults de profit/kWh.
  String get settingsDefaultTypical;
  /// Estado cuando filamento fue salteado: "Sin filamento — agregar después".
  String get configFilamentSkipStatus;
  /// CTA "Agregar filamento" (mismo texto que configAddFilament, pero semánticamente separado).
  String get configFilamentAddAction;
  /// CTA final del paso 3: "Empezar a cotizar" / "Start quoting".
  String get configStartButton;
  /// Título del bloque Resumen al final del paso 3.
  String get configSummaryTitle;
  /// Slide motivacional breve antes del CTA final: "Tu próxima cotización:" / "Your next quote:".
  String get configSummaryImprint;
  ```
- **Acceptance criteria**: archivo compila. Los 16 getters están en la interfaz.
- **Dependencies**: ninguna.
- **Risk**: Bajo. Si los implementadores no agregan overrides en `EsImpl`/`EnImpl`, `flutter analyze` rompe → eso fuerza completar Tasks 5.2 y 5.3 antes de commitear.

#### Task 5.2 — Implementar en `EsImpl`

- **Archivo**: `lib/l10n/es_bo.dart` (MODIFICAR)
- **Acción**: agregar 16 overrides en la clase `EsImpl` (al final, después de línea 1318). Valores exactos del PRD-2 §10:

  | Key | Valor es_BO |
  |---|---|
  | `configStepSubtitle1` | `'Empecemos por lo básico.'` |
  | `configStepSubtitle2` | `'Empecemos por lo que usás para imprimir. La impresora es necesaria para el costo de energía.'` |
  | `configStepSubtitle3` | `'Estos valores se usan en cada cotización. Los podés cambiar después.'` |
  | `configStepCounter(int s, int t)` | `'Paso $s de $t'` |
  | `configLanguageHelper` | `'Elegí el idioma de la app. Podés cambiarlo después.'` |
  | `configCurrencyHelper` | `'Moneda en que se muestran precios y cotizaciones. No convierte valores.'` |
  | `configPrinterSectionHelper` | `'La necesitamos para calcular el costo de energía de cada impresión.'` |
  | `configFilamentSectionHelper` | `'Si tenés el rollo a mano, anotalo ahora. Si no, podés agregarlo desde Ajustes → Catálogos.'` |
  | `configProfitHelper` | `'Margen sobre el costo base. 200% duplica el costo. Típico: 100%–300%.'` |
  | `configKwhHelper` | `'Tarifa de tu factura eléctrica. Típico: 0.5–1.5 BOB/kWh.'` |
  | `settingsDefaultTypical` | `'Típico'` |
  | `configFilamentSkipStatus` | `'Sin filamento — agregar después'` |
  | `configFilamentAddAction` | `'Agregar filamento'` |
  | `configStartButton` | `'Empezar a cotizar'` |
  | `configSummaryTitle` | `'Resumen'` |
  | `configSummaryImprint` | `'Tu próxima cotización:'` |

- **Acceptance criteria**: `flutter analyze` retorna 0 missing overrides (los 16 deben estar).
- **Dependencies**: Task 5.1.
- **Risk**: Bajo.

#### Task 5.3 — Implementar en `EnImpl`

- **Archivo**: `lib/l10n/en_us.dart` (MODIFICAR)
- **Acción**: agregar 16 overrides en la clase `EnImpl`. Valores en inglés (tomar del PRD-2 §10):

  | Key | Valor en_US |
  |---|---|
  | `configStepSubtitle1` | `'Let\'s start with the basics.'` |
  | `configStepSubtitle2` | `'Let\'s start with what you use to print. The printer is required for energy cost.'` |
  | `configStepSubtitle3` | `'These values apply to every quote. You can change them later.'` |
  | `configStepCounter(int s, int t)` | `'Step $s of $t'` |
  | `configLanguageHelper` | `'Choose the app language. You can change it later.'` |
  | `configCurrencyHelper` | `'Currency used for prices and quotes. Does not convert values.'` |
  | `configPrinterSectionHelper` | `'We need it to calculate the energy cost of each print.'` |
  | `configFilamentSectionHelper` | `'If you have the spool handy, add it now. Otherwise, add it later from Settings → Catalogues.'` |
  | `configProfitHelper` | `'Margin over base cost. 200% doubles the cost. Typical: 100%–300%.'` |
  | `configKwhHelper` | `'Your electricity bill rate. Typical: 0.5–1.5 BOB/kWh.'` |
  | `settingsDefaultTypical` | `'Typical'` |
  | `configFilamentSkipStatus` | `'No filament — add later'` |
  | `configFilamentAddAction` | `'Add filament'` |
  | `configStartButton` | `'Start quoting'` |
  | `configSummaryTitle` | `'Summary'` |
  | `configSummaryImprint` | `'Your next quote:'` |

- **Acceptance criteria**: `flutter analyze` retorna 0 missing overrides.
- **Dependencies**: Task 5.1.
- **Risk**: Bajo.

> **Sugerencia de commit**: Tasks 5.1 + 5.2 + 5.3 van en un solo commit (`feat(i18n): add 16 keys for onboarding redesign`) — sin esto el código no compila.

---

### FASE 6 — FEATURE 2: Eliminar `OnboardingPage`

#### Task 6.1 — Eliminar archivo

- **Archivo**: `lib/features/onboarding/presentation/pages/onboarding_page.dart` (ELIMINAR)
- **Acción**: `git rm lib/features/onboarding/presentation/pages/onboarding_page.dart`
- **Acceptance criteria**: archivo borrado del filesystem y del index.
- **Dependencies**: ninguna (pero requiere Task 6.2 antes de compilar).
- **Risk**: Bajo. Si Task 6.2 no se hace primero, `flutter analyze` rompe (referencia rota).

#### Task 6.2 — Limpiar router

- **Archivo**: `lib/core/router/app_router.dart` (MODIFICAR)
- **Cambios concretos**:
  1. Remover import: `import '../../features/onboarding/presentation/pages/onboarding_page.dart';`
  2. Remover el bloque:
     ```dart
     GoRoute(
       path: '/onboarding',
       builder: (context, state) => const OnboardingPage(),
     ),
     ```
- **Acceptance criteria**: `flutter analyze` clean. La ruta `/onboarding` ya no es válida (cualquier redirect a ella caería en `_RouterErrorPage`).
- **Dependencies**: Task 6.1 (orden lógico).
- **Risk**: Bajo. Verificar con `grep -r "OnboardingPage" lib/` que no queden referencias (debería ser 0).

#### Task 6.3 — Eliminar keys deprecated

- **Archivos**: `lib/l10n/app_strings.dart`, `lib/l10n/es_bo.dart`, `lib/l10n/en_us.dart` (MODIFICAR)
- **Acción**: remover los 11 getters deprecated:
  - `onboardingTitle1`, `onboardingTitle2`, `onboardingTitle3`, `onboardingTitle4`
  - `onboardingDesc1`, `onboardingDesc2`, `onboardingDesc3`, `onboardingDesc4`
  - `onboardingNext`, `onboardingSkip`, `onboardingStart`
- **Acceptance criteria**:
  - `flutter analyze` retorna 0 missing overrides (los 11 deben estar **eliminados** de la interfaz).
  - `grep -r "onboardingTitle\|onboardingDesc\|onboardingNext\|onboardingSkip\|onboardingStart" lib/` retorna 0 resultados.
- **Dependencies**: Task 6.1 (la única referencia real era `onboarding_page.dart`).
- **Risk**: Bajo. Las keys no se usan en ningún otro lugar del runtime.

> **Sugerencia de commit**: Tasks 6.1 + 6.2 + 6.3 van en un solo commit (`refactor(onboarding): remove OnboardingPage 4-slides + deprecated i18n keys`).

---

### FASE 7 — FEATURE 2: Rediseño `InitialConfigPage`

> **Convención**: este archivo pasa de **889 líneas → ~450–500 líneas**. La reducción viene principalmente de eliminar `_StepperIndicator` (~107 líneas) y simplificar `_buildStep2` con microcopy externa.
>
> **No** extraer widgets nuevos (`_ConfigProgressBar`, `_ConfigSection`, `_TypicalValueChip`, `_ConfigSummaryCard`) a menos que la implementación lo justifique (regla YAGNI). Inline widgets privados en el mismo archivo son aceptables.

#### Task 7.1 — Reemplazar `_StepperIndicator` con `LinearProgressIndicator`

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambios concretos**:
  1. En el método `build` (línea 260–268), reemplazar:
     ```dart
     // Stepper indicator
     _StepperIndicator(
       currentStep: _step,
       totalSteps: _totalSteps,
       labels: [
         EsBO.configStep1Title,
         EsBO.configStep2Title,
         EsBO.configStep3Title,
       ],
     ),
     const SizedBox(height: AppSpacing.xxl),
     ```
     por:
     ```dart
     // Indicador de progreso M3 nativo
     Semantics(
       label: EsBO.configStepCounter(_step + 1, _totalSteps),
       child: LinearProgressIndicator(
         value: (_step + 1) / _totalSteps,
         minHeight: 6,
         borderRadius: BorderRadius.circular(AppSpacing.sm),
       ),
     ),
     const SizedBox(height: AppSpacing.md),
     // Subtítulo contextual del paso actual
     Text(
       _stepSubtitle(),
       style: theme.textTheme.bodyMedium?.copyWith(
         color: color.onSurfaceVariant,
       ),
     ),
     const SizedBox(height: AppSpacing.xxl),
     ```
  2. Agregar helper privado:
     ```dart
     String _stepSubtitle() {
       switch (_step) {
         case 0: return EsBO.configStepSubtitle1;
         case 1: return EsBO.configStepSubtitle2;
         default: return EsBO.configStepSubtitle3;
       }
     }
     ```
  3. **Eliminar** las clases `_StepperIndicator` y `_StepCircle` completas (líneas 554–662 actuales, ~107 líneas).
  4. **Eliminar** el import no usado `import '../../../../core/theme/app_radii.dart';` si quedó huérfano (verificar con grep).
- **Acceptance criteria**:
  - `grep -r "_StepperIndicator" lib/` retorna 0 resultados.
  - `grep -r "_StepCircle" lib/` retorna 0 resultados.
  - `LinearProgressIndicator` aparece exactamente 1 vez en el archivo (en el header).
  - `flutter analyze` clean.
- **Dependencies**: Task 5.1 (necesita `configStepSubtitle1/2/3` y `configStepCounter`).
- **Risk**: Bajo. Reemplazo 1:1.

#### Task 7.2 — Refactor `_Step1Content` con helpers

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambio concreto**: en `_Step1Content.build` (líneas 666–711), agregar `helperText` a las dos secciones:
  ```dart
  // SegmentedButton idioma
  SegmentedButton<AppLocale>(
    // ... igual
  ),
  const SizedBox(height: AppSpacing.sm),
  Text(
    EsBO.configLanguageHelper,
    style: theme.textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
  ),
  const SizedBox(height: AppSpacing.xxl),
  // Dropdown moneda
  _CurrencyDropdown(),
  const SizedBox(height: AppSpacing.sm),
  Text(
    EsBO.configCurrencyHelper,
    style: theme.textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
  ),
  ```
- **Acceptance criteria**: ambas helpers visibles en es_BO. `flutter analyze` clean.
- **Dependencies**: Task 5.1.
- **Risk**: Bajo.

#### Task 7.3 — Refactor `_buildStep2` con helpers

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambio concreto**: agregar `configPrinterSectionHelper` debajo del `_StepSectionHeader` de impresora, y `configFilamentSectionHelper` debajo del de filamento:
  ```dart
  // Sub-sección impresora
  _StepSectionHeader(
    icon: Icons.print_rounded,
    title: EsBO.configPrinterRequired,
    color: color.primary,
  ),
  const SizedBox(height: AppSpacing.sm),
  Text(
    EsBO.configPrinterSectionHelper,
    style: theme.textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
  ),
  const SizedBox(height: AppSpacing.md),
  // ... resto del form (la marca ya viene primero por FEATURE 1)
  ```
  Análogo para filamento.
- **Acceptance criteria**: ambas helpers visibles. La sub-sección filamento cuando está skipped muestra `EsBO.configFilamentSkipStatus` en lugar del texto actual.
- **Dependencies**: Task 7.2, Task 3.3 (orden de inputs ya viene de FEATURE 1).
- **Risk**: Bajo.

#### Task 7.4 — Refactor `_buildStep3` con chip "Típico"

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambio concreto**: envolver cada `NumericInputField` en un `Row` con un `Chip` condicional:
  ```dart
  // Constantes para defaults (mismos que el notifier)
  static const _kDefaultProfit = 200;
  static const _kDefaultKwh = 0.7;

  // Helper privado
  bool _showTypicalChip(String raw, num defaultValue) {
    final parsed = Decimal.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null) return false;
    return parsed == Decimal.parse(defaultValue.toString());
  }

  Widget _buildTypicalChip({required bool visible}) {
    return visible
        ? Chip(
            label: Text(EsBO.settingsDefaultTypical),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        : const SizedBox.shrink();
  }

  // Dentro de _buildStep3:
  Row(
    children: [
      Expanded(
        child: NumericInputField(
          label: EsBO.settingsProfitBase,
          controller: _profitCtrl,
          // ... resto
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      _buildTypicalChip(
        visible: _showTypicalChip(_profitCtrl.text, _kDefaultProfit),
      ),
    ],
  ),
  ```
  Idem para kWh con `_kDefaultKwh`. El chip debe **re-evaluarse** en cada rebuild — agregar listener en `_profitCtrl` y `_kwhCtrl` con `addListener(() => setState(() {}))` en `initState`.
- **Acceptance criteria**:
  - Con `_profitCtrl.text == '200'`: chip "Típico" visible.
  - Con `_profitCtrl.text == '250'`: chip "Típico" NO visible.
  - Idem para kWh (0.7 / 0.85).
- **Dependencies**: Task 5.1 (necesita `settingsDefaultTypical`).
- **Risk**: **Medio**. Requiere manejo de `setState` correcto. Si el listener no dispara, el chip no se actualiza al editar.

#### Task 7.5 — Bloque "Resumen" al final del paso 3

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambio concreto**: agregar al final de `_buildStep3`, antes del cierre del `Column`:

  ```dart
  const SizedBox(height: AppSpacing.xxl),
  // Bloque Resumen (Q3 integrar marketing onboarding)
  Card(
    color: color.tertiaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: color.onTertiaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Text(
                EsBO.configSummaryTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.language_rounded,
            label: EsBO.configLanguage,
            value: ref.watch(localeProvider).label,
          ),
          _SummaryRow(
            icon: Icons.attach_money_rounded,
            label: EsBO.configCurrency,
            value: '${currency.code} (${currency.symbol})',
          ),
          _SummaryRow(
            icon: Icons.print_rounded,
            label: EsBO.configPrinterRequired.replaceAll(' (requerida)', ''),
            value: _printerSavedName ?? '—',
          ),
          _SummaryRow(
            icon: Icons.label_rounded,
            label: EsBO.configFilamentOptional.replaceAll(' (opcional)', ''),
            value: _filamentSavedName ?? '—',
          ),
          _SummaryRow(
            icon: Icons.percent_rounded,
            label: EsBO.settingsProfitBase,
            value: '${_profitCtrl.text}%',
          ),
          _SummaryRow(
            icon: Icons.bolt_rounded,
            label: EsBO.settingsKwhRate(currency.symbol),
            value: '${_kwhCtrl.text} ${currency.symbol}/kWh',
          ),
        ],
      ),
    ),
  ),
  ```

  Y un widget helper privado al final del archivo:

  ```dart
  class _SummaryRow extends StatelessWidget {
    const _SummaryRow({
      required this.icon,
      required this.label,
      required this.value,
    });

    final IconData icon;
    final String label;
    final String value;

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final color = theme.colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.onTertiaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$label: $value',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  ```
- **Acceptance criteria**:
  - 6 filas visibles con los 6 valores.
  - Color `tertiaryContainer` aplicado al card (verificación visual).
  - `_SummaryRow` reutilizable, sin duplicación.
- **Dependencies**: Task 7.4.
- **Risk**: Bajo. Patrón de `_SavedCard` ya existe en el archivo.

#### Task 7.6 — Slide motivacional

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambio concreto**: después del bloque Resumen (Task 7.5), agregar:

  ```dart
  const SizedBox(height: AppSpacing.lg),
  // Slide motivacional breve (reemplaza las 4 slides de OnboardingPage)
  Center(
    child: Column(
      children: [
        Icon(Icons.celebration_rounded, size: 48, color: color.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configSummaryImprint,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
  ```

- **Acceptance criteria**: visible solo en paso 3, debajo del Resumen, encima del botón "Finalizar".
- **Dependencies**: Task 7.5.
- **Risk**: Bajo.

#### Task 7.7 — `_finish()` navega directo a `/`

- **Archivo**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (MODIFICAR)
- **Cambio concreto**: en `_finish()` (línea 205–217), reemplazar:
  ```dart
  GoRouter.of(context).go('/onboarding');
  ```
  por:
  ```dart
  GoRouter.of(context).go('/');
  ```
- **Acceptance criteria**: al terminar el paso 3, el usuario va directo a home (sin pasar por `/onboarding`).
- **Dependencies**: Task 6.2 (la ruta `/onboarding` ya no existe).
- **Risk**: Bajo.

#### Task 7.8 — Actualizar `initial_config_stepper_test.dart`

- **Archivo**: `test/widget/initial_config_stepper_test.dart` (MODIFICAR)
- **Cambios concretos**:
  1. Test `'paso 1 muestra idioma + moneda'` (línea 40–48): agregar:
     ```dart
     expect(find.byType(LinearProgressIndicator), findsOneWidget);
     // El value es 1/3 (paso 1 de 3).
     final lpi = tester.widget<LinearProgressIndicator>(
         find.byType(LinearProgressIndicator));
     expect(lpi.value, closeTo(1 / 3, 0.01));
     // Helpers presentes.
     expect(find.textContaining('idioma', findRichText: false), findsAtLeastNWidgets(1));
     ```
     Nota: el helper `configLanguageHelper` empieza con "Elegí el idioma..." → contiene "idioma".
  2. Test `'paso 3: ganancia y energia precargadas con defaults'` (línea 153–178): agregar:
     ```dart
     // Chips "Típico" visibles.
     expect(find.text('Típico'), findsNWidgets(2)); // profit + kWh
     // Bloque Resumen presente.
     expect(find.text('Resumen'), findsOneWidget);
     ```
  3. Agregar test nuevo `'chip Típico desaparece al cambiar el valor'`:
     ```dart
     testWidgets('paso 3: chip Típico desaparece al cambiar el valor',
         (tester) async {
       final container = await _pumpStepper(tester);
       await tester.tap(find.text('Continuar'));
       await tester.pumpAndSettle();
       await tester.enterText(find.widgetWithText(TextField, 'Modelo'), 'Ender 3');
       await tester.enterText(find.widgetWithText(TextField, 'Consumo promedio (W)'), '180');
       await tester.pump();
       await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar').first);
       await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
       await tester.pumpAndSettle();
       await tester.tap(find.text('Continuar'));
       await tester.pumpAndSettle();

       // Inicialmente hay 2 chips Típico.
       expect(find.text('Típico'), findsNWidgets(2));

       // Cambio profit a 250.
       await tester.enterText(find.widgetWithText(TextField, '200'), '250');
       await tester.pump();
       expect(find.text('Típico'), findsOneWidget); // Solo kWh queda.

       // Vuelvo a 200.
       await tester.enterText(find.widgetWithText(TextField, '250'), '200');
       await tester.pump();
       expect(find.text('Típico'), findsNWidgets(2));
     });
     ```
  4. Agregar test nuevo `'finish navega a / sin pasar por /onboarding'`:
     ```dart
     testWidgets('finish navega a / sin pasar por /onboarding', (tester) async {
       final container = await _pumpStepper(tester);
       await tester.tap(find.text('Continuar')); // paso 2
       await tester.pumpAndSettle();
       await tester.enterText(find.widgetWithText(TextField, 'Modelo'), 'Ender 3');
       await tester.enterText(find.widgetWithText(TextField, 'Consumo promedio (W)'), '180');
       await tester.pump();
       await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar').first);
       await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
       await tester.pumpAndSettle();
       await tester.tap(find.text('Continuar')); // paso 3
       await tester.pumpAndSettle();
       await tester.tap(find.text('Finalizar'));
       await tester.pumpAndSettle();

       // Verificar SharedPreferences.
       final prefs = await SharedPreferences.getInstance();
       expect(prefs.getBool('onboarding_done'), isTrue);

       // El router ya está en / (no en /onboarding).
       // Verificable con el widget tree: no debe haber OnboardingPage.
       expect(find.byType(OnboardingPage), findsNothing);
     });
     ```
     Nota: agregar import `import 'package:tresdcal/features/onboarding/presentation/pages/onboarding_page.dart';` arriba, aunque solo se use para `findsNothing`.
- **Acceptance criteria**:
  - 4 tests originales actualizados + 2 nuevos = 6 tests.
  - Suite completa pasa.
- **Dependencies**: Tasks 7.1–7.7.
- **Risk**: **Medio**. Los tests pueden ser flaky si no se hace `tester.pumpAndSettle()` en los lugares correctos. Patrón ya usado en tests existentes.

#### Task 7.9 — Verificación grep

- **Acción**: `grep -r "_StepperIndicator" lib/` debe retornar 0 resultados. `grep -r "OnboardingPage" lib/` debe retornar 0 resultados.
- **Acceptance criteria**: ambos greps retornan vacío.
- **Dependencies**: Tasks 7.1, 6.1.
- **Risk**: Bajo. Si grep retorna algo, hay una referencia que no se limpió.

---

### FASE 8 — Verificación final

#### Task 8.1 — QA end-to-end

- **Acciones**:
  - `dart format --set-exit-if-changed lib/ test/`
  - `flutter analyze`
  - `flutter test --no-pub --reporter=expanded`
  - Smoke manual con `flutter run -d <device>`:
    1. Borrar datos de la app o instalar fresh.
    2. Abrir la app → splash → `/initial-config` (paso 1).
    3. Verificar `LinearProgressIndicator` en 33%.
    4. Seleccionar idioma ES, moneda BOB → Continuar.
    5. Paso 2: dropdown impresora muestra marcas de impresoras (Voron sí, Hatchbox no).
    6. Idem filamento (Hatchbox sí, Voron no).
    7. Guardar impresora → Continuar.
    8. Paso 3: chips "Típico" visibles junto a 200 y 0.7.
    9. Bloque Resumen visible con 6 filas.
    10. Slide motivacional visible.
    11. Tap "Finalizar" → navega a `/` (home).
    12. Verificar `prefs.getBool('onboarding_done') == true`.
  - Smoke en Android emulator con `flutter run -d emulator-5554`.
  - (Opcional) `flutter build apk --debug` para verificar que no rompe el build release-style.
- **Acceptance criteria**:
  - Todos los checks pasan.
  - Smoke manual completo en ≤90 segundos.
- **Dependencies**: Tasks 7.1–7.9.
- **Risk**: Bajo.

---

## Snippets clave

### Snippet 1: `BrandSelectorField` refactor (cambio de `_registeredBrands`)

**Path**: `lib/shared/widgets/brand_selector_field.dart` (líneas 88–110 del archivo actual)

```dart
/// Marcas registradas en la app del dominio del widget, únicas.
Set<String> _registeredBrands(WidgetRef ref) {
  final brands = <String>{};
  switch (widget.domain) {
    case BrandDomain.filament:
      final filaments = ref.watch(filamentsNotifierProvider).value;
      for (final f in filaments ?? const <Filament>[]) {
        final b = f.brand;
        if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
      }
    case BrandDomain.printer:
      final printers = ref.watch(printersNotifierProvider).value;
      for (final p in printers ?? const <PrinterProfile>[]) {
        final b = p.brand;
        if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
      }
  }
  return brands;
}

/// Opciones ordenadas: conocidas del dominio + registradas del dominio.
List<String> _options(WidgetRef ref) {
  final known = widget.domain == BrandDomain.filament
      ? kKnownFilamentBrands
      : kKnownPrinterBrands;
  final all = <String>{...known, ..._registeredBrands(ref)};
  return all.toList()..sort();
}
```

### Snippet 2: `LinearProgressIndicator` reemplazando `_StepperIndicator`

**Path**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (líneas 259–269 del archivo actual)

```dart
const SizedBox(height: AppSpacing.xxl),
// Indicador de progreso M3 nativo (reemplaza _StepperIndicator custom).
Semantics(
  label: EsBO.configStepCounter(_step + 1, _totalSteps),
  child: LinearProgressIndicator(
    value: (_step + 1) / _totalSteps,
    minHeight: 6,
    borderRadius: BorderRadius.circular(AppSpacing.sm),
  ),
),
const SizedBox(height: AppSpacing.md),
Text(
  _stepSubtitle(),
  style: theme.textTheme.bodyMedium?.copyWith(
    color: color.onSurfaceVariant,
  ),
),
const SizedBox(height: AppSpacing.xxl),
```

### Snippet 3: Chip "Típico" condicional

**Path**: `lib/features/onboarding/presentation/pages/initial_config_page.dart`

```dart
// Constantes para defaults (deben coincidir con Settings.defaults).
static const int _kDefaultProfit = 200;
static const double _kDefaultKwh = 0.7;

// Helper: chip visible solo cuando el valor coincide con el default.
bool _showTypicalChip(String raw, num defaultValue) {
  final parsed = Decimal.tryParse(raw.trim().replaceAll(',', '.'));
  if (parsed == null) return false;
  return parsed.toDouble() == defaultValue;
}

Widget _buildTypicalChip(BuildContext context, {required bool visible}) {
  if (!visible) return const SizedBox.shrink();
  return Chip(
    label: Text(EsBO.settingsDefaultTypical),
    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
```

Y dentro de `_buildStep3` (reemplazando el `NumericInputField` actual):

```dart
// Ganancia base (%) con chip Típico
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: NumericInputField(
        label: EsBO.settingsProfitBase,
        controller: _profitCtrl,
        allowDecimals: false,
        helperText: EsBO.configProfitHelper,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
          final n = int.tryParse(v.trim());
          if (n == null) return EsBO.commonInvalidNumber;
          if (n < 0 || n > 1000) return EsBO.settingsProfitBaseRange;
          return null;
        },
        onBlur: (raw) {
          final n = int.tryParse(raw.trim());
          if (n == null || n < 0 || n > 1000) return;
          ref.read(settingsNotifierProvider.notifier).updateProfitBase(
                Decimal.fromInt(n),
              );
        },
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    _buildTypicalChip(
      context,
      visible: _showTypicalChip(_profitCtrl.text, _kDefaultProfit),
    ),
  ],
),
```

> **Importante**: en `initState()`, agregar:
> ```dart
> _profitCtrl.addListener(() { if (mounted) setState(() {}); });
> _kwhCtrl.addListener(() { if (mounted) setState(() {}); });
> ```
> Sin esto, el chip no se actualiza al editar el input.

### Snippet 4: Bloque "Resumen"

**Path**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (al final de `_buildStep3`)

```dart
const SizedBox(height: AppSpacing.xxl),
// Bloque Resumen (reemplaza el antiguo /onboarding 4-slides).
Card(
  color: color.tertiaryContainer,
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: color.onTertiaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Text(
              EsBO.configSummaryTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onTertiaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SummaryRow(
          icon: Icons.language_rounded,
          label: EsBO.configLanguage,
          value: _localeLabel(),
        ),
        _SummaryRow(
          icon: Icons.attach_money_rounded,
          label: EsBO.configCurrency,
          value: '${currency.code} (${currency.symbol})',
        ),
        _SummaryRow(
          icon: Icons.print_rounded,
          label: 'Impresora',
          value: _printerSavedName ?? '—',
        ),
        _SummaryRow(
          icon: Icons.label_rounded,
          label: 'Filamento',
          value: _filamentSavedName ?? '—',
        ),
        _SummaryRow(
          icon: Icons.percent_rounded,
          label: EsBO.settingsProfitBase,
          value: '${_profitCtrl.text}%',
        ),
        _SummaryRow(
          icon: Icons.bolt_rounded,
          label: EsBO.settingsKwhRate(currency.symbol),
          value: '${_kwhCtrl.text} ${currency.symbol}/kWh',
        ),
      ],
    ),
  ),
),
const SizedBox(height: AppSpacing.lg),
// Slide motivacional breve.
Center(
  child: Column(
    children: [
      Icon(Icons.celebration_rounded, size: 48, color: color.primary),
      const SizedBox(height: AppSpacing.sm),
      Text(
        EsBO.configSummaryImprint,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),
```

Y el widget privado (al final del archivo, junto con `_StepSectionHeader`, `_SavedCard`, `_FilamentSkipCard`):

```dart
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.onTertiaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$label: $value',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Snippet 5: Router cleanup

**Path**: `lib/core/router/app_router.dart` (líneas 16 + 70–73)

```dart
// REMOVER:
// import '../../features/onboarding/presentation/pages/onboarding_page.dart';
// Y el bloque:
// GoRoute(
//   path: '/onboarding',
//   builder: (context, state) => const OnboardingPage(),
// ),
```

### Snippet 6: `_finish()` navega a `/`

**Path**: `lib/features/onboarding/presentation/pages/initial_config_page.dart` (línea 216)

```dart
// ANTES:
GoRouter.of(context).go('/onboarding');

// DESPUÉS:
GoRouter.of(context).go('/');
```

---

## Branch strategy recomendada

**Una sola branch: `feat/catalog-and-onboarding-redesign`**.

Razones:
1. FEATURE 1 phases (1–4) son **prerequisito estricto** del paso 2 de FEATURE 2 (las sub-secciones del stepper usan `BrandSelectorField(domain: ...)`).
2. Ambos features se deployan juntos (mismo release, mismo QA cycle).
3. Reduce overhead de sincronización entre branches (no hay risk de merge conflicts en `initial_config_page.dart` entre dos branches paralelas).

**Estructura de commits** (granularidad fina — un commit por task):

```
feat(catalog): add k3d_brands constants + tests                                # Fase 1
feat(catalog): parametrize BrandSelectorField with BrandDomain enum            # Fase 2.1
feat(catalog): reorder filament form to Brand → Nombre → ...                   # Fase 3.1
feat(catalog): reorder printer form to Brand → Modelo → Watts                  # Fase 3.2
feat(catalog): wire initial_config_page sub-sections with correct domain       # Fase 3.3
test(catalog): update filament_form + initial_config_stepper tests             # Fases 3.4 + 3.5
chore(catalog): dart format + flutter analyze + test pass                      # Fase 4
                                                                               # --- PR-1 catalog: merge aquí ---
feat(i18n): add 16 keys for onboarding redesign                                # Fases 5.1 + 5.2 + 5.3
refactor(onboarding): remove OnboardingPage 4-slides + deprecated i18n keys   # Fases 6.1 + 6.2 + 6.3
feat(onboarding): replace _StepperIndicator with LinearProgressIndicator       # Fase 7.1
feat(onboarding): add microcopy helpers to step 1 + 2                          # Fases 7.2 + 7.3
feat(onboarding): add Típico chip + Summary block + motivational slide         # Fases 7.4 + 7.5 + 7.6
feat(onboarding): finish navigates to / directly                               # Fase 7.7
test(onboarding): update stepper tests with microcopy + chips + nav            # Fase 7.8
chore(onboarding): grep verification + dart format                              # Fase 7.9
                                                                               # --- PR-2 onboarding: merge aquí ---
chore(release): full QA pass + flutter test + build                            # Fase 8
```

**Total commits**: ~16. **PRs**: 2.

Si el repo no permite múltiples PRs en una branch, los 2 PRs se mergean back-to-back sin squash (mantener granularidad para `git bisect`).

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| 1 | Tests flaky por `setState` no propagado en chips "Típico" | Media | Bajo | Agregar `controller.addListener(() => setState(() {}))` en `initState`. Documentado en Snippet 3. |
| 2 | `_StepperIndicator` aún referenciado en otro lugar | Baja | Bajo | `grep -r "_StepperIndicator" lib/` antes de merge. PRD §8 dice "verificar con grep". |
| 3 | 16 keys nuevas con typos en es_BO/en_US | Baja | Medio | Revisión bilingüe en PR — usar tabla Snippet vs PRD §10 como checklist. |
| 4 | `_finish()` navega a `/` pero `/` no es la pantalla correcta | Baja | Alto | Verificar que `GoRouter.of(context).go('/')` después de onboarding_done lleva al home (no al splash). Confirmar con `SplashScreen` redirect logic. |
| 5 | Conflicto entre `decimal` package y double comparison en chip "Típico" | Media | Bajo | Usar `parsed.toDouble() == defaultValue` o comparación con epsilon. Snippet 3 usa `==` simple (los valores son enteros o 0.7 exacto). |
| 6 | Reorder de forms rompe tests existentes que asumen orden viejo | Media | Bajo | Tests de FEATURE 1 actualizados explícitamente (Tasks 3.4, 3.5, 7.8). |
| 7 | Eliminar `OnboardingPage` rompe algún test que la importa | Baja | Bajo | `grep -r "OnboardingPage" test/` antes de eliminar. Si hay tests, eliminarlos o migrarlos. |
| 8 | `configFilamentAddAction` duplica `configAddFilament` (textos idénticos) | Baja | Trivial | Decisión de implementación: usar el nuevo (`configFilamentAddAction`) y deprecate `configAddFilament` si queda redundante. Documentar en commit message. |
| 9 | El usuario quiere agregar `printerBrand` separado (no en scope locked) | Media | Trivial | Confirmado en el prompt del usuario como fuera de scope (Q6 = "helper text se mantiene como está"). Si el implementador lo quiere agregar, OK pero requiere 3 archivos extras. |
| 10 | Cobertura de tests baja al inicio (archivos pre-existentes sin coverage) | Alta | Bajo | Coverage target es por archivo modificado. Coverage global puede bajar levemente pero coverage de archivos tocados se mantiene ≥70%. |

---

## Criterios de salida globales

- [ ] **Fase 0**: `flutter analyze` y `flutter test` pasan en `main` antes de empezar.
- [ ] **FEATURE 1 — Fases 1–4**:
  - [ ] `k3d_brands.dart` exporta 3 constantes (`kKnownFilamentBrands`, `kKnownPrinterBrands`, `kBrandClassification`).
  - [ ] `BrandSelectorField` tiene `domain: BrandDomain` required, observa solo el notifier del dominio.
  - [ ] Forms de filamento y printer tienen `BrandSelectorField` como primer campo.
  - [ ] `initial_config_page.dart` pasa `domain` correcto en las 2 invocaciones.
  - [ ] `grep -r "kKnown3dBrands" lib/` retorna 0.
  - [ ] Tests `k3d_brands_test.dart` (7), `brand_selector_field_test.dart` (5), `filament_form_page_test.dart` actualizado, `initial_config_stepper_test.dart` (+2) — todos pasan.
  - [ ] `flutter analyze` clean.
- [ ] **FEATURE 2 — Fases 5–7**:
  - [ ] 16 i18n keys nuevas en `app_strings.dart` + `EsImpl` + `EnImpl`.
  - [ ] 11 i18n keys deprecated eliminadas (`onboardingTitle*`, `onboardingDesc*`, `onboardingNext`, `onboardingSkip`, `onboardingStart`).
  - [ ] `onboarding_page.dart` eliminado.
  - [ ] Ruta `/onboarding` removida del router.
  - [ ] `LinearProgressIndicator` M3 en header de `initial_config_page.dart`.
  - [ ] `grep -r "_StepperIndicator" lib/` retorna 0.
  - [ ] Chips "Típico" visibles junto a 200% y 0.7, desaparecen al cambiar.
  - [ ] Bloque Resumen visible al final del paso 3 con 6 filas.
  - [ ] Slide motivacional visible después del Resumen.
  - [ ] `_finish()` navega a `/` (no `/onboarding`).
- [ ] **Tests FEATURE 2**: 6 tests en `initial_config_stepper_test.dart` (4 originales + 2 nuevos).
- [ ] **Fase 8**:
  - [ ] `dart format --set-exit-if-changed lib/ test/` exit 0.
  - [ ] `flutter analyze` 0 issues.
  - [ ] `flutter test --no-pub` 100% pass.
  - [ ] `flutter run -d <device>` smoke manual pasa el flow completo en ≤90s.
  - [ ] (Opcional) `flutter build apk --debug` exit 0.

---

## Rollback strategy

Si después de mergear se descubre un bug crítico:

1. **FEATURE 1 (PR-1)**: revert del merge commit → `git revert -m 1 <merge-commit>`. No toca la BD (sin schema changes). Tests que dependen del nuevo `domain:` fallarán como guía.
2. **FEATURE 2 (PR-2)**: idem. **Antes** de revertir, considerar que `SettingsKeys.onboardingDone` puede estar en `true` para usuarios que pasaron por el nuevo flow. El revert deja el router sin `/onboarding`, así que un usuario en estado "entre paso 3 y home" puede quedar sin destino claro. **Mitigación**: si el bug es solo visual (ej: chip Típico no aparece), NO revertir — fix forward.
3. **Si el bug está en la transición final**: agregar fallback en router `_RouterErrorPage` para que `/onboarding` redirige a `/` (regression-safe).

**No** se requiere rollback de BD en ningún caso — FEATURE 1 y FEATURE 2 son cero migraciones.

---

## Out of scope — future improvements (NO implementar)

Estos items aparecen mencionados en los PRDs pero están **explícitamente fuera** del alcance de este plan. NO los implementes. Si surgen, crear planes separados.

- **Q1**: Cambiar calculator picker dialog (`filament_selector_dialog`, `printer_selector_dialog`) — NO cambiar.
- **Q2**: Cambiar subtítulo de cards del catálogo — NO cambiar.
- **Q4**: Preview del cotizador dentro del onboarding — NO incluir.
- **OS-1 / OS-2 / OS-3**: Cambios de schema Drift, notifiers, motor de cálculo — NO tocar.
- **OS-4**: Ajustes avanzados (`SettingsPage`) — NO tocar.
- **OS-6**: Animaciones complejas (Hero, flutter_animate) — NO agregar.
- **OS-7**: Telemetría de funnel — NO agregar.
- **`printerBrand` como key separada**: opcional del PRD-1 §10 pero no en locked decisions. Mantener `EsBO.filamentBrand` para ambos forms.
- **Extraer widgets nuevos** (`_ConfigProgressBar`, `_ConfigSection`, `_TypicalValueChip`, `_ConfigSummaryCard`) a `lib/features/onboarding/presentation/widgets/`: solo si la implementación lo justifica (YAGNI). Por ahora inline en `initial_config_page.dart`.
- **Tests de integración E2E** (Patrol / integration_test): no están en scope. Los tests widget existentes cubren el flow.

---

## Resumen para el implementador

- **26 tasks** distribuidos en **9 fases** (1 setup + 4 F1 + 4 F2 + verificación final).
- **1 branch** con **16 commits** y **2 PRs** secuenciales.
- **18 horas estimadas** de trabajo enfocado.
- **3 archivos nuevos** (`k3d_brands.dart`, `k3d_brands_test.dart`, `brand_selector_field_test.dart`).
- **1 archivo eliminado** (`onboarding_page.dart`).
- **5 archivos de producción modificados** (`brand_selector_field.dart`, `filament_form_page.dart`, `printer_form_page.dart`, `initial_config_page.dart`, `app_router.dart`).
- **6 archivos de l10n modificados** (`app_strings.dart`, `es_bo.dart`, `en_us.dart` — 2 rondas: 16 nuevas + 11 removidas).
- **2 archivos de tests modificados** (`filament_form_page_test.dart`, `initial_config_stepper_test.dart`) + **2 nuevos** (`k3d_brands_test.dart`, `brand_selector_field_test.dart`).
