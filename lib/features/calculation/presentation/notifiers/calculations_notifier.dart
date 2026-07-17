// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers.dart';

/// Notifier reactivo para la lista de cotizaciones con search/filter.
///
/// **Estado**: `AsyncValue<List<Calculation>>`. Carga inicial via
/// [CalculationRepository.listAll], luego filtra en memoria por busqueda
/// ([searchQuery]) y estado de venta ([soldFilter]).
///
/// Filtros:
/// - [searchQuery]: busca en pieceName + clientName (LIKE %).
/// - [soldFilter]: null = todas, true = solo vendidas, false = solo pendientes.
class CalculationsNotifier extends AsyncNotifier<List<Calculation>> {
  /// Cache de todas las cotizaciones (sin filtrar).
  List<Calculation> _all = [];

  /// Query de busqueda activa (vacio = sin filtro).
  String _searchQuery = '';

  /// Filtro por estado de venta (null = todas).
  bool? _soldFilter;

  @override
  Future<List<Calculation>> build() async {
    final repo = ref.watch(calculationRepositoryProvider);
    _all = await repo.listAll();
    return _applyFilters();
  }

  /// Busca cotizaciones cuyo nombre de pieza o cliente contenga [query].
  /// Vacio restaura la lista completa.
  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    state = AsyncValue.data(_applyFilters());
  }

  /// Filtra por estado de venta: null = todas, true = vendidas, false = pendientes.
  void setSoldFilter(bool? filter) {
    _soldFilter = filter;
    state = AsyncValue.data(_applyFilters());
  }

  /// Recarga datos desde DB manteniendo filtros activos.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(calculationRepositoryProvider);
      _all = await repo.listAll();
      return _applyFilters();
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
    _all = await repo.listAll();
    state = AsyncValue.data(_applyFilters());
  }

  /// Aplica filtros activos (_searchQuery + _soldFilter) a _all.
  List<Calculation> _applyFilters() {
    var result = _all;

    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        final piece = c.pieceName ?? '';
        final client = c.clientName ?? '';
        return piece.toLowerCase().contains(_searchQuery) ||
            client.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filtro por estado de venta
    if (_soldFilter != null) {
      result = result.where((c) => c.isSold == _soldFilter).toList();
    }

    return result;
  }
}

/// Provider del [CalculationsNotifier].
final calculationsNotifierProvider =
    AsyncNotifierProvider<CalculationsNotifier, List<Calculation>>(
  CalculationsNotifier.new,
);
