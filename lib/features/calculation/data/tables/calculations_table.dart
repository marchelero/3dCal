// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla padre de cotizaciones.
///
/// Almacena los **snapshots** de los valores al momento de guardar, para que
/// cambios futuros en el catalogo (borrar filamento, cambiar precio) NO
/// afecten registros historicos.
///
/// Se omite la FK dura a `printers`: la relacion es soft via [printerId]
/// nullable + [printerWattsSnapshot]. Esto permite que al eliminar una
/// impresora, las cotizaciones sigan mostrando su nombre y watts historicos.
@DataClassName('Calculation')
class Calculations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Fecha de creacion. UTC.
  DateTimeColumn get createdAt => dateTime()();

  /// Nombre de la pieza. Nullable para proformas rapidas.
  TextColumn get pieceName => text().nullable()();

  /// Nombre del cliente. Nullable.
  TextColumn get clientName => text().nullable()();

  /// Soft FK a `printers.id`. Nullable si no habia impresora.
  IntColumn get printerId => integer().nullable()();

  /// Snapshot del nombre de la impresora (para mostrar en historico).
  TextColumn get printerNameSnapshot => text().nullable()();

  /// Snapshot de watts de la impresora al guardar.
  RealColumn get printerWattsSnapshot => real().withDefault(const Constant(0))();

  /// Tiempo total en horas.
  RealColumn get totalHours => real()();

  /// Descuento aplicado en % (0-50).
  RealColumn get discountPercentage => real()();

  /// Snapshot de la tarifa electrica al guardar.
  RealColumn get kwhRateSnapshot => real()();

  /// Snapshot de la ganancia base al guardar.
  RealColumn get profitBaseSnapshot => real()();

  /// Marca como vendida (alimenta dashboard).
  BoolColumn get isSold => boolean().withDefault(const Constant(false))();

  /// Snapshots financieros (cacheados para queries rapidas en dashboard).
  RealColumn get materialCostSnapshot => real()();
  RealColumn get electricCostSnapshot => real()();
  RealColumn get laborCostSnapshot => real()();
  RealColumn get postProcessCostSnapshot => real()();
  RealColumn get baseCostSnapshot => real()();
  RealColumn get failureCostSnapshot => real()();
  RealColumn get markupCostSnapshot => real()();
  RealColumn get profitAmountSnapshot => real()();
  RealColumn get minimumChargeAppliedSnapshot => real()();
  RealColumn get effectiveTotalSnapshot => real()();
  RealColumn get totalPriceSnapshot => real()();

  /// Snapshots de settings (F1) al momento de guardar.
  RealColumn get laborRateSnapshot => real()();
  RealColumn get postProcessRateSnapshot => real()();
  RealColumn get failureRateSnapshot => real()();
  RealColumn get minimumChargeSnapshot => real()();
  RealColumn get markupOnMaterialsSnapshot => real()();

  @override
  List<Set<Column>> get uniqueKeys => [];
}
