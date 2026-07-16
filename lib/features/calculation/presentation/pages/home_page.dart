// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../shared/widgets/money_row.dart';
import '../../../../shared/widgets/skeleton_widget.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../domain/dashboard_stats.dart';

/// Home page: landing del app con hero + quick actions + stats.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, color),
              const SizedBox(height: 28),
              _buildQuickActions(context, color),
              const SizedBox(height: 28),
              _buildStatsSection(context, ref, asyncStats, theme, color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.calculate_rounded,
                color: color.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '3dCal',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Cotizaciones 3D local-first',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        Text(
          'Rapido. Preciso. Sin internet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme color) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_rounded,
        label: 'Nueva cotizacion',
        subtitle: 'Calcula precio de impresion',
        color: color.primary,
        bgColor: color.primaryContainer,
        onTap: () => context.push('/calculator'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'Historial',
        subtitle: 'Cotizaciones guardadas',
        color: color.secondary,
        bgColor: color.secondaryContainer,
        onTap: () => context.go('/history'),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'Dashboard',
        subtitle: 'Estadisticas y graficos',
        color: color.tertiary,
        bgColor: color.tertiaryContainer,
        onTap: () => context.go('/dashboard'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acceso rapido',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        // Mobile: column, Tablet/Web: row
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            if (isWide) {
              return Row(
                children: [
                  for (final a in actions)
                    Expanded(child: Padding(
                      padding: EdgeInsets.only(
                        left: actions.indexOf(a) > 0 ? 8 : 0,
                        right: actions.indexOf(a) < actions.length - 1 ? 8 : 0,
                      ),
                      child: _QuickActionCard(action: a),
                    )),
                ],
              );
            }
            return Column(
              children: [
                for (final a in actions) ...[
                  if (actions.indexOf(a) > 0) const SizedBox(height: 10),
                  _QuickActionCard(action: a),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, WidgetRef ref,
      AsyncValue<DashboardStats> asyncStats, ThemeData theme, ColorScheme color) {
    return asyncStats.when(
      loading: () => const HomePageSkeleton(),
      error: (e, _) => Card(
        color: color.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: color.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error cargando stats',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (stats) {
        if (stats.countAll == 0) {
          return _buildEmptyStats(color, theme);
        }
        return _buildStatsContent(context, stats, theme, color);
      },
    );
  }

  Widget _buildEmptyStats(ColorScheme color, ThemeData theme) {
    return Card(
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long_outlined, color: color.onSurfaceVariant, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Todavia no hay cotizaciones',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(
      BuildContext context, DashboardStats stats, ThemeData theme, ColorScheme color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Resumen',
              style: theme.textTheme.titleMedium?.copyWith(color: color.onSurface),
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver todo'),
              onPressed: () => context.go('/dashboard'),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                MoneyRow(
                  label: 'Total cotizado',
                  value: formatBob(stats.totalQuoted),
                  valueColor: color.onSurface,
                ),
                const SizedBox(height: 8),
                MoneyRow(
                  label: 'Total vendido',
                  value: formatBob(stats.totalSold),
                  valueColor: color.tertiary,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
