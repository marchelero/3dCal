# 3dcal

Calculadora de precios para impresiones 3D. **100% local, mobile + web, sin backend.**

Stack: Flutter 3.47 · Dart 3.13 · drift 2.x (SQLite) · Riverpod 3.x · fl_chart 1.x · go_router 17 · decimal · crypto (HMAC de backups).

## Status

**v0.6.0+13** en desarrollo activo (auditoría + hardening). `flutter analyze` 0 issues, `flutter test` 970/970.

Features:
- Cotizacion express (1 material) y avanzado (multi-material), motor con `decimal` (nunca `double`).
- Lotes/mayorista: descuento por escalones de cantidad (tiered) + totales de lote.
- Catalogo de filamentos e impresoras con default toggle; plantillas de cotizacion.
- Historial con snapshot de materiales (sobrevive a deletes) + toggle vendido + export CSV.
- Dashboard con bar chart Cotizado vs Ganado + conversion%.
- Export PDF + imagen de cotizacion, share por plataforma.
- Pro (RevenueCat): paywall, gates de features, deteccion de refund/revocacion en boot.
- Backup/restore local con firma HMAC-SHA256 (detecta archivos alterados).
- i18n: es_BO (default), en_US, de_DE, fr_FR, pt_BR. Moneda BOB hardcoded.
- Draft recovery, dark mode auto, responsive (NavigationBar/NavigationRail).
- A11y: contraste WCAG AA verificado por test + text-scale 1.5× sin overflow.

## Requisitos

- Flutter 3.47+ (estable)
- Dart 3.13+
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
- **Riverpod 3.x** para estado (inyeccion manual, sin codegen). `AsyncNotifier` para fetch, `Notifier` para estado local.
- **drift 2.x** para SQLite cross-platform (NativeDatabase en mobile, WasmDatabase en web).
- **go_router 17** con `StatefulShellRoute` para tabs (Inicio / Historial / Dashboard / Ajustes) + rutas full-screen (calculator, detail, form).
- **decimal package** obligatorio en calculos monetarios (nunca `double`).
- **Material 3** con seed color deep purple + light/dark themes automaticos.

### Estructura

```
lib/
  main.dart                    # bootstrap async (SharedPreferences) + ProviderScope
  app.dart                     # MaterialApp.router + themes
  core/
    backup/                    # export/import JSON + firma HMAC-SHA256
    constants/                 # kDefaultKwhRate, etc
    database/                  # AppDatabase (drift, schema v17)
    money/                     # Decimal helpers, BOB formatter
    router/                    # app_router (go_router config)
    storage/                   # DraftStorage (SharedPreferences)
    theme/                     # AppTheme.light/dark + tokens
  features/
    calculation/               # motor + Home + Calculator + History + detail
    catalog/                   # filaments + printers
    dashboard/                 # bar chart + stats
    entitlement/               # Pro: RevenueCat, paywall, revocacion
    legal/                     # privacy / terms
    onboarding/                # initial config + idioma
    settings/                  # page + notifier + domain
    splash/
  l10n/                        # AppStrings + es_bo/en_us/de_de/fr_fr/pt_br
  shared/
    widgets/                   # LoadingView / ErrorView / AppScaffold / StatTile
test/
  unit/                        # motor + repos + backup + a11y (contraste)
  widget/                      # pages + drafts + text-scale 1.5×
docs/
  prds/                        # requirements
  reports/                     # verificacion
  sessions/                    # snapshots de sesion (LATEST.md)
```

## Decisiones tecnicas

- **Flutter only** (web + mobile = mismo codebase).
- **drift** en lugar de Isar (Isar no compila en web).
- **Decimal package** obligatorio en motor de calculo (prohibido `double`).
- **Riverpod 3.x** para inyeccion de dependencias + estado (manual, sin codegen).
- **go_router** con `StatefulShellRoute` para tabs + rutas full-screen. Datos no serializables via `state.extra`.
- **Draft recovery** via SharedPreferences con debounce 500ms en save.
- **Historial snapshot**: cada cotizacion guarda `materialLabelSnapshot` + `materialPricePerGramSnapshot` para sobrevivir deletes de filamentos.
- **dark mode automatic** via `themeMode: ThemeMode.system`.

## Documentacion

- **Project context**: [`docs/PROJECT.md`](docs/PROJECT.md) — stack, convenciones, non-negotiables.
- **PRD**: [`docs/prds/`](docs/prds/) — requisitos ejecutables.
- **Reports**: [`docs/reports/`](docs/reports/) — verificacion por ronda.
- **Sesiones**: [`docs/sessions/LATEST.md`](docs/sessions/LATEST.md) — ultimo snapshot.
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
