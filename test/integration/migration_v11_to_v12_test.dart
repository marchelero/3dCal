// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Integration test de la migracion Drift v11 → v12 (feature A — Hito 1:
/// escalones de descuento por cantidad).
///
/// **Que prueba**: que un usuario que actualiza desde v11 (con datos
/// existentes) recibe:
/// - la tabla `discount_tiers` (id TEXT PK, min_qty INTEGER, percent TEXT,
///   sort_order INTEGER);
/// - las columnas `batch_discount_percent` / `batch_discount_amount`
///   (TEXT NULL) en `calculations`.
/// Sin perder datos: la fila existente de `calculations` sobrevive con los
/// nuevos campos en NULL (comportamiento actual intacto).
///
/// Patron identico a `migration_v10_to_v11_test.dart`: seed del schema v11
/// raw con `PRAGMA user_version = 11`, hand-off via `NativeDatabase.opened`,
/// y Drift dispara `onUpgrade(11, 12)` al abrir.
///
/// **Re-open idempotente**: tras la primera apertura (que migra a v12),
/// volver a abrir `AppDatabase` sobre la misma DB no debe re-ejecutar la
/// migración ni romper el schema.
void _seedV11Schema(Database rawDb) {
  // --- printers (v11) ---
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
  rawDb.execute(
    'INSERT INTO printers '
    '(brand, name, average_watts, is_default, created_at) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Creality', 'Ender 3 V3', 120, 1, 1234567890],
  );

  // --- filaments (v11) — CON color (v11), SIN batch_tiers (v12) ---
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
    'INSERT INTO filaments (name, brand, price_per_bobbin, grams_per_bobbin, '
    'is_default, created_at, color) '
    "VALUES ('PLA Negro', 'eSun', 150.0, 1000.0, 1, 1234567890, '#000000')",
  );

  // --- calculations (v11) — SIN columnas batch (v12) ---
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
  // Fila existente pre-v12: debe sobrevivir con batch_* NULL.
  rawDb.execute(
    'INSERT INTO calculations (created_at, piece_name, client_name, '
    'total_hours, discount_percentage, quantity) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [1234567890, 'Llavero logo', 'Juan Perez', 1.5, 0.0, 1],
  );

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

  // --- settings (key-value, v11) ---
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (key)
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

  // Marca la DB como v11 para que AppDatabase dispare onUpgrade(11, 12).
  rawDb.execute('PRAGMA user_version = 11');
}

void main() {
  group('Migration v11 → v12', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _seedV11Schema(rawDb);
    });

    tearDown(() {
      rawDb.close();
    });

    test(
      'onUpgrade(11, 12) crea discount_tiers, agrega batch_* en calculations '
      'y bumpea a 12',
      () async {
        final db = AppDatabase.forTesting(
          NativeDatabase.opened(rawDb),
        );
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        final versionRows = await db.customSelect('PRAGMA user_version').get();
        expect(
          versionRows.first.read<int>('user_version'),
          12,
          reason: 'AppDatabase debe setear user_version=12 tras onUpgrade.',
        );
        expect(db.schemaVersion, 12);

        // discount_tiers: nueva tabla con el schema correcto.
        final tierCols = await db
            .customSelect(
              'SELECT name, type, "notnull" AS isNotNull, "pk" AS isPrimaryKey '
              "FROM pragma_table_info('discount_tiers')",
            )
            .get();
        final tByName = <String, QueryRow>{};
        for (final r in tierCols) {
          tByName[r.read<String>('name')] = r;
        }
        expect(tByName.keys.toSet(), {'id', 'min_qty', 'percent', 'sort_order'});
        final idCol = tByName['id']!;
        expect(idCol.read<int>('isPrimaryKey'), 1, reason: 'id debe ser PK.');
        expect(idCol.read<String>('type'), 'TEXT');
        expect(tByName['min_qty']!.read<String>('type'), 'INTEGER');
        expect(tByName['min_qty']!.read<int>('isNotNull'), 1);
        expect(tByName['percent']!.read<String>('type'), 'TEXT');
        expect(tByName['percent']!.read<int>('isNotNull'), 1);
        expect(tByName['sort_order']!.read<String>('type'), 'INTEGER');
        expect(tByName['sort_order']!.read<int>('isNotNull'), 1);

        // calculations: columnas batch TEXT nullable.
        final calcCols = await db
            .customSelect(
              'SELECT name, type, "notnull" AS isNotNull '
              "FROM pragma_table_info('calculations')",
            )
            .get();
        final cByName = <String, QueryRow>{};
        for (final r in calcCols) {
          cByName[r.read<String>('name')] = r;
        }
        final pct = cByName['batch_discount_percent'];
        expect(pct, isNotNull, reason: 'v12 debe crear batch_discount_percent.');
        expect(pct!.read<String>('type'), 'TEXT');
        expect(pct.read<int>('isNotNull'), 0, reason: 'debe ser nullable.');
        final amount = cByName['batch_discount_amount'];
        expect(amount, isNotNull, reason: 'v12 debe crear batch_discount_amount.');
        expect(amount!.read<String>('type'), 'TEXT');
        expect(amount.read<int>('isNotNull'), 0, reason: 'debe ser nullable.');
      },
    );

    test(
      'migracion es no-destructiva: la fila v11 sobrevive con batch_* NULL',
      () async {
        final db = AppDatabase.forTesting(
          NativeDatabase.opened(rawDb),
        );
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        final calcs = await db.customSelect('SELECT * FROM calculations').get();
        expect(calcs, hasLength(1));
        expect(calcs.first.read<String>('piece_name'), 'Llavero logo');
        expect(calcs.first.read<String>('client_name'), 'Juan Perez');
        expect(
          calcs.first.data.containsKey('batch_discount_percent'),
          isTrue,
          reason: 'El snapshot batch debe existir tras la migracion.',
        );
        expect(
          calcs.first.read<String?>('batch_discount_percent'),
          isNull,
          reason: 'Cotizaciones pre-v12 quedan sin escalón (NULL).',
        );
        expect(
          calcs.first.read<String?>('batch_discount_amount'),
          isNull,
          reason: 'Cotizaciones pre-v12 quedan sin monto batch (NULL).',
        );

        // El filamento con color sobrevive intacto.
        final filaments =
            await db.customSelect('SELECT * FROM filaments').get();
        expect(filaments, hasLength(1));
        expect(filaments.first.read<String>('name'), 'PLA Negro');
        expect(filaments.first.read<String>('color'), '#000000');
      },
    );

    test(
      'post-migration: discount_tiers es usable (insert + read redondo)',
      () async {
        final db = AppDatabase.forTesting(
          NativeDatabase.opened(rawDb),
        );
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        await db.customStatement(
          'INSERT INTO discount_tiers (id, min_qty, percent, sort_order) '
          "VALUES ('a1b2c3d4-e5f6-4701-9d2c-abcdef123456', 10, '10', 0)",
        );

        final tiers = await db.customSelect('SELECT * FROM discount_tiers').get();
        expect(tiers, hasLength(1));
        expect(tiers.first.read<String>('id'), 'a1b2c3d4-e5f6-4701-9d2c-abcdef123456');
        expect(tiers.first.read<int>('min_qty'), 10);
        expect(tiers.first.read<String>('percent'), '10');
        expect(tiers.first.read<int>('sort_order'), 0);
      },
    );

    test('re-open idempotente: segunda apertura no re-migra y sigue en v12',
        () async {
      final db1 = AppDatabase.forTesting(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
      await db1.customSelect('SELECT 1').get();
      final v1 = await db1.customSelect('PRAGMA user_version').get();
      expect(v1.first.read<int>('user_version'), 12);
      await db1.close();

      // Reabrir sobre la misma DB: user_version sigue 12, schema usable.
      final db2 = AppDatabase.forTesting(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
      addTearDown(() async => db2.close());
      await db2.customSelect('SELECT 1').get();
      final v2 = await db2.customSelect('PRAGMA user_version').get();
      expect(
        v2.first.read<int>('user_version'),
        12,
        reason: 'La segunda apertura no debe re-ejecutar la migracion.',
      );
      final calcs = await db2.customSelect('SELECT * FROM calculations').get();
      expect(calcs, hasLength(1));
    });
  });
}
