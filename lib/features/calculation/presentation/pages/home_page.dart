// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/storage/calculation_draft.dart';
import '../../../../core/storage/draft_storage_providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/pro_active_badge.dart';
import '../../../../shared/widgets/skeleton_widget.dart';
import '../../data/calculation_repository.dart' hide CalculationDraft;
import '../notifiers/calculations_notifier.dart';
import '../widgets/quote_guide_dialog.dart';

/// Home page: landing del app con hero + quick actions + stats.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final asyncSettings = ref.watch(settingsNotifierProvider);
    final asyncDraft = ref.watch(draftStatusProvider);
    final settings = asyncSettings.value;
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
                _buildHeader(
                  theme,
                  color,
                  companyName: settings?.companyName,
                  companyLogoBase64: settings?.companyLogoBase64,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      // Banner "Continuar cotización" (solo si hay draft).
                      if (asyncDraft.value != null &&
                          _hasDraftContent(asyncDraft.value!)) ...[
                        _buildDraftBanner(
                          context,
                          theme,
                          color,
                          asyncDraft.value!,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _buildQuickActions(context, color),
                      const SizedBox(height: AppSpacing.lg),
                      _buildCatalogsRow(context, theme, color),
                      const SizedBox(height: AppSpacing.lg),
                      _buildGuideEntry(context, theme, color),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildRecentQuotesSection(context, ref, theme, color),
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

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme color, {
    String? companyName,
    String? companyLogoBase64,
  }) {
    final hasCompanyConfig =
        companyName != null &&
        companyName != kDefaultCompanyName &&
        companyName.isNotEmpty;
    final hasLogo = companyLogoBase64 != null && companyLogoBase64.isNotEmpty;

    final Widget content;
    final String semanticsLabel;

    // Modo empresa: muestra logo + nombre empresa grande, app name pequeno
    if (hasCompanyConfig || hasLogo) {
      final displayName = hasCompanyConfig ? companyName : EsBO.appName;
      semanticsLabel = '$displayName — ${EsBO.homeHeroSemanticsSuffix}';
      content = Row(
        children: [
          // Logo o icono default
          if (hasLogo)
            _buildCompanyLogo(theme, companyLogoBase64)
          else
            _defaultHeroIcon(color),
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
                        EsBO.appName,
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
                        EsBO.homeHeroTagline,
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
      );
    } else {
      // Modo default: solo app name
      semanticsLabel = '${EsBO.appName} — ${EsBO.homeHeroSemanticsSuffix}';
      content = Row(
        children: [
          // Sello de plano con logo
          Semantics(excludeSemantics: true, child: _defaultHeroIcon(color)),
          const SizedBox(width: AppSpacing.lg),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EsBO.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  EsBO.homeHeroTagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Caratula de plano: hoja de papel con banda de cota superior
    return Semantics(
      header: true,
      label: semanticsLabel,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: color.outlineVariant, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: color.onSurface.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banda de cota superior del plano
            Container(
              height: 4,
              decoration: BoxDecoration(color: color.primary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenido hero (logo + nombre + tagline) a la izquierda.
                  Expanded(child: content),
                  const SizedBox(width: AppSpacing.sm),
                  // Badge PRO activo — extremo derecho de la cabecera.
                  const ProActiveBadge(),
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
        color: color.primary,
        borderRadius: BorderRadius.circular(AppRadii.sm),
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
        errorBuilder: (_, _, _) => _defaultHeroIcon(theme.colorScheme),
      ),
    );
  }

  Uint8List _base64ToBytes(String base64) {
    try {
      return base64Decode(base64);
    } catch (e) {
      // BUG-020 fix: loggear — el logo corrupto se muestra vacio.
      debugPrint('Logo base64 corrupto (home): $e');
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color.onSurface),
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
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: actions.indexOf(a) > 0 ? AppSpacing.sm : 0,
                          right: actions.indexOf(a) < actions.length - 1
                              ? AppSpacing.sm
                              : 0,
                        ),
                        child: _QuickActionCard(action: a),
                      ),
                    ),
                ],
              );
            }
            return Column(
              children: [
                for (final a in actions) ...[
                  if (actions.indexOf(a) > 0)
                    const SizedBox(height: AppSpacing.md),
                  _QuickActionCard(action: a),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// Seccion "Ultimas cotizaciones": las 3 mas recientes como springboard.
  ///
  /// Reemplaza a las stats duplicadas del Dashboard (dedup Home/Dashboard).
  /// El Dashboard queda como unico analytics; la Home solo apunta al
  /// historial y al detalle.
  Widget _buildRecentQuotesSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme color,
  ) {
    final asyncQuotes = ref.watch(calculationsNotifierProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    return asyncQuotes.when(
      loading: () => const HomePageSkeleton(),
      error: (e, _) => ErrorView(
        message: EsBO.homeErrorLoadStats,
        details: e.toString(),
        onRetry: () => ref.invalidate(calculationsNotifierProvider),
      ),
      data: (quotes) {
        if (quotes.isEmpty) {
          return _buildEmptyQuotes(context, theme, color);
        }
        // Mas reciente primero (defensivo: el repo ya ordena, pero aca no
        // dependemos de ese detalle de implementacion).
        final sorted = [...quotes]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recent = sorted.take(3).toList();
        return _buildRecentQuotesContent(
          context,
          recent,
          theme,
          color,
          currency,
        );
      },
    );
  }

  Widget _buildRecentQuotesContent(
    BuildContext context,
    List<CalculationListItem> recent,
    ThemeData theme,
    ColorScheme color,
    WorldCurrency currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              EsBO.homeRecentTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color.onSurface,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.history_rounded, size: 16),
              label: Text(EsBO.homeSeeAll),
              onPressed: () => context.go('/history'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < recent.length; i++) ...[
          _RecentQuoteCard(calc: recent[i]),
          if (i < recent.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  /// Banner "Continuar cotización": aparece cuando hay un draft persistido
  /// con contenido (la calculadora guarda en cada cambio, debounced).
  ///
  /// "Continuar" navega a `/calculator`, que restaura el draft al iniciar
  /// (comportamiento default de la pagina). El banner se pinta con el color
  /// del contenedor primario para diferenciarse de las acciones neutras.
  Widget _buildDraftBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme color,
    CalculationDraft draft,
  ) {
    final label = draft.label.trim();
    return Semantics(
      container: true,
      label:
          '${EsBO.homeDraftTitle}: ${label.isEmpty ? EsBO.homeDraftBody : label}',
      child: Card(
        color: color.primaryContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: color.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EsBO.homeDraftTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label.isNotEmpty ? label : EsBO.homeDraftBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // El theme fuerza minimumSize full-width en FilledButton:
              // lo sobreescribimos para que quepa en la fila del banner.
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
                onPressed: () => context.push('/calculator'),
                child: Text(EsBO.homeDraftContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Un draft "con contenido" merece banner: cualquier campo relevante
  /// completado. Evita el banner cuando el usuario abrio la calculadora,
  /// no escribio nada y salio (draft vacio persistido igualmente).
  static bool _hasDraftContent(CalculationDraft d) =>
      d.weight.isNotEmpty ||
      d.printHours.isNotEmpty ||
      d.printMinutes.isNotEmpty ||
      d.label.isNotEmpty ||
      d.filamentLabel.isNotEmpty ||
      d.extraLaborRate.isNotEmpty ||
      d.extraPostProcessRate.isNotEmpty ||
      d.extraFailureRate.isNotEmpty ||
      d.extraMarkupOnMaterials.isNotEmpty ||
      d.materials.isNotEmpty;

  /// Fila compacta "Mis catálogos": acceso directo a Filamentos e
  /// Impresoras (antes solo alcanzables via Settings). Son parte del flujo
  /// core (se eligen al cotizar), por eso merecen entrada propia en la Home.
  Widget _buildCatalogsRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: EsBO.homeCatalogsTitle,
          child: Text(
            EsBO.homeCatalogsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _CatalogCard(
                icon: Icons.inventory_2_rounded,
                label: EsBO.settingsFilamentos,
                onTap: () => context.push('/settings/filaments'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CatalogCard(
                icon: Icons.print_rounded,
                label: EsBO.settingsImpresoras,
                onTap: () => context.push('/settings/printers'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Entrada a la guia de cotizacion (paso a paso, modal estilo onboarding).
  ///
  /// Antes vivia en el menu del AppBar de la calculadora; ahora es parte de
  /// la Home como landing (dedup Home/Dashboard): ayuda visible sin robar
  /// protagonismo a las acciones principales.
  Widget _buildGuideEntry(
    BuildContext context,
    ThemeData theme,
    ColorScheme color,
  ) {
    return Semantics(
      button: true,
      label: EsBO.quoteGuideTitle,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => showQuoteGuideDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    EsBO.quoteGuideTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: color.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQuotes(
    BuildContext context,
    ThemeData theme,
    ColorScheme color,
  ) {
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
              child: Icon(
                Icons.receipt_long_outlined,
                color: color.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              EsBO.homeEmptyQuotations,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/calculator'),
              icon: const Icon(Icons.add_circle_rounded),
              label: Text(EsBO.homeEmptyCta),
            ),
          ],
        ),
      ),
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

/// Card compacta de acceso a un catalogo (Filamentos / Impresoras).
///
/// Mas liviana que las quick actions principales: icono + label, sin
/// subtitulo, para no competir con las 3 acciones primarias de la Home.
class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card compacta de una cotizacion reciente (Home).
///
/// Muestra nombre de pieza (o cliente, o fallback), cliente + fecha y el
/// total efectivo (unitario x cantidad) en mono tabular. Tap navega al
/// detalle `/history/:id`. El icono refleja el estado vendida/pendiente.
class _RecentQuoteCard extends ConsumerWidget {
  const _RecentQuoteCard({required this.calc});

  final CalculationListItem calc;

  String _title() {
    final piece = calc.pieceName;
    if (piece != null && piece.isNotEmpty) return piece;
    final client = calc.clientName;
    if (client != null && client.isNotEmpty) {
      return '${EsBO.calcSheetTitle} · $client';
    }
    return EsBO.calcDetailNoName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);
    final client = calc.clientName;

    return Semantics(
      container: true,
      label: '${_title()}, ${formatCurrency(calc.effectiveTotal, currency)}',
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => context.push('/history/${calc.id}', extra: calc),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: calc.isSold
                        ? color.tertiaryContainer
                        : color.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    calc.isSold
                        ? Icons.check_rounded
                        : Icons.receipt_long_rounded,
                    size: 18,
                    color: calc.isSold
                        ? color.onTertiaryContainer
                        : color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (client != null && client.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                client,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: color.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            DateFormat(
                              'dd MMM',
                            ).format(calc.createdAt.toLocal()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatCurrency(calc.effectiveTotal, currency),
                  style: AppTheme.num(
                    theme.textTheme.labelLarge ?? const TextStyle(),
                    color: color.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
