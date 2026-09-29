// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

void _seedV13Schema(Database rawDb) {
  rawDb.execute('''
    CREATE TABLE printers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      brand TEXT,
      name TEXT NOT NULL,
      average_watts INTEGER NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      purchase_cost REAL,
      useful_life_hours INTEGER,
      current_hours INTEGER,
      created_at INTEGER NOT NULL
    )
  ''');
  rawDb.execute(
    'INSERT INTO printers '
    '(brand, name, average_watts, is_default, created_at) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Creality', 'Ender 3 V3', 120, 1, 1234567890],
  );

  rawDb.execute('''
    CREATE TABLE filaments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      brand TEXT,
      price_per_bobbin REAL NOT NULL,
      grams_per_bobbin REAL NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      color TEXT
    )
  ''');
  rawDb.execute(
    "INSERT INTO filaments (name, brand, price_per_bobbin, grams_per_bobbin, "
    "is_default, created_at, color) "
    "VALUES ('PLA Negro', 'eSun', 150.0, 1000.0, 1, 1234567890, '#000000')",
  );

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
      kwh_rate_snapshot REAL NOT NULL DEFAULT 0,
      profit_base_snapshot REAL NOT NULL DEFAULT 0,
      quantity INTEGER NOT NULL DEFAULT 1,
      is_sold INTEGER NOT NULL DEFAULT 0,
      is_template INTEGER NOT NULL DEFAULT 0,
      material_cost_snapshot REAL NOT NULL,
      electric_cost_snapshot REAL NOT NULL,
      amortization_cost_snapshot REAL NOT NULL DEFAULT 0,
      labor_cost_snapshot REAL NOT NULL,
      post_process_cost_snapshot REAL NOT NULL,
      base_cost_snapshot REAL NOT NULL DEFAULT 0,
      failure_cost_snapshot REAL NOT NULL,
      markup_cost_snapshot REAL NOT NULL,
      profit_amount_snapshot REAL NOT NULL,
      minimum_charge_applied_snapshot REAL NOT NULL DEFAULT 0,
      effective_total_snapshot REAL NOT NULL DEFAULT 0,
      total_price_snapshot REAL NOT NULL,
      labor_rate_snapshot REAL NOT NULL DEFAULT 0,
      post_process_rate_snapshot REAL NOT NULL DEFAULT 0,
      failure_rate_snapshot REAL NOT NULL DEFAULT 0,
      minimum_charge_snapshot REAL NOT NULL DEFAULT 0,
      markup_on_materials_snapshot REAL NOT NULL DEFAULT 0,
      piece_image_blob BLOB,
      batch_discount_percent TEXT,
      batch_discount_amount TEXT
    )
  ''');
  rawDb.execute(
    'INSERT INTO calculations (created_at, piece_name, client_name, '
    'total_hours, discount_percentage, quantity, material_cost_snapshot, '
    'electric_cost_snapshot, labor_cost_snapshot, post_process_cost_snapshot, '
    'failure_cost_snapshot, markup_cost_snapshot, profit_amount_snapshot, '
    'total_price_snapshot) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [1234567890, 'Llavero logo', 'Juan Perez', 1.5, 0.0, 1, 10, 0, 0, 0, 0, 0, 0, 10],
  );

  rawDb.execute('''
    CREATE TABLE calculation_materials (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      calculation_id INTEGER NOT NULL,
      label TEXT NOT NULL,
      weight_grams REAL NOT NULL,
      price_per_bobbin REAL NOT NULL,
      grams_per_bobbin REAL NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (calculation_id) REFERENCES calculations(id)
    )
  ''');

  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (key)
    )
  ''');

  rawDb.execute('''
    CREATE TABLE entitlements (
      id INTEGER NOT NULL PRIMARY KEY,
      product_id TEXT NOT NULL,
      is_active INTEGER NOT NULL,
      purchased_at INTEGER,
      expires_at INTEGER,
      source TEXT NOT NULL,
      original_transaction_id TEXT
    )
  ''');

  rawDb.execute('''
    CREATE TABLE discount_tiers (
      id TEXT NOT NULL PRIMARY KEY,
      min_qty INTEGER NOT NULL,
      percent TEXT NOT NULL,
      sort_order INTEGER NOT NULL
    )
  ''');

  rawDb.execute('PRAGMA user_version = 13');
}

void main() {
  group('Migration v13 -> v14', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _seedV13Schema(rawDb);
    });

    tearDown(() {
      rawDb.close();
    });

    test(
      'onUpgrade(13, 14) adds is_partial column to calculations',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        final versionRows = await db.customSelect('PRAGMA user_version').get();
        expect(
          versionRows.first.read<int>('user_version'),
          14,
          reason: 'AppDatabase debe setear user_version=14 tras onUpgrade.',
        );
        expect(db.schemaVersion, 14);

        final cols = await db
            .customSelect(
              "SELECT name, type, \"notnull\" AS isNotNull, \"pk\" AS isPrimaryKey "
              "FROM pragma_table_info('calculations')",
            )
            .get();
        final byName = <String, QueryRow>{};
        for (final r in cols) {
          byName[r.read<String>('name')] = r;
        }
        final isPartial = byName['is_partial'];
        expect(isPartial, isNotNull, reason: 'v14 must create is_partial column.');
        expect(isPartial!.read<String>('type'), 'INTEGER');
        expect(
          isPartial.read<int>('isNotNull'),
          1,
          reason: 'is_partial has DEFAULT 0 (NOT NULL).',
        );
      },
    );

    test(
      'pre-existing rows survive with is_partial = false',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        final calcs = await db.customSelect('SELECT * FROM calculations').get();
        expect(calcs, hasLength(1));
        expect(calcs.first.read<String>('piece_name'), 'Llavero logo');
        expect(
          calcs.first.read<int?>('is_partial'),
          0,
          reason: 'Pre-v14 rows get is_partial = 0 (false).',
        );
      },
    );

    test('re-open idempotent: second open stays at v14', () async {
      final db1 = AppDatabase.forTesting(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
      await db1.customSelect('SELECT 1').get();
      final v1 = await db1.customSelect('PRAGMA user_version').get();
      expect(v1.first.read<int>('user_version'), 14);
      await db1.close();

      final db2 = AppDatabase.forTesting(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
      addTearDown(() async => db2.close());
      await db2.customSelect('SELECT 1').get();
      final v2 = await db2.customSelect('PRAGMA user_version').get();
      expect(
        v2.first.read<int>('user_version'),
        14,
        reason: 'Second open must not re-run migration.',
      );
      final calcs = await db2.customSelect('SELECT * FROM calculations').get();
      expect(calcs, hasLength(1));
    });
  });
}
