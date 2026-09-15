// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/providers.dart';

/// Notifier reactivo para el catalogo de impresoras.
class PrintersNotifier extends AsyncNotifier<List<PrinterProfile>> {
  @override
  Future<List<PrinterProfile>> build() async {
    final repo = ref.watch(printerRepositoryProvider);
    return repo.listAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(printerRepositoryProvider);
      return repo.listAll();
    });
  }

  Future<void> create({
    required String name,
    String? brand,
    required int averageWatts,
    bool asDefault = false,
    Decimal? purchaseCost,
    int? usefulLifeHours,
    int? currentHours,
  }) async {
    final repo = ref.read(printerRepositoryProvider);
    await repo.create(
      name: name,
      brand: brand,
      averageWatts: averageWatts,
      asDefault: asDefault,
      purchaseCost: purchaseCost,
      usefulLifeHours: usefulLifeHours,
      currentHours: currentHours,
    );
    await _reload();
  }

  /// Nombre `updatePrinter` (no `update`) para no colisionar con
  /// `AsyncNotifier.update` del base class de Riverpod.
  Future<void> updatePrinter({
    required int id,
    required String name,
    String? brand,
    required int averageWatts,
    bool? asDefault,
    Decimal? purchaseCost,
    int? usefulLifeHours,
    int? currentHours,
    bool clearAmortization = false,
  }) async {
    final repo = ref.read(printerRepositoryProvider);
    await repo.update(
      id: id,
      name: name,
      brand: brand,
      averageWatts: averageWatts,
      asDefault: asDefault,
      purchaseCost: purchaseCost,
      usefulLifeHours: usefulLifeHours,
      currentHours: currentHours,
      clearAmortization: clearAmortization,
    );
    await _reload();
  }

  Future<void> delete(int id) async {
    final repo = ref.read(printerRepositoryProvider);
    await repo.delete(id);
    await _reload();
  }

  Future<void> setAsDefault(int id) async {
    final repo = ref.read(printerRepositoryProvider);
    final list = state.value;
    if (list == null) {
      await refresh();
      return;
    }
    // BUG-C fix: id inexistente en la lista cacheada → no-op (no crashear
    // con StateError). La UI solo muestra ids de la lista, pero un stale
    // state tras borrar/duplicar podria referenciar un id eliminado.
    PrinterProfile? current;
    for (final p in list) {
      if (p.id == id) {
        current = p;
        break;
      }
    }
    if (current == null) return;
    await repo.update(
      id: id,
      name: current.name,
      brand: current.brand,
      averageWatts: current.averageWatts,
      asDefault: true,
      purchaseCost: _toDecimal(current.purchaseCost),
      usefulLifeHours: current.usefulLifeHours,
      currentHours: current.currentHours,
    );
    await _reload();
  }

  /// Convierte el `double?` que drift expone para REAL al `Decimal?` del repo.
  static Decimal? _toDecimal(double? v) =>
      v == null ? null : Decimal.parse(v.toString());

  Future<void> _reload() async {
    final repo = ref.read(printerRepositoryProvider);
    final fresh = await repo.listAll();
    state = AsyncValue.data(fresh);
  }
}

final printersNotifierProvider =
    AsyncNotifierProvider<PrintersNotifier, List<PrinterProfile>>(
      PrintersNotifier.new,
    );
