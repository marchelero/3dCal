// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/page_header_card.dart';
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
                  onSave: (v) => unawaited(
                    _persistAndNotify(
                      context,
                      () => ref
                          .read(settingsNotifierProvider.notifier)
                          .updateProfitBase(v),
                    ),
                  ),
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
                  infoTooltip: EsBO.settingsKwhRateInfo(currency.symbol),
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
                    if (n < Decimal.zero) return EsBO.commonInvalidNumber;
                    return null;
                  },
                  onSave: (v) => unawaited(
                    _persistAndNotify(
                      context,
                      () => ref
                          .read(settingsNotifierProvider.notifier)
                          .updateKwhRate(v),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Piso de precio: Cargo mínimo (HIGH-03 fix) ──
                GroupLabel(
                  icon: Icons.low_priority_rounded,
                  title: EsBO.settingsMinimumCharge(currency.symbol),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatParamTile(
                  icon: Icons.anchor_rounded,
                  title: EsBO.settingsMinimumCharge(currency.symbol),
                  helper: EsBO.settingsMinimumChargeHelper,
                  accent: color.secondary,
                  initialValue: settings.minimumCharge == Decimal.zero
                      ? ''
                      : settings.minimumCharge.toString(),
                  allowDecimals: true,
                  sliderMin: 0,
                  sliderMax: 500,
                  sliderDivisions: 100,
                  showSlider: false,
                  suffix: currency.symbol,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return EsBO.commonRequired;
                    }
                    final n = Decimal.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null) return EsBO.commonInvalidNumber;
                    if (n < Decimal.zero || n > Decimal.fromInt(100000)) {
                      // MED-09: era settingsKwhRateRange ("Rango: 0.10-5.00"),
                      // el rango de la tarifa kWh — mensaje sin sentido aqui.
                      return EsBO.settingsMinimumChargeRange;
                    }
                    return null;
                  },
                  onSave: (v) => unawaited(
                    _persistAndNotify(
                      context,
                      () => ref
                          .read(settingsNotifierProvider.notifier)
                          .updateMinimumCharge(v),
                    ),
                  ),
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
                            icon: MdiIcons.printer3d,
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

/// Ejecuta [action] y muestra el snackbar de exito SOLO si la persistencia
/// termina bien; si falla, muestra un error generico en vez de mentir con
/// "Guardado" (y evita tragarse el error async). Reemplaza el patron
/// `unawaited(updateX(...)); _showSavedSnack()`.
Future<void> _persistAndNotify(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    if (!context.mounted) return;
    _showSavedSnack(context);
  } catch (e) {
    debugPrint('[PrintSettings] persist fallo: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.error(EsBO.commonErrorGeneric));
  }
}

// ─────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────

class _PrintSettingsHeader extends StatelessWidget {
  const _PrintSettingsHeader();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    // Cabecera estandar del shell: card generica (PageHeaderCard).
    // Sin flecha de retroceso (es un tab, no una pagina empujada), sin
    // version de app ni fila de privacidad.
    return PageHeaderCard(
      title: EsBO.settingsPrintConfigTitle,
      subtitle: EsBO.settingsPrintConfigSubtitle,
      icon: MdiIcons.printer3d,
      accentColor: color.primary,
    );
  }
}
