// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../../data/calculation_repository.dart';
import 'history_sort.dart';

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

/// Alias de compatibilidad: delega al getter [CalculationListItem.effectiveTotal].
///
/// TODO(deprecacion): migrar call-sites restantes al getter. El alias se
/// mantiene para no romper imports que usan la funcion top-level.
Decimal effectiveTotal(CalculationListItem c) => c.effectiveTotal;

/// Notifier reactivo para la lista de cotizaciones con search/filter/sort.
///
/// **Estado**: `AsyncValue<List<CalculationListItem>>`. Carga inicial via
/// [CalculationRepository.listItems] (sin BLOBs, F3), luego filtra en
/// memoria por el pipeline de [applyFilters].
///
/// Filtros (PRD 2026-09-11, orden de aplicacion):
/// 1. [clientFilter]: match EXACTO case-insensitive sobre clientName.
/// 2. [dateRange]: rango sobre `createdAt.toLocal()`, bornes inclusivos.
/// 3. [soldFilter]: null = todas, true = solo vendidas, false = solo pendientes.
/// 4. [searchQuery]: busca en pieceName + clientName + labels de materiales
///    (cache [materialLabels], contains case-insensitive).
/// 5. [sort]: reordena el resultado (NO es un filtro).
class CalculationsNotifier extends AsyncNotifier<List<CalculationListItem>> {
  /// Cache de todas las cotizaciones (sin filtrar).
  List<CalculationListItem> _all = [];

  /// Query de busqueda activa (vacio = sin filtro).
  String _searchQuery = '';

  /// Filtro por estado de venta (null = todas).
  bool? _soldFilter;

  /// Filtro por rango de fechas (null = todas).
  DateTimeRange? _dateRange;

  /// Orden activo (default: mas recientes primero).
  HistorySort _sort = HistorySort.dateNewest;

  /// Filtro por cliente (null = todos).
  String? _clientFilter;

  /// Cache `calcId -> labels de materiales` para la busqueda por filamento.
  Map<int, String> _materialLabels = {};

  /// Query de busqueda activa (lectura para la UI).
  String get searchQuery => _searchQuery;

  /// Filtro de venta activo (lectura para la UI).
  bool? get soldFilter => _soldFilter;

  /// Rango de fechas activo (lectura para la UI).
  DateTimeRange? get dateRange => _dateRange;

  /// Orden activo (lectura para la UI).
  HistorySort get sort => _sort;

  /// Cliente filtrado activo (lectura para la UI).
  String? get clientFilter => _clientFilter;

  /// Labels de materiales por cotizacion (cache de busqueda, lectura UI).
  Map<int, String> get materialLabels => _materialLabels;

  /// Historial COMPLETO sin filtrar (criterio #10 del PRD: el CSV exporta
  /// todo independiente del set filtrado en pantalla).
  List<CalculationListItem> get all => _all;

  @override
  Future<List<CalculationListItem>> build() async {
    final repo = ref.watch(calculationRepositoryProvider);
    _materialLabels = await repo.materialLabelsByCalcId();
    _all = await repo.listItems();
    return _applyFilters();
  }

  /// Busca cotizaciones cuyo nombre de pieza, cliente o material contenga
  /// [query]. Vacio restaura la lista completa.
  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    state = AsyncValue.data(_applyFilters());
  }

  /// Filtra por estado de venta: null = todas, true = vendidas, false = pendientes.
  void setSoldFilter(bool? filter) {
    _soldFilter = filter;
    state = AsyncValue.data(_applyFilters());
  }

  /// Filtra por rango de fechas [range] (null restaura todas las fechas).
  /// El rango se compara contra `createdAt.toLocal()` con bornes inclusivos.
  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    state = AsyncValue.data(_applyFilters());
  }

  /// Cambia el orden de la lista (ver [HistorySort]).
  void setSort(HistorySort sort) {
    _sort = sort;
    state = AsyncValue.data(_applyFilters());
  }

  /// Filtra por cliente (match exacto case-insensitive). [null] restaura.
  void setClientFilter(String? client) {
    _clientFilter = client;
    state = AsyncValue.data(_applyFilters());
  }

  /// Recarga datos desde DB manteniendo filtros activos.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(calculationRepositoryProvider);
      _materialLabels = await repo.materialLabelsByCalcId();
      _all = await repo.listItems();
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
        throw HistoryCapReachedException(
          cap: kFreeHistoryCap,
          currentCount: await repo.countAll(),
        );
      }
      newId = limitedId;
    }
    await _reload();
    return newId;
  }

  Future<void> _reload() async {
    final repo = ref.read(calculationRepositoryProvider);
    _materialLabels = await repo.materialLabelsByCalcId();
    _all = await repo.listItems();
    state = AsyncValue.data(_applyFilters());
  }

  /// Aplica el pipeline del historial (PRD 2026-09-11) a [_all] en orden:
  /// cliente → fecha → venta → busqueda → orden.
  ///
  /// Siempre trabaja sobre una COPIA: (a) Riverpod no notifica si el nuevo
  /// estado tiene la misma instancia de lista, y (b) sort() in-place sobre
  /// [_all] corromperia el cache.
  List<CalculationListItem> _applyFilters() {
    var result = List<CalculationListItem>.of(_all);

    // 1. Cliente: match exacto case-insensitive.
    final clientFilter = _clientFilter;
    if (clientFilter != null) {
      final target = clientFilter.toLowerCase();
      result = result
          .where((c) => (c.clientName ?? '').toLowerCase() == target)
          .toList();
    }

    // 2. Rango de fechas: sobre createdAt.toLocal(), bornes inclusivos
    //    (el preset del dia lleva el end a fin-de-dia en la UI).
    final range = _dateRange;
    if (range != null) {
      result = result.where((c) {
        final local = c.createdAt.toLocal();
        return !local.isBefore(range.start) && !local.isAfter(range.end);
      }).toList();
    }

    // 3. Estado de venta.
    final soldFilter = _soldFilter;
    if (soldFilter != null) {
      result = result.where((c) => c.isSold == soldFilter).toList();
    }

    // 4. Busqueda: pieza O cliente O labels de materiales (contains).
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        final piece = c.pieceName ?? '';
        final client = c.clientName ?? '';
        final labels = _materialLabels[c.id] ?? '';
        return piece.toLowerCase().contains(_searchQuery) ||
            client.toLowerCase().contains(_searchQuery) ||
            labels.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // 5. Orden (NO es filtro: no afecta contador ni resumen).
    result.sort(_compareHistory);

    return result;
  }

  /// Compara dos items segun el orden activo.
  int _compareHistory(CalculationListItem a, CalculationListItem b) {
    switch (_sort) {
      case HistorySort.dateOldest:
        return a.createdAt.compareTo(b.createdAt);
      case HistorySort.priceHigh:
        return b.effectiveTotal.compareTo(a.effectiveTotal);
      case HistorySort.priceLow:
        return a.effectiveTotal.compareTo(b.effectiveTotal);
      case HistorySort.clientAz:
        final left = (a.clientName ?? '').toLowerCase();
        final right = (b.clientName ?? '').toLowerCase();
        return left.compareTo(right);
      case HistorySort.dateNewest:
        return b.createdAt.compareTo(a.createdAt);
    }
  }
}

/// Provider del [CalculationsNotifier].
final calculationsNotifierProvider =
    AsyncNotifierProvider<CalculationsNotifier, List<CalculationListItem>>(
      CalculationsNotifier.new,
    );
