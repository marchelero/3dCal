# Changelog

Todos los cambios notables del proyecto tresdcal se documentan aca.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

## [Unreleased]

### Sprint 0 — Bootstrap (2026-07-13)

#### Added
- Proyecto Flutter 3.44.0 con plataformas web + android + ios.
- `pubspec.yaml` con stack: drift, drift_flutter, sqlite3_flutter_libs, flutter_riverpod, riverpod_annotation, decimal, fl_chart, go_router, intl, path_provider.
- `analysis_options.yaml` con lints estrictos (custom_lint + riverpod_lint + ~120 reglas de dart_lint).
- Estructura de carpetas `lib/{core,features,shared}` segun PRD seccion 6.2.
- `lib/core/constants/app_constants.dart` — constantes globales (ganancia base, tarifa kWh, limites).
- `lib/core/money/decimal_extensions.dart` — `DecimalParse.fromString/tryFromString/fromNum`.
- `lib/core/money/currency_formatter.dart` — `formatBob`, `formatBobNumber`, `formatPercentage`, `formatHours` (formato es_BO).
- `lib/core/theme/app_theme.dart` — Material 3 con seed deep purple, light + dark.
- `lib/main.dart` — bootstrap con `ProviderScope`.
- `lib/app.dart` — `MaterialApp` raiz.
- `lib/features/calculation/presentation/pages/home_page.dart` — placeholder Sprint 0.
- `test/widget/sprint0_smoke_test.dart` — smoke test que verifica que la app arranca y muestra formatter BOB.
- README.md propio del proyecto (sustituye al README default de flutter create).
- Mover specs originales a `_docs/README.md` y `_docs/read.md`.

#### Verified
- `flutter analyze` — 0 issues.
- `flutter test` — 2/2 passing.
- `flutter build web --release` — `Built build\web`, 235s, main.dart.js = 1.83 MB.
- Wasm dry run exitoso (senal positiva para performance web).
- Tree-shake de iconos: CupertinoIcons 99.4% reducido, MaterialIcons 99.5% reducido.

#### Changed
- `package:decimal` upgraded de 3.0.2 (solicitado) a 3.2.4 (resuelto).
- `package:custom_lint` upgraded de 0.6.4 a 0.7.6 (conflicto con riverpod_lint 2.6.5).
- `package:riverpod_lint` upgraded de 2.3.13 a 2.6.5.

#### Notes
- Stack final diverge del PRD original en una decision tecnica: **Isar → drift**. Razon: Isar v3 no compila en Flutter Web. drift es la unica opcion seria para paridad web/mobile.
- Renombre del proyecto: package name es `tresdcal` (Dart no permite `3dcal` por arrancar con digito). Directorio sigue siendo `3dCal`.
