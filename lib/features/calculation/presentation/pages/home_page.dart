// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/money_row.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_widget.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../domain/dashboard_stats.dart';

/// Home page: landing del app con hero + quick actions + stats.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final asyncStats = ref.watch(dashboardStatsProvider);
    final asyncSettings = ref.watch(settingsNotifierProvider);
    final settings = asyncSettings.valueOrNull;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: MaxWidthScrollView(
            maxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, color,
                    companyName: settings?.companyName,
                    companyLogoBase64: settings?.companyLogoBase64),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildQuickActions(context, color),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildStatsSection(
                          context, ref, asyncStats, theme, color),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme color, {
    String? companyName,
    String? companyLogoBase64,
  }) {
    final hasCompanyConfig = companyName != null &&
        companyName != '3dCalc' &&
        companyName.isNotEmpty;
    final hasLogo = companyLogoBase64 != null && companyLogoBase64.isNotEmpty;

    // Modo empresa: muestra logo + nombre empresa grande, app name pequeno
    if (hasCompanyConfig || hasLogo) {
      final displayName = hasCompanyConfig ? companyName : '3dCalc';
    return Semantics(
      header: true,
      label: '$displayName — Cotizaciones 3D',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primaryContainer,
              color.primaryContainer.withValues(alpha: 0.6),
              color.primaryContainer.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Row(
          children: [
            // Logo o icono default
            hasLogo
                ? _buildCompanyLogo(theme, companyLogoBase64)
                : _defaultHeroIcon(color),
            const SizedBox(width: AppSpacing.lg),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      // Badge 3dCalc
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          '3dCalc',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Cotizaciones 3D · Rapido · Preciso · Sin internet',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modo default: solo app name
  return Semantics(
    header: true,
    label: '3dCalc — Cotizaciones 3D',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primaryContainer,
            color.primaryContainer.withValues(alpha: 0.6),
            color.primaryContainer.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Icon area grande con decoracion
          Semantics(
            excludeSemantics: true,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.primary,
                    color.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                boxShadow: [
                  BoxShadow(
                    color: color.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/3dlogo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3dCalc',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cotizaciones 3D · Rapido · Preciso · Sin internet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _defaultHeroIcon(ColorScheme color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primary,
            color.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/3dlogo.png',
        width: 30,
        height: 30,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildCompanyLogo(ThemeData theme, String base64) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Image.memory(
        _base64ToBytes(base64),
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _defaultHeroIcon(theme.colorScheme),
      ),
    );
  }

  Uint8List _base64ToBytes(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme color) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_rounded,
        label: EsBO.homeActionNewCalc,
        subtitle: EsBO.homeActionNewCalcSub,
        color: color.primary,
        bgColor: color.primaryContainer,
        onTap: () => context.push('/calculator'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: EsBO.homeActionHistory,
        subtitle: EsBO.homeActionHistorySub,
        color: color.secondary,
        bgColor: color.secondaryContainer,
        onTap: () => context.go('/history'),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: EsBO.homeActionDashboard,
        subtitle: EsBO.homeActionDashboardSub,
        color: color.tertiary,
        bgColor: color.tertiaryContainer,
        onTap: () => context.go('/dashboard'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: EsBO.homeQuickAccess,
          child: Text(
            EsBO.homeQuickAccess,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color.onSurface,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Mobile/tablet portrait: column, Desktop/Web: row.
        // Threshold subido a 800 para que 3 cards en row tengan espacio
        // suficiente y el texto no rompa mid-word en viewports intermedios.
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Row(
                children: [
                  for (final a in actions)
                    Expanded(child: Padding(
                      padding: EdgeInsets.only(
                        left: actions.indexOf(a) > 0 ? AppSpacing.sm : 0,
                        right: actions.indexOf(a) < actions.length - 1 ? AppSpacing.sm : 0,
                      ),
                      child: _QuickActionCard(action: a),
                    )),
                ],
              );
            }
            return Column(
              children: [
                for (final a in actions) ...[
                  if (actions.indexOf(a) > 0) const SizedBox(height: AppSpacing.md),
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
    final currency = ref.watch(selectedCurrencyProvider);
    return asyncStats.when(
      loading: () => const HomePageSkeleton(),
      error: (e, _) => ErrorView(
        message: EsBO.homeErrorLoadStats,
        details: e.toString(),
        onRetry: () => ref.invalidate(dashboardStatsProvider),
      ),
      data: (stats) {
        if (stats.countAll == 0) {
          return _buildEmptyStats(color, theme);
        }
        return _buildStatsContent(context, stats, theme, color, currency);
      },
    );
  }

  Widget _buildEmptyStats(ColorScheme color, ThemeData theme) {
    return Card(
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.xxl),
              ),
              child: Icon(Icons.receipt_long_outlined, color: color.onSurfaceVariant, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              EsBO.homeEmptyQuotations,
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
      BuildContext context, DashboardStats stats, ThemeData theme, ColorScheme color, WorldCurrency currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              EsBO.homeSummary,
              style: theme.textTheme.titleMedium?.copyWith(color: color.onSurface),
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(EsBO.homeSeeAll),
              onPressed: () => context.go('/dashboard'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
    return Semantics(
      button: true,
      label: action.label,
      hint: action.subtitle,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.xxl),
          onTap: action.onTap,
          child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.bgColor,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      action.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
