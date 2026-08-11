// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/money_row.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../../calculation/domain/dashboard_stats.dart';
import '../../../calculation/domain/monthly_totals.dart';
import '../providers/dashboard_entitlement_provider.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/profit_bar_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final asyncStats = ref.watch(dashboardStatsProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final isPro = ref.watch(dashboardIsProProvider);
    return Scaffold(
      appBar: AppBar(title: Text(EsBO.dashboardTitle)),
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
                subtitle: EsBO.dashboardEmptySubtitle,
                ctaLabel: EsBO.dashboardEmptyCta,
                ctaIcon: Icons.home_rounded,
                onCta: () => context.go('/'),
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(dashboardStatsProvider.future),
              child: _DashboardBody(
                stats: stats,
                currency: currency,
                isPro: isPro,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.stats,
    required this.currency,
    required this.isPro,
  });

  final DashboardStats stats;
  final WorldCurrency currency;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: MaxWidthScrollView(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    MoneyRow(
                      label: EsBO.dashboardTotalQuoted,
                      value: formatCurrency(stats.totalQuoted, currency),
                      valueColor: color.onSurface,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MoneyRow(
                      label: EsBO.dashboardTotalSold,
                      value: formatCurrency(stats.totalSold, currency),
                      valueColor: color.tertiary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (isPro) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        icon: Icons.bar_chart_rounded,
                        title: EsBO.dashboardChartTitle,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ProfitBarChart(
                        totalQuoted: stats.totalQuoted,
                        totalSold: stats.totalSold,
                        currency: currency,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (stats.monthlyTotals.length >= 2)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          icon: Icons.trending_up_rounded,
                          title: EsBO.dashboardMonthlyTrend,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              _LegendDot(
                                color: color.primary,
                                label: EsBO.dashboardChartQuoted,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              _LegendDot(
                                color: color.tertiary,
                                label: EsBO.dashboardChartSold,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MonthlyTrendChart(data: stats.monthlyTotals),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              if (stats.topMaterials.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          icon: Icons.inventory_2_rounded,
                          title: EsBO.dashboardTopMaterials,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...stats.topMaterials.map((m) => _MaterialRow(m: m)),
                      ],
                    ),
                  ),
                ),
            ] else
              const _ProAnalyticsTeaser(),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ProAnalyticsTeaser extends StatelessWidget {
  const _ProAnalyticsTeaser();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.workspace_premium_rounded,
              title: EsBO.dashboardProTeaserTitle,
              accentColor: color.tertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              EsBO.dashboardProTeaserBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.push('/paywall'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(EsBO.dashboardGoProAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.m});
  final TopMaterial m;

  @override
  Widget build(BuildContext context) {
    final grams = m.totalWeightGrams;
    final gramsStr = grams >= 1000
        ? '${(grams / 1000).toStringAsFixed(1)}kg'
        : '${grams.toStringAsFixed(0)}g';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              m.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '${m.count}x · $gramsStr',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
