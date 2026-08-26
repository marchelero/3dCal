// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
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
    // Rango de fechas activo (7d/30d/90d/YTD/Todo). null = sin filtro.
    final since = ref.watch(dashboardRangeProvider);
    final asyncStats = ref.watch(dashboardStatsProvider(since));
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
            onRetry: () => ref.invalidate(dashboardStatsProvider(since)),
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
              onRefresh: () =>
                  ref.refresh(dashboardStatsProvider(since).future),
              child: _DashboardBody(
                stats: stats,
                currency: currency,
                isPro: isPro,
                since: since,
                onRangeSelected: (s) =>
                    ref.read(dashboardRangeProvider.notifier).state = s,
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
    required this.since,
    required this.onRangeSelected,
  });

  final DashboardStats stats;
  final WorldCurrency currency;
  final bool isPro;

  /// Rango activo (para marcar el ChoiceChip seleccionado).
  final DateTime? since;

  /// Callback cuando el user toca un chip de rango.
  final ValueChanged<DateTime?> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    // Insights solo se calculan para Pro (free no los ve).
    final insights = isPro ? _buildInsights(stats, currency) : const <String>[];

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
                    // BUG-023: null = "sin datos" → mostrar "—".
                    value: stats.conversionPct == null
                        ? '—'
                        : '${stats.conversionPct!.toStringAsFixed(0)}%',
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
              // Filtro de rango de fechas (solo Pro analytics).
              _RangeChips(selected: since, onSelected: onRangeSelected),
              const SizedBox(height: AppSpacing.md),

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

              // Rentabilidad: ganancia estimada + margen promedio.
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: EsBO.dashboardStatEstimatedProfit,
                      value: formatCurrency(stats.profitQuoted, currency),
                      icon: Icons.savings_rounded,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatTile(
                      label: EsBO.dashboardMarginLabel,
                      // marginPct null = "no aplica" (sin total cotizado).
                      value: stats.marginPct == null
                          ? '—'
                          : '${stats.marginPct!.toStringAsFixed(1)}%',
                      icon: Icons.percent_rounded,
                      color: color.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Ticket promedio (cotizado / vendido), derivado de totales.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      MoneyRow(
                        label: EsBO.dashboardAvgTicketQuoted,
                        value: stats.avgTicketQuoted == null
                            ? '—'
                            : formatCurrency(stats.avgTicketQuoted!, currency),
                        valueColor: color.onSurface,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MoneyRow(
                        label: EsBO.dashboardAvgTicketSold,
                        value: stats.avgTicketSold == null
                            ? '—'
                            : formatCurrency(stats.avgTicketSold!, currency),
                        valueColor: color.tertiary,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (stats.topClients.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          icon: Icons.group_rounded,
                          title: EsBO.dashboardTopClients,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...stats.topClients.asMap().entries.map(
                          (e) => _ClientRow(
                            rank: e.key + 1,
                            client: e.value,
                            currency: currency,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // Metricas operativas: horas de impresion + filamento.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        icon: Icons.timer_outlined,
                        title: EsBO.dashboardOperationalTitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MoneyRow(
                        label: EsBO.dashboardPrintHours,
                        value: '${stats.printHours.toStringAsFixed(1)}h',
                        valueColor: color.onSurface,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MoneyRow(
                        label: EsBO.dashboardFilament,
                        value: _formatGrams(stats.filamentGrams),
                        valueColor: color.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Insights automaticos (frases derivadas de datos existentes).
              // Solo se muestran para Pro (free no los ve).
              if (insights.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          icon: Icons.lightbulb_rounded,
                          title: EsBO.dashboardInsightsTitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...insights.map((i) => _InsightRow(text: i)),
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

/// Genera las frases de insights (max 5) a partir de datos ya cargados.
/// Guarda contra datos vacios: cada insight solo aparece si aplica.
List<String> _buildInsights(DashboardStats stats, WorldCurrency currency) {
  final insights = <String>[];
  final pct = stats.conversionPct;
  if (pct != null) {
    insights.add(
      EsBO.insightConversion(stats.countSold, stats.countAll, pct.round()),
    );
  }
  final avgSold = stats.avgTicketSold;
  if (avgSold != null) {
    insights.add(EsBO.insightAvgTicketSold(formatCurrency(avgSold, currency)));
  }
  final best = _bestMonth(stats.monthlyTotals);
  if (best != null) {
    insights.add(
      EsBO.insightBestMonth(
        _monthLabel(best.yearMonth),
        formatCurrency(best.quoted, currency),
      ),
    );
  }
  if (stats.topClients.isNotEmpty) {
    final top = stats.topClients.first;
    insights.add(
      EsBO.insightTopClient(top.label, formatCurrency(top.total, currency)),
    );
  }
  if (stats.filamentGrams > Decimal.zero) {
    insights.add(EsBO.insightFilament(_formatGrams(stats.filamentGrams)));
  }
  return insights;
}

MonthlyTotal? _bestMonth(List<MonthlyTotal> totals) {
  MonthlyTotal? best;
  for (final m in totals) {
    if (best == null || m.quoted > best.quoted) best = m;
  }
  return best;
}

/// "2026-07" → "Jul 2026" (reusa los meses cortos de l10n).
String _monthLabel(String yearMonth) {
  final parts = yearMonth.split('-');
  if (parts.length != 2) return yearMonth;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return yearMonth;
  return '${EsBO.chartShortMonths[month - 1]} ${parts[0]}';
}

/// Formatea gramos g→kg igual que [_MaterialRow]: >=1000 → "X,Xkg".
String _formatGrams(Decimal grams) {
  final g = grams.toDouble();
  if (g >= 1000) return '${(g / 1000).toStringAsFixed(1)}kg';
  return '${g.toStringAsFixed(0)}g';
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

/// Chips de rango de fechas del dashboard Pro.
///
/// Los cutoffs se calculan UNA vez en [initState] (no por build) para que
/// el valor guardado en [dashboardRangeProvider] sea exactamente el mismo
/// que el comparado en [selected] — el highlight del chip activo es estable.
/// Se usan fechas UTC porque `created_at` se persiste como UTC en la DB
/// (de lo contrario el cutoff local desplazaria los bordes del rango).
class _RangeChips extends StatefulWidget {
  const _RangeChips({required this.selected, required this.onSelected});

  final DateTime? selected;
  final ValueChanged<DateTime?> onSelected;

  @override
  State<_RangeChips> createState() => _RangeChipsState();
}

class _RangeChipsState extends State<_RangeChips> {
  late final List<_RangeOption> _options;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _options = [
      _RangeOption(
        EsBO.dashboardRange7d,
        now.subtract(const Duration(days: 7)),
      ),
      _RangeOption(
        EsBO.dashboardRange30d,
        now.subtract(const Duration(days: 30)),
      ),
      _RangeOption(
        EsBO.dashboardRange90d,
        now.subtract(const Duration(days: 90)),
      ),
      _RangeOption(EsBO.dashboardRangeYtd, DateTime.utc(now.year)),
      _RangeOption(EsBO.dashboardRangeAll, null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in _options)
          ChoiceChip(
            label: Text(
              o.label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            selected: _sameRange(widget.selected, o.since),
            onSelected: (_) => widget.onSelected(o.since),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class _RangeOption {
  const _RangeOption(this.label, this.since);
  final String label;
  final DateTime? since;
}

/// Compara dos cutoffs de rango. Ambos null = "Todo" (iguales). Para
/// fechas usa tolerancia de 1s (los cutoffs se recomputan por build).
bool _sameRange(DateTime? a, DateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.difference(b).inSeconds.abs() <= 1;
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
    // BUG-003 fix: totalWeightGrams es Decimal; convertir a double solo
    // para el formateo visual (helper compartido con insights).
    final gramsStr = _formatGrams(m.totalWeightGrams);
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

/// Fila del ranking de clientes: rank + nombre + total + N cotizaciones.
class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.rank,
    required this.client,
    required this.currency,
  });

  final int rank;
  final TopClient client;
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              client.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${client.count}x · ${formatCurrency(client.total, currency)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bullet de insight: lightbulb + frase.
class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
