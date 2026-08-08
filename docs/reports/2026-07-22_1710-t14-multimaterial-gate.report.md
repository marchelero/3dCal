# T14 — Multi-material (advanced calculator) feature gate

> Task: T14 del plan `docs/plans/2026-07-22_1100-free-pro-monetization.plan.md`.
> TDD: tests first (RED), implement (GREEN), refactor (IMPROVE).

## Resumen

Gate de la feature multi-material (`CalculatorMode.advanced`) en el calculator.
Free user: tap en el segmento "Advanced" muestra SnackBar con body
"Desbloquea Pro para cotizaciones multi-material" + accion "Ir a Pro" que
navega a `/paywall`. El modo NO cambia. Pro user: comportamiento normal.

## Paths tocados

| Path | Cambio |
|---|---|
| `lib/features/calculation/presentation/pages/calculator_page.dart` | Gate en `_switchMode` (line 245-). +import go_router + entitlement_providers |
| `lib/l10n/app_strings.dart` | +2 abstract getters (l10n interface) |
| `lib/l10n/es_bo.dart` | +2 static accessors en EsBO + 2 impls en EsImpl |
| `lib/l10n/en_us.dart` | +2 impls en EnImpl |
| `test/unit/calculator_page_test.dart` | +2 helpers (`_pumpPagePro`, `_pumpPageWithRouter`) + grupo T14 con 3 tests |

## Test count

- Baseline: 225 tests
- Nuevos: 3 tests
- Final: **228 tests, all pass**

### Tests nuevos (todos en `test/unit/calculator_page_test.dart`)

Grupo `CalculatorPage — Multi-material gate (T14)`:

1. `Free user: tap Advanced muestra SnackBar con unlock message y modo NO cambia`
   — Verifica body + accion del SnackBar + que el modo sigue en express
   (no aparece "Agregar material", exclusivo de Advanced form).

2. `Free user: tap "Ir a Pro" en el SnackBar navega a /paywall`
   — Helper con GoRouter minimo. Verifica que el marker del paywall stub
   aparece despues de tap.

3. `Pro user: tap Advanced cambia el modo normalmente (sin SnackBar)`
   — Override `isProProvider.overrideWith((ref) => true)`. Verifica que
   "Agregar material" aparece (Advanced form) y NO hay SnackBar.

### Tests existentes

**No modifique tests existentes**. Los 6 tests de `CalculatorPage` previos
testean express mode exclusivamente, no tocan el SegmentedButton con
"Advanced", entonces el gate no se dispara. Corren en free state por
default (`isProProvider` resuelve a false con DB+SP vacios) y siguen
verdes.

## Decisiones

1. **Override de `isProProvider` en test Pro** — `isProProvider` es un
   `Provider<bool>` simple, overridable directo. Mas limpio que seedear
   SharedPreferences con `kIsProKey=true` (el path de cache) o construir
   un `EntitlementNotifier` fake. Tambien es el patron recomendado por
   el diseno: derived provider = single source of truth para gates.

2. **GoRouter mini en test de navegacion** — Para verificar
   `context.push('/paywall')` necesito un GoRouter en el widget tree.
   Sigo el patron de `test/widget/settings_page_test.dart:101` (mini
   GoRouter con 2 routes). Stub del paywall es un `Scaffold` con
   `Text('PAYWALL_OK')` para confirmar navigation sin acoplar al
   `PaywallPage` real (que tiene sus propios deps fakados).

3. **SnackBar construido directo, no via `AppSnackBar` factory** —
   `AppSnackBar` no soporta `action` y la constraint "no tocar archivos
   fuera del calculator feature" me prohibe extender
   `lib/shared/widgets/app_snack_bar.dart`. Build directo en
   `_switchMode`. 4s de duracion (estandar de warning).

4. **Gate en `_switchMode` (single check point)** — El SegmentedButton
   pasa el mode al callback. El gate se evalua en
   `_CalculatorPageState._switchMode` (single source). No agrego logica
   en `_ModeSelector` (stateless) ni duplico checks en `_buildExpressForm`
   / `_buildAdvancedForm`.

5. **Gate check ANTES de mutar state** — El check va primero, return
   early. No se llama `addMaterial()` ni `setMode()` cuando se dispara
   el gate. Asi no hay material row fantasma ni flicker de modo.

6. **`ref.read(isProProvider)` en el callback** — No `watch` (no
   necesitamos reactivity aca; el callback se dispara una vez por tap).
   El `watch` vive en el `build()` superior.

7. **2 l10n keys, no mas** — Solo `calculatorAdvancedLockedBody` y
   `calculatorGoProAction`. Suficientes para el SnackBar. No agregue
   variantes de los features pro (ya viven en `paywallFeatures`).

## Verificacion

- `flutter test` → **228 passed** (225 baseline + 3 new). 0 failures.
- `flutter analyze` sobre `lib/features/calculation/`, `lib/l10n/`,
  `test/unit/calculator_page_test.dart` → solo info-level
  `public_member_api_docs` pre-existentes (mismo patron que el resto de
  l10n/EsBO). No errors. No warnings nuevos.
- `flutter analyze` global → 625 issues, todos pre-existentes, ninguno
  en archivos tocados por este cambio.

## Issues / Notas

- **EsBO mutable singleton**: el existing test usa `EsBO` directo (que
  por default delega a `EsImpl`). En los tests nuevos uso `EsBO.xxx`
  sin `setUp` que fuerce locale — matchea el patron del archivo
  existente. Si en el futuro algun test cambia el impl, habria que
  aislar.

- **Gate al cambiar DE advanced A express no se evalua** — Eso es
  intencionado: bajar a express es siempre gratis. Solo subir a
  advanced requiere Pro.

- **Pre-state del modo en tests** — Todos los tests nuevos arrancan en
  express (estado inicial del calculator notifier). El primer tap en
  Advanced dispara el gate. Si el calculator arrancara en advanced por
  algun motivo (no es el caso actual), los tests fallarian en su
  premisa. Cubierto por el default de `CalculatorState.initial()`.
