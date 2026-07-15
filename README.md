# 3dcal

Calculadora de precios para impresiones 3D. **100% local, mobile + web, sin backend.**

Stack: Flutter 3.x · Dart 3.12 · drift 2.x (SQLite) · Riverpod 2.x · fl_chart 0.68 · go_router 14 · decimal.

## Status

**MVP 1.0.0** — 9 sprints completados. `flutter analyze` 0 issues, `flutter test` 118/118, `flutter build web --release` exitoso.

Features:
- Cotizacion express (1 material) y avanzado (multi-material con animacion).
- Catalogo de filamentos e impresoras con default toggle.
- Historial de cotizaciones con snapshot de materiales (sobrevive a deletes).
- Dashboard con bar chart Cotizado vs Ganado + conversion%.
- Settings con profit base, kWh rate, genericos.
- Draft recovery (cierre accidental restaura form).
- Dark mode auto (ThemeMode.system).
- Responsive: NavigationBar en mobile/tablet, NavigationRail en web desktop.

## Requisitos

- Flutter 3.22+ (estable)
- Dart 3.12+
- Chrome (opcional, para dev web)
- Android SDK (opcional, para APK)
- iOS toolchain (opcional, para iOS)

## Setup

```bash
# Clonar
git clone <repo>
cd 3dcal

# Dependencias
flutter pub get

# Generar codigo (drift .g.dart, riverpod .g.dart)
dart run build_runner build --delete-conflicting-outputs

# (o en watch mode durante desarrollo)
dart run build_runner watch --delete-conflicting-outputs
```

## Run

```bash
# Web (Chrome)
flutter run -d chrome

# Android (con device o emulador conectado)
flutter run -d android

# iOS
flutter run -d ios

# Lista devices disponibles
flutter devices
```

## Test

```bash
# Unit + widget tests
flutter test

# Con coverage
flutter test --coverage
# Output: coverage/lcov.info
```

## Build

```bash
# Web release
flutter build web --release
# Output: build/web/ (estatico, deployable a cualquier static host)

# Android APK debug
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

# Android APK release (requiere signing config)
flutter build apk --release

# iOS (requiere Mac + signing)
flutter build ios --release
```

## Arquitectura

- **Clean Architecture lite**: `lib/features/<feature>/{data,domain,presentation}/`.
- **Riverpod 2.x** para estado. `AsyncNotifier` para fetch, `Notifier` para estado local.
- **drift 2.x** para SQLite cross-platform (NativeDatabase en mobile, WasmDatabase en web).
- **go_router 14** con `StatefulShellRoute` para tabs (Inicio / Historial / Dashboard / Ajustes) + rutas full-screen (calculator, detail, form).
- **decimal package** obligatorio en calculos monetarios (nunca `double`).
- **Material 3** con seed color deep purple + light/dark themes automaticos.

### Estructura

```
lib/
  main.dart                    # bootstrap async (SharedPreferences) + ProviderScope
  app.dart                     # MaterialApp.router + themes
  core/
    constants/                 # kDefaultKwhRate, etc
    money/                     # Decimal helpers, BOB formatter
    theme/                     # AppTheme.light/dark
    database/                  # AppDatabase (drift)
    storage/                   # DraftStorage (SharedPreferences)
    router/                    # app_router (go_router config)
  features/
    calculation/               # motor + Home + Calculator + History
    catalog/                   # filaments + printers
    dashboard/                 # bar chart + stats
    settings/                  # page + notifier + domain
  shared/
    widgets/                   # LoadingView / ErrorView / EmptyView / AppScaffold
    l10n/                      # es_bo.dart
test/
  unit/                        # motor + repos
  widget/                      # pages + drafts
  integration/                 # (Sprint 9)
docs/
  prds/                        # requirements
  plans/                       # implementation plan
  reports/                     # sprint reports
```

## Decisiones tecnicas

- **Flutter only** (web + mobile = mismo codebase).
- **drift** en lugar de Isar (Isar no compila en web).
- **Decimal package** obligatorio en motor de calculo (prohibido `double`).
- **Riverpod 2.x** para inyeccion de dependencias + estado.
- **go_router** con `StatefulShellRoute` para tabs + rutas full-screen. Datos no serializables via `state.extra`.
- **Draft recovery** via SharedPreferences con debounce 500ms en save.
- **Historial snapshot**: cada cotizacion guarda `materialLabelSnapshot` + `materialPricePerGramSnapshot` para sobrevivir deletes de filamentos.
- **dark mode automatic** via `themeMode: ThemeMode.system`.

## Documentacion

- **PRD**: [`docs/prds/2026-07-13_2206-3dcal-app.prd.md`](docs/prds/2026-07-13_2206-3dcal-app.prd.md) — requisitos ejecutables.
- **Plan**: [`docs/plans/2026-07-13_2206-3dcal-app.plan.md`](docs/plans/2026-07-13_2206-3dcal-app.plan.md) — 9 sprints.
- **Reports**: [`docs/reports/`](docs/reports/) — trazabilidad sprint por sprint.
- **CHANGELOG**: [`CHANGELOG.md`](CHANGELOG.md).

## Convenciones

- Codigo (variables, funciones) en **ingles**.
- UI y comentarios en **espanol**.
- `dart format` + `dart analyze` (line_length 100, lints estrictos).
- Commits conventional (`feat:`, `fix:`, `refactor:`, etc) en espanol.
- Branch: `main` estable.

## Privacidad

**100% local.** Sin backend, sin telemetria, sin tracking. Todos los datos quedan en el dispositivo:
- Mobile: SQLite en app docs dir + SharedPreferences.
- Web: IndexedDB (via drift WasmDatabase) + localStorage.

Al desinstalar la app / limpiar datos del browser, se pierde todo. No hay sync ni export automatico.

## Licencia

MIT — ver [`LICENSE`](LICENSE).
