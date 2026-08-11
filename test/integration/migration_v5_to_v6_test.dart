// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
import 'package:drift/drift.dart' show QueryRow, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Integration test de la migracion Drift v5 → v6 (notas + condiciones por
/// cotizacion).
///
/// **Que prueba**: que un usuario que actualiza desde v5 (con datos
/// existentes) recibe las columnas `notes` y `conditions` en `calculations`
/// sin perder datos.
///
/// Mismo patron que migration_v4_to_v5_test.dart: seed del schema v5 raw
/// con `PRAGMA user_version = 5`, hand-off via `NativeDatabase.opened`, y
/// Drift dispara `onUpgrade(5, 6)` al abrir.
void _seedV5Schema(Database rawDb) {
  // --- printers (v5) ---
  rawDb.execute('''
    CREATE TABLE printers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      brand TEXT,
      name TEXT NOT NULL,
      average_watts INTEGER NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');

  // --- filaments (v5) ---
  rawDb.execute('''
    CREATE TABLE filaments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      brand TEXT,
      price_per_bobbin REAL NOT NULL,
      grams_per_bobbin REAL NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');

  // --- calculations (v5) — SIN notes/conditions (es el cambio de v6) ---
  rawDb.execute('''
    CREATE TABLE calculations (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      created_at INTEGER NOT NULL,
      piece_name TEXT,
      client_name TEXT,
      printer_id INTEGER,
      printer_name_snapshot TEXT,
      printer_watts_snapshot REAL NOT NULL DEFAULT 0,
      total_hours REAL NOT NULL,
      print_minutes INTEGER NOT NULL DEFAULT 0,
      discount_percentage REAL NOT NULL,
      kwh_rate_snapshot REAL NOT NULL,
      profit_base_snapshot REAL NOT NULL,
      is_sold INTEGER NOT NULL DEFAULT 0,
      material_cost_snapshot REAL NOT NULL,
      electric_cost_snapshot REAL NOT NULL,
      labor_cost_snapshot REAL NOT NULL,
      post_process_cost_snapshot REAL NOT NULL,
      base_cost_snapshot REAL NOT NULL,
      failure_cost_snapshot REAL NOT NULL,
      markup_cost_snapshot REAL NOT NULL,
      profit_amount_snapshot REAL NOT NULL,
      minimum_charge_applied_snapshot REAL NOT NULL,
      effective_total_snapshot REAL NOT NULL,
      total_price_snapshot REAL NOT NULL,
      labor_rate_snapshot REAL NOT NULL,
      post_process_rate_snapshot REAL NOT NULL,
      failure_rate_snapshot REAL NOT NULL,
      minimum_charge_snapshot REAL NOT NULL,
      markup_on_materials_snapshot REAL NOT NULL
    )
  ''');

  // --- calculation_materials (v5) ---
  rawDb.execute('''
    CREATE TABLE calculation_materials (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      calculation_id INTEGER NOT NULL,
      filament_id INTEGER,
      label TEXT NOT NULL,
      weight_grams REAL NOT NULL,
      price_per_bobbin_snapshot REAL NOT NULL,
      grams_per_bobbin_snapshot REAL NOT NULL
    )
  ''');

  // --- settings (v5) ---
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (key)
    )
  ''');

  // --- entitlements (v5) — creada en v4→v5 ---
  rawDb.execute('''
    CREATE TABLE entitlements (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      source TEXT NOT NULL,
      product_id TEXT NOT NULL,
      purchased_at INTEGER NOT NULL,
      validated_at INTEGER,
      expires_at INTEGER,
      receipt_data TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''');

  // --- seed 1 row representativa ---
  final nowEpoch = DateTime.utc(2026, 7, 22, 10, 0, 0).millisecondsSinceEpoch;

  rawDb.execute(
    'INSERT INTO printers '
    '(brand, name, average_watts, is_default, created_at) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Creality', 'Ender 3 V3', 120, 1, nowEpoch],
  );

  rawDb.execute(
    'INSERT INTO filaments '
    '(name, brand, price_per_bobbin, grams_per_bobbin, is_default, '
    'created_at) VALUES (?, ?, ?, ?, ?, ?)',
    ['PLA Negro', 'eSun', 120.0, 1000.0, 1, nowEpoch],
  );

  rawDb.execute(
    'INSERT INTO calculations '
    '(created_at, piece_name, client_name, printer_id, '
    'printer_name_snapshot, printer_watts_snapshot, total_hours, '
    'print_minutes, discount_percentage, kwh_rate_snapshot, '
    'profit_base_snapshot, is_sold, material_cost_snapshot, '
    'electric_cost_snapshot, labor_cost_snapshot, '
    'post_process_cost_snapshot, base_cost_snapshot, '
    'failure_cost_snapshot, markup_cost_snapshot, '
    'profit_amount_snapshot, minimum_charge_applied_snapshot, '
    'effective_total_snapshot, total_price_snapshot, '
    'labor_rate_snapshot, post_process_rate_snapshot, '
    'failure_rate_snapshot, minimum_charge_snapshot, '
    'markup_on_materials_snapshot) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '
    '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      nowEpoch,
      'Llave Allen',
      'Juan Perez',
      1,
      'Ender 3 V3',
      120.0,
      2.5,
      30,
      0.0,
      1.5,
      30.0,
      0,
      10.0,
      0.45,
      5.0,
      0.0,
      15.45,
      0.0,
      0.0,
      4.64,
      0,
      20.0,
      20.0,
      20.0,
      0.0,
      0.0,
      10.0,
      0.0,
    ],
  );

  rawDb.execute(
    'INSERT INTO calculation_materials '
    '(calculation_id, filament_id, label, weight_grams, '
    'price_per_bobbin_snapshot, grams_per_bobbin_snapshot) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [1, 1, 'PLA Negro', 85.0, 120.0, 1000.0],
  );

  rawDb.execute(
    'INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)',
    ['profit_base_percentage', '30', nowEpoch],
  );

  // Marca la DB como v5 para que AppDatabase dispare onUpgrade(5, 6).
  rawDb.execute('PRAGMA user_version = 5');
}

void main() {
  group('Migration v5 → v6', () {
    late AppDatabase db;
    late Database rawDb;

    setUp(() async {
      rawDb = sqlite3.openInMemory();
      _seedV5Schema(rawDb);
      final native = NativeDatabase.opened(rawDb);
      db = AppDatabase.forTesting(native);
      addTearDown(() async => db.close());
    });

    test('onUpgrade(5, 7) agrega notes/conditions y bumpea '
        'user_version a 7', () async {
      await db.customSelect('SELECT 1').get();

      final versionRows = await db.customSelect('PRAGMA user_version').get();
      expect(
        versionRows.first.read<int>('user_version'),
        7,
        reason: 'AppDatabase debe setear user_version=7 tras onUpgrade '
            '(cadena v5→v6 + v6→v7).',
      );

      final rows = await db
          .customSelect(
            'SELECT name, type, "notnull" AS isNotNull '
            'FROM pragma_table_info(\'calculations\')',
          )
          .get();
      final byName = <String, QueryRow>{};
      for (final r in rows) {
        byName[r.read<String>('name')] = r;
      }

      expect(
        byName['notes'],
        isNotNull,
        reason: 'v6 debe crear columna notes en calculations.',
      );
      expect(byName['notes']!.read<String>('type'), 'TEXT');
      expect(
        byName['notes']!.read<int>('isNotNull'),
        0,
        reason: 'notes debe ser NULLABLE (opcional).',
      );

      expect(
        byName['conditions'],
        isNotNull,
        reason: 'v6 debe crear columna conditions en calculations.',
      );
      expect(byName['conditions']!.read<String>('type'), 'TEXT');
      expect(
        byName['conditions']!.read<int>('isNotNull'),
        0,
        reason: 'conditions debe ser NULLABLE (opcional).',
      );
    });

    test(
      'migration es no-destructiva: datos v5 sobreviven con notas null',
      () async {
        await db.customSelect('SELECT 1').get();

        final calcs = await db.customSelect('SELECT * FROM calculations').get();
        expect(calcs, hasLength(1));
        expect(calcs.first.read<String>('piece_name'), 'Llave Allen');
        expect(calcs.first.read<String>('client_name'), 'Juan Perez');
        expect(calcs.first.read<double>('total_hours'), 2.5);
        expect(calcs.first.read<int>('print_minutes'), 30);
        expect(
          calcs.first.read<String?>('notes'),
          isNull,
          reason: 'Registros pre-v6 deben quedar con notes NULL.',
        );
        expect(
          calcs.first.read<String?>('conditions'),
          isNull,
          reason: 'Registros pre-v6 deben quedar con conditions NULL.',
        );
        expect(
          calcs.first.read<int>('is_template'),
          0,
          reason: 'Registros pre-v7 deben quedar con is_template=0 (default).',
        );

        final mats = await db
            .customSelect('SELECT * FROM calculation_materials')
            .get();
        expect(mats, hasLength(1));
        expect(mats.first.read<String>('label'), 'PLA Negro');
      },
    );

    test(
      'post-migration: insert + read de notas/condiciones via accessor',
      () async {
        await db.customSelect('SELECT 1').get();

        final id = await db
            .into(db.calculations)
            .insert(
              CalculationsCompanion.insert(
                createdAt: DateTime.now().toUtc(),
                pieceName: const Value('Pieza nueva'),
                clientName: const Value('Maria'),
                notes: const Value('Entregar en 3 dias'),
                conditions: const Value('Pago contra entrega'),
                totalHours: 1.5,
                printMinutes: const Value(20),
                discountPercentage: 0,
                kwhRateSnapshot: 0,
                profitBaseSnapshot: 0,
                materialCostSnapshot: 5,
                electricCostSnapshot: 0,
                laborCostSnapshot: 0,
                postProcessCostSnapshot: 0,
                baseCostSnapshot: 5,
                failureCostSnapshot: 0,
                markupCostSnapshot: 0,
                profitAmountSnapshot: 0,
                minimumChargeAppliedSnapshot: 0,
                effectiveTotalSnapshot: 5,
                totalPriceSnapshot: 5,
                laborRateSnapshot: 0,
                postProcessRateSnapshot: 0,
                failureRateSnapshot: 0,
                minimumChargeSnapshot: 0,
                markupOnMaterialsSnapshot: 0,
              ),
            );
        expect(id, greaterThan(0));

        final all = await db.select(db.calculations).get();
        final calc = all.firstWhere((c) => c.id == id);
        expect(calc.notes, 'Entregar en 3 dias');
        expect(calc.conditions, 'Pago contra entrega');
      },
    );
  });
}
