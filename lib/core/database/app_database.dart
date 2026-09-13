// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/calculation/data/tables/calculation_materials_table.dart';
import '../../features/calculation/data/tables/calculations_table.dart';
import '../../features/catalog/filaments/data/filaments_table.dart';
import '../../features/catalog/printers/data/printers_table.dart';
import '../../features/entitlement/data/entitlements_table.dart';
import '../../features/settings/data/settings_table.dart';
import '../../features/settings/data/tables/discount_tiers_table.dart';

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
    Entitlements,
    DiscountTiersTable,
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
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // BUG-004 fix: el patron `if (from <= N)` re-ejecutaba migraciones
      // cuando un usuario venia de una version intermedia y un release
      // futuro publicaba un schemaVersion < N. La convencion correcta es
      // `if (from < N)`: cada bloque corre solo si la version actual del
      // usuario es estrictamente menor que la version objetivo del bloque,
      // lo cual garantiza que las migraciones se aplican en orden.
      if (from < 2) {
        // v1→v2: agregar columna brand a printers
        await m.addColumn(printers, printers.brand);
      }
      if (from < 3) {
        // v2→v3: agregar columnas F1 (mano de obra + post-procesado)
        await m.addColumn(calculations, calculations.laborCostSnapshot);
        await m.addColumn(calculations, calculations.postProcessCostSnapshot);
        await m.addColumn(calculations, calculations.failureCostSnapshot);
        await m.addColumn(calculations, calculations.markupCostSnapshot);
        await m.addColumn(
          calculations,
          calculations.minimumChargeAppliedSnapshot,
        );
        await m.addColumn(calculations, calculations.effectiveTotalSnapshot);
        await m.addColumn(calculations, calculations.laborRateSnapshot);
        await m.addColumn(calculations, calculations.postProcessRateSnapshot);
        await m.addColumn(calculations, calculations.failureRateSnapshot);
        await m.addColumn(calculations, calculations.minimumChargeSnapshot);
        await m.addColumn(calculations, calculations.markupOnMaterialsSnapshot);
      }
      if (from < 4) {
        // v3→v4: persistir minutos del tiempo de impresion por separado.
        // Antes solo se guardaba `totalHours` como decimal, perdiendo el
        // split h+m. Para registros viejos, minutos=0 (default) y el
        // notifier los deriva del decimal al recargar (best-effort).
        await m.addColumn(calculations, calculations.printMinutes);
      }
      if (from < 5) {
        // v4→v5: agregar tabla entitlements (T1 del plan de monetizacion).
        // Una sola fila activa a la vez (enforcement en
        // EntitlementRepository, no DB constraint).
        await m.createTable(entitlements);
      }
      if (from < 6) {
        // v5→v6: notas y condiciones comerciales por cotizacion (se
        // imprimen en el PDF). Columnas opcionales: registros viejos
        // quedan null.
        await m.addColumn(calculations, calculations.notes);
        await m.addColumn(calculations, calculations.conditions);
      }
      if (from < 7) {
        // v6→v7: plantillas de trabajo. Reusa la misma tabla
        // calculations con flag isTemplate (excluida de historial/
        // dashboard/cap). Registros viejos quedan isTemplate=false.
        await m.addColumn(calculations, calculations.isTemplate);
      }
      if (from < 8) {
        // v7→v8: cantidad por cotizacion (lotes). Aditiva: registros
        // viejos quedan quantity=1 (comportamiento identico al actual).
        await m.addColumn(calculations, calculations.quantity);
      }
      if (from < 9) {
        // v8→v9: persistir la foto de la pieza en el historial (F2).
        // Se guarda downscaled (max 1200px lado mayor, JPEG q85). Aditiva:
        // registros viejos quedan piece_image_blob NULL (sin foto).
        await m.addColumn(calculations, calculations.pieceImageBlob);
      }
      if (from < 10) {
        // v9→v10: amortizacion de impresora (F5). Aditiva: impresoras
        // viejas quedan purchase_cost/useful_life_hours NULL (sin linea
        // de amortizacion) y cotizaciones viejas amortization=0.
        await m.addColumn(printers, printers.purchaseCost);
        await m.addColumn(printers, printers.usefulLifeHours);
        await m.addColumn(calculations, calculations.amortizationCostSnapshot);
      }
      if (from < 11) {
        // v10→v11: color del filamento (RF1-1 del PRD 2026-09-08). Aditiva:
        // filamentos viejos quedan NULL (sin color, comportamiento actual).
        // El backup/restore de drift cubre la columna automaticamente via
        // `toJson()` de la data class.
        await m.addColumn(filaments, filaments.color);
      }
      if (from < 12) {
        // v11→v12: feature A (Hito 1 — descuento mayorista por cantidad).
        // + Tabla `discount_tiers` (escalones min_qty → %).
        // + Columnas batch en `calculations` (snapshot del escalón aplicado).
        //   Aditiva: registros viejos quedan batch_* NULL (sin línea de
        //   descuento de lote — comportamiento actual intacto, regla 95 %).
        await m.createTable(discountTiersTable);
        await m.addColumn(calculations, calculations.batchDiscountPercent);
        await m.addColumn(calculations, calculations.batchDiscountAmount);
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
