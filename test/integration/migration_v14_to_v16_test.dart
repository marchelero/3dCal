// ignore_for_file: public_member_api_docs, depend_on_referenced_packages

/// Migracion v14 -> v16.
library;

import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Schema v14: identico a v13 + `is_partial` en `calculations` + las
/// columnas `price_per_bobbin_snapshot` / `grams_per_bobbin_snapshot` que ya
/// existen desde antes. NO tiene las columnas de v15 ni el flag de v16.
void _seedV14Schema(Database rawDb) {
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
      discount_percentage REAL NOT NULL DEFAULT 0,
      kwh_rate_snapshot REAL NOT NULL DEFAULT 0,
      profit_base_snapshot REAL NOT NULL DEFAULT 0,
      material_cost_snapshot REAL NOT NULL DEFAULT 0,
      electric_cost_snapshot REAL NOT NULL DEFAULT 0,
      quantity INTEGER NOT NULL DEFAULT 1,
      is_sold INTEGER NOT NULL DEFAULT 0,
      is_template INTEGER NOT NULL DEFAULT 0,
      is_partial INTEGER NOT NULL DEFAULT 0,
      piece_image_blob BLOB,
      batch_discount_percent TEXT,
      batch_discount_amount TEXT
    )
  ''');
  rawDb.execute(
    'INSERT INTO calculations '
    '(created_at, piece_name, total_hours, print_minutes) '
    'VALUES (?, ?, ?, ?)',
    [1234567890, 'Llavero logo', 2.5, 30],
  );

  // Schema v14 de calculation_materials: sin las columnas de tiempo propio.
  rawDb.execute('''
    CREATE TABLE calculation_materials (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      calculation_id INTEGER NOT NULL,
      filament_id INTEGER,
      label TEXT NOT NULL,
      weight_grams REAL NOT NULL,
      price_per_bobbin_snapshot REAL NOT NULL,
      grams_per_bobbin_snapshot REAL NOT NULL,
      FOREIGN KEY (calculation_id) REFERENCES calculations(id)
    )
  ''');
  rawDb.execute(
    'INSERT INTO calculation_materials '
    '(calculation_id, label, weight_grams, price_per_bobbin_snapshot, '
    'grams_per_bobbin_snapshot) VALUES (?, ?, ?, ?, ?)',
    [1, 'PLA Negro', 120, 150, 1000],
  );

  rawDb.execute('PRAGMA user_version = 14');
}

Future<Map<String, QueryRow>> _columnsOf(AppDatabase db, String table) async {
  final cols = await db
      .customSelect(
        'SELECT name, type, "notnull" AS isNotNull, dflt_value AS defaultValue '
        "FROM pragma_table_info('$table')",
      )
      .get();
  return {for (final r in cols) r.read<String>('name'): r};
}

void main() {
  group('Migration v14 -> v16', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _seedV14Schema(rawDb);
    });

    tearDown(() {
      rawDb.close();
    });

    test('onUpgrade crea las 3 columnas de tiempo propio', () async {
      final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
      addTearDown(() async => db.close());
      await db.customSelect('SELECT 1').get();

      final byName = await _columnsOf(db, 'calculation_materials');
      expect(
        byName['use_own_time'],
        isNotNull,
        reason: 'v15 must create use_own_time.',
      );
      expect(byName['material_hours'], isNotNull);
      expect(byName['material_minutes'], isNotNull);
    });

    test('onUpgrade crea el flag is_advanced en calculations', () async {
      final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
      addTearDown(() async => db.close());
      await db.customSelect('SELECT 1').get();

      final byName = await _columnsOf(db, 'calculations');
      final isAdvanced = byName['is_advanced'];
      expect(isAdvanced, isNotNull, reason: 'v16 must create is_advanced.');
      expect(isAdvanced!.read<String>('type'), 'INTEGER');
      expect(
        isAdvanced.read<int>('isNotNull'),
        1,
        reason: 'is_advanced has DEFAULT 0 (NOT NULL).',
      );
    });

    test(
      'filas preexistentes quedan con defaults del comportamiento viejo',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        final calcs = await db.customSelect('SELECT * FROM calculations').get();
        expect(calcs, hasLength(1));
        expect(calcs.first.read<String>('piece_name'), 'Llavero logo');
        expect(
          calcs.first.read<int?>('is_advanced'),
          0,
          reason:
              'Pre-v16 rows get is_advanced = 0: se infiere por materiales.',
        );

        final mats = await db
            .customSelect('SELECT * FROM calculation_materials')
            .get();
        expect(mats, hasLength(1));
        expect(mats.first.read<String>('label'), 'PLA Negro');
        expect(
          mats.first.read<int?>('use_own_time'),
          isNull,
          reason: 'NULL = no usaba tiempo propio (NULL se lee como false).',
        );
        expect(mats.first.read<double?>('material_hours'), isNull);
        expect(mats.first.read<double?>('material_minutes'), isNull);
      },
    );

    test('el snapshot previo de material sobrevive intacto', () async {
      final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
      addTearDown(() async => db.close());
      await db.customSelect('SELECT 1').get();

      final mat = (await db.select(db.calculationMaterials).get()).single;
      expect(mat.label, 'PLA Negro');
      expect(mat.weightGrams, 120.0);
      expect(mat.pricePerBobbinSnapshot, 150.0);
      expect(mat.gramsPerBobbinSnapshot, 1000.0);
      // Escritura sobre columnas nuevas funciona.
      expect(mat.useOwnTime, isNull);
    });

    test('user_version queda en 16 y el re-open es idempotente', () async {
      final db1 = AppDatabase.forTesting(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
      await db1.customSelect('SELECT 1').get();
      final v1 = await db1.customSelect('PRAGMA user_version').get();
      expect(v1.first.read<int>('user_version'), 16);
      await db1.close();

      final db2 = AppDatabase.forTesting(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
      addTearDown(() async => db2.close());
      await db2.customSelect('SELECT 1').get();
      final v2 = await db2.customSelect('PRAGMA user_version').get();
      expect(
        v2.first.read<int>('user_version'),
        16,
        reason: 'Second open must not re-run migration.',
      );
      expect(
        (await db2.customSelect('SELECT * FROM calculations').get()).length,
        1,
      );
    });
  });
}
