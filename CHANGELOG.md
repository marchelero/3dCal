# Changelog

Todos los cambios notables del proyecto tresdcal se documentan aca.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

## [Unreleased]

### Sprint 3 — Calculator single-material (2026-07-14)

#### Added
- `lib/features/calculation/presentation/state/calculator_state.dart` — state inmutable con `mode` (express/advanced placeholder), `materials` (1 sola en Sprint 3), `totalHours`, `printerId?`, `discountPercentage`. Valida `isValid` cuando todos los campos requeridos son > 0.
- `lib/features/calculation/presentation/state/calculator_notifier.dart` — `ChangeNotifier` (Riverpod 2.x manual, sin codegen) con metodos `setWeight`, `setTime`, `setPrice`, `setGrams`, `setWatts`, `setKwhRate`, `setProfit`, `setDiscount`, `reset`, `loadFilamentDefaults`. Output derivado via getter, recalcula reactivo.
- `lib/features/calculation/presentation/widgets/decimal_input_field.dart` — input reutilizable para `Decimal`, integra con notifier, soporta teclado numerico y validacion en vivo.
- `lib/features/calculation/presentation/pages/calculator_page.dart` — pagina principal del calculator. Express form con 8 inputs (peso, tiempo, precio bobina, gramos/bobina, watts, kWh, profit, descuento). Output card con desglose (Costo material, Costo electrico, Costo base, Profit efectivo, Precio final) formateado en BOB. Hint cuando form invalido. Boton reset.
- `lib/features/calculation/presentation/pages/home_page.dart` — actualizado de placeholder Sprint 0 a launcher con boton "Nueva cotizacion" que navega a `CalculatorPage`.
- `test/unit/calculator_notifier_test.dart` — 12 tests: estado inicial, setters, validacion, output derivado, clamp descuento agresivo 50%, reset, loadFilamentDefaults, recompute al cambiar kwhRate, inmutabilidad.
- `test/unit/calculator_page_test.dart` — 4 tests: render con todos los labels, output live al cambiar kwh, output desaparece al borrar weight, reset restaura defaults, descuento agresivo muestra warning.
- `test/widget/sprint0_smoke_test.dart` — extendido de 2 a 3 tests: smoke launcher + smoke navigation + smoke form vacio→lleno→output BOB visible.

#### Notes
- **Reorganizacion del plan original**: el plan `.opencode/plans/2026-07-13_2206-3dcal-app.plan.md` ponia calculator en Sprint 4 y CRUD de catalogos en Sprint 3. La implementacion los invirtio: calculator (single material) en Sprint 3, CRUD de filaments/printers queda absorbido en Sprint 4 (cuando se conecte con los repos ya existentes).
- **Single material**: el modo multi-material con `AnimatedList` queda pendiente para sprint posterior. En Sprint 3 la cotizacion usa 1 filamento a la vez, con `loadFilamentDefaults` placeholder hasta que se conecte con `FilamentRepository` (Sprint 4).
- **Riverpod manual**: este sprint usa `ChangeNotifier` + `Provider` manuales en vez de `@riverpod` codegen. Migracion a codegen queda para sprint posterior si se justifica.
- **No se commiteo** — cambio de CHANGELOG queda working tree, esperando instruccion explicita del usuario.

#### Verified
- `flutter test` — 80/80 passed (~4s). Distribucion: 29 Sprint 1 (engine) + 32 Sprint 2 (db repos) + 16 Sprint 3 (notifier 12 + page 4) + 3 smoke (Sprint 0 extendido).
- `flutter analyze` — 0 issues.

### Sprint 1 — Motor de calculo + Money (2026-07-13)

#### Added
- `lib/features/calculation/domain/entities/material_input.dart` — entity pure Dart, valida `weight > 0` semanticamente.
- `lib/features/calculation/domain/entities/calculation_input.dart` — input value object, validacion documentada.
- `lib/features/calculation/domain/entities/calculation_output.dart` — output value object con `==`, `hashCode`, `toString`.
- `lib/features/calculation/domain/calculation_engine.dart` — motor de calculo, pure Dart, sin Flutter.
- `test/unit/calculation_engine_test.dart` — 29 tests cubriendo:
  - Express basico (AC-2 PRD)
  - Multi-material (2 filamentos)
  - Con tiempo + electrico (AC-2: Bs. 46.05)
  - Descuento 10% (AC-3 PRD: Bs. 42.98, NO Bs. 43.04 del PRD narrativo)
  - Edges: printerWatts=0, totalHours=0, materials vacios
  - Clamp: effProfit<0 clampea profitAmount a 0
  - effProfit=0 exacto
  - Precision: 0.1+0.2=0.3 (NO 0.30000000000000004)
  - Precision: 1000 iteraciones sin acumular error
  - Inmutabilidad (==, hashCode)
  - MaterialInput.pricePerGram, MaterialInput.cost
  - Formateo BOB (formatBob, formatBobNumber, formatPercentage, formatHours)
  - Constantes (kwhRate, profitBase, maxMaterials, maxDiscount)

#### Fixed
- `formatBob` ahora pone "Bs." ANTES del monto (convencion boliviana), no despues como hacia intl por default.
- `formatBob` fuerza 2 decimales (pattern `#,##0.00`), evitando outputs como "Bs. 0" en lugar de "Bs. 0,00".

#### Verified
- `flutter test` — 31/31 passed (29 Sprint 1 + 2 Sprint 0).
- `flutter analyze` — No issues found.
- `flutter test --coverage` — engine coverage 96.8% (30/31 lineas). La unica linea no cubierta es `const CalculationEngine._();` (constructor privado sin invocacion por diseno). Supera target >= 95%.

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
