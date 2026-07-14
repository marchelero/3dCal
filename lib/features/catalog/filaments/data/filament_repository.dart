// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// CRUD de filamentos.
///
/// **Importante**: precios y gramos se almacenan como `REAL` (double) en la
/// tabla. La conversion a `Decimal` se hace en la capa de presentation.
/// Para valores monetarios <= 1e15 con 2 decimales, double es exacto.
class FilamentRepository {
  const FilamentRepository(this._db);

  final AppDatabase _db;

  Future<List<Filament>> listAll() {
    return (_db.select(_db.filaments)
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .get();
  }

  Stream<List<Filament>> watchAll() {
    return (_db.select(_db.filaments)
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .watch();
  }

  Future<Filament?> getDefault() {
    return (_db.select(_db.filaments)..where((f) => f.isDefault.equals(true)))
        .getSingleOrNull();
  }

  Future<int> create({
    required String name,
    String? brand,
    required Decimal pricePerBobbin,
    required Decimal gramsPerBobbin,
    bool asDefault = false,
  }) async {
    if (asDefault) {
      await _clearDefault();
    }
    return _db.into(_db.filaments).insert(
          FilamentsCompanion.insert(
            name: name,
            brand: Value(brand),
            pricePerBobbin: pricePerBobbin.toDouble(),
            gramsPerBobbin: gramsPerBobbin.toDouble(),
            isDefault: Value(asDefault),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<bool> update({
    required int id,
    required String name,
    String? brand,
    required Decimal pricePerBobbin,
    required Decimal gramsPerBobbin,
    bool? asDefault,
  }) async {
    if (asDefault == true) {
      await _clearDefault();
    }
    final updated = await (_db.update(_db.filaments)..where((f) => f.id.equals(id)))
        .write(
      FilamentsCompanion(
        name: Value(name),
        brand: Value(brand),
        pricePerBobbin: Value(pricePerBobbin.toDouble()),
        gramsPerBobbin: Value(gramsPerBobbin.toDouble()),
        isDefault: asDefault == null
            ? const Value.absent()
            : Value(asDefault),
      ),
    );
    return updated > 0;
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.filaments)..where((f) => f.id.equals(id))).go();
  }

  Future<void> _clearDefault() async {
    await (_db.update(_db.filaments)..where((f) => f.isDefault.equals(true)))
        .write(const FilamentsCompanion(isDefault: Value(false)));
  }
}
