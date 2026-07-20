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

  /// Tiempo total en horas (decimal, ej: 1.55 = 1h 33min).
  RealColumn get totalHours => real()();

  /// Parte de minutos del tiempo de impresion (0-59).
  ///
  /// **Por que existe**: el form tiene 2 inputs separados (Horas, Minutos) por
  /// UX. Persistir solo `totalHours` como decimal perdia el split: al recargar
  /// con "Reusar", el campo Minutos quedaba vacio. Esta columna preserva la
  /// entrada original del usuario.
  ///
  /// Para registros pre-migracion v4 el valor es 0 (default). El notifier
  /// deriva los minutos del decimal en ese caso (best-effort).
  IntColumn get printMinutes => integer().withDefault(const Constant(0))();

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
