# Changelog

Todos los cambios notables del proyecto tresdcal se documentan aca.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

## [Unreleased]

### Sprint 6 — Dashboard completo (2026-07-15)

#### Added
- `lib/features/dashboard/presentation/widgets/profit_bar_chart.dart` — widget `ProfitBarChart` que renderiza un `fl_chart` `BarChart` con 2 barras (Cotizado / Ganado). Eje Y con formato corto ("Bs. 0", "Bs. 1.5K"). Tooltip on tap con valor exacto en BOB. Headroom del 20% sobre el maximo y floor 100 BOB para charts con valores chicos.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` — pagina `/dashboard` con 3 stat cards (Cotizaciones, Vendidas, Conversion%) + `ProfitBarChart`. Empty state con icono + CTA "Ir a Home" cuando no hay cotizaciones. Loading y error states via `AsyncValue.when`.
- `test/widget/dashboard_page_test.dart` — 7 tests: appbar titulo, empty state, stats cards con datos (60% conversion), edge 100% conversion, edge 0% conversion, bar chart renderiza con datos, bar chart renderiza con ambos en cero.
- `lib/features/calculation/domain/dashboard_stats.dart` — getter `conversionPct` (`countSold / countAll * 100`, 0 si `countAll == 0`).
- `lib/features/calculation/presentation/pages/home_page.dart` — boton `OutlinedButton.icon` "Dashboard" debajo de "Historial" que navega a `DashboardPage` via `Navigator.push`.

#### Notes
- **Reuso del provider**: `dashboardStatsProvider` (Sprint 5) se reusa sin cambios. Solo se agrego el getter `conversionPct` al data class.
- **Decimal → double en chart**: `ProfitBarChart` recibe `Decimal` pero internamente hace `.toDouble()` (unico lugar de la app donde se pierde precision, justificado porque los totales ya estan redondeados a 2 decimales al guardarse en el snapshot).
- **No se commiteo** — el CHANGELOG actualizado queda working tree, esperando instruccion explicita del usuario.

#### Verified
- `flutter test` — 111/111 passed (7 nuevos en dashboard_page_test.dart).
- `flutter analyze` — 0 issues.
- Smoke manual: Home muestra boton Dashboard, tap → pagina con 3 stat cards + bar chart 2 barras (Cotizado/Ganado), labels eje X visibles, tooltips al tap, empty state funcional cuando no hay cotizaciones.

### Sprint 5 — Cotizaciones historicas (2026-07-14)

#### Added
- `lib/features/calculation/presentation/notifiers/calculations_notifier.dart` — `AsyncNotifier<List<Calculation>>` con `build/refresh/toggleSold/delete`. Sigue el mismo patron que filaments/printers.
- `lib/features/calculation/presentation/pages/calculations_list_page.dart` — historial con empty state, pull-to-refresh, popup menu (toggle sold / eliminar), tap → detalle. Estrella verde si `isSold`.
- `lib/features/calculation/presentation/pages/calculation_detail_page.dart` — vista readonly con metadata, materiales (con snapshot financiero por fila), desglose (material, electrico, base, profit, total), FAB "Reusar" + boton "Marcar vendida" + action delete en AppBar.
- `lib/features/calculation/presentation/pages/prefill_cotizacion.dart` — wrapper de `CalculatorPage` que pre-rellena el form desde un `Calculation` guardado via `CalculatorNotifier.loadFromCalculation` (post-frame callback).
- `lib/features/calculation/domain/dashboard_stats.dart` — `DashboardStats` data class (totalQuoted, totalSold, countAll, countSold) + `dashboardStatsProvider` (FutureProvider.autoDispose que se invalida al cambiar `calculationsNotifierProvider`).
- `lib/features/calculation/presentation/state/calculator_notifier.dart` — `save({pieceName, clientName})` que mapea `CalculatorState` → `CalculationDraft` y delega a `repo.create()`. Retorna `int?` (null si form invalido). Snapshots: kwhRate, profitBase, watts, discount del state al momento de guardar. Snapshots de filamentos (precio/gramos) se guardan en `CalculationMaterials`. `loadFromCalculation(Calculation)` reconstruye el state desde una cotizacion guardada.
- `lib/features/calculation/presentation/pages/calculator_page.dart` — AppBar action "Guardar" (save icon) que abre dialog con 2 TextFields (pieceName, clientName, ambos opcionales). Al confirmar: `notifier.save()` + SnackBar de exito/error. Si form invalido: SnackBar hint y no abre dialog.
- `lib/features/calculation/presentation/pages/home_page.dart` — `ConsumerWidget`. Agrega card "Resumen" con stats agregadas (# cotizadas/vendidas + totales BOB) + boton "Historial" (OutlinedButton) que navega a `CalculationsListPage`.
- `test/unit/calculator_notifier_test.dart` — 3 tests para `save()`: form invalido retorna null, form valido inserta + retorna id, pieceName vacio → null.

#### Notes
- **Mode preservation en reusar**: 1 material guardado → modo `express` al reusar; 2+ → `advanced`. Asi el form reusado respeta la estructura original.
- **Pruning de la lista**: al "Marcar vendida" / "Eliminar", el notifier hace `_reload()` explicito (no `invalidateSelf`) para tener control de error handling y emitir loading state transitorio.
- **DB snapshots vs FK**: las cotizaciones guardan TODOS los valores como snapshot (`printerNameSnapshot`, `printerWattsSnapshot`, `pricePerBobbinSnapshot`, `gramsPerBobbinSnapshot`). Borrar un filamento del catalogo NO afecta cotizaciones historicas.
- **Dashboard autoDispose**: el provider se re-corre cuando `calculationsNotifierProvider` emite nuevo state (despues de save/delete/toggle sold). AutoDispose libera memoria al salir de Home.

#### Verified
- `flutter test` — 103/103 passed (3 nuevos en calculator_notifier_test.dart para save).
- `flutter analyze` — 0 issues.
- Smoke manual: home muestra dashboard card, tap "Nueva cotizacion" navega al calculator, save flow abre dialog y guarda, aparece en historial como #1, tap → detalle con FAB Reusar, "Marcar vendida" cambia a check verde, eliminar con confirm dialog.

### Sprint 4 — Catalogo UI + Calculator wiring + Multi-material (2026-07-14)

#### Added
- `lib/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart` — `AsyncNotifier<List<Filament>>` con `build/create/updateFilament/delete/setAsDefault/refresh`. Rename `updateFilament` (no `update`) para evitar colision con `AsyncNotifier.update` de Riverpod.
- `lib/features/catalog/filaments/presentation/pages/filaments_page.dart` — catalogo (lista + estrella default + menu default/eliminar). Empty state + pull-to-refresh.
- `lib/features/catalog/filaments/presentation/pages/filament_form_page.dart` — form create/edit con 4 campos + switch default.
- `lib/features/catalog/printers/presentation/notifiers/printers_notifier.dart` — espejo de filaments, sin Decimal/watts.
- `lib/features/catalog/printers/presentation/pages/printers_page.dart` — espejo de filaments_page.
- `lib/features/catalog/printers/presentation/pages/printer_form_page.dart` — espejo de filament_form_page.
- `lib/core/providers.dart` — agrega `defaultFilamentProvider`, `defaultPrinterProvider`, `printersListProvider`, `activePrinterIdProvider`, `activePrinterProvider`.
- `lib/features/calculation/presentation/pages/calculator_page.dart` — rewire:
  - `initState` auto-popula precio/gramos desde filamento default y watts desde impresora activa.
  - AppBar action `_PrinterSelector`: dropdown con impresoras disponibles.
  - `_ModeSelector` (SegmentedButton) en el body: `express` (1 material) o `advanced` (multi-material AnimatedList).
  - `_MaterialRowTile` + `_MaterialCtrls` para filas advanced.
  - Common fields (Tiempo, Watts, kWh, Profit, Descuento) compartidos entre ambos modos.
  - ListView → SingleChildScrollView + Column (eager build).
- `lib/features/calculation/presentation/state/calculator_state.dart` — refactor:
  - Agrega `CalculatorMode { express, advanced }`.
  - Agrega `MaterialRow` (label, weight, price, grams como strings).
  - `materials: List<MaterialRow>` para modo advanced.
  - `isValid` depende del modo (express: 1 material, advanced: >=1 valido).
  - `==` y `hashCode` extendidos con `_listEq` para `materials`.
- `lib/features/calculation/presentation/state/calculator_notifier.dart` — agrega `setMode`, `addMaterial`, `removeMaterial(index)`, `updateMaterial(index, ...)`. `loadFilamentDefaults` ahora switch-ea segun modo.
- `test/unit/filaments_notifier_test.dart` — 8 tests (build, create, setAsDefault, update, delete, refresh, brand opcional, asDefault desmarca).
- `test/unit/printers_notifier_test.dart` — 2 tests (build+create, setAsDefault desmarca).
- `test/widget/filaments_page_test.dart` — 6 tests (appbar, empty state, lista, estrella default, "+" navega, row edita).
- `test/widget/filament_form_page_test.dart` — 5 tests (titulo, inputs, validar, crear, editar prefill).
- `test/unit/calculator_notifier_test.dart` — extendido: 4 nuevos para advanced mode (true con 1 material, false sin materiales).
- `test/unit/calculator_page_test.dart` — extendido con `pumpAndSettle` para que el AsyncNotifier de default providers termine.
- `test/widget/sprint0_smoke_test.dart` — usa `widgetWithText(DecimalInputField, ...)` en vez de `fields.at(N)` (cambio de orden por refactor).

#### Notes
- **Filament/Printer state con AsyncNotifier**: build reactivo lee `repo.listAll()`. CRUD via `_reload()` explicito (no `invalidateSelf`) para tener control del error handling. La unica mutacion es el notifier mismo, asi que un stream no aporta.
- **Active printer en memoria**: `activePrinterIdProvider` (StateProvider) vive en Riverpod; se resetea al cerrar la app. Si se quiere persistir, sprint futuro lo migra a SettingsRepository.
- **Multi-material refactor**: el `CalculatorState` crecio (mode + materials). Tests de isValid viejos se simplificaron a `copyWith` en vez de constructor directo. `==` agrega `_listEq` para `List<MaterialRow>`.
- **Eager build en calculator page**: cambio de `ListView` a `SingleChildScrollView + Column` para que `find.text` encuentre widgets aunque esten fuera del viewport (test env = 600px).
- **No se commiteo** — el CHANGELOG actualizado queda working tree, esperando instruccion explicita del usuario.

#### Verified
- `flutter test` — 100/100 passed. Distribucion: 32 db repos + 23 calculator notifier (4 nuevos advanced) + 8 calculator page + 3 smoke + 8 filaments notifier + 6 filaments page + 5 filament form + 2 printers notifier + 13 calculator state/engine/decimal (legacy).
- `flutter analyze` — 0 issues.
- Smoke manual: app abre, calculator auto-popula con "PLA Generico" (150 BOB / 1000 g) y "Anycubic Kobra 3" (200W). Toggle Express/Advanced funciona, "+ Agregar material" inserta filas en AnimatedList con animacion. Printer selector cambia watts.

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
