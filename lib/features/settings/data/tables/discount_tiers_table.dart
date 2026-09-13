// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla de escalones de descuento por cantidad (feature A — Hito 1).
///
/// Un escalón = `(cantidad mínima → % de descuento mayorista)`.
/// - `min_qty` >= 2 (validación de dominio en `DiscountTier`; acá solo NOT NULL).
/// - `percent` es TEXT `decimal` (regla no negociable: porcentaje/dinero
///   nunca en double). Se parsea con `Decimal.parse` en `DiscountTier.fromRow`.
/// - `sort_order` define el orden de la lista; el repository lo re-secuencia
///   automáticamente al guardar (auto-sort por min_qty) y al borrar.
///
/// Id texto tipo UUID (consistente con PRD v2). La data class se llama
/// `DiscountTiers` (no `DiscountTier`) para no chocar con la entidad de
/// dominio homónima.
@DataClassName('DiscountTiers')
class DiscountTiersTable extends Table {
  @override
  String get tableName => 'discount_tiers';
  /// Id texto tipo UUID del escalón.
  TextColumn get id => text()();

  /// Cantidad mínima de unidades que dispara el escalón (>= 2).
  IntColumn get minQty => integer()();

  /// Porcentaje de descuento como texto `decimal` (0 < % <= 100).
  TextColumn get percent => text()();

  /// Posición en la lista (0..n-1). Re-secuenciado por el repository.
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
