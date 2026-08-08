// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Tests de la tabla `entitlements` (T1 del plan de monetizacion).
///
/// Verifica que la tabla existe en el schema de Drift con TODAS las columnas
/// esperadas, sus tipos SQL y su nullability — la base para que
/// `EntitlementRepository` (T3) y la migracion v4→v5 (T19) funcionen.
///
/// **TDD**: este test se escribio ANTES de crear la tabla. La primera
/// ejecucion debe fallar (RED) — la tabla `entitlements` no existe en
/// @DriftDatabase todavia. Tras implementar la tabla + migracion +
/// build_runner, debe pasar (GREEN).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Entitlements table — schema', () {
    test('esta registrada en @DriftDatabase con tableName "entitlements"',
        () async {
      final tableInfo = db.allTables.where(
        (t) => t.actualTableName == 'entitlements',
      );
      expect(tableInfo, isNotEmpty,
          reason: 'entitlements debe estar en @DriftDatabase(tables:). '
              'Si fallo, agregar `Entitlements` al array de tables en '
              'app_database.dart y regenear app_database.g.dart.');
    });

    test('existe en SQLite tras onCreate (pragma_table_info)', () async {
      final rows = await db.customSelect(
        'SELECT name FROM sqlite_master '
        "WHERE type='table' AND name='entitlements'",
      ).get();
      expect(rows, isNotEmpty,
          reason: 'La tabla `entitlements` debe existir en la DB tras '
              'onCreate. Si fallo, m.createAll() no la esta creando — '
              'verificar que la clase esta en @DriftDatabase(tables:).');
    });

    test(
        'tiene todas las columnas esperadas con tipos SQL y nullability '
        'correctos (via pragma_table_info)', () async {
      final rows = await db.customSelect(
        'SELECT name, type, "notnull" AS isNotNull, '
        'dflt_value AS defaultValue, pk AS isPk '
        'FROM pragma_table_info(\'entitlements\') '
        'ORDER BY cid',
      ).get();

      // Si la tabla no existe, pragma_table_info devuelve 0 filas.
      // Saltamos a un expect que falle con mensaje util.
      expect(rows, isNotEmpty,
          reason: 'pragma_table_info(\'entitlements\') devolvio vacio. '
              'La tabla no existe en la DB.');

      // Index por nombre para asserts legibles.
      final byName = <String, QueryRow>{};
      for (final r in rows) {
        byName[r.read<String>('name')] = r;
      }

      // ---------- id ----------
      expect(byName.keys, contains('id'),
          reason: 'Falta columna id (PK AUTOINCREMENT).');
      expect(byName['id']!.read<String>('type'), 'INTEGER',
          reason: 'id debe ser INTEGER.');
      expect(byName['id']!.read<int>('isNotNull'), 1,
          reason: 'id debe ser NOT NULL (PK).');
      expect(byName['id']!.read<int>('isPk'), 1,
          reason: 'id debe ser PK (pk=1).');

      // ---------- source ----------
      expect(byName.keys, contains('source'),
          reason: 'Falta columna source (NOT NULL).');
      expect(byName['source']!.read<String>('type'), 'TEXT',
          reason: 'source debe ser TEXT.');
      expect(byName['source']!.read<int>('isNotNull'), 1,
          reason: 'source debe ser NOT NULL.');

      // ---------- productId (SQL: product_id) ----------
      expect(byName.keys, contains('product_id'),
          reason: 'Falta columna product_id (NOT NULL). Drift genera '
              'snake_case desde el field Dart `productId`.');
      expect(byName['product_id']!.read<String>('type'), 'TEXT',
          reason: 'product_id debe ser TEXT.');
      expect(byName['product_id']!.read<int>('isNotNull'), 1,
          reason: 'product_id debe ser NOT NULL.');

      // ---------- purchasedAt (SQL: purchased_at) ----------
      expect(byName.keys, contains('purchased_at'),
          reason: 'Falta columna purchased_at (NOT NULL). Drift genera '
              'snake_case desde el field Dart `purchasedAt`.');
      expect(byName['purchased_at']!.read<int>('isNotNull'), 1,
          reason: 'purchased_at debe ser NOT NULL.');

      // ---------- validatedAt (SQL: validated_at, nullable) ----------
      expect(byName.keys, contains('validated_at'),
          reason: 'Falta columna validated_at (nullable).');
      expect(byName['validated_at']!.read<int>('isNotNull'), 0,
          reason: 'validated_at debe ser NULLABLE '
              '(ultima vez que RevenueCat valido el receipt).');

      // ---------- expiresAt (SQL: expires_at, nullable) ----------
      expect(byName.keys, contains('expires_at'),
          reason: 'Falta columna expires_at (nullable, null = lifetime).');
      expect(byName['expires_at']!.read<int>('isNotNull'), 0,
          reason: 'expires_at debe ser NULLABLE '
              '(null = one-time unlock, no expira).');

      // ---------- receiptData (SQL: receipt_data, nullable) ----------
      expect(byName.keys, contains('receipt_data'),
          reason: 'Falta columna receipt_data (nullable).');
      expect(byName['receipt_data']!.read<String>('type'), 'TEXT',
          reason: 'receipt_data debe ser TEXT.');
      expect(byName['receipt_data']!.read<int>('isNotNull'), 0,
          reason: 'receipt_data debe ser NULLABLE.');

      // ---------- isActive (SQL: is_active, NOT NULL DEFAULT true) ----------
      expect(byName.keys, contains('is_active'),
          reason: 'Falta columna is_active (NOT NULL DEFAULT true).');
      expect(byName['is_active']!.read<int>('isNotNull'), 1,
          reason: 'is_active debe ser NOT NULL.');
      final isActiveDefault =
          byName['is_active']!.read<String?>('defaultValue');
      expect(isActiveDefault, isNotNull,
          reason: 'is_active debe tener DEFAULT (true = 1).');
      expect(int.parse(isActiveDefault!), 1,
          reason: 'is_active DEFAULT debe ser 1 (true en SQLite).');
    });
  });
}
