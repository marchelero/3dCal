// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers.dart';

/// Notifier reactivo para la lista de cotizaciones.
///
/// **Estado**: `AsyncValue<List<Calculation>>`. Carga inicial via
/// [CalculationRepository.listAll] y se re-carga tras cada accion CRUD.
///
/// **Sin stream reactivo**: el unico mutador del historial es este notifier
/// (Sprint 5). Si en el futuro se necesita reactividad cross-feature, migrar
/// a `StreamNotifier` sobre `repo.watchAll()`.
class CalculationsNotifier extends AsyncNotifier<List<Calculation>> {
  @override
  Future<List<Calculation>> build() async {
    final repo = ref.watch(calculationRepositoryProvider);
    return repo.listAll();
  }

  /// Recarga la lista desde la DB.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(calculationRepositoryProvider);
      return repo.listAll();
    });
  }

  /// Cambia el flag `isSold` de una cotizacion.
  Future<void> toggleSold(int id, bool isSold) async {
    final repo = ref.read(calculationRepositoryProvider);
    await repo.toggleSold(id, isSold);
    await _reload();
  }

  /// Elimina una cotizacion por id.
  Future<void> delete(int id) async {
    final repo = ref.read(calculationRepositoryProvider);
    await repo.delete(id);
    await _reload();
  }

  Future<void> _reload() async {
    final repo = ref.read(calculationRepositoryProvider);
    final fresh = await repo.listAll();
    state = AsyncValue.data(fresh);
  }
}

/// Provider del [CalculationsNotifier].
final calculationsNotifierProvider =
    AsyncNotifierProvider<CalculationsNotifier, List<Calculation>>(
  CalculationsNotifier.new,
);
