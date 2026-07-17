// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/calculation_output.dart';
import '../domain/entities/material_input.dart';

/// Datos de entrada para crear una cotizacion.
///
/// Snapshot de los valores al guardar.
class CalculationDraft {
  const CalculationDraft({
    required this.materials,
    required this.totalHours,
    required this.discountPercentage,
    required this.output,
    this.filamentLabel = '',
    this.pieceName,
    this.clientName,
  });

  final List<MaterialInput> materials;
  final Decimal totalHours;
  final Decimal discountPercentage;
  final CalculationOutput output;
  final String filamentLabel;
  final String? pieceName;
  final String? clientName;
}

/// CRUD + queries de cotizaciones.
///
/// **Atomicidad**: `create` usa una transaccion para insertar el padre
/// (calculation) y los hijos (materials) en una sola operacion.
class CalculationRepository {
  const CalculationRepository(this._db);

  final AppDatabase _db;

  /// Crea una cotizacion con sus materiales.
  ///
  /// Devuelve el id de la cotizacion creada.
  /// Los campos legacy (electricCost, profit, watts, kwh) se guardan como 0
  /// para nuevos registros; los historicos conservan sus valores.
  Future<int> create(CalculationDraft draft) {
    return _db.transaction(() async {
      final o = draft.output;
      final calcId = await _db.into(_db.calculations).insert(
            CalculationsCompanion.insert(
              createdAt: DateTime.now().toUtc(),
              pieceName: Value(draft.pieceName),
              clientName: Value(draft.clientName),
              printerId: const Value(null),
              printerNameSnapshot: const Value(null),
              printerWattsSnapshot: Value(0.0),
              totalHours: draft.totalHours.toDouble(),
              discountPercentage: draft.discountPercentage.toDouble(),
              kwhRateSnapshot: 0.0,
              profitBaseSnapshot: 0.0,
              materialCostSnapshot: o.materialCost.toDouble(),
              electricCostSnapshot: o.electricCost.toDouble(),
              laborCostSnapshot: o.laborCost.toDouble(),
              postProcessCostSnapshot: o.postProcessCost.toDouble(),
              baseCostSnapshot: o.baseCost.toDouble(),
              failureCostSnapshot: o.failureCost.toDouble(),
              markupCostSnapshot: o.markupCost.toDouble(),
              profitAmountSnapshot: o.profitAmount.toDouble(),
              minimumChargeAppliedSnapshot: 0.0,
              effectiveTotalSnapshot: o.totalFinal.toDouble(),
              totalPriceSnapshot: o.totalPrice.toDouble(),
              laborRateSnapshot: 0.0,
              postProcessRateSnapshot: 0.0,
              failureRateSnapshot: 0.0,
              minimumChargeSnapshot: 0.0,
              markupOnMaterialsSnapshot: 0.0,
            ),
          );
      for (final m in draft.materials) {
        await _db.into(_db.calculationMaterials).insert(
              CalculationMaterialsCompanion.insert(
                calculationId: calcId,
                filamentId: Value(_filamentIdFromLabel(m.label)),
                label: m.label,
                weightGrams: m.weightGrams.toDouble(),
                pricePerBobbinSnapshot: m.pricePerBobbin.toDouble(),
                gramsPerBobbinSnapshot: m.gramsPerBobbin.toDouble(),
              ),
            );
      }
      return calcId;
    });
  }

  /// Lista todas las cotizaciones, mas recientes primero.
  Future<List<Calculation>> listAll() {
    return (_db.select(_db.calculations)
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Busca cotizaciones por nombre de pieza o cliente (LIKE %query%).
  Future<List<Calculation>> search(String query) {
    final pattern = '%$query%';
    return (_db.select(_db.calculations)
          ..where((c) =>
              c.pieceName.like(pattern) | c.clientName.like(pattern))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Stream<List<Calculation>> watchAll() {
    return (_db.select(_db.calculations)
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  /// Obtiene los materiales de una cotizacion.
  Future<List<CalculationMaterial>> materialsOf(int calculationId) {
    return (_db.select(_db.calculationMaterials)
          ..where((m) => m.calculationId.equals(calculationId)))
        .get();
  }

  /// Cambia el flag isSold de una cotizacion.
  Future<bool> toggleSold(int id, bool isSold) async {
    final updated = await (_db.update(_db.calculations)
          ..where((c) => c.id.equals(id)))
        .write(CalculationsCompanion(isSold: Value(isSold)));
    return updated > 0;
  }

  /// Actualiza el nombre de pieza / cliente. Otros campos NO se modifican.
  Future<bool> updateMetadata({
    required int id,
    String? pieceName,
    String? clientName,
  }) async {
    final updated = await (_db.update(_db.calculations)
          ..where((c) => c.id.equals(id)))
        .write(
      CalculationsCompanion(
        pieceName: Value(pieceName),
        clientName: Value(clientName),
      ),
    );
    return updated > 0;
  }

  /// Elimina una cotizacion (CASCADE borra sus materiales).
  Future<int> delete(int id) {
    return (_db.delete(_db.calculations)..where((c) => c.id.equals(id))).go();
  }

  /// Total cotizado (suma de totalPriceSnapshot de todas las cotizaciones).
  Future<Decimal> totalQuoted() async {
    final all = await listAll();
    return all.fold<Decimal>(Decimal.zero, (acc, c) => acc + Decimal.parse(c.totalPriceSnapshot.toString()));
  }

  /// Total ganado (suma de totalPriceSnapshot donde isSold=true).
  Future<Decimal> totalSold() async {
    final sold = await (_db.select(_db.calculations)
          ..where((c) => c.isSold.equals(true)))
        .get();
    return sold.fold<Decimal>(Decimal.zero, (acc, c) => acc + Decimal.parse(c.totalPriceSnapshot.toString()));
  }

  /// Cantidad de cotizaciones vendidas.
  Future<int> countSold() async {
    final result = await (_db.selectOnly(_db.calculations)
          ..addColumns([_db.calculations.id.count()])
          ..where(_db.calculations.isSold.equals(true)))
        .getSingle();
    return result.read(_db.calculations.id.count()) ?? 0;
  }

  /// Cantidad total de cotizaciones.
  Future<int> countAll() async {
    final result = await (_db.selectOnly(_db.calculations)
          ..addColumns([_db.calculations.id.count()]))
        .getSingle();
    return result.read(_db.calculations.id.count()) ?? 0;
  }

  // -------- Helpers --------

  /// Extrae filamentId numerico del label si tiene formato "id:N".
  /// En caso contrario, devuelve null (proforma rapida).
  int? _filamentIdFromLabel(String label) {
    if (label.startsWith('id:')) {
      final idStr = label.substring(3);
      return int.tryParse(idStr);
    }
    return null;
  }
}
