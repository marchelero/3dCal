// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/calculation_output.dart';
import '../domain/entities/material_input.dart';
import '../domain/monthly_totals.dart';

/// Fila de material para persistir en el guardado parcial.
///
/// [DraftMaterial] (el draft de sesion) usa strings porque el form todavia
/// esta en edicion; el parcial se escribe a la DB y necesita numeros.
class DraftMaterialInput {
  const DraftMaterialInput({
    required this.label,
    required this.weightGrams,
    required this.pricePerBobbin,
    required this.gramsPerBobbin,
    this.useOwnTime = false,
    this.materialHours,
    this.materialMinutes,
  });

  final String label;
  final double weightGrams;
  final double pricePerBobbin;
  final double gramsPerBobbin;

  /// Tiempo propio del material (schema v15). Null = no usaba tiempo propio.
  final bool? useOwnTime;
  final double? materialHours;
  final double? materialMinutes;
}

/// Vista ligera de una cotizacion para el historial (F3).
///
/// Pensada para la lista y el export CSV: contiene SOLO las columnas que
/// esos flujos leen, NUNCA el BLOB de imagen. `hasImage` indica si la foto
/// existe para que la UI decida renderizar el thumbnail SIN materializar
/// el BLOB; la fila completa (con BLOB) se lee on-demand via
/// [CalculationRepository.getById] (detalle, prefill, thumbnail).
class CalculationListItem {
  const CalculationListItem({
    required this.id,
    required this.createdAt,
    this.pieceName,
    this.clientName,
    required this.quantity,
    required this.totalHours,
    required this.discountPercentage,
    required this.isSold,
    required this.isPartial,
    required this.materialCostSnapshot,
    required this.electricCostSnapshot,
    required this.profitAmountSnapshot,
    required this.totalPriceSnapshot,
    required this.hasImage,
    this.batchDiscountPercent,
    this.batchDiscountAmount,
  });

  final int id;
  final DateTime createdAt;
  final String? pieceName;
  final String? clientName;
  final int quantity;
  final double totalHours;
  final double discountPercentage;
  final bool isSold;
  final bool isPartial;
  final double materialCostSnapshot;
  final double electricCostSnapshot;
  final double profitAmountSnapshot;
  final double totalPriceSnapshot;
  final bool hasImage;

  /// Porcentaje del escalÃ³n de descuento mayorista (snapshot).
  final String? batchDiscountPercent;

  /// Monto del descuento mayorista (snapshot).
  final String? batchDiscountAmount;

  /// Total efectivo de la cotizacion: `totalPriceSnapshot` (normalizado a 2
  /// decimales, ver doc de precision monetaria de este archivo) x `quantity`,
  /// con `quantity < 1` tratada como 1 unidad.
  ///
  /// Dinero es SIEMPRE [Decimal]; el `double` es solo la frontera de
  /// persistencia de drift.
  Decimal get effectiveTotal {
    final unit = Decimal.parse(totalPriceSnapshot.toStringAsFixed(2));
    return unit * Decimal.fromInt(quantity < 1 ? 1 : quantity);
  }
}

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
    this.isAdvanced = false,
    this.quantity = 1,
    this.pieceImageBytes,
    this.batchDiscountPercent,
    this.batchDiscountAmount,
    this.modelingMode = 'fixed',
    this.modelingValue = 0,
    this.postprocMode = 'fixed',
    this.postprocValue = 0,
    this.extraCostMode = 'fixed',
    this.extraCostValue = 0,
    this.extraCostLabel = '',
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

  /// v16: la cotizacion se creo en modo Advanced. Persistido porque la
  /// inferencia por cantidad de materiales degrada Advanced de 1 material
  /// a Express al reusar.
  final bool isAdvanced;

  /// Cantidad de unidades del lote (>= 1). Los snapshots financieros de
  /// [output] son UNITARIOS; el total efectivo es `unitario x quantity`.
  final int quantity;

  /// Foto de la pieza persistida (F2): BLOB ya downscaled (max 1200px,
  /// JPEG q85). Null = cotizacion sin foto.
  final Uint8List? pieceImageBytes;

  /// Porcentaje del escalÃ³n de descuento mayorista (snapshot).
  /// Null cuando no aplica escalÃ³n.
  final Decimal? batchDiscountPercent;

  /// Monto del descuento mayorista (snapshot). 0 sin escalÃ³n.
  final Decimal? batchDiscountAmount;

  // === v17: Costos de la pieza ===

  /// Modo del campo "Modelado y diseÃ±o": `pct` (porcentaje sobre el costo
  /// base) o `fixed` (monto fijo). Default `fixed`.
  final String modelingMode;

  /// Valor del modelado: porcentaje si [modelingMode] es `pct`, monto si es
  /// `fixed`.
  final double modelingValue;

  /// Modo del campo "Postprocesado". Misma semantica que [modelingMode].
  final String postprocMode;

  /// Valor del postprocesado.
  final double postprocValue;

  /// Modo del campo "Extras". Misma semantica que [modelingMode].
  final String extraCostMode;

  /// Valor de los extras.
  final double extraCostValue;

  /// Texto libre de los extras ("2 argollas M3"). No afecta el calculo.
  final String extraCostLabel;
}

/// CRUD + queries de cotizaciones.
///
/// **Atomicidad**: `create` usa una transaccion para insertar el padre
/// (calculation) y los hijos (materials) en una sola operacion.
///
/// **Precision monetaria (decisiÃ³n documentada)**: drift persiste los
/// snapshots como REAL (`double`). El motor y el dominio usan `Decimal`;
/// el redondeo solo ocurre en la frontera de persistencia y en lectura se
/// normaliza con `toStringAsFixed(2)` antes del `Decimal.parse`. Con los
/// rangos de la app (miles de Bs por cotizacion) el error de double es
/// < 0.005 â€” indetectable a 2 decimales. Migrar a TEXT/centavos es la
/// salida si algÃºn dÃ­a se suman >10^11 Bs acumulados.
///
/// **Cantidad (lotes, v8)**: `quantity` >= 1. Los snapshots financieros y
/// de materiales son UNITARIOS; todas las queries agregadas multiplican
/// por `quantity` para reportar totales efectivos.
class CalculationRepository {
  const CalculationRepository(this._db);

  final AppDatabase _db;

  /// BUG-010 fix: filtro base que excluye plantillas.
  ///
  /// Usar en TODAS las queries que NO deben incluir plantillas de trabajo
  /// (historial, dashboard, busqueda, contadores). Centralizado aca para
  /// que sea imposible olvidar al agregar un campo o una query nueva.
  /// Para las plantillas, ver [listTemplates].
  Expression<bool> excludeTemplatesFilter() =>
      _db.calculations.isTemplate.equals(false);

  /// Filtro que excluye plantillas **y borradores** (`isPartial`).
  ///
  /// Se usa SOLO donde un borrador no debe contar: el **cap free**
  /// ([_countCalculations]) y las ventas ([countSold]). Un borrador es una
  /// cotizacion a medio hacer: no debe consumir el cap (si no, el guardado
  /// real falla) ni contar como venta.
  ///
  /// El HISTORIAL ([listItems], [listAll], [search]) y el detalle ([getById])
  /// usan [excludeTemplatesFilter] a proposito: el usuario quiere ver y
  /// retomar sus borradores.
  Expression<bool> excludeDraftsAndTemplatesFilter() =>
      _db.calculations.isTemplate.equals(false) &
      _db.calculations.isPartial.equals(false);

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
    final calcId = await _db
        .into(_db.calculations)
        .insert(
          _snapshotColumns(draft).copyWith(
            createdAt: Value(DateTime.now().toUtc()),
            isSold: const Value(false),
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
              useOwnTime: Value(m.useOwnTime),
              materialHours: Value(m.ownTimeHours?.toDouble()),
              materialMinutes: Value(m.ownTimeMinutes?.toDouble()),
            ),
          );
    }
    return calcId;
  }

  /// Columnas de snapshot derivadas de [draft], compartidas por la escritura
  /// inicial ([_insertInTransaction]) y la edicion ([updateCalculation]).
  ///
  /// **Por que un solo lugar**: `CalculationsCompanion.insert(...)` obliga a
  /// enumerar cada columna a mano, asi que agregar un campo al draft obliga a
  /// tocar ambos caminos. Si solo se actualiza el `insert`, una edicion deja
  /// el snapshot viejo (bug silencioso de datos, no de compilacion).
  ///
  /// Deliberadamente NO incluye `createdAt`, `isSold` ni `isTemplate`: son
  /// identidad/estado de la fila, no resultado del calculo. Editar NO puede
  /// cambiarlos.
  CalculationsCompanion _snapshotColumns(CalculationDraft draft) {
    final o = draft.output;
    return CalculationsCompanion(
      pieceName: Value(draft.pieceName),
      clientName: Value(draft.clientName),
      notes: Value(draft.notes),
      conditions: Value(draft.conditions),
      printerId: const Value(null),
      printerNameSnapshot: const Value(null),
      printerWattsSnapshot: const Value(0),
      totalHours: Value(draft.totalHours.toDouble()),
      printMinutes: Value(draft.printMinutes),
      discountPercentage: Value(draft.discountPercentage.toDouble()),
      kwhRateSnapshot: const Value(0),
      profitBaseSnapshot: const Value(0),
      materialCostSnapshot: Value(o.materialCost.toDouble()),
      electricCostSnapshot: Value(o.electricCost.toDouble()),
      amortizationCostSnapshot: Value(o.amortizationCost.toDouble()),
      laborCostSnapshot: Value(o.laborCost.toDouble()),
      postProcessCostSnapshot: Value(o.postProcessCost.toDouble()),
      baseCostSnapshot: Value(o.baseCost.toDouble()),
      failureCostSnapshot: Value(o.failureCost.toDouble()),
      markupCostSnapshot: Value(o.markupCost.toDouble()),
      profitAmountSnapshot: Value(o.profitAmount.toDouble()),
      minimumChargeAppliedSnapshot: const Value(0),
      effectiveTotalSnapshot: Value(o.totalFinal.toDouble()),
      totalPriceSnapshot: Value(o.totalPrice.toDouble()),
      quantity: Value(draft.quantity < 1 ? 1 : draft.quantity),
      laborRateSnapshot: const Value(0),
      postProcessRateSnapshot: const Value(0),
      failureRateSnapshot: const Value(0),
      minimumChargeSnapshot: const Value(0),
      markupOnMaterialsSnapshot: const Value(0),
      isAdvanced: Value(draft.isAdvanced),
      pieceImageBlob: Value(draft.pieceImageBytes),
      batchDiscountPercent: Value(draft.batchDiscountPercent?.toString()),
      batchDiscountAmount: Value(draft.batchDiscountAmount?.toString()),
      // v17: los 3 costos de servicio con su modo (% / fijo). Sin esto el
      // INSERT deja los defaults de columna ('auto'/'auto'/'off') y el valor
      // del usuario se pierde al guardar.
      modelingMode: Value(draft.modelingMode),
      modelingValue: Value(draft.modelingValue),
      postprocMode: Value(draft.postprocMode),
      postprocValue: Value(draft.postprocValue),
      extraMode: Value(draft.extraCostMode),
      extraValue: Value(draft.extraCostValue),
      extraLabel: Value(draft.extraCostLabel),
    );
  }

  /// Actualiza una cotizacion existente en el lugar ("Editar" / "guardar
  /// definitiva desde un borrador").
  ///
  /// **NO crea una fila nueva**: la transaccion hace UPDATE de los snapshots y
  /// reemplaza los materiales, conservando `id`, `createdAt`, `isSold` e
  /// `isTemplate`. Editar una venta no la desmarca ni cambia su fecha en el
  /// historial.
  ///
  /// [markDefinitive]: cuando true, la fila deja de ser borrador
  /// (`isPartial = false`). Es el caso "guardar con cliente" sobre un
  /// autoguardado: el mismo id pasa a ser cotizacion definitiva.
  ///
  /// Atomicidad: el UPDATE y el reemplazo de materiales van juntos; si el
  /// segundo falla, la fila queda con los snapshots viejo y los materiales
  /// nuevos (estado incoherente que un rollback evita).
  ///
  /// Devuelve `false` si la cotizacion ya no existe (borrada en otra pestana
  /// mientras el usuario editaba).
  Future<bool> updateCalculation(
    int id,
    CalculationDraft draft, {
    bool markDefinitive = false,
  }) {
    return _db.transaction(() async {
      final columns = _snapshotColumns(draft);
      final updated = await (_db.update(
        _db.calculations,
      )..where((c) => c.id.equals(id))).write(
        markDefinitive
            ? columns.copyWith(isPartial: const Value(false))
            : columns,
      );
      if (updated == 0) return false;
      await _replaceMaterialsFromDraft(id, draft);
      return true;
    });
  }

  /// Inserta las filas de material de un [CalculationDraft] (weight/price ya
  /// vem en double, a diferencia de [DraftMaterialInput]).
  Future<void> _replaceMaterialsFromDraft(
    int calculationId,
    CalculationDraft draft,
  ) async {
    await (_db.delete(
      _db.calculationMaterials,
    )..where((t) => t.calculationId.equals(calculationId))).go();
    for (final m in draft.materials) {
      await _db
          .into(_db.calculationMaterials)
          .insert(
            CalculationMaterialsCompanion.insert(
              calculationId: calculationId,
              filamentId: Value(_filamentIdFromLabel(m.label)),
              label: m.label,
              weightGrams: m.weightGrams.toDouble(),
              pricePerBobbinSnapshot: m.pricePerBobbin.toDouble(),
              gramsPerBobbinSnapshot: m.gramsPerBobbin.toDouble(),
              useOwnTime: Value(m.useOwnTime),
              materialHours: Value(m.ownTimeHours?.toDouble()),
              materialMinutes: Value(m.ownTimeMinutes?.toDouble()),
            ),
          );
    }
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
            isAdvanced: Value(source.isAdvanced),
            discountPercentage: source.discountPercentage,
            kwhRateSnapshot: source.kwhRateSnapshot,
            profitBaseSnapshot: source.profitBaseSnapshot,
            materialCostSnapshot: source.materialCostSnapshot,
            electricCostSnapshot: source.electricCostSnapshot,
            amortizationCostSnapshot: Value(source.amortizationCostSnapshot),
            laborCostSnapshot: source.laborCostSnapshot,
            postProcessCostSnapshot: source.postProcessCostSnapshot,
            baseCostSnapshot: source.baseCostSnapshot,
            failureCostSnapshot: source.failureCostSnapshot,
            markupCostSnapshot: source.markupCostSnapshot,
            profitAmountSnapshot: source.profitAmountSnapshot,
            minimumChargeAppliedSnapshot: source.minimumChargeAppliedSnapshot,
            effectiveTotalSnapshot: source.effectiveTotalSnapshot,
            totalPriceSnapshot: source.totalPriceSnapshot,
            quantity: Value(source.quantity),
            laborRateSnapshot: source.laborRateSnapshot,
            postProcessRateSnapshot: source.postProcessRateSnapshot,
            failureRateSnapshot: source.failureRateSnapshot,
            minimumChargeSnapshot: source.minimumChargeSnapshot,
            markupOnMaterialsSnapshot: source.markupOnMaterialsSnapshot,
            pieceImageBlob: Value(source.pieceImageBlob),
            // v17: duplicar una cotizacion debe arrastrar los 3 costos de
            // servicio, no reiniciarlos a los defaults de columna.
            modelingMode: Value(source.modelingMode),
            modelingValue: Value(source.modelingValue),
            postprocMode: Value(source.postprocMode),
            postprocValue: Value(source.postprocValue),
            extraMode: Value(source.extraMode),
            extraValue: Value(source.extraValue),
            extraLabel: Value(source.extraLabel),
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
              useOwnTime: Value(m.useOwnTime),
              materialHours: Value(m.materialHours),
              materialMinutes: Value(m.materialMinutes),
            ),
          );
    }
    return newId;
  }

  /// Lista todas las cotizaciones (no plantillas), mas recientes primero.
  ///
  /// **Incluye borradores** (`isPartial`): el historial los muestra con el
  /// badge "Borrador" para que el usuario retome una cotizacion empezada.
  Future<List<Calculation>> listAll() {
    return (_db.select(_db.calculations)
          ..where((_) => excludeTemplatesFilter())
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Lista "ligera" de cotizaciones (no plantillas), mas recientes primero.
  ///
  /// **F3**: NO materializa los BLOBs de imagen — solo las columnas que la
  /// lista/CSV leen + `hasImage` (bool) para que la UI sepa que la foto
  /// existe sin cargarla. La fila completa (con BLOB) se lee on-demand via
  /// [getById].
  ///
  /// **Reactiva**: [watchItems] re-emite cuando cambia la tabla
  /// `calculations` (drift invalidacion automatica). El historial la usa para
  /// no quedar stale tras editar un borrador (bug: la lista mostraba el total
  /// viejo mientras el detalle/edit ya leian el nuevo).
  Future<List<CalculationListItem>> listItems() async {
    return watchItems().first;
  }

  /// Stream reactivo de [listItems]: re-emite en cada escritura a
  /// `calculations` (insert/update/delete de cotizaciones y borradores).
  ///
  /// Preferir esta API en providers que quieran auto-refresh sin
  /// `ref.invalidate` manual. `materialLabelsByCalcId` NO viaja en el
  /// stream: es cara (GROUP_CONCAT) y solo hace falta al buscar.
  Stream<List<CalculationListItem>> watchItems() {
    final t = _db.calculations;
    final hasImage = t.pieceImageBlob.isNotNull();
    return (_db.selectOnly(t)
          ..addColumns([
            t.id,
            t.createdAt,
            t.pieceName,
            t.clientName,
            t.quantity,
            t.totalHours,
            t.discountPercentage,
            t.isSold,
            t.isPartial,
            t.materialCostSnapshot,
            t.electricCostSnapshot,
            t.profitAmountSnapshot,
            t.totalPriceSnapshot,
            hasImage,
            t.batchDiscountPercent,
            t.batchDiscountAmount,
          ])
          ..where(excludeTemplatesFilter())
          ..orderBy([OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              CalculationListItem(
                id: r.read(t.id)!,
                createdAt: r.read(t.createdAt)!,
                pieceName: r.read(t.pieceName),
                clientName: r.read(t.clientName),
                quantity: r.read(t.quantity)!,
                totalHours: r.read(t.totalHours)!,
                discountPercentage: r.read(t.discountPercentage)!,
                isSold: r.read(t.isSold)!,
                isPartial: r.read(t.isPartial) ?? false,
                materialCostSnapshot: r.read(t.materialCostSnapshot)!,
                electricCostSnapshot: r.read(t.electricCostSnapshot)!,
                profitAmountSnapshot: r.read(t.profitAmountSnapshot)!,
                totalPriceSnapshot: r.read(t.totalPriceSnapshot)!,
                hasImage: r.read(hasImage) ?? false,
                batchDiscountPercent: r.read(t.batchDiscountPercent),
                batchDiscountAmount: r.read(t.batchDiscountAmount),
              ),
          ],
        );
  }

  /// Obtiene una cotizacion completa (incluido el BLOB de imagen) por id.
  ///
  /// **F3**: unica puerta para materializar el BLOB on-demand (detalle,
  /// prefill y thumbnail de la lista). Excluye plantillas.
  Future<Calculation?> getById(int id) {
    return (_db.select(_db.calculations)
          ..where((c) => c.id.equals(id) & excludeTemplatesFilter()))
        .getSingleOrNull();
  }

  /// Parcial (borrador de guardado rapido) mas reciente, o null.
  ///
  /// Lo usa Home para ofrecer "Continuar" cuando el usuario dejo un
  /// borrador a medias que quedo `isPartial` en DB (incluso si el draft
  /// de sesion en SharedPreferences se perdio o se limpio).
  Future<Calculation?> latestPartial() {
    return (_db.select(_db.calculations)
          ..where(
            (c) => c.isPartial.equals(true) & excludeTemplatesFilter(),
          )
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Stream reactivo de [getById]: re-emite cuando cambia ESA fila.
  ///
  /// El detalle lo usa para no quedar stale al volver del calculator
  /// (el autosave del borrador actualiza la fila y el stream notifica).
  Stream<Calculation?> watchById(int id) {
    return (_db.select(_db.calculations)
          ..where((c) => c.id.equals(id) & excludeTemplatesFilter()))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Stream reactivo de [materialsOf]: re-emite al reemplazar materiales
  /// del parcial (delete + insert en cada autosave).
  Stream<List<CalculationMaterial>> watchMaterialsOf(int calculationId) {
    return (_db.select(
      _db.calculationMaterials,
    )..where((m) => m.calculationId.equals(calculationId))).watch();
  }

  /// Busca cotizaciones por nombre de pieza o cliente (LIKE %query%).
  /// Excluye plantillas (incluye borradores).
  Future<List<Calculation>> search(String query) {
    final pattern = '%$query%';
    return (_db.select(_db.calculations)
          ..where(
            (c) =>
                excludeTemplatesFilter() &
                (c.pieceName.like(pattern) | c.clientName.like(pattern)),
          )
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
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

  /// Clientes mÃ¡s recientes (distintos), ordenados por la Ãºltima cotizaciÃ³n
  /// de cada uno. Excluye plantillas y nombres vacÃ­os. Pensado para el
  /// quick-pick del diÃ¡logo de guardado.
  Future<List<String>> recentClientNames({int limit = 8}) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT client_name AS name
      FROM calculations
      WHERE is_template = 0
        AND is_partial = 0
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

  /// Mapa `calculation_id -> labels de materiales` unidos con `|`, para la
  /// busqueda por filamento del historial (PRD 2026-09-11).
  ///
  /// Usa un `LEFT JOIN` para que las cotizaciones SIN materiales mapeen a
  /// `''` (la busqueda no debe romperse) y excluye plantillas. Query
  /// agregada read-only: no toca BLOBs ni el schema.
  Future<Map<int, String>> materialLabelsByCalcId() async {
    final rows = await _db.customSelect('''
      SELECT c.id AS calc_id,
             GROUP_CONCAT(cm.label, '|') AS labels
      FROM calculations c
      LEFT JOIN calculation_materials cm ON cm.calculation_id = c.id
      WHERE c.is_template = 0
      GROUP BY c.id
      ''').get();
    return {
      for (final row in rows)
        row.read<int>('calc_id'): row.read<String?>('labels') ?? '',
    };
  }

  /// Cambia el flag isSold de una cotizacion.
  Future<bool> toggleSold(int id, bool isSold) async {
    final updated =
        await (_db.update(_db.calculations)..where((c) => c.id.equals(id)))
            .write(CalculationsCompanion(isSold: Value(isSold)));
    return updated > 0;
  }

  /// Actualiza el nombre de pieza / cliente. Otros campos NO se modifican.
  ///
  /// Los parametros son opcionales: un campo NO provisto (null) se deja
  /// intacto (`Value.absent()`), no se borra.
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
            pieceName: pieceName == null
                ? const Value.absent()
                : Value(pieceName),
            clientName: clientName == null
                ? const Value.absent()
                : Value(clientName),
          ),
        );
    return updated > 0;
  }

  /// Elimina una cotizacion (CASCADE borra sus materiales).
  Future<int> delete(int id) {
    return (_db.delete(_db.calculations)..where((c) => c.id.equals(id))).go();
  }

  /// Total cotizado efectivo (suma `totalPriceSnapshot * quantity` de todas
  /// las cotizaciones, excluye plantillas). Opcionalmente filtrado por rango
  /// (`created_at`).
  Future<Decimal> totalQuoted({DateTime? since}) async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_price_snapshot * quantity), 0) AS total FROM calculations WHERE is_template = 0${_sinceSql(since)}',
          variables: _sinceVariables(since),
        )
        .getSingle();
    return Decimal.parse(result.read<double>('total').toStringAsFixed(2));
  }

  /// Total ganado efectivo (`totalPriceSnapshot * quantity` donde
  /// isSold=true, excluye plantillas). Opcionalmente filtrado por rango.
  Future<Decimal> totalSold({DateTime? since}) async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_price_snapshot * quantity), 0) AS total FROM calculations WHERE is_sold = 1 AND is_template = 0${_sinceSql(since)}',
          variables: _sinceVariables(since),
        )
        .getSingle();
    return Decimal.parse(result.read<double>('total').toStringAsFixed(2));
  }

  /// Ganancia total de cotizaciones vendidas (suma
  /// `profit_amount_snapshot * quantity`, is_sold=1, excluye plantillas).
  ///
  /// NOTA (legacy): los registros historicos creados antes de que existiera
  /// el snapshot guardan `profit_amount_snapshot` como 0, asi que la
  /// ganancia puede subestimar si hay historicos viejos sin recalcular.
  Future<Decimal> totalProfitSold({DateTime? since}) async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(profit_amount_snapshot * quantity), 0) AS total FROM calculations WHERE is_sold = 1 AND is_template = 0${_sinceSql(since)}',
          variables: _sinceVariables(since),
        )
        .getSingle();
    return Decimal.parse(result.read<double>('total').toStringAsFixed(2));
  }

  /// Ganancia total cotizada (suma `profit_amount_snapshot * quantity`,
  /// excluye plantillas).
  ///
  /// Misma NOTA legacy que [totalProfitSold]: 0 en registros antiguos.
  Future<Decimal> totalProfitQuoted({DateTime? since}) async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(profit_amount_snapshot * quantity), 0) AS total FROM calculations WHERE is_template = 0${_sinceSql(since)}',
          variables: _sinceVariables(since),
        )
        .getSingle();
    return Decimal.parse(result.read<double>('total').toStringAsFixed(2));
  }

  /// Cantidad de cotizaciones vendidas (excluye plantillas).
  Future<int> countSold({DateTime? since}) async {
    final result =
        await (_db.selectOnly(_db.calculations)
              ..addColumns([_db.calculations.id.count()])
              ..where(
                _db.calculations.isSold.equals(true) &
                    excludeDraftsAndTemplatesFilter() &
                    _sinceExpression(since),
              ))
            .getSingle();
    return result.read(_db.calculations.id.count()) ?? 0;
  }

  /// Cantidad total de cotizaciones (excluye plantillas).
  Future<int> countAll({DateTime? since}) async {
    return _countCalculations(since: since);
  }

  Future<int> _countCalculations({DateTime? since}) async {
    final countExpression = _db.calculations.id.count();
    final result =
        await (_db.selectOnly(_db.calculations)
              ..addColumns([countExpression])
              ..where(
                excludeDraftsAndTemplatesFilter() & _sinceExpression(since),
              ))
            .getSingle();
    return result.read(countExpression) ?? 0;
  }

  /// Totales efectivos agrupados por mes (YYYY-MM): `total_price_snapshot *
  /// quantity` (cotizado) y lo mismo donde is_sold=1 (vendido).
  /// Ordenados por mes ascendente. Maneja DB vacia (retorna []) y
  /// created_at null (filtra esos rows).
  Future<List<MonthlyTotal>> monthlyTotals({DateTime? since}) async {
    final rows = await _db.customSelect('''
      SELECT COALESCE(strftime('%Y-%m', created_at), 'desconocido') AS month,
             COALESCE(SUM(total_price_snapshot * quantity), 0) AS quoted,
             COALESCE(SUM(CASE WHEN is_sold = 1 THEN total_price_snapshot * quantity ELSE 0 END), 0) AS sold
      FROM calculations
      WHERE created_at IS NOT NULL AND is_template = 0${_sinceSql(since)}
      GROUP BY month
      ORDER BY month ASC
      ''', variables: _sinceVariables(since)).get();
    return rows.map((r) {
      return MonthlyTotal(
        yearMonth: r.read<String>('month'),
        quoted: Decimal.parse(r.read<double>('quoted').toStringAsFixed(2)),
        sold: Decimal.parse(r.read<double>('sold').toStringAsFixed(2)),
      );
    }).toList();
  }

  /// Top materiales mas usados en cotizaciones.
  Future<List<TopMaterial>> topMaterials({
    int limit = 5,
    DateTime? since,
  }) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT cm.label, COUNT(*) AS cnt, COALESCE(SUM(cm.weight_grams * c.quantity), 0) AS total_g
      FROM calculation_materials cm
      JOIN calculations c ON c.id = cm.calculation_id
      WHERE cm.label IS NOT NULL AND cm.label != '' AND c.is_template = 0${_sinceSql(since, column: 'c.created_at')}
      GROUP BY cm.label
      ORDER BY cnt DESC
      LIMIT ?
      ''',
          variables: [..._sinceVariables(since), Variable<int>(limit)],
        )
        .get();
    return rows.map((r) {
      return TopMaterial(
        label: r.read<String>('label'),
        count: r.read<double>('cnt').round(),
        totalWeightGrams: Decimal.parse(
          r.read<double>('total_g').toStringAsFixed(2),
        ),
      );
    }).toList();
  }

  /// Top clientes por total cotizado (excluye plantillas y nombres
  /// vacios). Pro analytics.
  Future<List<TopClient>> topClients({int limit = 5, DateTime? since}) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT client_name AS label,
             COALESCE(SUM(total_price_snapshot * quantity), 0) AS total,
             COUNT(*) AS cnt
      FROM calculations
      WHERE is_template = 0
        AND is_partial = 0
        AND client_name IS NOT NULL
        AND client_name != ''${_sinceSql(since)}
      GROUP BY client_name
      ORDER BY total DESC
      LIMIT ?
      ''',
          variables: [..._sinceVariables(since), Variable<int>(limit)],
        )
        .get();
    return rows.map((r) {
      return TopClient(
        label: r.read<String>('label'),
        total: Decimal.parse(r.read<double>('total').toStringAsFixed(2)),
        count: r.read<double>('cnt').round(),
      );
    }).toList();
  }

  /// Horas totales de impresion cotizadas, efectivas
  /// (`total_hours * quantity`, excluye plantillas).
  ///
  /// Horas NO es dinero, asi que se permite `double` aca (mismo criterio
  /// que [monthlyTotals] usa para horas, excepcion al non-negotiable).
  Future<double> totalPrintHours({DateTime? since}) async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_hours * quantity), 0) AS hours FROM calculations WHERE is_template = 0${_sinceSql(since)}',
          variables: _sinceVariables(since),
        )
        .getSingle();
    return result.read<double>('hours');
  }

  /// Gramos totales de filamento cotizado (suma
  /// `weight_grams * quantity` de materiales de cotizaciones no plantilla).
  /// Pro analytics.
  Future<Decimal> totalFilamentGrams({DateTime? since}) async {
    final result = await _db.customSelect('''
      SELECT COALESCE(SUM(cm.weight_grams * c.quantity), 0) AS total_g
      FROM calculation_materials cm
      JOIN calculations c ON c.id = cm.calculation_id
      WHERE c.is_template = 0${_sinceSql(since, column: 'c.created_at')}
      ''', variables: _sinceVariables(since)).getSingle();
    return Decimal.parse(result.read<double>('total_g').toStringAsFixed(2));
  }

  // -------- Helpers --------

  /// Fragmento SQL de rango de fechas: ` AND <column> >= ?` si [since] no
  /// es null. Se usa para filtrar stats del dashboard por 7d/30d/90d/YTD.
  String _sinceSql(DateTime? since, {String column = 'created_at'}) {
    return since == null ? '' : ' AND $column >= ?';
  }

  /// Variables de rango de fechas a pasar a customSelect (en el mismo
  /// orden que los `?` de [_sinceSql]).
  List<Variable<DateTime>> _sinceVariables(DateTime? since) {
    return since == null ? [] : [Variable<DateTime>(since)];
  }

  /// Expression de rango para las queries tipadas (selectOnly). Devuelve
  /// la condicion `created_at >= since` o un vacio (sin filtro).
  Expression<bool> _sinceExpression(DateTime? since) {
    if (since == null) {
      return const Constant<bool>(true);
    }
    return _db.calculations.createdAt.isBiggerOrEqualValue(since);
  }

  /// Extrae filamentId numerico del label si tiene formato "id:N".
  /// En caso contrario, devuelve null (proforma rapida).
  ///
  /// Protocolo interno: el selector de catalogo construye el label como
  /// `id:<filamentId>`. Un material manual cuyo nombre empiece por "id:"
  /// seguido de digits colisionaria con este protocolo â€” caso aceptado,
  /// el efecto es solo un filamentId soft-FK incorrecto en la fila.
  int? _filamentIdFromLabel(String label) {
    if (label.startsWith('id:')) {
      final idStr = label.substring(3);
      return int.tryParse(idStr);
    }
    return null;
  }

  // === Partial save (T6) ===

  /// Inserta o actualiza la cotizacion parcial **activa** (upsert por id).
  ///
  /// **Identidad estable**: recibe [existingId] (el id del parcial que el
  /// calculator ya venia editando, ver `currentPartialIdProvider`). Si viene,
  /// se actualiza ESA fila; si no, se inserta una nueva.
  ///
  /// Antes se hacia upsert por **minuto** (`findLatestPartialForMinute`): cada
  /// vez que un autosave caia en un minuto distinto creaba una fila nueva, asi
  /// que una sola cotizacion terminaba como N borradores "Sin nombre". El id
  /// es la identidad real de la cotizacion, no la hora.
  ///
  /// [materials] son las filas de material del form. Se persisten para que
  /// "Reusar" sobre un parcial no pierda los materiales.
  Future<int> savePartial(
    CalculationsCompanion companion, {
    List<DraftMaterialInput> materials = const [],
    int? existingId,
  }) async {
    final int id;
    if (existingId != null) {
      // Verificar que la fila sigue existiendo (pudo borrarse desde otra
      // pantalla). Si ya no esta, cae a insert.
      final exists = await (_db.select(_db.calculations)
            ..where((t) => t.id.equals(existingId)))
          .getSingleOrNull();
      if (exists != null) {
        await updatePartial(existingId, companion);
        id = existingId;
      } else {
        id = await _db.into(_db.calculations).insert(companion);
      }
    } else {
      id = await _db.into(_db.calculations).insert(companion);
    }
    await _replaceMaterials(id, materials);
    return id;
  }

  /// Reemplaza todas las filas de material de una cotizacion.
  ///
  /// Borra las previas (update idempotente del parcial) e inserta las nuevas.
  Future<void> _replaceMaterials(
    int calculationId,
    List<DraftMaterialInput> materials,
  ) async {
    await (_db.delete(
      _db.calculationMaterials,
    )..where((t) => t.calculationId.equals(calculationId))).go();
    for (final m in materials) {
      await _db
          .into(_db.calculationMaterials)
          .insert(
            CalculationMaterialsCompanion.insert(
              calculationId: calculationId,
              filamentId: Value(_filamentIdFromLabel(m.label)),
              label: m.label,
              weightGrams: m.weightGrams,
              pricePerBobbinSnapshot: m.pricePerBobbin,
              gramsPerBobbinSnapshot: m.gramsPerBobbin,
              useOwnTime: Value(m.useOwnTime),
              materialHours: Value(m.materialHours),
              materialMinutes: Value(m.materialMinutes),
            ),
          );
    }
  }

  /// Actualiza un parcial existente con los campos del patch.
  ///
  /// Escribe **todo** el [patch] (no una lista a mano): enumerar columnas era
  /// fragil y omitia campos como `isAdvanced`, asi que el upsert del borrador
  /// nunca actualizaba el modo -> un Express cambiado a Advanced se guardaba
  /// (y se reabria) como Express, perdiendo los materiales.
  ///
  /// Solo se fuerza `isPartial = true` (la fila es un borrador) y se preservan
  /// los campos de identidad que el patch no debe tocar (`createdAt`,
  /// `isSold`, `isTemplate`).
  Future<void> updatePartial(int id, CalculationsCompanion patch) async {
    final companion = patch.copyWith(
      isPartial: const Value(true),
      // Identidad/estado de la fila: no los cambia el autoguardado.
      createdAt: const Value.absent(),
      isSold: const Value.absent(),
      isTemplate: const Value.absent(),
    );
    await (_db.update(
      _db.calculations,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  /// Elimina un parcial por id.
  Future<void> deletePartial(int id) async {
    await _db.transaction(() async {
      //materials primero (FK): si no, quedan filas huerfanas.
      await (_db.delete(
        _db.calculationMaterials,
      )..where((t) => t.calculationId.equals(id))).go();
      await (_db.delete(_db.calculations)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Busca el parcial mas reciente dentro de un minuto dado.
  Future<Calculation?> findLatestPartialForMinute(DateTime bucket) async {
    final start = bucket;
    final end = bucket.add(const Duration(minutes: 1));
    return (_db.select(_db.calculations)
          ..where((t) => t.isPartial.equals(true))
          ..where((t) => t.createdAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
