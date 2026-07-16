// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/money_row.dart';
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
        title: const Text(EsBO.dashboardTitle),
      ),
      body: SafeArea(
        child: asyncStats.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: EsBO.dashboardErrorLoad,
            details: e.toString(),
            onRetry: () => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) {
            if (stats.countAll == 0) {
              return EmptyView(
                icon: Icons.bar_chart_rounded,
                message: EsBO.dashboardEmpty,
                subtitle: 'Crea tu primera cotizacion desde el inicio.',
                ctaLabel: EsBO.dashboardEmptyCta,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: MaxWidthScrollView(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats row
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: EsBO.dashboardStatQuotations,
                  value: '${stats.countAll}',
                  icon: Icons.receipt_long_rounded,
                  color: color.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: EsBO.dashboardStatSold,
                  value: '${stats.countSold}',
                  icon: Icons.check_circle_rounded,
                  color: color.tertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: EsBO.dashboardStatConversion,
                  value: '${stats.conversionPct.toStringAsFixed(0)}%',
                  icon: Icons.trending_up_rounded,
                  color: color.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Monetary totals
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MoneyRow(
                    label: EsBO.dashboardTotalQuoted,
                    value: formatBob(stats.totalQuoted),
                    valueColor: color.onSurface,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MoneyRow(
                    label: EsBO.dashboardTotalSold,
                    value: formatBob(stats.totalSold),
                    valueColor: color.tertiary,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Chart section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.bar_chart_rounded,
                    title: EsBO.dashboardChartTitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfitBarChart(
                    totalQuoted: stats.totalQuoted,
                    totalSold: stats.totalSold,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        ),
      ),
    );
  }
}






