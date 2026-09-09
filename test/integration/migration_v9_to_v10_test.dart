// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryRow, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Integration test de la migracion Drift v9 → v10 (amortizacion de
/// impresora por hora, F5).
///
/// **Que prueba**: que un usuario que actualiza desde v9 (con datos
/// existentes) recibe `purchase_cost`/`useful_life_hours` en `printers` y
/// `amortization_cost_snapshot` en `calculations`, sin perder datos.
///
/// Mismo patron que migration_v8_to_v9: seed del schema v9 raw con
/// `PRAGMA user_version = 9`, hand-off via `NativeDatabase.opened`, y
/// Drift dispara `onUpgrade(9, 11)` al abrir.
void _seedV9Schema(Database rawDb) {
  // --- printers (v9) — SIN purchase_cost/useful_life_hours (v10) ---
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

  // --- filaments (v9) ---
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

  // --- calculations (v9) — CON piece_image_blob, SIN amortization (v10) ---
  rawDb.execute('''
    CREATE TABLE calculations (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      created_at INTEGER NOT NULL,
      piece_name TEXT,
      client_name TEXT,
      notes TEXT,
      conditions TEXT,
      printer_id INTEGER,
      printer_name_snapshot TEXT,
      printer_watts_snapshot REAL NOT NULL DEFAULT 0,
      total_hours REAL NOT NULL,
      print_minutes INTEGER NOT NULL DEFAULT 0,
      discount_percentage REAL NOT NULL,
      kwh_rate_snapshot REAL NOT NULL,
      profit_base_snapshot REAL NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      is_sold INTEGER NOT NULL DEFAULT 0,
      is_template INTEGER NOT NULL DEFAULT 0,
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
      markup_on_materials_snapshot REAL NOT NULL,
      piece_image_blob BLOB
    )
  ''');

  // --- calculation_materials (v9) ---
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

  // --- settings (v9) ---
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (key)
    )
  ''');

  // --- entitlements (v9) ---
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

  // --- seed 1 fila representativa ---
  final nowEpoch = DateTime.utc(2026, 9, 7, 10, 0, 0).millisecondsSinceEpoch;

  rawDb.execute(
    'INSERT INTO printers '
    '(brand, name, average_watts, is_default, created_at) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Creality', 'Ender 3 V3', 120, 1, nowEpoch],
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
    'markup_on_materials_snapshot, notes, conditions, '
    'is_template, quantity, piece_image_blob) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '
    '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      nowEpoch,
      'Vaso con foto',
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
      'Entregar en 3 dias',
      'Pago contra entrega',
      0,
      2,
      Uint8List.fromList([1, 2, 3, 4]),
    ],
  );

  // Marca la DB como v9 para que AppDatabase dispare onUpgrade(9, 11).
  rawDb.execute('PRAGMA user_version = 9');
}

void main() {
  group('Migration v9 → v10', () {
    late AppDatabase db;
    late Database rawDb;

    setUp(() async {
      rawDb = sqlite3.openInMemory();
      _seedV9Schema(rawDb);
      final native = NativeDatabase.opened(rawDb);
      db = AppDatabase.forTesting(native);
      addTearDown(() async => db.close());
    });

    test(
      'onUpgrade(9, 11) agrega columnas F5 y bumpea user_version a 11',
      () async {
        await db.customSelect('SELECT 1').get();

        final versionRows = await db.customSelect('PRAGMA user_version').get();
        expect(
          versionRows.first.read<int>('user_version'),
          11,
          reason: 'AppDatabase debe setear user_version=11 tras onUpgrade.',
        );
        expect(db.schemaVersion, 11);

        // printers: purchase_cost REAL nullable + useful_life_hours INTEGER.
        final printerCols = await db
            .customSelect(
              'SELECT name, type, "notnull" AS isNotNull '
              'FROM pragma_table_info(\'printers\')',
            )
            .get();
        final pByName = <String, QueryRow>{};
        for (final r in printerCols) {
          pByName[r.read<String>('name')] = r;
        }
        expect(
          pByName['purchase_cost'],
          isNotNull,
          reason: 'v10 debe crear purchase_cost en printers.',
        );
        expect(pByName['purchase_cost']!.read<String>('type'), 'REAL');
        expect(
          pByName['purchase_cost']!.read<int>('isNotNull'),
          0,
          reason: 'purchase_cost NULLABLE (sin linea si vacio).',
        );
        expect(
          pByName['useful_life_hours'],
          isNotNull,
          reason: 'v10 debe crear useful_life_hours en printers.',
        );
        expect(pByName['useful_life_hours']!.read<String>('type'), 'INTEGER');

        // calculations: amortization_cost_snapshot REAL.
        final calcCols = await db
            .customSelect(
              'SELECT name FROM pragma_table_info(\'calculations\')',
            )
            .get();
        final cNames = calcCols.map((r) => r.read<String>('name')).toSet();
        expect(
          cNames.contains('amortization_cost_snapshot'),
          isTrue,
          reason: 'v10 debe crear amortization_cost_snapshot en calculations.',
        );
      },
    );

    test(
      'migracion es no-destructiva: datos v9 sobreviven con defaults F5',
      () async {
        await db.customSelect('SELECT 1').get();

        final printers = await db.customSelect('SELECT * FROM printers').get();
        expect(printers, hasLength(1));
        expect(printers.first.read<String>('name'), 'Ender 3 V3');
        expect(
          printers.first.read<double?>('purchase_cost'),
          isNull,
          reason: 'Impresoras pre-v10 quedan sin costo (NULL).',
        );
        expect(
          printers.first.read<int?>('useful_life_hours'),
          isNull,
          reason: 'Impresoras pre-v10 quedan sin vida util (NULL).',
        );

        final calcs = await db.customSelect('SELECT * FROM calculations').get();
        expect(calcs, hasLength(1));
        expect(calcs.first.read<String>('piece_name'), 'Vaso con foto');
        expect(
          calcs.first.read<double>('amortization_cost_snapshot'),
          0.0,
          reason: 'Cotizaciones pre-v10 quedan amortizacion 0.',
        );
        expect(
          calcs.first.read<Uint8List?>('piece_image_blob'),
          isNotNull,
          reason: 'La foto v9 sobrevive la migracion a v10.',
        );
      },
    );

    test(
      'post-migration: insert + read de impresora con amortizacion (F5)',
      () async {
        await db.customSelect('SELECT 1').get();

        final id = await db
            .into(db.printers)
            .insert(
              PrintersCompanion.insert(
                name: 'Kobra 3',
                averageWatts: 180,
                purchaseCost: const Value(3500),
                usefulLifeHours: const Value(4000),
                createdAt: DateTime.now().toUtc(),
              ),
            );
        expect(id, greaterThan(0));

        final row = (await db.select(db.printers).get()).firstWhere(
          (p) => p.name == 'Kobra 3',
        );
        expect(row.purchaseCost, closeTo(3500.0, 0.0001));
        expect(row.usefulLifeHours, 4000);
      },
    );
  });
}
