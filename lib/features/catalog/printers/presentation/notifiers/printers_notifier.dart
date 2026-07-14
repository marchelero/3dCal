// ignore_for_file: public_member_api_docs
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
    required int averageWatts,
    bool asDefault = false,
  }) async {
    final repo = ref.read(printerRepositoryProvider);
    await repo.create(
      name: name,
      averageWatts: averageWatts,
      asDefault: asDefault,
    );
    await _reload();
  }

  /// Nombre `updatePrinter` (no `update`) para no colisionar con
  /// `AsyncNotifier.update` del base class de Riverpod.
  Future<void> updatePrinter({
    required int id,
    required String name,
    required int averageWatts,
    bool? asDefault,
  }) async {
    final repo = ref.read(printerRepositoryProvider);
    await repo.update(
      id: id,
      name: name,
      averageWatts: averageWatts,
      asDefault: asDefault,
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
    final list = state.valueOrNull;
    if (list == null) {
      await refresh();
      return;
    }
    final current = list.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Printer $id not found'),
    );
    await repo.update(
      id: id,
      name: current.name,
      averageWatts: current.averageWatts,
      asDefault: true,
    );
    await _reload();
  }

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
