// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
//
// Migracion v1 | v2 | v3 -> v17 (AC-011).
//
// Cubre el camino mas largo de la historia del schema: una base creada en la
// primera version publicada (v1) y las dos primeras evoluciones (v2: brand de
// impresora; v3: snapshots F1 de mano de obra/postprocesado/fallo/markup/
// minimo/efectivo) deben llegar a schema 17 con los datos intactos y los
// defaults aditivos aplicados.
//
// Contrato a proteger:
// - Datos de trabajo (cotizacion, material, filamento, impresora, settings)
//   sobreviven los 14+ saltos de version.
// - Toda columna aditiva queda con el default documentado en el schema
//   actual (is_partial=0, is_advanced=0, quantity=1, modeling_mode='auto',
//   postproc_mode='auto', extra_mode='off', extra_label='', etc.).
// - Tablas creadas despues de v3 (entitlements en v5, discount_tiers en v12)
//   existen y estan vacias tras migrar.
library;

import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

const int _kSeedTs = 1234567890;

/// Schema v1 = tablas base (printers, filaments, calculations,
/// calculation_materials, settings). Sin `brand` en printers y sin las
/// columnas F1 de calculations (v3+).
void _seedV1Schema(Database rawDb) {
  rawDb.execute('''
    CREATE TABLE printers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      average_watts INTEGER NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');
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
      discount_percentage REAL NOT NULL DEFAULT 0,
      kwh_rate_snapshot REAL NOT NULL DEFAULT 0,
      profit_base_snapshot REAL NOT NULL DEFAULT 0,
      is_sold INTEGER NOT NULL DEFAULT 0,
      material_cost_snapshot REAL NOT NULL,
      electric_cost_snapshot REAL NOT NULL,
      base_cost_snapshot REAL NOT NULL,
      profit_amount_snapshot REAL NOT NULL,
      total_price_snapshot REAL NOT NULL
    )
  ''');
  rawDb.execute('''
    CREATE TABLE calculation_materials (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      calculation_id INTEGER NOT NULL
        REFERENCES calculations(id) ON DELETE CASCADE,
      filament_id INTEGER,
      label TEXT NOT NULL,
      weight_grams REAL NOT NULL,
      price_per_bobbin_snapshot REAL NOT NULL,
      grams_per_bobbin_snapshot REAL NOT NULL
    )
  ''');
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  _seedSharedRows(rawDb, printerBrand: null, v3Columns: false);
  rawDb.execute('PRAGMA user_version = 1');
}

/// Schema v2 = v1 + `brand` en printers.
void _seedV2Schema(Database rawDb) {
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
      discount_percentage REAL NOT NULL DEFAULT 0,
      kwh_rate_snapshot REAL NOT NULL DEFAULT 0,
      profit_base_snapshot REAL NOT NULL DEFAULT 0,
      is_sold INTEGER NOT NULL DEFAULT 0,
      material_cost_snapshot REAL NOT NULL,
      electric_cost_snapshot REAL NOT NULL,
      base_cost_snapshot REAL NOT NULL,
      profit_amount_snapshot REAL NOT NULL,
      total_price_snapshot REAL NOT NULL
    )
  ''');
  rawDb.execute('''
    CREATE TABLE calculation_materials (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      calculation_id INTEGER NOT NULL
        REFERENCES calculations(id) ON DELETE CASCADE,
      filament_id INTEGER,
      label TEXT NOT NULL,
      weight_grams REAL NOT NULL,
      price_per_bobbin_snapshot REAL NOT NULL,
      grams_per_bobbin_snapshot REAL NOT NULL
    )
  ''');
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  _seedSharedRows(rawDb, printerBrand: 'Creality', v3Columns: false);
  rawDb.execute('PRAGMA user_version = 2');
}

/// Schema v3 = v2 + columnas F1 de calculations (snapshots de mano de obra,
/// postprocesado, fallo, markup, minimo y total efectivo).
void _seedV3Schema(Database rawDb) {
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
      discount_percentage REAL NOT NULL DEFAULT 0,
      kwh_rate_snapshot REAL NOT NULL DEFAULT 0,
      profit_base_snapshot REAL NOT NULL DEFAULT 0,
      is_sold INTEGER NOT NULL DEFAULT 0,
      material_cost_snapshot REAL NOT NULL,
      electric_cost_snapshot REAL NOT NULL,
      labor_cost_snapshot REAL NOT NULL DEFAULT 0,
      post_process_cost_snapshot REAL NOT NULL DEFAULT 0,
      base_cost_snapshot REAL NOT NULL,
      failure_cost_snapshot REAL NOT NULL DEFAULT 0,
      markup_cost_snapshot REAL NOT NULL DEFAULT 0,
      profit_amount_snapshot REAL NOT NULL,
      minimum_charge_applied_snapshot REAL NOT NULL DEFAULT 0,
      effective_total_snapshot REAL NOT NULL DEFAULT 0,
      total_price_snapshot REAL NOT NULL,
      labor_rate_snapshot REAL NOT NULL DEFAULT 0,
      post_process_rate_snapshot REAL NOT NULL DEFAULT 0,
      failure_rate_snapshot REAL NOT NULL DEFAULT 0,
      minimum_charge_snapshot REAL NOT NULL DEFAULT 0,
      markup_on_materials_snapshot REAL NOT NULL DEFAULT 0
    )
  ''');
  rawDb.execute('''
    CREATE TABLE calculation_materials (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      calculation_id INTEGER NOT NULL
        REFERENCES calculations(id) ON DELETE CASCADE,
      filament_id INTEGER,
      label TEXT NOT NULL,
      weight_grams REAL NOT NULL,
      price_per_bobbin_snapshot REAL NOT NULL,
      grams_per_bobbin_snapshot REAL NOT NULL
    )
  ''');
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  _seedSharedRows(rawDb, printerBrand: 'Creality', v3Columns: true);
  rawDb.execute('PRAGMA user_version = 3');
}

void _seedSharedRows(
  Database rawDb, {
  required String? printerBrand,
  required bool v3Columns,
}) {
  if (printerBrand == null) {
    rawDb.execute(
      'INSERT INTO printers (name, average_watts, is_default, created_at) '
      'VALUES (?, ?, 1, ?)',
      ['Kobra 3', 200, _kSeedTs],
    );
  } else {
    rawDb.execute(
      'INSERT INTO printers (brand, name, average_watts, is_default, '
      'created_at) VALUES (?, ?, ?, 1, ?)',
      [printerBrand, 'Kobra 3', 200, _kSeedTs],
    );
  }

  rawDb.execute(
    'INSERT INTO filaments (name, brand, price_per_bobbin, '
    'grams_per_bobbin, is_default, created_at) VALUES (?, ?, ?, ?, 1, ?)',
    ['PLA Negro', 'eSun', 120.0, 1000.0, _kSeedTs],
  );

  if (v3Columns) {
    rawDb.execute(
      'INSERT INTO calculations '
      '(created_at, piece_name, printer_id, printer_name_snapshot, '
      'total_hours, discount_percentage, kwh_rate_snapshot, '
      'profit_base_snapshot, material_cost_snapshot, '
      'electric_cost_snapshot, labor_cost_snapshot, '
      'post_process_cost_snapshot, base_cost_snapshot, '
      'failure_cost_snapshot, markup_cost_snapshot, '
      'profit_amount_snapshot, minimum_charge_applied_snapshot, '
      'effective_total_snapshot, total_price_snapshot, '
      'labor_rate_snapshot, post_process_rate_snapshot, '
      'failure_rate_snapshot, minimum_charge_snapshot, '
      'markup_on_materials_snapshot) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '
      '?, ?, ?, ?, ?)',
      [
        _kSeedTs,
        'Pieza legacy v3',
        1,
        'Kobra 3',
        1.5,
        0,
        0.65,
        30,
        8.0,
        2.0,
        0.0,
        0.0,
        10.0,
        0.0,
        0.0,
        3.0,
        0.0,
        10.0,
        13.0,
        15.0,
        5.0,
        10.0,
        30.0,
        20.0,
      ],
    );
  } else {
    rawDb.execute(
      'INSERT INTO calculations '
      '(created_at, piece_name, printer_id, printer_name_snapshot, '
      'total_hours, discount_percentage, kwh_rate_snapshot, '
      'profit_base_snapshot, material_cost_snapshot, '
      'electric_cost_snapshot, base_cost_snapshot, '
      'profit_amount_snapshot, total_price_snapshot) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _kSeedTs,
        'Pieza legacy v1',
        1,
        'Kobra 3',
        1.5,
        0,
        0.65,
        30,
        8.0,
        2.0,
        10.0,
        3.0,
        13.0,
      ],
    );
  }

  rawDb.execute(
    'INSERT INTO calculation_materials (calculation_id, filament_id, label, '
    'weight_grams, price_per_bobbin_snapshot, grams_per_bobbin_snapshot) '
    'VALUES (1, 1, ?, ?, ?, ?)',
    ['PLA Negro', 25.0, 120.0, 1000.0],
  );

  rawDb.execute(
    'INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)',
    ['profit_base_percentage', '30', _kSeedTs],
  );
  rawDb.execute(
    'INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)',
    ['kwh_rate', '0.65', _kSeedTs],
  );
}

Future<Map<String, QueryRow>> _columnsOf(AppDatabase db, String table) async {
  final cols = await db
      .customSelect(
        'SELECT name FROM pragma_table_info(?1)',
        variables: [Variable(table)],
      )
      .get();
  return {for (final r in cols) r.read<String>('name'): r};
}

/// Verifica el contrato completo tras migrar a 17.
Future<void> _assertMigratedToV17(
  AppDatabase db, {
  required String expectedPiece,
  required bool seedHasBrand,
  required bool seedHasV3CostColumns,
}) async {
  // user_version 17.
  final v = await db.customSelect('PRAGMA user_version').get();
  expect(v.first.read<int>('user_version'), 17);

  // Datos de trabajo preservados.
  final calcs = await db.customSelect('SELECT * FROM calculations').get();
  expect(calcs, hasLength(1));
  final calc = calcs.first;
  expect(calc.read<String>('piece_name'), expectedPiece);
  expect(calc.read<double>('kwh_rate_snapshot'), 0.65);
  expect(calc.read<double>('profit_base_snapshot'), 30);
  expect(calc.read<double>('material_cost_snapshot'), 8.0);
  expect(calc.read<double>('electric_cost_snapshot'), 2.0);
  expect(calc.read<double>('base_cost_snapshot'), 10.0);
  expect(calc.read<double>('profit_amount_snapshot'), 3.0);
  expect(calc.read<double>('total_price_snapshot'), 13.0);
  expect(calc.read<int>('printer_id'), 1);
  expect(calc.read<String>('printer_name_snapshot'), 'Kobra 3');

  if (seedHasV3CostColumns) {
    expect(calc.read<double>('labor_rate_snapshot'), 15.0);
    expect(calc.read<double>('post_process_rate_snapshot'), 5.0);
    expect(calc.read<double>('failure_rate_snapshot'), 10.0);
    expect(calc.read<double>('minimum_charge_snapshot'), 30.0);
    expect(calc.read<double>('markup_on_materials_snapshot'), 20.0);
  } else {
    // Columnas v3 sobre filas v1/v2: default 0.
    expect(calc.read<double>('labor_cost_snapshot'), 0);
    expect(calc.read<double>('post_process_cost_snapshot'), 0);
    expect(calc.read<double>('failure_cost_snapshot'), 0);
    expect(calc.read<double>('markup_cost_snapshot'), 0);
    expect(calc.read<double>('minimum_charge_applied_snapshot'), 0);
    expect(calc.read<double>('effective_total_snapshot'), 0);
    expect(calc.read<double>('labor_rate_snapshot'), 0);
    expect(calc.read<double>('post_process_rate_snapshot'), 0);
    expect(calc.read<double>('failure_rate_snapshot'), 0);
    expect(calc.read<double>('minimum_charge_snapshot'), 0);
    expect(calc.read<double>('markup_on_materials_snapshot'), 0);
  }

  // Defaults aditivos de migraciones posteriores.
  expect(calc.read<int>('print_minutes'), 0);
  expect(calc.read<int>('quantity'), 1);
  expect(calc.read<int>('is_sold'), 0);
  expect(calc.read<int>('is_template'), 0);
  expect(calc.read<int>('is_partial'), 0);
  expect(calc.read<int>('is_advanced'), 0);
  expect(calc.read<double>('amortization_cost_snapshot'), 0);
  expect(calc.read<String?>('notes'), isNull);
  expect(calc.read<String?>('conditions'), isNull);
  expect(calc.read<Uint8List?>('piece_image_blob'), isNull);
  expect(calc.read<String?>('batch_discount_percent'), isNull);
  expect(calc.read<String?>('batch_discount_amount'), isNull);
  // v17: defaults que reproducen el calculo legacy.
  expect(calc.read<String>('modeling_mode'), 'auto');
  expect(calc.read<double>('modeling_value'), 0);
  expect(calc.read<String>('postproc_mode'), 'auto');
  expect(calc.read<double>('postproc_value'), 0);
  expect(calc.read<String>('extra_mode'), 'off');
  expect(calc.read<double>('extra_value'), 0);
  expect(calc.read<String>('extra_label'), '');

  // Materiales: tiempo propio v15 en NULL (usa tiempo global).
  final mats = await db
      .customSelect('SELECT * FROM calculation_materials')
      .get();
  expect(mats, hasLength(1));
  expect(mats.first.read<String>('label'), 'PLA Negro');
  expect(mats.first.read<double>('weight_grams'), 25.0);
  expect(mats.first.read<bool?>('use_own_time'), isNull);
  expect(mats.first.read<double?>('material_hours'), isNull);
  expect(mats.first.read<double?>('material_minutes'), isNull);

  // Filamento: color v11 en NULL.
  final fils = await db.customSelect('SELECT * FROM filaments').get();
  expect(fils, hasLength(1));
  expect(fils.first.read<String>('name'), 'PLA Negro');
  expect(fils.first.read<String?>('color'), isNull);

  // Impresora: defaults aditivos.
  final printers = await db.customSelect('SELECT * FROM printers').get();
  expect(printers, hasLength(1));
  expect(printers.first.read<String>('name'), 'Kobra 3');
  expect(printers.first.read<int>('average_watts'), 200);
  expect(
    printers.first.read<String?>('brand'),
    seedHasBrand ? 'Creality' : null,
  );
  expect(printers.first.read<double?>('purchase_cost'), isNull);
  expect(printers.first.read<int?>('useful_life_hours'), isNull);
  expect(printers.first.read<int?>('current_hours'), isNull);

  // Settings intactos.
  final settings = await db
      .customSelect('SELECT * FROM settings ORDER BY key')
      .get();
  expect(settings, hasLength(2));
  expect(settings.first.read<String>('key'), 'kwh_rate');
  expect(settings.first.read<String>('value'), '0.65');

  // Tablas creadas despues de v3 existen y estan vacias.
  final entitlementsExists = await _columnsOf(db, 'entitlements');
  expect(entitlementsExists, isNotEmpty);
  final tiersExists = await _columnsOf(db, 'discount_tiers');
  expect(tiersExists, isNotEmpty);
  final ents = await db
      .customSelect('SELECT COUNT(*) AS n FROM entitlements')
      .get();
  expect(ents.first.read<int>('n'), 0);
  final tiers = await db
      .customSelect('SELECT COUNT(*) AS n FROM discount_tiers')
      .get();
  expect(tiers.first.read<int>('n'), 0);
}

Future<void> _expectV17Columns(AppDatabase db) async {
  final byName = await _columnsOf(db, 'calculations');
  for (final col in [
    'print_minutes',
    'notes',
    'conditions',
    'is_template',
    'quantity',
    'piece_image_blob',
    'amortization_cost_snapshot',
    'batch_discount_percent',
    'batch_discount_amount',
    'is_partial',
    'is_advanced',
    'modeling_mode',
    'modeling_value',
    'postproc_mode',
    'postproc_value',
    'extra_mode',
    'extra_value',
    'extra_label',
  ]) {
    expect(byName[col], isNotNull, reason: 'v17 debe tener columna `$col`.');
  }
}

void main() {
  void defineGroup(
    String label, {
    required void Function(Database) seed,
    required String expectedPiece,
    required bool seedHasBrand,
    required bool seedHasV3CostColumns,
  }) {
    group(label, () {
      late Database rawDb;

      setUp(() {
        rawDb = sqlite3.openInMemory();
        seed(rawDb);
      });

      tearDown(() {
        rawDb.close();
      });

      test('migra a 17 preservando datos y aplicando defaults', () async {
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        await _assertMigratedToV17(
          db,
          expectedPiece: expectedPiece,
          seedHasBrand: seedHasBrand,
          seedHasV3CostColumns: seedHasV3CostColumns,
        );
      });

      test('schema 17 final: columnas aditivas presentes', () async {
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        await _expectV17Columns(db);
      });

      test('re-open es idempotente (no re-migra)', () async {
        final db1 = AppDatabase.forTesting(
          NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
        );
        await db1.customSelect('SELECT 1').get();
        final v1 = await db1.customSelect('PRAGMA user_version').get();
        expect(v1.first.read<int>('user_version'), 17);
        await db1.close();

        final db2 = AppDatabase.forTesting(
          NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
        );
        addTearDown(() async => db2.close());
        await db2.customSelect('SELECT 1').get();
        final v2 = await db2.customSelect('PRAGMA user_version').get();
        expect(
          v2.first.read<int>('user_version'),
          17,
          reason: 'Segunda apertura no debe re-ejecutar la migracion.',
        );
      });
    });
  }

  defineGroup(
    'Migracion v1 -> v17',
    seed: _seedV1Schema,
    expectedPiece: 'Pieza legacy v1',
    seedHasBrand: false,
    seedHasV3CostColumns: false,
  );

  defineGroup(
    'Migracion v2 -> v17',
    seed: _seedV2Schema,
    expectedPiece: 'Pieza legacy v1',
    seedHasBrand: true,
    seedHasV3CostColumns: false,
  );

  defineGroup(
    'Migracion v3 -> v17',
    seed: _seedV3Schema,
    expectedPiece: 'Pieza legacy v3',
    seedHasBrand: true,
    seedHasV3CostColumns: true,
  );
}
