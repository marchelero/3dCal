import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

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
  /// `seedOnCreate = true`: la primera vez que se cree el schema en una
  /// DB vacia, se inserta filamento + impresora default.
  AppDatabase()
      : seedOnCreate = true,
        super(_openConnection());

  /// Constructor para tests. Acepta un [QueryExecutor] custom (ej: in-memory).
  ///
  /// [seedOnCreate] = false por default. En tests normalmente no queremos
  /// que se inserten datos semilla; los tests insertan lo que necesitan.
  AppDatabase.forTesting(super.executor, {this.seedOnCreate = false});

  /// Si true, ejecuta [_seedDefaults] al crear el schema.
  final bool seedOnCreate;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          if (seedOnCreate) {
            await _seedDefaults(this);
          }
        },
      );
}

/// Abre la conexion a la base de datos. Cross-platform via [driftDatabase].
///
/// **Web**: requiere `web/sqlite3.wasm` y `web/drift_worker.dart.js`. Ambos
/// se generan/download en setup del proyecto (ver `web/drift_worker.dart`).
/// **Desktop/mobile**: drift_flutter usa `NativeDatabase` con path en
/// app docs dir.
QueryExecutor _openConnection() {
  return driftDatabase(name: 'tresdcal');
}

/// Inserta filamento + impresora default si las tablas estan vacias.
Future<void> _seedDefaults(AppDatabase db) async {
  final printerCount = (await db.printers.count().getSingleOrNull()) ?? 0;
  if (printerCount == 0) {
    await db.into(db.printers).insert(
          PrintersCompanion.insert(
            name: 'Anycubic Kobra 3',
            averageWatts: 200,
            isDefault: const Value(true),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }
  final filamentCount = (await db.filaments.count().getSingleOrNull()) ?? 0;
  if (filamentCount == 0) {
    await db.into(db.filaments).insert(
          FilamentsCompanion.insert(
            name: 'PLA Generico',
            // ignore: prefer_int_literals
            pricePerBobbin: 150.0,
            // ignore: prefer_int_literals
            gramsPerBobbin: 1000.0,
            isDefault: const Value(true),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }
}
