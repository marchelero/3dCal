// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// CRUD de impresoras.
///
/// Encapsula queries a la tabla `printers`. Single source of truth
/// para que `PrinterProfile` no se importe fuera de esta capa.
class PrinterRepository {
  const PrinterRepository(this._db);

  final AppDatabase _db;

  /// Lista todas las impresoras ordenadas por nombre.
  Future<List<PrinterProfile>> listAll() {
    return (_db.select(
      _db.printers,
    )..orderBy([(p) => OrderingTerm.asc(p.name)])).get();
  }

  /// Obtiene la impresora marcada como default. Devuelve null si no hay.
  Future<PrinterProfile?> getDefault() {
    return (_db.select(
      _db.printers,
    )..where((p) => p.isDefault.equals(true))).getSingleOrNull();
  }

  /// Inserta una nueva impresora.
  ///
  /// Si [asDefault] es true, desmarca cualquier otra default primero.
  Future<int> create({
    required String name,
    String? brand,
    required int averageWatts,
    bool asDefault = false,
    Decimal? purchaseCost,
    int? usefulLifeHours,
    int? currentHours,
  }) {
    return _db.transaction(() async {
      if (asDefault) {
        await _clearDefault();
      }
      return _db
          .into(_db.printers)
          .insert(
            PrintersCompanion.insert(
              name: name,
              brand: Value(brand),
              averageWatts: averageWatts,
              isDefault: Value(asDefault),
              purchaseCost: Value(purchaseCost?.toDouble()),
              usefulLifeHours: Value(usefulLifeHours),
              currentHours: Value(currentHours),
              createdAt: DateTime.now().toUtc(),
            ),
          );
    });
  }

  /// Actualiza una impresora existente.
  Future<bool> update({
    required int id,
    required String name,
    String? brand,
    required int averageWatts,
    bool? asDefault,
    Decimal? purchaseCost,
    int? usefulLifeHours,
    int? currentHours,
    bool clearAmortization = false,
  }) {
    return _db.transaction(() async {
      if (asDefault == true) {
        await _clearDefault();
      }
      final updated =
          await (_db.update(_db.printers)..where((p) => p.id.equals(id))).write(
            PrintersCompanion(
              name: Value(name),
              brand: Value(brand),
              averageWatts: Value(averageWatts),
              isDefault: asDefault == null
                  ? const Value.absent()
                  : Value(asDefault),
              purchaseCost: clearAmortization
                  ? const Value(null)
                  : (purchaseCost == null
                        ? const Value.absent()
                        : Value(purchaseCost.toDouble())),
              usefulLifeHours: clearAmortization
                  ? const Value(null)
                  : (usefulLifeHours == null
                        ? const Value.absent()
                        : Value(usefulLifeHours)),
              currentHours: currentHours == null
                  ? const Value.absent()
                  : Value(currentHours),
            ),
          );
      return updated > 0;
    });
  }

  /// Suma horas impresas a una impresora (para estadisticas).
  Future<void> addHours(int printerId, double hours) async {
    final printer =
        await (_db.select(
          _db.printers,
        )..where((p) => p.id.equals(printerId))).getSingleOrNull();
    if (printer == null) return;
    final current = printer.currentHours ?? 0;
    final added = hours.ceil(); // Redondeo hacia arriba
    await (_db.update(_db.printers)..where((p) => p.id.equals(printerId)))
        .write(PrintersCompanion(currentHours: Value(current + added)));
  }

  /// Elimina una impresora por id.
  Future<int> delete(int id) {
    return (_db.delete(_db.printers)..where((p) => p.id.equals(id))).go();
  }

  /// Marca todas las impresoras como no-default.
  Future<void> _clearDefault() async {
    await (_db.update(_db.printers)..where((p) => p.isDefault.equals(true)))
        .write(const PrintersCompanion(isDefault: Value(false)));
  }
}
