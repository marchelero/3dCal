// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/calculation_output.dart';
import '../domain/entities/material_input.dart';
import '../domain/monthly_totals.dart';

/// Datos de entrada para crear una cotizacion.
///
/// Snapshot de los valores al guardar.
class CalculationDraft {
  const CalculationDraft({
    required this.materials,
    required this.totalHours,
    required this.discountPercentage,
    required this.output,
    this.printMinutes = 0,
    this.filamentLabel = '',
    this.pieceName,
    this.clientName,
    this.notes,
    this.conditions,
    this.isTemplate = false,
  });

  final List<MaterialInput> materials;
  final Decimal totalHours;
  final Decimal discountPercentage;
  final CalculationOutput output;
  final String filamentLabel;
  final String? pieceName;
  final String? clientName;

  /// Notas de la cotizacion (se imprimen en el PDF).
  final String? notes;

  /// Condiciones comerciales (se imprimen en el PDF).
  final String? conditions;

  /// Minutos del tiempo de impresion (0-59). Persistido por separado de
  /// [totalHours] para preservar el split h/m al recargar.
  final int printMinutes;

  /// True si el registro es una plantilla de trabajo frecuente (reusada para
  /// cargar configuraciones, nunca aparece en historial/dashboard).
  final bool isTemplate;
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
    return _insert(draft, isTemplate: draft.isTemplate);
  }

  /// Crea una cotizacion normal si aun queda espacio en el limite indicado.
  ///
  /// El conteo y la insercion comparten la misma transaccion para que dos
  /// guardados concurrentes no puedan pasar ambos un limite Free.
  /// Retorna `null` cuando el limite ya fue alcanzado.
  Future<int?> createIfWithinLimit(
    CalculationDraft draft, {
    required int limit,
  }) {
    return _db.transaction(() async {
      final count = await _countCalculations();
      if (count >= limit) return null;
      return _insertInTransaction(draft, isTemplate: false);
    });
  }

  /// Crea una plantilla de trabajo frecuente.
  ///
  /// Reusa la misma fila/snapshots que una cotizacion pero marcada como
  /// [isTemplate]: se excluye del historial, dashboard y cap free. Aplicar
  /// una plantilla = [loadFromCalculation] en el notifier.
  Future<int> createTemplate(CalculationDraft draft) {
    return _insert(draft, isTemplate: true);
  }

  Future<int> _insert(CalculationDraft draft, {required bool isTemplate}) {
    return _db.transaction(() async {
      return _insertInTransaction(draft, isTemplate: isTemplate);
    });
  }

  Future<int> _insertInTransaction(
    CalculationDraft draft, {
    required bool isTemplate,
  }) async {
    final o = draft.output;
    final calcId = await _db
        .into(_db.calculations)
        .insert(
          CalculationsCompanion.insert(
            createdAt: DateTime.now().toUtc(),
            pieceName: Value(draft.pieceName),
            clientName: Value(draft.clientName),
            notes: Value(draft.notes),
            conditions: Value(draft.conditions),
            printerId: const Value(null),
            printerNameSnapshot: const Value(null),
            printerWattsSnapshot: Value(0),
            totalHours: draft.totalHours.toDouble(),
            printMinutes: Value(draft.printMinutes),
            discountPercentage: draft.discountPercentage.toDouble(),
            kwhRateSnapshot: 0,
            profitBaseSnapshot: 0,
            materialCostSnapshot: o.materialCost.toDouble(),
            electricCostSnapshot: o.electricCost.toDouble(),
            laborCostSnapshot: o.laborCost.toDouble(),
            postProcessCostSnapshot: o.postProcessCost.toDouble(),
            baseCostSnapshot: o.baseCost.toDouble(),
            failureCostSnapshot: o.failureCost.toDouble(),
            markupCostSnapshot: o.markupCost.toDouble(),
            profitAmountSnapshot: o.profitAmount.toDouble(),
            minimumChargeAppliedSnapshot: 0,
            effectiveTotalSnapshot: o.totalFinal.toDouble(),
            totalPriceSnapshot: o.totalPrice.toDouble(),
            laborRateSnapshot: 0,
            postProcessRateSnapshot: 0,
            failureRateSnapshot: 0,
            minimumChargeSnapshot: 0,
            markupOnMaterialsSnapshot: 0,
            isTemplate: Value(isTemplate),
          ),
        );
    for (final m in draft.materials) {
      await _db
          .into(_db.calculationMaterials)
          .insert(
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
  }

  /// Duplica una cotizacion existente: copia todos los snapshots y
  /// materiales con un id nuevo, `createdAt` = ahora e `isSold` = false.
  ///
  /// [pieceNameSuffix] se agrega al nombre de la pieza original (ej:
  /// `' (copia)'`) para distinguir la copia en el historial. Si la
  /// original no tiene nombre, la copia tampoco.
  ///
  /// Devuelve el id de la nueva cotizacion.
  Future<int> duplicate(int sourceId, {String? pieceNameSuffix}) {
    return _db.transaction(() async {
      return _duplicateInTransaction(
        sourceId,
        pieceNameSuffix: pieceNameSuffix,
      );
    });
  }

  /// Duplica una cotizacion solo si aun queda espacio en el limite indicado.
  ///
  /// El conteo y la copia comparten la misma transaccion, igual que
  /// [createIfWithinLimit], para que una duplicacion concurrente no supere
  /// el limite Free.
  Future<int?> duplicateIfWithinLimit(
    int sourceId, {
    required int limit,
    String? pieceNameSuffix,
  }) {
    return _db.transaction(() async {
      final count = await _countCalculations();
      if (count >= limit) return null;
      return _duplicateInTransaction(
        sourceId,
        pieceNameSuffix: pieceNameSuffix,
      );
    });
  }

  Future<int> _duplicateInTransaction(
    int sourceId, {
    String? pieceNameSuffix,
  }) async {
    final source = await (_db.select(
      _db.calculations,
    )..where((c) => c.id.equals(sourceId))).getSingleOrNull();
    if (source == null) {
      throw StateError('Calculation $sourceId not found for duplicate');
    }
    final materials = await (_db.select(
      _db.calculationMaterials,
    )..where((m) => m.calculationId.equals(sourceId))).get();

    final pieceName = source.pieceName == null
        ? null
        : source.pieceName! + (pieceNameSuffix ?? '');

    final newId = await _db
        .into(_db.calculations)
        .insert(
          CalculationsCompanion.insert(
            createdAt: DateTime.now().toUtc(),
            pieceName: Value(pieceName),
            clientName: Value(source.clientName),
            notes: Value(source.notes),
            conditions: Value(source.conditions),
            printerId: Value(source.printerId),
            printerNameSnapshot: Value(source.printerNameSnapshot),
            printerWattsSnapshot: Value(source.printerWattsSnapshot),
            totalHours: source.totalHours,
            printMinutes: Value(source.printMinutes),
            discountPercentage: source.discountPercentage,
            kwhRateSnapshot: source.kwhRateSnapshot,
            profitBaseSnapshot: source.profitBaseSnapshot,
            materialCostSnapshot: source.materialCostSnapshot,
            electricCostSnapshot: source.electricCostSnapshot,
            laborCostSnapshot: source.laborCostSnapshot,
            postProcessCostSnapshot: source.postProcessCostSnapshot,
            baseCostSnapshot: source.baseCostSnapshot,
            failureCostSnapshot: source.failureCostSnapshot,
            markupCostSnapshot: source.markupCostSnapshot,
            profitAmountSnapshot: source.profitAmountSnapshot,
            minimumChargeAppliedSnapshot: source.minimumChargeAppliedSnapshot,
            effectiveTotalSnapshot: source.effectiveTotalSnapshot,
            totalPriceSnapshot: source.totalPriceSnapshot,
            laborRateSnapshot: source.laborRateSnapshot,
            postProcessRateSnapshot: source.postProcessRateSnapshot,
            failureRateSnapshot: source.failureRateSnapshot,
            minimumChargeSnapshot: source.minimumChargeSnapshot,
            markupOnMaterialsSnapshot: source.markupOnMaterialsSnapshot,
          ),
        );
    for (final m in materials) {
      await _db
          .into(_db.calculationMaterials)
          .insert(
            CalculationMaterialsCompanion.insert(
              calculationId: newId,
              filamentId: Value(m.filamentId),
              label: m.label,
              weightGrams: m.weightGrams,
              pricePerBobbinSnapshot: m.pricePerBobbinSnapshot,
              gramsPerBobbinSnapshot: m.gramsPerBobbinSnapshot,
            ),
          );
    }
    return newId;
  }

  /// Lista todas las cotizaciones (no plantillas), mas recientes primero.
  Future<List<Calculation>> listAll() {
    return (_db.select(_db.calculations)
          ..where((c) => c.isTemplate.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Busca cotizaciones por nombre de pieza o cliente (LIKE %query%).
  /// Excluye plantillas.
  Future<List<Calculation>> search(String query) {
    final pattern = '%$query%';
    return (_db.select(_db.calculations)
          ..where(
            (c) =>
                c.isTemplate.equals(false) &
                (c.pieceName.like(pattern) | c.clientName.like(pattern)),
          )
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Stream<List<Calculation>> watchAll() {
    return (_db.select(_db.calculations)
          ..where((c) => c.isTemplate.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  /// Lista las plantillas de trabajo, mas recientes primero.
  Future<List<Calculation>> listTemplates() {
    return (_db.select(_db.calculations)
          ..where((c) => c.isTemplate.equals(true))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Cantidad de plantillas guardadas.
  Future<int> countTemplates() async {
    final result =
        await (_db.selectOnly(_db.calculations)
              ..addColumns([_db.calculations.id.count()])
              ..where(_db.calculations.isTemplate.equals(true)))
            .getSingle();
    return result.read(_db.calculations.id.count()) ?? 0;
  }

  /// Clientes más recientes (distintos), ordenados por la última cotización
  /// de cada uno. Excluye plantillas y nombres vacíos. Pensado para el
  /// quick-pick del diálogo de guardado.
  Future<List<String>> recentClientNames({int limit = 8}) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT client_name AS name
      FROM calculations
      WHERE is_template = 0
        AND client_name IS NOT NULL
        AND client_name != ''
      GROUP BY client_name
      ORDER BY MAX(created_at) DESC, MAX(id) DESC
      LIMIT ?
      ''',
          variables: [Variable<int>(limit)],
        )
        .get();
    return [for (final row in rows) row.read<String>('name')];
  }

  /// Obtiene los materiales de una cotizacion.
  Future<List<CalculationMaterial>> materialsOf(int calculationId) {
    return (_db.select(
      _db.calculationMaterials,
    )..where((m) => m.calculationId.equals(calculationId))).get();
  }

  /// Cambia el flag isSold de una cotizacion.
  Future<bool> toggleSold(int id, bool isSold) async {
    final updated =
        await (_db.update(_db.calculations)..where((c) => c.id.equals(id)))
            .write(CalculationsCompanion(isSold: Value(isSold)));
    return updated > 0;
  }

  /// Actualiza el nombre de pieza / cliente. Otros campos NO se modifican.
  Future<bool> updateMetadata({
    required int id,
    String? pieceName,
    String? clientName,
  }) async {
    final updated =
        await (_db.update(
          _db.calculations,
        )..where((c) => c.id.equals(id))).write(
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

  /// Total cotizado (suma de totalPriceSnapshot de todas las cotizaciones,
  /// excluye plantillas).
  Future<Decimal> totalQuoted() async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_price_snapshot), 0) AS total FROM calculations WHERE is_template = 0',
        )
        .getSingle();
    return Decimal.parse(result.read<double>('total').toStringAsFixed(2));
  }

  /// Total ganado (suma de totalPriceSnapshot donde isSold=true, excluye
  /// plantillas).
  Future<Decimal> totalSold() async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_price_snapshot), 0) AS total FROM calculations WHERE is_sold = 1 AND is_template = 0',
        )
        .getSingle();
    return Decimal.parse(result.read<double>('total').toStringAsFixed(2));
  }

  /// Cantidad de cotizaciones vendidas (excluye plantillas).
  Future<int> countSold() async {
    final result =
        await (_db.selectOnly(_db.calculations)
              ..addColumns([_db.calculations.id.count()])
              ..where(
                _db.calculations.isSold.equals(true) &
                    _db.calculations.isTemplate.equals(false),
              ))
            .getSingle();
    return result.read(_db.calculations.id.count()) ?? 0;
  }

  /// Cantidad total de cotizaciones (excluye plantillas).
  Future<int> countAll() async {
    return _countCalculations();
  }

  Future<int> _countCalculations() async {
    final countExpression = _db.calculations.id.count();
    final result =
        await (_db.selectOnly(_db.calculations)
              ..addColumns([countExpression])
              ..where(_db.calculations.isTemplate.equals(false)))
            .getSingle();
    return result.read(countExpression) ?? 0;
  }

  /// Totales agrupados por mes (YYYY-MM).
  /// Ordenados por mes ascendente. Maneja DB vacia (retorna []) y
  /// created_at null (filtra esos rows).
  Future<List<MonthlyTotal>> monthlyTotals() async {
    final rows = await _db.customSelect('''
      SELECT COALESCE(strftime('%Y-%m', created_at), 'desconocido') AS month,
             COALESCE(SUM(total_price_snapshot), 0) AS quoted,
             COALESCE(SUM(CASE WHEN is_sold = 1 THEN total_price_snapshot ELSE 0 END), 0) AS sold
      FROM calculations
      WHERE created_at IS NOT NULL AND is_template = 0
      GROUP BY month
      ORDER BY month ASC
      ''').get();
    return rows.map((r) {
      return MonthlyTotal(
        yearMonth: r.read<String>('month'),
        quoted: r.read<double>('quoted'),
        sold: r.read<double>('sold'),
      );
    }).toList();
  }

  /// Top materiales mas usados en cotizaciones.
  Future<List<TopMaterial>> topMaterials({int limit = 5}) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT cm.label, COUNT(*) AS cnt, COALESCE(SUM(cm.weight_grams), 0) AS total_g
      FROM calculation_materials cm
      JOIN calculations c ON c.id = cm.calculation_id
      WHERE cm.label IS NOT NULL AND cm.label != '' AND c.is_template = 0
      GROUP BY cm.label
      ORDER BY cnt DESC
      LIMIT ?
      ''',
          variables: [Variable<int>(limit)],
        )
        .get();
    return rows.map((r) {
      return TopMaterial(
        label: r.read<String>('label'),
        count: r.read<double>('cnt').round(),
        totalWeightGrams: r.read<double>('total_g'),
      );
    }).toList();
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
