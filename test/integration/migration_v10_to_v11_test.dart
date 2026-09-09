// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Integration test de la migracion Drift v10 → v11 (color de filamento,
/// RF1-1 del PRD 2026-09-08).
///
/// **Que prueba**: que un usuario que actualiza desde v10 (con datos
/// existentes) recibe la columna `color TEXT NULL` en `filaments`, sin perder
/// datos. Filamentos viejos quedan con `color = NULL` (sin color).
///
/// Patron identico a `migration_v9_to_v10_test.dart`: seed del schema v10 raw
/// con `PRAGMA user_version = 10`, hand-off via `NativeDatabase.opened`, y
/// Drift dispara `onUpgrade(10, 11)` al abrir.
void _seedV10Schema(Database rawDb) {
  // --- printers (v10) ---
  rawDb.execute('''
    CREATE TABLE printers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      brand TEXT,
      name TEXT NOT NULL,
      average_watts INTEGER NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      purchase_cost REAL,
      useful_life_hours INTEGER,
      created_at INTEGER NOT NULL
    )
  ''');

  // --- filaments (v10) — SIN color (v11) ---
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

  // --- calculations (v10) ---
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
      quantity INTEGER NOT NULL DEFAULT 1,
      is_template INTEGER NOT NULL DEFAULT 0,
      piece_image_blob BLOB,
      amortization_cost_snapshot REAL NOT NULL DEFAULT 0,
      labor_cost_snapshot REAL NOT NULL DEFAULT 0,
      post_process_cost_snapshot REAL NOT NULL DEFAULT 0,
      failure_cost_snapshot REAL NOT NULL DEFAULT 0,
      markup_cost_snapshot REAL NOT NULL DEFAULT 0,
      minimum_charge_applied_snapshot REAL NOT NULL DEFAULT 0,
      effective_total_snapshot REAL NOT NULL DEFAULT 0,
      labor_rate_snapshot REAL NOT NULL DEFAULT 0,
      post_process_rate_snapshot REAL NOT NULL DEFAULT 0,
      failure_rate_snapshot REAL NOT NULL DEFAULT 0,
      minimum_charge_snapshot REAL NOT NULL DEFAULT 0,
      markup_on_materials_snapshot REAL NOT NULL DEFAULT 0
    )
  ''');

  // --- calculation_materials ---
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

  // --- settings ---
  rawDb.execute('''
    CREATE TABLE settings (
      id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
      profit_base_percentage REAL NOT NULL,
      kwh_rate REAL NOT NULL,
      currency_code TEXT NOT NULL,
      company_name TEXT,
      company_logo BLOB,
      company_logo_mime TEXT,
      extra_labor_rate REAL NOT NULL DEFAULT 0,
      extra_post_process_rate REAL NOT NULL DEFAULT 0,
      extra_failure_rate REAL NOT NULL DEFAULT 0,
      extra_minimum_charge REAL NOT NULL DEFAULT 0,
      extra_markup_on_materials REAL NOT NULL DEFAULT 0,
      last_modified INTEGER NOT NULL
    )
  ''');

  // --- entitlements ---
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

  // Insertar un filamento existente (sin color) para verificar que se
  // preserva con color=NULL tras la migracion.
  rawDb.execute(
    'INSERT INTO filaments (name, brand, price_per_bobbin, grams_per_bobbin, is_default, created_at) '
    "VALUES ('PLA Negro', 'eSun', 150.0, 1000.0, 1, 1234567890)",
  );

  // Marca la DB como v10 para que AppDatabase dispare onUpgrade(10, 11).
  rawDb.execute('PRAGMA user_version = 10');
}

void main() {
  group('Migration v10 → v11', () {
    late AppDatabase db;
    late Database rawDb;

    setUp(() async {
      rawDb = sqlite3.openInMemory();
      _seedV10Schema(rawDb);
      final native = NativeDatabase.opened(rawDb);
      db = AppDatabase.forTesting(native);
      addTearDown(() async => db.close());
    });

    test(
      'onUpgrade(10, 11) agrega color TEXT NULL en filaments y bumpea a 11',
      () async {
        await db.customSelect('SELECT 1').get();

        final versionRows = await db.customSelect('PRAGMA user_version').get();
        expect(
          versionRows.first.read<int>('user_version'),
          11,
          reason: 'AppDatabase debe setear user_version=11 tras onUpgrade.',
        );
        expect(db.schemaVersion, 11);

        // filaments: nueva columna `color` TEXT nullable.
        final filamentCols = await db
            .customSelect(
              'SELECT name, type, "notnull" AS isNotNull '
              "FROM pragma_table_info('filaments')",
            )
            .get();
        final fByName = <String, QueryRow>{};
        for (final r in filamentCols) {
          fByName[r.read<String>('name')] = r;
        }
        expect(
          fByName['color'],
          isNotNull,
          reason: 'v11 debe crear color en filaments.',
        );
        expect(
          fByName['color']!.read<String>('type'),
          'TEXT',
          reason: 'color debe ser TEXT.',
        );
        expect(
          fByName['color']!.read<int>('isNotNull'),
          0,
          reason: 'color debe ser nullable (sin NOT NULL).',
        );

        // Filamento viejo preservado: nombre, marca, precio, etc.
        final filaments = await db
            .customSelect('SELECT * FROM filaments')
            .get();
        expect(filaments, hasLength(1));
        expect(filaments.first.read<String>('name'), 'PLA Negro');
        expect(filaments.first.read<String>('brand'), 'eSun');

        // color es NULL (no hay valor por default — el usuario lo asigna).
        // SQLite reporta NULL como null en el result.
        expect(filaments.first.data.containsKey('color'), isTrue);
      },
    );

    test('color persiste en INSERT tras migracion', () async {
      await db.customSelect('SELECT 1').get();

      await db.customStatement(
        'INSERT INTO filaments (name, price_per_bobbin, grams_per_bobbin, color, is_default, created_at) '
        "VALUES ('PLA Azul', 150.0, 1000.0, '#1E88E5', 0, 1234567890)",
      );

      final all = await db.customSelect('SELECT * FROM filaments').get();
      expect(all, hasLength(2));
      final azul = all.firstWhere((r) => r.read<String>('name') == 'PLA Azul');
      expect(azul.read<String>('color'), '#1E88E5');
    });
  });
}
