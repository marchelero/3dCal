// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/discount_tier.dart';

/// CRUD de escalones de descuento por cantidad (feature A — Hito 1).
///
/// Patron del proyecto: queries inline sobre `AppDatabase` (no
/// `@DriftAccessor`), igual que `FilamentRepository`/`SettingsRepository`.
///
/// **Orden**: la lista se expone ordenada por `sort_order` (+ `min_qty` como
/// desempate). El repository mantiene los slots contiguos (0..n-1) **en
/// orden de `min_qty` ascendente**: al guardar o borrar re-secuencia toda la
/// tabla. Efecto de negocio: editar la cantidad mínima de un escalón lo
/// reubica solo (auto-sort), que es el comportamiento del PRD
/// ("orden creciente o auto-ordenado").
///
/// **Porcentaje**: columna `percent` es TEXT `decimal`; el parseo vive en
/// [_fromRow]. Acá nunca se toca con `double`.
class DiscountTiersRepository {
  const DiscountTiersRepository(this._db);

  final AppDatabase _db;

  /// Stream reactivo de todos los escalones, ordenados por [sortOrder].
  ///
  /// Tras cada upsert/delete el stream emite la lista re-secuenciada.
  Stream<List<DiscountTier>> watchAll() {
    return (_db.select(_db.discountTiersTable)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.minQty),
          ]))
        .watch()
        .map((rows) => rows.map<DiscountTier>(_fromRow).toList(growable: false));
  }

  /// Lista única con el mismo orden que [watchAll].
  Future<List<DiscountTier>> listAll() {
    return (_db.select(_db.discountTiersTable)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.minQty),
          ]))
        .get()
        .then(
          (rows) => rows.map<DiscountTier>(_fromRow).toList(growable: false),
        );
  }

  /// Inserta un escalón nuevo o actualiza uno existente (mismo id), y luego
  /// re-secuencia los slots. Las dos operaciones comparten transacción.
  Future<void> upsert(DiscountTier tier) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.discountTiersTable)
            ..where((t) => t.id.equals(tier.id)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.discountTiersTable).insert(_toRow(tier));
      } else {
        await (_db.update(_db.discountTiersTable)
              ..where((t) => t.id.equals(tier.id))).write(
          DiscountTiersTableCompanion(
            minQty: Value(tier.minQty),
            percent: Value(tier.percent.toString()),
            sortOrder: Value(tier.sortOrder),
          ),
        );
      }
      await _resequenceSlots();
    });
  }

  /// Elimina un escalón y re-secuencia los slots restantes.
  Future<void> delete(String id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.discountTiersTable,
      )..where((t) => t.id.equals(id))).go();
      await _resequenceSlots();
    });
  }

  /// Re-secuencia `sort_order = 0..n-1` en orden de `min_qty` ascendente
  /// (desempate por `sort_order` actual y luego por id, para un orden
  /// determinista aunque haya cantidades mínimas repetidas).
  ///
  /// Solo escribe filas cuyo slot cambió (UPDATE por fila mínima).
  Future<void> _resequenceSlots() async {
    final rows = await (_db.select(_db.discountTiersTable)
          ..orderBy([
            (t) => OrderingTerm.asc(t.minQty),
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].sortOrder != i) {
        await (_db.update(
          _db.discountTiersTable,
        )..where((t) => t.id.equals(rows[i].id)))
            .write(DiscountTiersTableCompanion(sortOrder: Value(i)));
      }
    }
  }

  /// Mapea la entidad a un `DiscountTiersTableCompanion.insert` (id UUID).
  DiscountTiersTableCompanion _toRow(DiscountTier tier) {
    return DiscountTiersTableCompanion.insert(
      id: tier.id,
      minQty: tier.minQty,
      percent: tier.percent.toString(),
      sortOrder: tier.sortOrder,
    );
  }

  /// Crea la entidad desde una fila drift, parseando el `decimal` del TEXT.
  DiscountTier _fromRow(DiscountTiers row) {
    return DiscountTier(
      id: row.id,
      minQty: row.minQty,
      percent: Decimal.parse(row.percent),
      sortOrder: row.sortOrder,
    );
  }
}
