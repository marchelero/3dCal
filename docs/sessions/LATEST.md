# Ultima sesion

**2026-08-09**: Fix bug de minutos (reportado por usuario): `Rational.toDecimal()` lanzaba `AssertionError` en divisiones no-terminantes (59/60, 100/300) → el precio no cambiaba. Fix: `scaleOnInfinitePrecision: 12` en 3 sitios (calculator_state.totalHoursDecimal, material_input.pricePerGram, detail L667) + 3 tests de regresión. Suite **315/315**, build web OK, repro browser $126→$155,50 con 0 errores de consola. Antes: Refinamiento UX/UI completo (312/312): colores → tema con AA, inputs unificados, snackbars → AppSnackBar, i18n, textTheme, a11y. Screenshots en `verify/`.

Ver: [2026-08-09-uxui-refinement.md](2026-08-09-uxui-refinement.md) · [2026-08-09_minutes-bug-fix.report.md](../reports/2026-08-09_minutes-bug-fix.report.md)
