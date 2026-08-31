// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/backup/backup_models.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme_mode_provider.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../calculation/domain/dashboard_stats.dart';
import '../../../calculation/presentation/notifiers/calculations_notifier.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../../entitlement/data/payment_service.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../../domain/settings.dart';
import '../notifiers/settings_notifier.dart';

/// Pagina `/settings` — DRAMATICAMENTE rediseñada.
///
/// Sin AppBar. Header gradiente heroico. Cards con barra de acento a la
/// izquierda. Espaciado generoso. Visual moderna y limpia.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

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
          data: (settings) => _SettingsBody(settings: settings),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Body — scroll vertical con header + secciones
// ─────────────────────────────────────────────────

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = WorldCurrency.fromCode(settings.currencyCode);

    // Patron de estado del gate visual (UX): "locked" solo cuando el
    // entitlement esta resuelto y el user es free. Durante el boot async
    // (loading) no se muestra badge ni dimming (evita falso "locked" en
    // cold start para un Pro real).
    final ent = ref.watch(entitlementNotifierProvider);
    final locked = !ent.isLoading && !ref.watch(isProProvider);
    final canRestore = ref.watch(paymentServiceProvider).isAvailable;

    return MaxWidthScrollView(
      maxWidth: 960,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          // ── CABECERA (bloque de titulo del plano) ──
          const _SettingsHeader(),
          const SizedBox(height: AppSpacing.xxl),

          // ── CONTENIDO CON PADDING LATERAL ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ref.watch(isProProvider)) ...[
                  _ProBadgePill(canRestore: canRestore),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // ── Empresa (arriba) ──
                _GroupLabel(
                  icon: Icons.business_rounded,
                  title: EsBO.settingsCompany.toUpperCase(),
                  trailing: locked ? ProBadge(accentColor: color.tertiary) : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  accentColor: color.tertiary,
                  divider: true,
                  children: [
                    _CompanyNameField(
                      initialValue: settings.companyName,
                      onSave: (value) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .updateCompanyName(value);
                        _showSavedSnack(context);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _LogoPicker(currentLogoBase64: settings.companyLogoBase64),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Costos y parametros (Ganancia + Electricidad) ──
                _GroupLabel(
                  icon: Icons.tune_rounded,
                  title: EsBO.settingsGlobalParams,
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatParamTile(
                  icon: Icons.percent_rounded,
                  title: EsBO.settingsProfitBase,
                  helper: EsBO.settingsProfitBaseHelper,
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
                _StatParamTile(
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
                    final n = Decimal.tryParse(
                      v.trim().replaceAll(',', '.'),
                    );
                    if (n == null) return EsBO.commonInvalidNumber;
                    if (n < Decimal.zero ||
                        n > Decimal.parse('5.00')) {
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

                // ── Catalogos ──
                const _GroupLabel(
                  icon: Icons.inventory_2_rounded,
                  titleKey: 'CATÁLOGOS',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  accentColor: color.secondary,
                  children: [
                    Builder(
                      builder: (ctx) {
                        final filaments = ref.watch(filamentsNotifierProvider).value ?? [];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _IconBadge(
                            icon: Icons.label_rounded,
                            background: color.secondaryContainer,
                            foreground: color.onSecondaryContainer,
                          ),
                          title: Text(EsBO.settingsFilamentos),
                          subtitle: Text('${filaments.length} filamentos'),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: color.onSurfaceVariant,
                          ),
                          onTap: () => context.push('/settings/filaments'),
                        );
                      },
                    ),
                    const _CardDivider(),
                    Builder(
                      builder: (ctx) {
                        final printers = ref.watch(printersNotifierProvider).value ?? [];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _IconBadge(
                            icon: Icons.print_rounded,
                            background: color.tertiaryContainer,
                            foreground: color.onTertiaryContainer,
                          ),
                          title: Text(EsBO.settingsImpresoras),
                          subtitle: Text('${printers.length} impresoras'),
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
                const SizedBox(height: AppSpacing.xxl),

                // ── Moneda e idioma ──
                const _GroupLabel(
                  icon: Icons.attach_money_rounded,
                  titleKey: 'MONEDA E IDIOMA',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  accentColor: color.primary,
                  divider: true,
                  children: [
                    _CurrencyPicker(),
                    const SizedBox(height: AppSpacing.lg),
                    _LocalePicker(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Apariencia ──
                const _GroupLabel(
                  icon: Icons.palette_rounded,
                  titleKey: 'APARIENCIA',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  accentColor: color.secondary,
                  divider: true,
                  children: [
                    Text(
                      EsBO.settingsTheme,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThemeModeSelector(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Datos (backup) ──
                const _GroupLabel(
                  icon: Icons.backup_rounded,
                  titleKey: 'TUS DATOS',
                ),
                const SizedBox(height: AppSpacing.sm),
                const _BackupSection(),
                const SizedBox(height: AppSpacing.xxl),

                if (canRestore) ...[
                  // ── Restaurar compras (T11) ──
                  const _GroupLabel(
                    icon: Icons.restore_rounded,
                    titleKey: 'CUENTA',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsCard(
                    accentColor: color.primary,
                    children: [_RestoreButton()],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // ── Acerca de + Legal ──
                const _GroupLabel(
                  icon: Icons.info_outline_rounded,
                  titleKey: 'ACERCA DE',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  accentColor: color.tertiary,
                  divider: true,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _IconBadge(
                        icon: Icons.privacy_tip_rounded,
                        background: color.primaryContainer,
                        foreground: color.onPrimaryContainer,
                      ),
                      title: Text(EsBO.paywallPrivacyPolicy),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: color.onSurfaceVariant,
                      ),
                      onTap: () => context.push('/legal/privacy'),
                    ),
                    const _CardDivider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _IconBadge(
                        icon: Icons.gavel_rounded,
                        background: color.secondaryContainer,
                        foreground: color.onSecondaryContainer,
                      ),
                      title: Text(EsBO.paywallTermsOfService),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: color.onSurfaceVariant,
                      ),
                      onTap: () => context.push('/legal/terms'),
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
// HEADER — bloque de titulo del plano
// ─────────────────────────────────────────────────

/// Cabecera de ajustes al estilo "bloque de titulo" del plano tecnico:
/// banda de cota superior, sello de engranaje y titulo AJUSTES en caps.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

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
            Container(height: 4, decoration: BoxDecoration(color: color.primary)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  // Sello de engranaje
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.primary, color.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: color.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: color.onPrimary,
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
                          'AJUSTES',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${EsBO.appName} · v$kAppVersion',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: color.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                EsBO.settingsPrivacy,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// SECTION — container con BARRA DE ACENTO IZQUIERDA
// ─────────────────────────────────────────────────

/// Seccion tipo card con una BARRA DE COLOR visible a la izquierda.
///
/// El `accentColor` define el color de la barra, el icono, y el tint del
/// icono. Cada seccion se ve distinta al instante.
class _ProBadgePill extends StatelessWidget {
  const _ProBadgePill({required this.canRestore});

  final bool canRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => _showProSheet(context, canRestore: canRestore),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: color.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, color: color.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  EsBO.settingsProActive,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: color.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: color.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre el modal con toda la info de los beneficios de Pro.
void _showProSheet(BuildContext context, {required bool canRestore}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ProSheetBody(canRestore: canRestore),
  );
}

/// Contenido del modal de Pro: titulo, estado activo y lista de beneficios.
class _ProSheetBody extends StatelessWidget {
  const _ProSheetBody({required this.canRestore});

  final bool canRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EsBO.settingsProTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                EsBO.settingsProUnlocked,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                EsBO.settingsProNoAdditionalPurchase,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                EsBO.settingsProFutureUpdates,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...EsBO.paywallFeatures.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: color.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          benefit,
                          style: TextStyle(color: color.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (canRestore)
                _RestoreButton(label: EsBO.settingsProRestorePurchase)
              else
                Text(
                  EsBO.paywallUnavailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de grupo que subdivide el menu de ajustes.
///
/// Titulo en MAYUSCULAS con tracking + icono en caja tintada + trailing
/// opcional (ej: badge PRO). Una regla corta de acento cierra el titulo,
/// como la linea pautada de un formulario.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.icon, this.title, this.titleKey, this.trailing});

  final IconData icon;
  final String? title;
  final String? titleKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = title ?? titleKey ?? '';

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 16, color: color.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: color.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Icono de badge reutilizable para filas (leading de ListTile).
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}

/// Divisor horizontal de una card.
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      color: color.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

/// Card contenedora de un grupo de ajustes.
///
/// Reemplaza el patron de barra lateral: una card limpia y redondeada con
/// contenido separado por hairlines ([_CardDivider]) si `divider` es true.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.accentColor,
    required this.children,
    this.divider = false,
  });

  final Color accentColor;
  final List<Widget> children;

  /// Aplica un borde superior de acento y separa los hijos con hairlines.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (divider)
            Container(height: 3, color: accentColor),
          // Material transparente para que ListTile/InkWell dibujen su
          // ink splash sobre la DecoratedBox de la card.
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// ThemeModeSelector — Claro / Oscuro / Sistema
// ─────────────────────────────────────────────────

/// Selector de tema Claro / Oscuro / Sistema.
class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return SegmentedButton<AppThemeMode>(
      segments: AppThemeMode.values.map((m) {
        IconData icon;
        switch (m) {
          case AppThemeMode.system:
            icon = Icons.settings_brightness_rounded;
          case AppThemeMode.light:
            icon = Icons.light_mode_rounded;
          case AppThemeMode.dark:
            icon = Icons.dark_mode_rounded;
        }
        return ButtonSegment(value: m, label: Text(m.label), icon: Icon(icon));
      }).toList(),
      selected: {current},
      onSelectionChanged: (selected) {
        ref.read(themeModeProvider.notifier).setMode(selected.first);
      },
      showSelectedIcon: false,
    );
  }
}

// ─────────────────────────────────────────────────
// StatParamTile — tarjeta de parametro estilo "stat"
// ─────────────────────────────────────────────────

/// Tarjeta editable presentada igual que los KPIs de la home ([StatTile]):
/// icono en caja tintada + titulo arriba y un valor numerico grande en mono
/// tabular debajo. Auto-save on blur.
///
/// Internamente usa [NumericInputField] para mantener el filtrado numerico,
/// la validacion y el comportamiento de [TextField] (requerido por tests).
class _StatParamTile extends StatefulWidget {
  const _StatParamTile({
    required this.icon,
    required this.title,
    required this.helper,
    required this.accent,
    required this.initialValue,
    required this.validator,
    required this.onSave,
    required this.allowDecimals,
    required this.sliderMin,
    required this.sliderMax,
    required this.sliderDivisions,
    this.suffix = '',
    this.sliderLeadingIcon,
    this.sliderTrailingIcon,
    this.showProfitPreview = false,
  });

  final IconData icon;
  final String title;
  final String helper;
  final Color accent;
  final String initialValue;
  final FormFieldValidator<String> validator;
  final ValueChanged<Decimal> onSave;
  final bool allowDecimals;
  final double sliderMin;
  final double sliderMax;
  final int sliderDivisions;
  final String suffix;
  final IconData? sliderLeadingIcon;
  final IconData? sliderTrailingIcon;
  final bool showProfitPreview;

  @override
  State<_StatParamTile> createState() => _StatParamTileState();
}

class _StatParamTileState extends State<_StatParamTile> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _StatParamTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBlur(String raw) {
    final err = widget.validator(raw);
    if (err != null) return;
    final cleaned = raw.trim().replaceAll(',', '.');
    final parsed = Decimal.tryParse(cleaned);
    if (parsed == null) return;
    widget.onSave(parsed);
  }

  double get _current {
    return double.tryParse(_ctrl.text.trim().replaceAll(',', '.')) ??
        widget.sliderMin;
  }

  void _onSliderChange(double v) {
    setState(() {
      _ctrl.text = widget.allowDecimals
          ? v.toStringAsFixed(2)
          : v.round().toString();
    });
  }

  void _onSliderEnd(double v) {
    if (!widget.allowDecimals) {
      widget.onSave(Decimal.fromInt(v.round()));
    } else {
      widget.onSave(Decimal.parse(v.toStringAsFixed(2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final raw = _current;
    final value = raw < widget.sliderMin
        ? widget.sliderMin
        : (raw > widget.sliderMax ? widget.sliderMax : raw);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barra de acento izquierda (formato del config inicial) ──
          Container(width: 4, color: widget.accent),
          // ── Contenido ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon chip + titulo
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Helper
                  Text(
                    widget.helper,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Slider con iconos de tendencia (igual al paso 2)
                  Row(
                    children: [
                      if (widget.sliderLeadingIcon != null) ...[
                        Icon(
                          widget.sliderLeadingIcon,
                          size: 16,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            activeTrackColor: widget.accent,
                            inactiveTrackColor: widget.accent.withValues(
                              alpha: 0.25,
                            ),
                            thumbColor: widget.accent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                            ),
                            overlayColor: widget.accent.withValues(alpha: 0.15),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 20,
                            ),
                          ),
                          child: Slider(
                            value: value,
                            min: widget.sliderMin,
                            max: widget.sliderMax,
                            divisions: widget.sliderDivisions,
                            label: widget.allowDecimals
                                ? value.toStringAsFixed(2)
                                : value.round().toString(),
                            onChanged: _onSliderChange,
                            onChangeEnd: _onSliderEnd,
                          ),
                        ),
                      ),
                      if (widget.sliderTrailingIcon != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          widget.sliderTrailingIcon,
                          size: 16,
                          color: color.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Valor + input (con preview si aplica)
                  if (widget.showProfitPreview)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: NumericInputField(
                            label: widget.title,
                            controller: _ctrl,
                            allowDecimals: widget.allowDecimals,
                            suffix: widget.suffix,
                            validator: widget.validator,
                            onBlur: _handleBlur,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Flexible: evita overflow cuando la fuente es
                        // grande y el preview no cabe junto al input.
                        Flexible(child: _GainPreview(value: _current, accent: widget.accent)),
                      ],
                    )
                  else
                    NumericInputField(
                      label: widget.title,
                      controller: _ctrl,
                      allowDecimals: widget.allowDecimals,
                      suffix: widget.suffix,
                      validator: widget.validator,
                      onBlur: _handleBlur,
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

/// Preview visual del porcentaje de ganancia (igual al paso 2 del config
/// inicial): muestra cuánto se multiplica sobre el costo.
class _GainPreview extends StatelessWidget {
  const _GainPreview({required this.value, required this.accent});

  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multiplier = 1 + (value / 100);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'x${multiplier.toStringAsFixed(1)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          Text(
            'sobre costo',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Company section: nombre + logo
// ──────────────────────────────────────────────

/// TextField para el nombre de la empresa con auto-save on blur.
///
/// **T12 gate**: si `isPro=false`, el field es `readOnly` y al tap
/// dispara un SnackBar con [EsBO.settingsBrandingLockedBody] +
/// accion [EsBO.settingsGoProAction] que navega a `/paywall`. El valor
/// visible sigue siendo el persistido (no se borra al upgradear a Pro).
class _CompanyNameField extends ConsumerStatefulWidget {
  const _CompanyNameField({required this.initialValue, required this.onSave});

  final String initialValue;
  final ValueChanged<String> onSave;

  @override
  ConsumerState<_CompanyNameField> createState() => _CompanyNameFieldState();
}

class _CompanyNameFieldState extends ConsumerState<_CompanyNameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _CompanyNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBlur(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == widget.initialValue) return;
    widget.onSave(trimmed);
  }

  /// SnackBar del gate. Llamado en el `onTap` cuando isPro=false.
  void _showLockedSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          EsBO.settingsBrandingLockedBody,
          actionLabel: EsBO.settingsGoProAction,
          onAction: () => GoRouter.of(context).push('/paywall'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final locked = !ent.isLoading && !isPro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.settingsCompanyName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Gate visual (UX): cuando el tier es free resuelto el field
        // esta atenuado (kLockedOpacity) para reforzar que es Pro. El
        // comportamiento (readOnly + SnackBar Go Pro) no cambia.
        Opacity(
          opacity: locked ? kLockedOpacity : 1.0,
          child: TextField(
            controller: _ctrl,
            readOnly: !isPro,
            decoration: InputDecoration(
              helperText: EsBO.settingsCompanyNameHelper,
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            onTap: isPro ? null : _showLockedSnack,
            onTapOutside: isPro
                ? (_) {
                    final value = _ctrl.text;
                    if (value.trim().isNotEmpty) _handleBlur(value);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// Logo picker: muestra logo actual + botones pick/remove.
///
/// **T12 gate**: si `isPro=false`, los botones de pick/remove disparan
/// un SnackBar con [EsBO.settingsBrandingLockedBody] + accion
/// [EsBO.settingsGoProAction] que navega a `/paywall`. El usuario
/// puede ver el logo (si lo tiene de un periodo Pro previo) pero no
/// modificarlo.
class _LogoPicker extends ConsumerWidget {
  const _LogoPicker({required this.currentLogoBase64});

  final String? currentLogoBase64;

  Future<void> _pickLogo(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      if (!context.mounted) return;
      unawaited(
        ref.read(settingsNotifierProvider.notifier).updateCompanyLogo(base64),
      );
      _showSavedSnack(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.settingsCompanyLogoError}: $e'));
    }
  }

  Future<void> _removeLogo(BuildContext context, WidgetRef ref) async {
    unawaited(
      ref.read(settingsNotifierProvider.notifier).updateCompanyLogo(null),
    );
    _showSavedSnack(context);
  }

  void _showSavedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.success(EsBO.settingsSaved));
  }

  /// SnackBar del gate. Llamado en los botones de pick/remove cuando
  /// isPro=false.
  void _showLockedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          EsBO.settingsBrandingLockedBody,
          actionLabel: EsBO.settingsGoProAction,
          onAction: () => GoRouter.of(context).push('/paywall'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final locked = !ent.isLoading && !isPro;
    final hasLogo = currentLogoBase64 != null && currentLogoBase64!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.settingsCompanyLogo,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // Preview
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: color.outlineVariant, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLogo
                  ? Image.memory(
                      _base64ToBytes(currentLogoBase64!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_rounded,
                        color: color.onSurfaceVariant,
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_rounded,
                      color: color.onSurfaceVariant,
                      size: 32,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Buttons. Gate visual (UX): cuando el tier es free resuelto
            // se atenuan (kLockedOpacity) para reforzar que son Pro. El
            // comportamiento (SnackBar Go Pro en tap) no cambia.
            // Expanded: evita overflow de la columna de botones cuando la
            // fuente del dispositivo es grande (los labels envuelven).
            Expanded(
              child: Opacity(
                opacity: locked ? kLockedOpacity : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.image_rounded, size: 18),
                      label: Text(EsBO.settingsCompanyLogoPick),
                      onPressed: isPro
                          ? () => _pickLogo(context, ref)
                          : () => _showLockedSnack(context),
                    ),
                    if (hasLogo)
                      TextButton.icon(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: color.error,
                        ),
                        label: Text(
                          EsBO.settingsCompanyLogoRemove,
                          style: TextStyle(color: color.error),
                        ),
                        onPressed: isPro
                            ? () => _removeLogo(context, ref)
                            : () => _showLockedSnack(context),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Uint8List _base64ToBytes(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }
}

// ─────────────────────────────────────────────────
// CurrencyPicker — searchable dialog
// ─────────────────────────────────────────────────

/// Selector de moneda con busqueda integrada.
class _CurrencyPicker extends ConsumerWidget {
  const _CurrencyPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings =
        ref.watch(settingsNotifierProvider).value ?? Settings.defaults;
    final current = WorldCurrency.fromCode(settings.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.settingsCurrency,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.settingsCurrencyHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => _showCurrencySearch(context, ref, current),
          child: InputDecorator(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              suffixIcon: Icon(Icons.search),
            ),
            child: Text(
              '${current.code} — ${current.name} (${current.symbol})',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCurrencySearch(
    BuildContext context,
    WidgetRef ref,
    WorldCurrency current,
  ) async {
    final selected = await showDialog<WorldCurrency>(
      context: context,
      useSafeArea: false,
      builder: (_) => _CurrencySearchDialog(initial: current),
    );
    if (selected != null && context.mounted) {
      unawaited(
        ref
            .read(settingsNotifierProvider.notifier)
            .updateCurrency(selected.code),
      );
      _showSavedSnack(context);
    }
  }
}

/// Dialog de busqueda de monedas.
class _CurrencySearchDialog extends StatefulWidget {
  const _CurrencySearchDialog({required this.initial});
  final WorldCurrency initial;

  @override
  State<_CurrencySearchDialog> createState() => _CurrencySearchDialogState();
}

class _CurrencySearchDialogState extends State<_CurrencySearchDialog> {
  late final TextEditingController _ctrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    // Filtrar
    final all = WorldCurrency.all;
    final filtered = _query.isEmpty
        ? all
        : all.where((c) {
            final q = _query.toLowerCase();
            return c.code.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q);
          }).toList();

    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            // Header with search
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: EsBO.settingsCurrencySearchHint,
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _ctrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        EsBO.settingsCurrencyNoResults(_query),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected = c.code == widget.initial.code;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: color.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? color.primary
                                : color.onSurfaceVariant,
                          ),
                          title: Text(
                            '${c.code} — ${c.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${EsBO.settingsCurrencySymbolPrefix}${c.symbol}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// LOCALE PICKER
// ─────────────────────────────────────────────────

class _LocalePicker extends ConsumerWidget {
  const _LocalePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final strings = ref.watch(localeStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.localeLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppLocale>(
              value: locale,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: AppLocale.es,
                  child: Text(strings.localeEs),
                ),
                DropdownMenuItem(
                  value: AppLocale.en,
                  child: Text(strings.localeEn),
                ),
                DropdownMenuItem(
                  value: AppLocale.ptBr,
                  child: Text(strings.localePtBr),
                ),
                DropdownMenuItem(
                  value: AppLocale.de,
                  child: Text(strings.localeDe),
                ),
                DropdownMenuItem(
                  value: AppLocale.fr,
                  child: Text(strings.localeFr),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// BACKUP SECTION — export/import database
// ─────────────────────────────────────────────────

class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _isExporting = false;
  bool _isImporting = false;

  /// Gate Pro: los backups (exportar/importar) son funcion paga.
  void _showLockedSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          EsBO.settingsBackupLockedBody,
          actionLabel: EsBO.settingsGoProAction,
          onAction: () => GoRouter.of(context).push('/paywall'),
        ),
      );
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    if (!ent.isLoading && !isPro) {
      _showLockedSnack();
      return;
    }
    setState(() => _isExporting = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final service = BackupService(db);
      await service.export();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.success(EsBO.settingsBackupExportSuccess));
    } catch (e) {
      debugPrint('Backup export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupExportError));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImport() async {
    if (_isImporting) return;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    if (!ent.isLoading && !isPro) {
      _showLockedSnack();
      return;
    }

    // First, preview what's in the backup
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [kBackupExtension, 'json'],
    );
    if (result == null || result.files.isEmpty) return;

    // En web `path` es null: leer desde `bytes`. En movil/desktop por path.
    final file = result.files.single;

    // Limite de tamaño ANTES de cargar a memoria.
    if (file.size > kBackupMaxFileBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupImportSizeError));
      return;
    }

    final String content;
    try {
      final bytes = file.bytes;
      if (bytes != null) {
        if (bytes.lengthInBytes > kBackupMaxFileBytes) {
          throw const FormatException('archivo demasiado grande');
        }
        content = utf8.decode(bytes);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw const FormatException('sin contenido');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupImportInvalidFile));
      return;
    }

    // Read and validate (JSON malformado o campos invalidos -> mensaje
    // amigable, nunca una excepcion cruda ni un crash).
    final BackupData backup;
    try {
      final parsed = jsonDecode(content);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('estructura inesperada');
      }
      backup = BackupData.fromJson(parsed);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupImportInvalidFile));
      return;
    }

    final error = backup.validate();
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(error));
      return;
    }

    // Rechazar backups de un schema FUTURO.
    final db = ref.read(appDatabaseProvider);
    if (backup.schemaVersion > db.schemaVersion) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar.error(EsBO.settingsBackupImportFutureVersion),
        );
      return;
    }

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      // Usar el context DEL DIALOGO (root navigator), no el de la pagina
      // (nested navigator del StatefulShellRoute) — si no, el pop intenta
      // sacar la ultima pagina del branch y go_router lanza assertion.
      builder: (dialogContext) => AlertDialog(
        title: Text(EsBO.settingsBackupImportConfirmTitle),
        content: Text(
          EsBO.settingsBackupImportConfirmBody(backup.summary.describe()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(EsBO.settingsBackupImportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(EsBO.settingsBackupImportConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Perform import (reusa `db` obtenido arriba para validar el schema).
    setState(() => _isImporting = true);
    try {
      final service = BackupService(db);
      final importResult = await service.restoreFromJson(content);
      if (!mounted) return;
      if (importResult == null) {
        // Should not happen here (validation already done above)
        return;
      }
      if (importResult.isEmpty) {
        final summary = backup.summary;
        // Invalida todos los providers de datos: son fetch-once (listAll o
        // cómputos únicos), así que sin esto el historial/dashboard/catálogo
        // seguirían mostrando el estado viejo hasta el próximo refresh.
        ref
          ..invalidate(calculationsNotifierProvider)
          // dashboardStatsProvider es family: invalidar la instancia default
          // (null = todo) cubre la home/dashboard en rango "Todo". Ademas
          // reseteamos el rango activo para que un filtro previo del
          // dashboard no tape los datos re-importados.
          ..invalidate(dashboardRangeProvider)
          ..invalidate(dashboardStatsProvider(null))
          ..invalidate(filamentsNotifierProvider)
          ..invalidate(printersNotifierProvider)
          ..invalidate(settingsNotifierProvider);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            AppSnackBar.success(
              EsBO.settingsBackupImportSuccess(
                summary.calculationCount,
                summary.filamentCount,
                summary.printerCount,
              ),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.error(importResult));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final locked = !ent.isLoading && !isPro;

    return _SettingsCard(
      accentColor: color.primary,
      children: [
        Text(
          EsBO.settingsBackupHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Opacity(
          opacity: locked ? kLockedOpacity : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isExporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color.onPrimary,
                      ),
                    )
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(EsBO.settingsBackupExport),
              onPressed: _isExporting ? null : _handleExport,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: locked ? kLockedOpacity : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _isImporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color.primary,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(EsBO.settingsBackupImport),
              onPressed: _isImporting ? null : _handleImport,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Restore purchases button (T11)
// ─────────────────────────────────────────────────

class _RestoreButton extends ConsumerStatefulWidget {
  const _RestoreButton({this.label});

  final String? label;

  @override
  ConsumerState<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends ConsumerState<_RestoreButton> {
  bool _isRestoring = false;

  Future<void> _handleRestore() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);

    try {
      final result = await ref
          .read(entitlementNotifierProvider.notifier)
          .restore();
      if (!mounted) return;
      if (result is RestoreActive) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.success(EsBO.settingsRestoreSuccess));
      } else if (result is RestoreEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.info(context, EsBO.settingsRestoreEmpty));
      } else if (result is RestoreError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.error(EsBO.settingsRestoreError));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: _isRestoring
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.restore_rounded, size: 18),
        label: Text(widget.label ?? EsBO.settingsProRestorePurchase),
        onPressed: _isRestoring ? null : _handleRestore,
      ),
    );
  }
}
