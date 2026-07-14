// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/providers.dart';
import '../../data/filament_repository.dart';

/// Notifier reactivo para el catalogo de filamentos.
///
/// **Estado**: `AsyncValue<List<Filament>>`. Carga inicial via
/// [FilamentRepository.listAll] y se re-carga tras cada accion CRUD.
///
/// **Sin stream reactivo**: el unico mutador del catalogo es este notifier
/// (Sprint 4 no expone escritura concurrente). Si en el futuro se necesita
/// reactividad cross-feature, migrar a `StreamProvider` sobre `repo.watchAll()`.
class FilamentsNotifier extends AsyncNotifier<List<Filament>> {
  @override
  Future<List<Filament>> build() async {
    final repo = ref.watch(filamentRepositoryProvider);
    return repo.listAll();
  }

  /// Recarga la lista desde la DB. Usado tras mutaciones externas o al volver
  /// al foreground.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(filamentRepositoryProvider);
      return repo.listAll();
    });
  }

  /// Crea un filamento y recarga la lista.
  Future<void> create({
    required String name,
    String? brand,
    required Decimal pricePerBobbin,
    required Decimal gramsPerBobbin,
    bool asDefault = false,
  }) async {
    final repo = ref.read(filamentRepositoryProvider);
    await repo.create(
      name: name,
      brand: brand,
      pricePerBobbin: pricePerBobbin,
      gramsPerBobbin: gramsPerBobbin,
      asDefault: asDefault,
    );
    await _reload();
  }

  /// Actualiza un filamento. Si [asDefault] es `true`, desmarca los demas.
  ///
  /// Nombre `updateFilament` (no `update`) para no colisionar con
  /// `AsyncNotifier.update` del base class de Riverpod.
  Future<void> updateFilament({
    required int id,
    required String name,
    String? brand,
    required Decimal pricePerBobbin,
    required Decimal gramsPerBobbin,
    bool? asDefault,
  }) async {
    final repo = ref.read(filamentRepositoryProvider);
    await repo.update(
      id: id,
      name: name,
      brand: brand,
      pricePerBobbin: pricePerBobbin,
      gramsPerBobbin: gramsPerBobbin,
      asDefault: asDefault,
    );
    await _reload();
  }

  /// Elimina un filamento por id.
  Future<void> delete(int id) async {
    final repo = ref.read(filamentRepositoryProvider);
    await repo.delete(id);
    await _reload();
  }

  /// Marca el filamento [id] como default. Desmarca cualquier otro que lo sea.
  Future<void> setAsDefault(int id) async {
    final repo = ref.read(filamentRepositoryProvider);
    final list = state.valueOrNull;
    if (list == null) {
      await refresh();
      return;
    }
    final current = list.firstWhere(
      (f) => f.id == id,
      orElse: () => throw StateError('Filament $id not found'),
    );
    await repo.update(
      id: id,
      name: current.name,
      brand: current.brand,
      pricePerBobbin: Decimal.parse(current.pricePerBobbin.toString()),
      gramsPerBobbin: Decimal.parse(current.gramsPerBobbin.toString()),
      asDefault: true,
    );
    await _reload();
  }

  Future<void> _reload() async {
    final repo = ref.read(filamentRepositoryProvider);
    final fresh = await repo.listAll();
    state = AsyncValue.data(fresh);
  }
}

/// Provider del [FilamentsNotifier].
final filamentsNotifierProvider =
    AsyncNotifierProvider<FilamentsNotifier, List<Filament>>(
  FilamentsNotifier.new,
);
