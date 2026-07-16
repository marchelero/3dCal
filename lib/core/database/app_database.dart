import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/calculation/data/tables/calculation_materials_table.dart';
import '../../features/calculation/data/tables/calculations_table.dart';
import '../../features/catalog/filaments/data/filaments_table.dart';
import '../../features/catalog/printers/data/printers_table.dart';
import '../../features/settings/data/settings_table.dart';

part 'app_database.g.dart';

/// Base de datos principal de tresdcal.
///
/// Centraliza todas las tablas (PRD §6.4 refinado por plan decision #1).
/// La apertura de conexion es cross-platform via `drift_flutter`:
/// - **Mobile** (iOS/Android): NativeDatabase con archivos en app docs dir.
/// - **Web**: WasmDatabase con persistencia en IndexedDB.
///
/// **Web setup**: requiere `sqlite3.wasm` y `drift_worker.dart.js` en `web/`.
/// Sprint 9 los agrega; Sprint 2-8 funcionan sin web runtime tests.
@DriftDatabase(
  tables: [
    Printers,
    Filaments,
    Calculations,
    CalculationMaterials,
    SettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Constructor default. Usa `driftDatabase` cross-platform.
  ///
  /// Sin seed on create — no se crean impresoras/filamentos por defecto.
  AppDatabase() : super(_openConnection());

  /// Constructor para tests. Acepta un [QueryExecutor] custom (ej: in-memory).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            // v1→v2: agregar columna brand a printers
            await m.addColumn(printers, printers.brand);
          }
        },
      );
}

/// Abre la conexion a la base de datos. Cross-platform via [driftDatabase].
///
/// **Web**: requiere `web/sqlite3.wasm` y `web/drift_worker.js` (pre-compilado
/// de drift releases, NO un dart_compile local — `package:web` v1.x necesita
/// plataforma web configurada que `dart compile js` no provee).
/// **Desktop/mobile**: drift_flutter usa `NativeDatabase` con path en
/// app docs dir. El parametro `web` se ignora en estas plataformas.
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'tresdcal',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}



