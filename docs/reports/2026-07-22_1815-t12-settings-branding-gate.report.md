# T12 — Settings/Branding gate — Report

**Status**: DONE. 15/15 settings_page_test pass. 267/267 full suite. 0 regresiones.

## Scope

Gate del branding (companyName + companyLogo) en `/settings`. Free user no puede editar
nombre ni logo; tap en campos gated dispara SnackBar con `settingsBrandingLockedBody`
+ accion `settingsGoProAction` que navega a `/paywall`. Pro user: comportamiento normal
(editable + pick enabled). Badge "Pro" visible en la seccion Empresa cuando isPro=false.

## Archivos tocados (T12 scope)

| Path | Diff |
|------|------|
| `lib/features/settings/presentation/pages/settings_page.dart` | + 3 widgets gated (`_CompanyNameField`, `_LogoPicker`, `_ProBadge`) + integration en `_SettingsBody` Empresa section. 1187 lines. |
| `test/widget/settings_page_test.dart` | + 12 tests en 3 groups (l10n + Free + Pro). 444 lines. |
| `lib/l10n/app_strings.dart` | + 3 abstract getters (L77, L81, L85) |
| `lib/l10n/en_us.dart` | + 3 EnImpl overrides (L142, L145, L147) |
| `lib/l10n/es_bo.dart` | + 3 EsBO statics (L100-103) + 3 EsImpl overrides (L475, L478, L480) |

## Test breakdown (15 tests, 3 groups)

### `T12 — Branding gate l10n` (4)
- `EsBO.settingsBrandingLockedBody` no vacio
- `EsBO.settingsGoProAction` no vacio
- `EsBO.settingsProBadge` no vacio
- `EnImpl` expone las 3 keys con texto no vacio

### `T12 — Branding gate en Free` (5)
1. companyName readOnly=true cuando isPro=false
2. tap en companyName dispara SnackBar con body + accion Go Pro
3. tap en accion "Go Pro" del SnackBar navega a /paywall
4. badge "Pro" visible en seccion Empresa
5. tap en "Seleccionar imagen" dispara SnackBar del gate

### `T12 — Branding gate en Pro` (3)
1. companyName editable cuando isPro=true (texto se puede cambiar y persistir)
2. tap en companyName NO dispara SnackBar cuando isPro=true
3. tap en "Seleccionar imagen" NO dispara SnackBar cuando isPro=true

## Decisiones

1. **Gate UX = SnackBar + accion, no bloqueante**. Pattern consistente con T14 (multi-material) y T16 (CSV). User puede leer, no puede editar. Si quiere editar → tap accion → /paywall.
2. **Badge "Pro" inline en la seccion Empresa** (no en la AppBar). Patron local `_ProBadge` reusable. Color = `tertiary` (mismo que la seccion Empresa). Lock icon para senalar visualmente.
3. **`onTap` del TextField + `onTapOutside` gated**. Free: `onTap` muestra SnackBar, `onTapOutside=null`. Pro: `onTap=null` (deja que el field maneje), `onTapOutside` dispara el save.
4. **`readOnly=true` + `onTap` SnackBar** (en vez de `enabled=false`). `enabled=false` deshabilita el `onTap` callback; `readOnly=true` permite el tap pero bloquea edicion. Es lo que queremos para que el SnackBar se dispare.
5. **`_LogoPicker` con gate en ambos botones (pick + remove)**. Free con logo previo (de un periodo Pro) puede ver el logo pero no modificarlo. Pick/remove gated, el preview siempre visible.
6. **Helpers de test separados por escenario**: `_pumpPageFree` (sin router, render-only), `_pumpPageFreeWithRouter` (con `/paywall` stub), `_pumpPagePro` (isPro=true). Evita acoplar tests que no navegan a un router que no necesitan.

## Verificacion

```
flutter test test/widget/settings_page_test.dart
→ 00:05 +15: All tests passed!

flutter test (full suite)
→ 00:51 +267: All tests passed!  (0 regresiones)

flutter analyze lib/features/settings/ test/widget/settings_page_test.dart
→ 8 issues (info only, todas pre-existentes: directives_ordering, omit_local_variable_types,
   unawaited_futures en image_picker callbacks, unnecessary_underscores en errorBuilder).
   0 nuevos warnings/errors.
```

## L10n strings

```dart
// app_strings.dart
String get settingsBrandingLockedBody;  // "Personaliza tu marca en PDF. Actualiza a Pro."
String get settingsGoProAction;          // "Ir a Pro" / "Go Pro"
String get settingsProBadge;             // "Pro"

// es_bo.dart
'Personaliza tu marca (logo y nombre) en cotizaciones y PDF. Disponible en Pro.'
'Ir a Pro'
'Pro'

// en_us.dart
'Customize your brand (logo and name) in quotes and PDF. Available in Pro.'
'Go Pro'
'Pro'
```

## No-go (fuera de scope T12)

- Restore button (T11) — independiente, mismo settings page pero en su propio card.
- Tests E2E del flow (T20 ya cubre widget + unit para gates).
- Compliance docs (T22).

## Next

Sigo con T13 (PDF branding gate) o T15 (history cap)? El user decidio "1 task a la vez".
