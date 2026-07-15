// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../calculation/domain/dashboard_stats.dart';
import '../widgets/profit_bar_chart.dart';

/// Pagina `/dashboard` con stats agregadas + bar chart (PRD FR-8).
///
/// **Sprint 5** anadio un `_DashboardCard` resumido en Home como teaser.
/// **Sprint 6** completa el flow con la pagina dedicada que muestra el
/// bar chart 2 barras (Cotizado vs Ganado) + 3 stat cards y empty state.
/// **Sprint 7** migra a go_router con `/dashboard` URL.
class DashboardPage extends ConsumerWidget {
  /// Crea la pagina del dashboard.
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SafeArea(
        child: asyncStats.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: 'Error al cargar el dashboard: $e',
            onRetry: () => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) {
            if (stats.countAll == 0) {
              return EmptyView(
                icon: Icons.bar_chart_outlined,
                message: 'Aun no cotizaste nada.\n'
                    'Empieza en Home creando tu primera cotizacion.',
                ctaLabel: 'Ir a Home',
                ctaIcon: Icons.home,
                onCta: () => context.go('/'),
              );
            }
            return _DashboardBody(stats: stats);
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsRow(stats: stats),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cotizado vs Ganado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ProfitBarChart(
                    totalQuoted: stats.totalQuoted,
                    totalSold: stats.totalSold,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Cotizaciones',
            value: '${stats.countAll}',
            icon: Icons.list_alt,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Vendidas',
            value: '${stats.countSold}',
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Conversion',
            value: '${stats.conversionPct.toStringAsFixed(0)}%',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
