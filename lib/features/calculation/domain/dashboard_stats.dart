// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../presentation/notifiers/calculations_notifier.dart';
import 'monthly_totals.dart';

/// Stats agregadas del historial de cotizaciones.
///
/// **Uso**: dashboard / home page. Muestra totales y counts en un solo
/// read derivado. Se invalida cuando [calculationsNotifierProvider]
/// cambia (al guardar / eliminar / toggle sold).
class DashboardStats {
  const DashboardStats({
    required this.totalQuoted,
    required this.totalSold,
    required this.countAll,
    required this.countSold,
    this.monthlyTotals = const [],
    this.topMaterials = const [],
  });

  final Decimal totalQuoted;
  final Decimal totalSold;
  final int countAll;
  final int countSold;

  /// Totales mensuales para trend chart.
  final List<MonthlyTotal> monthlyTotals;

  /// Top 5 materiales mas usados.
  final List<TopMaterial> topMaterials;

  /// Porcentaje de cotizaciones vendidas (0.0 - 100.0).
  ///
  /// Si `countAll == 0` (aun no hay cotizaciones), retorna 0.
  double get conversionPct {
    if (countAll == 0) return 0;
    return (countSold / countAll) * 100;
  }
}

/// Provider derivado: queries agregadas + monthly + top materials.
/// Se re-corre cuando [calculationsNotifierProvider] emite nuevo state.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  ref.watch(calculationsNotifierProvider);
  final repo = ref.watch(calculationRepositoryProvider);
  return DashboardStats(
    totalQuoted: await repo.totalQuoted(),
    totalSold: await repo.totalSold(),
    countAll: await repo.countAll(),
    countSold: await repo.countSold(),
    monthlyTotals: await repo.monthlyTotals(),
    topMaterials: await repo.topMaterials(),
  );
});
