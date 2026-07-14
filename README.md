# tresdcal

Calculadora de precios para impresiones 3D. **100% local, mobile + web, sin backend.**

Stack: Flutter 3.44 · Dart 3.12 · drift 2.28 (SQLite) · Riverpod 2.6 · fl_chart 0.68 · go_router 14.

## Status

**Sprint 0 / 9** — bootstrap completo. `flutter analyze` y `flutter test` verdes. `flutter build web --release` exitoso.

Proxima fase: Sprint 1 = motor de calculo con TDD puro.

## Documentacion del proyecto

- **PRD**: [`.opencode/prds/2026-07-13_2206-3dcal-app.prd.md`](.opencode/prds/2026-07-13_2206-3dcal-app.prd.md) — requisitos ejecutables.
- **Plan de implementacion**: [`.opencode/plans/2026-07-13_2206-3dcal-app.plan.md`](.opencode/plans/2026-07-13_2206-3dcal-app.plan.md) — 9 sprints, 13-18 sesiones.
- **Specs originales** (guias iniciales): [`_docs/README.md`](_docs/README.md) y [`_docs/read.md`](_docs/read.md).
- **Reports**: [`.opencode/reports/2026-07-13_2215-3dcal-app.report.md`](.opencode/reports/2026-07-13_2215-3dcal-app.report.md) — trazabilidad del flujo /orchestrate.

## Decisiones arquitectonicas

- **Flutter only** (web + mobile = mismo codebase).
- **drift** en lugar de Isar (Isar no compila en web).
- **Decimal package** obligatorio en motor de calculo (prohibido `double`).
- **Riverpod 2.x con codegen** para estado.
- **Material 3** con seed color deep purple (provisional).

## Build

```bash
# Dependencias (primera vez)
flutter pub get

# Analisis estatico
flutter analyze

# Tests
flutter test

# Web (release)
flutter build web --release
# Output: build/web/

# Mobile (debug APK, requiere Android SDK)
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

## Estructura

```
lib/
  main.dart                    # ProviderScope + runApp
  app.dart                     # MaterialApp + tema M3
  core/
    constants/                 # kDefaultKwhRate, etc
    money/                     # Decimal helpers, BOB formatter
    theme/                     # AppTheme.light/dark
    database/                  # (Sprint 2)
  features/
    calculation/               # core: motor + HomePage
    catalog/
      filaments/               # (Sprint 3)
      printers/                # (Sprint 3)
    history/                   # (Sprint 5)
    dashboard/                 # (Sprint 6)
    settings/                  # (Sprint 7)
  shared/
    widgets/                   # (Sprint 4)
test/
  unit/                        # (Sprint 1: motor)
  widget/                      # (Sprint 3+)
  integration/                 # (Sprint 9)
_docs/                         # specs originales movidas
```

## Convenciones

- Codigo (variables, funciones) en **ingles**.
- UI y comentarios en **espanol**.
- `dart format` + `dart analyze` (line_length 100, lints estrictos).
- Commits conventional (`feat:`, `fix:`, `refactor:`, etc) en espanol.
- Branch: `main` estable, `feature/sprint-N-desc` para trabajo.

## Licencia

A definir por el usuario. Sugerencia: MIT para codigo abierto.
