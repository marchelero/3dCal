// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../domain/settings.dart';
import '../notifiers/settings_notifier.dart';
import '../widgets/discount_tiers_section.dart';
import '../widgets/settings_widgets.dart';

/// Sub-pagina `/config/print-settings` — Configuracion de impresion.
///
/// Agrupa todos los ajustes relacionados con la impresion 3D:
/// costos (profit base), energia (kWh), descuentos por cantidad y
/// catalogos (filamentos/impresoras).
class PrintSettingsPage extends ConsumerWidget {
  const PrintSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final asyncSettings = ref.watch(settingsNotifierProvider);
    return Scaffold(
      body: SafeArea(
        child: asyncSettings.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: EsBO.settingsErrorLoad,
            details: e.toString(),
            onRetry: () => ref.invalidate(settingsNotifierProvider),
          ),
          data: (settings) => _PrintSettingsBody(settings: settings),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Body — scroll vertical con header + secciones
// ─────────────────────────────────────────────────

class _PrintSettingsBody extends ConsumerWidget {
  const _PrintSettingsBody({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = WorldCurrency.fromCode(settings.currencyCode);

    return MaxWidthScrollView(
      maxWidth: 960,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          // ── CABECERA ──
          const _PrintSettingsHeader(),
          const SizedBox(height: AppSpacing.xxl),

          // ── CONTENIDO CON PADDING LATERAL ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Costos de impresión (Ganancia base) ──
                GroupLabel(
                  icon: Icons.tune_rounded,
                  title: EsBO.settingsGroupPrintingCosts,
                ),
                const SizedBox(height: AppSpacing.sm),
                StatParamTile(
                  icon: Icons.percent_rounded,
                  title: EsBO.settingsProfitBase,
                  helper: EsBO.settingsProfitBaseHelper,
                  infoTooltip: EsBO.settingsProfitBaseInfo,
                  accent: color.primary,
                  initialValue: settings.profitBase == Decimal.zero
                      ? ''
                      : settings.profitBase.toString(),
                  allowDecimals: false,
                  sliderMin: 0,
                  sliderMax: 500,
                  sliderDivisions: 50,
                  suffix: '%',
                  sliderLeadingIcon: Icons.trending_down_rounded,
                  sliderTrailingIcon: Icons.trending_up_rounded,
                  showProfitPreview: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return EsBO.commonRequired;
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null) return EsBO.commonInvalidNumber;
                    if (n < 0 || n > 1000) {
                      return EsBO.settingsProfitBaseRange;
                    }
                    return null;
                  },
                  onSave: (v) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .updateProfitBase(v);
                    _showSavedSnack(context);
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Energía (kWh) ──
                GroupLabel(
                  icon: Icons.bolt_rounded,
                  title: EsBO.settingsGroupEnergy,
                ),
                const SizedBox(height: AppSpacing.sm),
                StatParamTile(
                  icon: Icons.bolt_rounded,
                  title: EsBO.settingsKwhRate(currency.symbol),
                  helper: EsBO.settingsKwhRateHelper,
                  accent: color.tertiary,
                  initialValue: settings.kwhRate == Decimal.zero
                      ? ''
                      : settings.kwhRate.toString(),
                  allowDecimals: true,
                  sliderMin: 0,
                  sliderMax: 5,
                  sliderDivisions: 50,
                  suffix: '${currency.symbol}/kWh',
                  sliderLeadingIcon: Icons.eco_rounded,
                  sliderTrailingIcon: Icons.bolt,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return EsBO.commonRequired;
                    }
                    final n = Decimal.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null) return EsBO.commonInvalidNumber;
                    if (n < Decimal.zero || n > Decimal.parse('5.00')) {
                      return EsBO.settingsKwhRateRange;
                    }
                    return null;
                  },
                  onSave: (v) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .updateKwhRate(v);
                    _showSavedSnack(context);
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Descuentos por cantidad ──
                GroupLabel(
                  icon: Icons.inventory_2_rounded,
                  title: EsBO.settingsGroupDiscountTiers,
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  accentColor: color.tertiary,
                  children: const [DiscountTiersSection()],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Catalogos ──
                GroupLabel(
                  icon: Icons.inventory_2_rounded,
                  title: EsBO.settingsGroupCatalogs,
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  accentColor: color.secondary,
                  children: [
                    Builder(
                      builder: (ctx) {
                        final filaments =
                            ref.watch(filamentsNotifierProvider).value ?? [];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: IconBadge(
                            icon: Icons.label_rounded,
                            background: color.secondaryContainer,
                            foreground: color.onSecondaryContainer,
                          ),
                          title: Text(EsBO.settingsFilamentos),
                          subtitle: Text(
                            EsBO.settingsFilamentsCount(filaments.length),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: color.onSurfaceVariant,
                          ),
                          onTap: () => context.push('/settings/filaments'),
                        );
                      },
                    ),
                    const CardDivider(),
                    Builder(
                      builder: (ctx) {
                        final printers =
                            ref.watch(printersNotifierProvider).value ?? [];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: IconBadge(
                            icon: Icons.print_rounded,
                            background: color.tertiaryContainer,
                            foreground: color.onTertiaryContainer,
                          ),
                          title: Text(EsBO.settingsImpresoras),
                          subtitle: Text(
                            EsBO.settingsPrintersCount(printers.length),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: color.onSurfaceVariant,
                          ),
                          onTap: () => context.push('/settings/printers'),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl * 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar unificado.
void _showSavedSnack(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(AppSnackBar.success(EsBO.settingsSaved));
}

// ─────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────

class _PrintSettingsHeader extends StatelessWidget {
  const _PrintSettingsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: color.outlineVariant, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: color.onSurface.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banda de cota superior
            Container(
              height: 4,
              decoration: BoxDecoration(color: color.tertiary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  // Flecha de retorno
                  IconButton(
                    tooltip: EsBO.configBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Sello de impresora
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.tertiary,
                          color.tertiary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: color.tertiary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.print_rounded,
                      color: color.onTertiary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Titulo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          EsBO.settingsPrintConfigTitle.toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          EsBO.settingsPrintConfigSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
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
}
