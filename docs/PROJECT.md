# Project Context

> Source of truth: actual project files (pubspec.yaml, lib/, etc.)
> Edit `Conventions` / `Non-Negotiables` / `Architecture Notes` sections manually — they are preserved across refreshes.

## Identity
- **Name**: 3dcal (3D Cal — Calculadora de Precios para Impresion 3D)
- **Type**: mobile + web app
- **Description**: Calculadora reactiva de precios para impresiones 3D con calculo multi-material, catalogo local de filamentos e impresoras, historial y dashboard de ganancias reales vs cotizadas. 100% offline, sin auth, sin backend.

## Stack
- **Language**: Dart (3.x, null safety estricto)
- **Framework**: Flutter (3.22+ estable, soporte web + mobile desde mismo codebase)
- **Runtime / Build**: Flutter SDK + MaterialApp 3 / Cupertino segun plataforma
- **Package manager**: pub (pubspec.yaml)
- **State management**: Riverpod 2.x (codegen) — NO setState en vistas dinamicas
- **Database**: drift 2.x (SQLite cross-platform — Isar NO anda en web, drift es la unica opcion seria para paridad total)
- **Money math**: paquete `decimal` (prohibido `double` en motor de calculo)
- **Charts**: `fl_chart` (bar chart dashboard)
- **i18n**: es_BO por default, BOB hardcoded
- **Deployment**: web = build estatico; mobile = debug APK / eventual store
- **Test**: flutter_test + integration_test

## Conventions
- Idiomas: espanol en UI, comentarios tecnicos en espanol. Codigo (variables, funciones) en ingles.
- Estilo: dart format + dart analyze. line_length 100.
- Commits: conventional commits (feat, fix, refactor, docs, test, chore, perf).
- Branching: main estable, feature/xxx para trabajo.
- Estructura: feature-first (ver Directorio).

## Directory Layout
```
lib/
  main.dart                    # bootstrap + ProviderScope
  app.dart                     # MaterialApp + router
  core/
    money/                     # decimal helpers, formatters BOB
    constants/                 # kBobElectricityRate, kDefaultProfitBase
    theme/                     # Material 3 themes
  features/
    calculation/
      domain/                  # CalculationEngine, entities puras
      data/                    # drift DAOs, repos
      presentation/            # pages, widgets, notifiers
    catalog/
      filaments/               # CRUD filamentos
      printers/                # CRUD impresoras
    history/                   # lista cronologica + isSold toggle
    dashboard/                 # chart ganancias reales vs cotizadas
    settings/                  # params globales
  shared/
    widgets/                   # design-system primitives (StatTile, SectionCard, MoneyRow, etc)
test/
  unit/                        # motor de calculo
  widget/                      # componentes
  integration/                 # flows
```

## License
unspecified (a definir por el usuario — sugerir MIT para codigo abierto)

## Non-Negotiables
- **No backend**: 100% local. Cero red. Cero auth. Privacidad absoluta.
- **No doubles en dinero**: motor de calculo con `decimal` o `int` centavos. `double` solo en formateo final.
- **No setState en vistas dinamicas**: solo Riverpod notifiers.
- **Regla del 95%**: modo Express visible por defecto (3 inputs).
- **No cloud sync**: cualquier feature de sync es out of scope MVP.
- **License**: inherited from user project (no embedded license in starter)

## Architecture Notes
```
- Drift reemplaza Isar (justificada: Isar v3 no compila en Flutter Web).
  Migrar a Isar v4 cuando estabilice web es opcion futura, NO MVP.
- Riverpod 2.x con codegen (`@riverpod`) para reducir boilerplate.
- Calculation Engine es clase pura sin dependencias de Flutter — testeable
  sin WidgetTester.
- drift genera DAOs tipados. Embedded lists se modelan con tablas
  child + FK, no @Embedded (drift no soporta igual que Isar).
- Web = mismo codigo, build con `flutter build web`.
- IndexedDB es backend de drift en web (via sqlcipher_wasm o sqlite3.wasm).
```

## Open Questions
- (resolver durante implementacion, no bloquean PRD)
  - Drift web backend: `drift_flutter` con `sqlite3_wasm` vs `package:drift/web/worker.dart`. Default: `drift_flutter` por simplicidad.
  - Charts en web: fl_chart funciona en canvas web sin cambios. Default OK.
  - Tamaños de fuente y densidad: configurable via theme, default M3.
