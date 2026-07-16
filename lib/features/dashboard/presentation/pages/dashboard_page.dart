// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../../calculation/domain/dashboard_stats.dart';
import '../widgets/profit_bar_chart.dart';

/// Pagina `/dashboard` con stats agregadas + bar chart.
class DashboardPage extends ConsumerWidget {
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
            message: 'Error al cargar el dashboard',
            details: e.toString(),
            onRetry: () => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) {
            if (stats.countAll == 0) {
              return EmptyView(
                icon: Icons.bar_chart_rounded,
                message: 'Aun no cotizaste nada',
                subtitle: 'Crea tu primera cotizacion desde el inicio.',
                ctaLabel: 'Ir a Home',
                ctaIcon: Icons.home_rounded,
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
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Cotizaciones',
                  value: '${stats.countAll}',
                  icon: Icons.receipt_long_rounded,
                  color: color.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'Vendidas',
                  value: '${stats.countSold}',
                  icon: Icons.check_circle_rounded,
                  color: color.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'Conversion',
                  value: '${stats.conversionPct.toStringAsFixed(0)}%',
                  icon: Icons.trending_up_rounded,
                  color: color.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Monetary totals
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TotalRow(
                    label: 'Total cotizado',
                    value: _formatMoney(stats.totalQuoted.toDouble()),
                    color: color.onSurface,
                  ),
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'Total vendido',
                    value: _formatMoney(stats.totalSold.toDouble()),
                    color: color.tertiary,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Chart section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.bar_chart_rounded,
                    title: 'Cotizado vs Ganado',
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return 'Bs. ${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return 'Bs. ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Bs. ${value.toStringAsFixed(2)}';
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
