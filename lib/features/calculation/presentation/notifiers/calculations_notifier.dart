// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';

/// Thrown when a Free user tries to create a quote beyond the history cap.
class HistoryCapReachedException implements Exception {
  const HistoryCapReachedException({
    required this.cap,
    required this.currentCount,
  });

  final int cap;
  final int currentCount;

  @override
  String toString() =>
      'HistoryCapReachedException: $currentCount/$cap cotizaciones. '
      'Upgrade a Pro para historial ilimitado.';
}

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

  /// Duplica una cotizacion (copia snapshots + materiales con id nuevo,
  /// createdAt = ahora e isSold = false). Devuelve el id de la copia.
  ///
  /// [pieceNameSuffix] se agrega al nombre de la pieza original para
  /// distinguir la copia (ej: ' (copia)').
  Future<int> duplicate(int id, {String? pieceNameSuffix}) async {
    final repo = ref.read(calculationRepositoryProvider);
    final int newId;
    final isPro = await resolveIsPro(ref);
    if (isPro) {
      newId = await repo.duplicate(id, pieceNameSuffix: pieceNameSuffix);
    } else {
      final limitedId = await repo.duplicateIfWithinLimit(
        id,
        limit: kFreeHistoryCap,
        pieceNameSuffix: pieceNameSuffix,
      );
      if (limitedId == null) {
        throw const HistoryCapReachedException(
          cap: kFreeHistoryCap,
          currentCount: kFreeHistoryCap,
        );
      }
      newId = limitedId;
    }
    await _reload();
    return newId;
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
