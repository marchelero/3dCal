// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../presentation/notifiers/calculations_notifier.dart';

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
  });

  final Decimal totalQuoted;
  final Decimal totalSold;
  final int countAll;
  final int countSold;
}

/// Provider derivado: 4 queries agregadas. Se re-corre cuando
/// [calculationsNotifierProvider] emite nuevo state.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  ref.watch(calculationsNotifierProvider);
  final repo = ref.watch(calculationRepositoryProvider);
  return DashboardStats(
    totalQuoted: await repo.totalQuoted(),
    totalSold: await repo.totalSold(),
    countAll: await repo.countAll(),
    countSold: await repo.countSold(),
  );
});
