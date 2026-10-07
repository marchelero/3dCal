// ignore_for_file: public_member_api_docs, depend_on_referenced_packages
//
// Migracion v16 -> v17.
//
// v17 agrega 7 columnas a `calculations`:
// - modeling_mode, modeling_value
// - postproc_mode, postproc_value
// - extra_mode, extra_value, extra_label
//
// Los defaults reproducen el calculo legacy (`auto` / `auto` / `off`), asi que
// una fila v16 migrada a v17 produce los MISMOS numeros que antes en el
// engine. Este test protege ese contrato.
library;

import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Schema v16 = v15 + `is_advanced`. No tiene las 7 columnas v17.
void _seedV16Schema(Database rawDb) {
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
      material_cost_snapshot REAL NOT NULL,
      electric_cost_snapshot REAL NOT NULL,
      amortization_cost_snapshot REAL NOT NULL DEFAULT 0,
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
      quantity INTEGER NOT NULL DEFAULT 1,
      is_sold INTEGER NOT NULL DEFAULT 0,
      is_template INTEGER NOT NULL DEFAULT 0,
      is_partial INTEGER NOT NULL DEFAULT 0,
      is_advanced INTEGER NOT NULL DEFAULT 0,
      piece_image_blob BLOB,
      batch_discount_percent TEXT,
      batch_discount_amount TEXT
    )
  ''');
  rawDb.execute(
    'INSERT INTO calculations '
    '(created_at, piece_name, total_hours, print_minutes, '
    'material_cost_snapshot, electric_cost_snapshot, labor_cost_snapshot, '
    'post_process_cost_snapshot, base_cost_snapshot, failure_cost_snapshot, '
    'markup_cost_snapshot, profit_amount_snapshot, '
    'minimum_charge_applied_snapshot, effective_total_snapshot, '
    'total_price_snapshot, labor_rate_snapshot, post_process_rate_snapshot, '
    'failure_rate_snapshot, minimum_charge_snapshot, '
    'markup_on_materials_snapshot) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      1234567890,
      'Cotizacion legacy v16',
      2.0,
      30,
      12.0,
      0.0,
      0.0,
      0.0,
      12.0,
      0.0,
      0.0,
      24.0,
      0.0,
      36.0,
      36.0,
      50.0,
      0.0,
      0.0,
      0.0,
      0.0,
    ],
  );

  rawDb.execute('PRAGMA user_version = 16');
}

Future<Map<String, QueryRow>> _columnsOf(
  AppDatabase db,
  String table,
) async {
  final cols = await db
      .customSelect(
        'SELECT name, type, "notnull" AS isNotNull, dflt_value AS defaultValue '
        "FROM pragma_table_info('$table')",
      )
      .get();
  return {for (final r in cols) r.read<String>('name'): r};
}

void main() {
  group('Migration v16 -> v17', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _seedV16Schema(rawDb);
    });

    tearDown(() {
      rawDb.close();
    });

    test('onUpgrade crea las 7 columnas de costos adicionales', () async {
      final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
      addTearDown(() async => db.close());
      await db.customSelect('SELECT 1').get();

      final byName = await _columnsOf(db, 'calculations');
      for (final col in [
        'modeling_mode',
        'modeling_value',
        'postproc_mode',
        'postproc_value',
        'extra_mode',
        'extra_value',
        'extra_label',
      ]) {
        expect(
          byName[col],
          isNotNull,
          reason: 'v17 must create column `$col`.',
        );
      }
    });

    test(
      'filas preexistentes quedan con defaults que reproducen el legacy',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(() async => db.close());
        await db.customSelect('SELECT 1').get();

        final calcs =
            await db.customSelect('SELECT * FROM calculations').get();
        expect(calcs, hasLength(1));
        final row = calcs.first;
        expect(row.read<String>('piece_name'), 'Cotizacion legacy v16');
        // modeling_mode='auto' delega a `hours * laborRate`.
        expect(
          row.read<String?>('modeling_mode'),
          'auto',
          reason:
              'Pre-v17 rows deben tener modeling_mode=auto para que el engine '
              'reproduzca la formula legacy (hours * laborRate).',
        );
        expect(row.read<double?>('modeling_value'), 0);
        expect(row.read<String?>('postproc_mode'), 'auto');
        expect(row.read<double?>('postproc_value'), 0);
        // Extras en off: pre-v17 no existia este concepto, no cobra nada.
        expect(
          row.read<String?>('extra_mode'),
          'off',
          reason: 'Pre-v17 rows deben tener extra_mode=off (no se cobra).',
        );
        expect(row.read<double?>('extra_value'), 0);
        expect(row.read<String?>('extra_label'), '');
      },
    );

    test('user_version queda en 17 y el re-open es idempotente', () async {
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
        reason: 'Second open must not re-run migration.',
      );
    });
  });
}
