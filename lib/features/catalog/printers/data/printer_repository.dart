// ignore_for_file: public_member_api_docs
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
    return (_db.select(_db.printers)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Observa la lista de impresoras (Stream para Riverpod .watch()).
  Stream<List<PrinterProfile>> watchAll() {
    return (_db.select(_db.printers)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Obtiene la impresora marcada como default. Devuelve null si no hay.
  Future<PrinterProfile?> getDefault() {
    return (_db.select(_db.printers)..where((p) => p.isDefault.equals(true)))
        .getSingleOrNull();
  }

  /// Inserta una nueva impresora.
  ///
  /// Si [asDefault] es true, desmarca cualquier otra default primero.
  Future<int> create({
    required String name,
    required int averageWatts,
    bool asDefault = false,
  }) async {
    if (asDefault) {
      await _clearDefault();
    }
    return _db.into(_db.printers).insert(
          PrintersCompanion.insert(
            name: name,
            averageWatts: averageWatts,
            isDefault: Value(asDefault),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Actualiza una impresora existente.
  Future<bool> update({
    required int id,
    required String name,
    required int averageWatts,
    bool? asDefault,
  }) async {
    if (asDefault == true) {
      await _clearDefault();
    }
    final updated = await (_db.update(_db.printers)..where((p) => p.id.equals(id)))
        .write(
      PrintersCompanion(
        name: Value(name),
        averageWatts: Value(averageWatts),
        isDefault: asDefault == null
            ? const Value.absent()
            : Value(asDefault),
      ),
    );
    return updated > 0;
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
