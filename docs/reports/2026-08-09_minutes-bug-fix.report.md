# Reporte: Fix bug de minutos (división no-terminante)

**Fecha**: 2026-08-09
**Bug reportado por usuario**: "si pongo 3 horas y luego 3 horas con 59 min no cambia el precio". Al setear 59 minutos el total se congelaba (quedaba el último valor calculado).

---

## Causa raíz

`Rational.toDecimal()` (paquete `decimal ^3.2.4`, decimal.dart L416-431) **lanza** `AssertionError('scaleOnInfinitePrecision is required for rationale without finite precision')` cuando el racional no tiene precisión finita (división no-terminante: 59/60 = 0.9833..., 100/300 = 0.3333...) y no se pasa `scaleOnInfinitePrecision`. Es un THROW real → también en release. El throw en `_recompute` congelaba el output anterior → el precio no cambiaba.

Los tests previos pasaban porque 33/60 = 0.55 es exacto (precisión finita) — nunca se ejercitó 59/60.

## Fix aplicado (3 sitios)

`scaleOnInfinitePrecision: 12` (12 decimales, más que suficiente; 1 min = 1.67e-2 h):

1. `lib/features/calculation/domain/calculator_state.dart` L348-352 — `totalHoursDecimal`: `(m / Decimal.fromInt(60)).toDecimal(scaleOnInfinitePrecision: 12)` (×2, minutos y combo horas+minutos).
2. `lib/features/calculation/domain/material_input.dart` L31 — `pricePerGram = (pricePerBobbin / gramsPerBobbin).toDecimal(scaleOnInfinitePrecision: 12)` (ratio no divisible, ej. 100/300, congelaba el costo de materiales).
3. `lib/features/calculation/presentation/pages/calculation_detail_page.dart` L667 — `(weight * price / grams).toDecimal(scaleOnInfinitePrecision: 12)` (desglose).

## Tests de regresión (3 nuevos)

- `test/unit/calculator_notifier_test.dart`: '3h + 59min: no lanza y produce 3.9833...h' (`closeTo(3.983333, 1e-6)`).
- `test/unit/calculator_notifier_test.dart`: 'regression (bug usuario): 3h + 59min SI cambia el precio con tiempo costeable' — laborCost 30 → 39.8333, totalPrice 120 → ~149.5.
- `test/unit/calculation_engine_test.dart`: 'ratio price/grams no-terminante (100/300) no lanza' — materialCost 100, totalPrice == materialCost.

## Verificación

- `flutter test` completo: **315/315** ✓ (312 + 3 nuevos).
- `flutter build web` ✓.
- **Repro browser en vivo** (Playwright, mobile 390×844): form Peso 100 / Precio 120 / Gramos 1000 / 3h + Mano de obra 10 → $126,00. Setear Minutos=59 → **$155,50** (labor 39.83). Antes: congelado en $36,00 con AssertionError en consola. Post-fix: 0 errores de consola.
