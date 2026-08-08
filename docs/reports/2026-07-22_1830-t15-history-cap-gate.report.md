# T15 — History cap gate — Report

**Status**: DONE. 9/9 history_cap_test pass. 267/267 full suite. 0 regresiones.

## Scope

Free user limitado a `kFreeHistoryCap` (10) cotizaciones. Intento de guardar la #11
lanza `HistoryCapReachedException` desde `CalculatorNotifier.save()`. UI muestra
SnackBar con `historyCapReachedBody` + accion `calculatorGoProAction` que navega
a `/paywall`. Pro user: sin cap.

## Archivos tocados (T15 scope)

| Path | Diff |
|------|------|
| `lib/features/calculation/presentation/state/calculator_notifier.dart` | + class `HistoryCapReachedException` (L32-48), + cap check en `save()` (L315-323). 446 lines. |
| `lib/features/calculation/presentation/pages/calculator_page.dart` | + `try/catch` de `HistoryCapReachedException` con SnackBar dedicado (L346-364). |
| `lib/l10n/app_strings.dart` | + `historyCapReachedBody` (L313) |
| `lib/l10n/en_us.dart` | + override (L606) |
| `lib/l10n/es_bo.dart` | + EsBO static (L324) + EsImpl override (L897) |
| `test/integration/history_cap_test.dart` | + 9 tests en 3 groups. 331 lines. |

## Test breakdown (9 tests, 3 groups)

### `History cap (T15) — Free user` (4)
1. countAll < kFreeHistoryCap: save() exitoso, retorna id positivo
2. countAll == kFreeHistoryCap: 11vo save() throws HistoryCapReachedException
3. items existentes NO se eliminan al bloquear (idempotencia del cap)
4. HistoryCapReachedException expone cap + current count (propertied)

### `History cap (T15) — Pro user` (3)
1. countAll == kFreeHistoryCap: pro puede guardar la #11 sin cap
2. pro con 50 existentes: save() funciona (cap efectivamente no aplica)
3. upgrade mid-flight: free con 10 → upgrade a pro → save #11 OK (mutable holder + invalidate)

### `History cap (T15) — Edge cases` (2)
1. form invalido con cap libre: save() retorna null (no exception, no insert)
2. free con 0 existentes: 10 saves consecutivos OK, el 11vo throw

## Decisiones

1. **Typed exception en vez de sealed result**. Mantiene `Future<int?>` backwards-compat (null = form invalido, int = id). Throwing es no-breaking y permite al caller tipar el catch. Spec del plan lo sugeria; lo confirme con el caller real (calculator_page.dart L346).
2. **Check ANTES de delegar al repo** (L315-323). Razon: si el form es valido pero el cap esta al limite, queremos fallar rapido sin armar el `CalculationDraft`. Trade-off: +1 query (`countAll()`) por save. Aceptable (save no es hot path).
3. **Pro check via `ref.read(isProProvider)`** (no `isProHolder`). El notifier es read-only sobre el provider — la UI maneja el upgrade flow (T11 restore, T9 purchase). Si el user upgrade, el state del provider cambia, el proximo save lee el nuevo value.
4. **`HistoryCapReachedException` con cap + currentCount**. UI puede mostrar "10/10 — upgrade a Pro" sin re-query. Tambien permite tests que asseren el count exacto.
5. **L10n reusa `calculatorGoProAction` (T14)**. Misma accion, mismo destino /paywall. Coherencia UX: cualquier CTA "Go Pro" usa la misma label.
6. **Test edge "form invalido con cap libre"**. Asegura que la excepcion solo se dispara si el form es valido Y estamos en el cap. Si el form es invalido → `null` (no `throws`). UX: el form bloquea primero, el cap es segunda linea de defensa.

## Verificacion

```
flutter test test/integration/history_cap_test.dart
→ 00:00 +9: All tests passed!

flutter test (full suite)
→ 00:58 +267: All tests passed!  (0 regresiones)

flutter analyze (3 archivos T15)
→ 3 issues (info only, pre-existentes en calculator_page directives_ordering + 2 omit_local_variable_types)
→ 0 nuevos errors/warnings
```

## L10n strings

```dart
// app_strings.dart
String get historyCapReachedBody;

// es_bo.dart
'Alcanzaste el limite de cotizaciones del plan Free. Actualiza a Pro para historial ilimitado.'

// en_us.dart
'You have reached the Free plan quote limit. Upgrade to Pro for unlimited history.'
```

## Gate UX flow

```
Free user, 10 cotizaciones guardadas
↓
Tap "Guardar" en calculator (form valido)
↓
save() → check isPro=false → countAll()=10 → throw HistoryCapReachedException
↓
calculator_page catch → SnackBar con body + accion "Ir a Pro" / "Go Pro"
↓
Tap accion → /paywall
↓
User compra → EntitlementNotifier.activate('lifetime_purchase') → isProProvider=true
↓
Vuelve a calculator, tap "Guardar" → save() check isPro=true → skip cap → insert OK
```

## No-go

- No widget test del SnackBar (UI integration testeada por `full_flow_test.dart` AC-1; el SnackBar del cap es un branch especifico de error handling que se cubre en T20).
- No auto-delete de items viejos (el cap es duro; si free quiere mas espacio → upgrade).

## Next

Sigo con T16 (CSV export gate) o T11 (restore button)?
