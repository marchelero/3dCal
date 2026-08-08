// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Integration test de la migracion Drift v4 → v5 (T19 del plan de
/// monetizacion).
///
/// **Que prueba**: que un usuario que actualiza la app desde v4 (con datos
/// existentes de filamentos, cotizaciones, impresoras, settings) recibe la
/// tabla `entitlements` (vacia) sin perder sus datos.
///
/// **Setup del v4 fake** (porque el schema pre-T1 no esta materializado
/// en ningun lado — los CREATE TABLE viven solo en el codigo generado
/// de Drift en build-time):
/// 1. Abrimos un [Database] raw de `package:sqlite3` (`sqlite3.openInMemory`).
/// 2. Ejecutamos `CREATE TABLE` para las 5 tablas que existian en v4
///    (todo en `@DriftDatabase` MENOS `entitlements`, que es el unico
///    cambio de T1).
/// 3. Insertamos 1 row representativa por tabla (filamento, impresora,
///    cotizacion, material, setting).
/// 4. Marcamos `PRAGMA user_version = 4`.
/// 5. Envolvemos la misma instancia con `NativeDatabase.opened(...)` y la
///    pasamos a `AppDatabase.forTesting`. El `beforeOpen` de Drift detecta
///    `user_version=4`, ve `schemaVersion=5`, y corre `onUpgrade(4, 5)` que
///    crea la tabla `entitlements`.
///
/// Patron recomendado por la doc oficial de drift ("integration tests for
/// migrations" — ver docstring de `NativeDatabase.opened`).
void _seedV4Schema(Database rawDb) {
  // --- printers (v4) ---
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

  // --- filaments (v4) ---
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

  // --- calculations (v4) — incluye print_minutes (v3→v4) y todos los
  //     snapshots financieros (v2→v3).
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

  // --- calculation_materials (v4) ---
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

  // --- settings (v4) — tableName overrideado a 'settings', PK custom.
  rawDb.execute('''
    CREATE TABLE settings (
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (key)
    )
  ''');

  // --- seed 1 row por tabla (valores representativos, UTC, 2026-07-22) ---
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

  // Marca la DB como v4 para que AppDatabase dispare onUpgrade(4, 5).
  rawDb.execute('PRAGMA user_version = 4');
}

void main() {
  group('Migration v4 → v5 (T19)', () {
    late AppDatabase db;
    late Database rawDb;

    setUp(() async {
      // 1. Crear DB en memoria cruda (sqlite3, no Drift).
      rawDb = sqlite3.openInMemory();
      // 2. Sembrar schema v4 + datos + user_version=4.
      _seedV4Schema(rawDb);
      // 3. Hand-off: envolver con NativeDatabase sin re-abrir la conexion.
      final native = NativeDatabase.opened(rawDb);
      // 4. AppDatabase abre LA MISMA instancia. Su beforeOpen detecta
      //    user_version=4, schemaVersion=5, corre onUpgrade.
      db = AppDatabase.forTesting(native);
      addTearDown(() async => db.close());
    });

    test('onUpgrade(4, 5) crea tabla entitlements y bumpea user_version a 5',
        () async {
      // Forzar la apertura lazy de Drift ejecutando una query.
      final tables = await db.customSelect(
        'SELECT name FROM sqlite_master '
        "WHERE type='table' AND name='entitlements'",
      ).get();
      expect(tables, hasLength(1),
          reason: 'onUpgrade(4, 5) debe haber creado la tabla entitlements. '
              'Si fallo, verificar app_database.dart onUpgrade '
              '`if (from <= 4)`.'
      );

      // user_version debe ser 5 post-migration.
      final versionRows = await db.customSelect('PRAGMA user_version').get();
      expect(versionRows.first.read<int>('user_version'), 5,
          reason: 'AppDatabase debe setear user_version=schemaVersion tras '
              'onUpgrade exitoso.');

      // Tabla entitlements vacia post-migration (sin inserts automaticos).
      final count = await db.customSelect(
        'SELECT COUNT(*) AS c FROM entitlements',
      ).get();
      expect(count.first.read<int>('c'), 0,
          reason: 'Migration NO debe insertar filas. El estado inicial es '
              'free (sin entitlement activo).');
    });

    test('migration es no-destructiva: datos v4 sobreviven', () async {
      // Dispara apertura lazy de Drift.
      await db.customSelect('SELECT 1').get();

      // printers: 1 row, valores correctos.
      final printers = await db.customSelect('SELECT * FROM printers').get();
      expect(printers, hasLength(1));
      expect(printers.first.read<String>('name'), 'Ender 3 V3');
      expect(printers.first.read<String>('brand'), 'Creality');
      expect(printers.first.read<int>('average_watts'), 120);

      // filaments: 1 row.
      final filaments = await db.customSelect('SELECT * FROM filaments').get();
      expect(filaments, hasLength(1));
      expect(filaments.first.read<String>('name'), 'PLA Negro');
      expect(filaments.first.read<double>('price_per_bobbin'), 120.0);
      expect(filaments.first.read<double>('grams_per_bobbin'), 1000.0);

      // calculations: 1 row, snapshot + print_minutes correctos.
      final calcs = await db.customSelect('SELECT * FROM calculations').get();
      expect(calcs, hasLength(1));
      expect(calcs.first.read<String>('piece_name'), 'Llave Allen');
      expect(calcs.first.read<String>('client_name'), 'Juan Perez');
      expect(calcs.first.read<double>('total_hours'), 2.5);
      expect(calcs.first.read<int>('print_minutes'), 30,
          reason: 'print_minutes (v3→v4 column) debe preservarse.');

      // calculation_materials: 1 row, FK a calculations ok.
      final mats = await db.customSelect(
        'SELECT * FROM calculation_materials',
      ).get();
      expect(mats, hasLength(1));
      expect(mats.first.read<String>('label'), 'PLA Negro');
      expect(mats.first.read<int>('calculation_id'), 1);
      expect(mats.first.read<double>('weight_grams'), 85.0);

      // settings: 1 row.
      final settings = await db.customSelect('SELECT * FROM settings').get();
      expect(settings, hasLength(1));
      expect(settings.first.read<String>('key'), 'profit_base_percentage');
      expect(settings.first.read<String>('value'), '30');
    });

    test('tabla entitlements tiene schema correcto (8 columnas, types, '
        'nullability, defaults)', () async {
      // Dispara apertura + migration.
      await db.customSelect('SELECT 1').get();

      final rows = await db.customSelect(
        'SELECT name, type, "notnull" AS isNotNull, '
        'dflt_value AS defaultValue, pk AS isPk '
        'FROM pragma_table_info(\'entitlements\') '
        'ORDER BY cid',
      ).get();

      expect(rows, isNotEmpty,
          reason: 'pragma_table_info(\'entitlements\') no devolvio filas. '
              'La tabla no existe.');

      // Index por nombre para asserts legibles.
      final byName = <String, QueryRow>{};
      for (final r in rows) {
        byName[r.read<String>('name')] = r;
      }

      // 8 columnas: id, source, product_id, purchased_at, validated_at,
      // expires_at, receipt_data, is_active.
      expect(byName.keys, hasLength(8),
          reason: 'entitlements debe tener exactamente 8 columnas. Drift '
              'genera snake_case desde los field names de '
              'Entitlements (entitlements_table.dart).');

      // id — INTEGER PK.
      expect(byName['id']!.read<String>('type'), 'INTEGER');
      expect(byName['id']!.read<int>('isPk'), 1,
          reason: 'id debe ser PK (pk=1).');
      expect(byName['id']!.read<int>('isNotNull'), 1,
          reason: 'id debe ser NOT NULL (PK).');

      // source — TEXT NOT NULL.
      expect(byName['source']!.read<String>('type'), 'TEXT');
      expect(byName['source']!.read<int>('isNotNull'), 1);

      // product_id — TEXT NOT NULL.
      expect(byName['product_id']!.read<String>('type'), 'TEXT');
      expect(byName['product_id']!.read<int>('isNotNull'), 1);

      // purchased_at — INTEGER NOT NULL (DateTime → unix epoch).
      expect(byName['purchased_at']!.read<int>('isNotNull'), 1,
          reason: 'purchased_at debe ser NOT NULL.');

      // validated_at — INTEGER NULLABLE.
      expect(byName['validated_at']!.read<int>('isNotNull'), 0,
          reason: 'validated_at debe ser NULLABLE.');

      // expires_at — INTEGER NULLABLE (null = lifetime).
      expect(byName['expires_at']!.read<int>('isNotNull'), 0,
          reason: 'expires_at debe ser NULLABLE.');

      // receipt_data — TEXT NULLABLE.
      expect(byName['receipt_data']!.read<String>('type'), 'TEXT');
      expect(byName['receipt_data']!.read<int>('isNotNull'), 0);

      // is_active — INTEGER NOT NULL DEFAULT 1 (boolean).
      expect(byName['is_active']!.read<int>('isNotNull'), 1);
      final isActiveDefault =
          byName['is_active']!.read<String?>('defaultValue');
      expect(isActiveDefault, isNotNull,
          reason: 'is_active debe tener DEFAULT (= 1 = true).');
      expect(int.parse(isActiveDefault!), 1,
          reason: 'is_active DEFAULT debe ser 1.');
    });

    test('post-migration: insert + read via AppDatabase accessor funciona',
        () async {
      // Dispara apertura + migration.
      await db.customSelect('SELECT 1').get();

      final purchasedAt = DateTime.utc(2026, 7, 22);
      final id = await db.into(db.entitlements).insert(
        EntitlementsCompanion.insert(
          source: 'play_store',
          productId: 'tresdcal_pro_lifetime',
          purchasedAt: purchasedAt,
        ),
      );
      expect(id, greaterThan(0),
          reason: 'autoIncrement debe retornar un id > 0.');

      final all = await db.select(db.entitlements).get();
      expect(all, hasLength(1));
      expect(all.first.id, id);
      expect(all.first.source, 'play_store');
      expect(all.first.productId, 'tresdcal_pro_lifetime');
      expect(all.first.purchasedAt.toUtc(), purchasedAt);
      expect(all.first.isActive, isTrue,
          reason: 'is_active DEFAULT true → fila nueva es activa.');
      expect(all.first.validatedAt, isNull);
      expect(all.first.expiresAt, isNull,
          reason: 'lifetime purchase → expiresAt null.');
      expect(all.first.receiptData, isNull);

      // Las tablas v4 siguen intactas despues del insert en entitlements.
      final calcs = await db.customSelect('SELECT * FROM calculations').get();
      expect(calcs, hasLength(1),
          reason: 'Insert en entitlements NO debe tocar calculations.');
    });
  });
}
