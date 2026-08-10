// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme_mode_provider.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/avatar_icon.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pro_badge.dart';
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

    return MaxWidthScrollView(
      maxWidth: 960,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          // ── HEADER HEROICO (full width) ──
          const _SettingsHeader(),
          const SizedBox(height: AppSpacing.xxl),

          // ── CONTENIDO CON PADDING LATERAL ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                // ── Parametros globales ──
                _SettingsSection(
                  icon: Icons.tune_rounded,
                  title: EsBO.settingsGlobalParams,
                  accentColor: color.primary,
                  children: [
                    _AutoSaveField(
                      label: EsBO.settingsProfitBase,
                      helper: EsBO.settingsProfitBaseHelper,
                      initialValue: settings.profitBase.toString(),
                      allowDecimals: false,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
                        final n = int.tryParse(v.trim());
                        if (n == null) return EsBO.commonInvalidNumber;
                        if (n < 0 || n > 1000) return 'Rango: 0-1000';
                        return null;
                      },
                      onSave: (v) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .updateProfitBase(v);
                        _showSavedSnack(context);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AutoSaveField(
                      label: EsBO.settingsKwhRate(currency.symbol),
                      helper: EsBO.settingsKwhRateHelper,
                      initialValue: settings.kwhRate.toString(),
                      allowDecimals: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
                        final n =
                            Decimal.tryParse(v.trim().replaceAll(',', '.'));
                        if (n == null) return EsBO.commonInvalidNumber;
                        if (n < Decimal.parse('0.10') ||
                            n > Decimal.parse('5.00')) {
                          return 'Rango: 0.10-5.00';
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
                  ],
                ),
                // ── Apariencia ──
                _SettingsSection(
                  icon: Icons.palette_rounded,
                  title: EsBO.settingsAppearance,
                  accentColor: color.secondary,
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
                const SizedBox(height: AppSpacing.xl),

                // ── Moneda ──
                _SettingsSection(
                  icon: Icons.attach_money_rounded,
                  title: EsBO.settingsCurrency,
                  accentColor: color.primary,
                  children: [
                    _CurrencyPicker(),
                    const SizedBox(height: AppSpacing.lg),
                    _LocalePicker(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Empresa ──
                _SettingsSection(
                  icon: Icons.business_rounded,
                  title: EsBO.settingsCompany,
                  accentColor: color.tertiary,
                  children: [
                    // T12 gate: badge "PRO" visible cuando el tier es
                    // free y el entitlement esta resuelto. ProBadge
                    // compartido (lib/shared/widgets/pro_badge.dart),
                    // color tertiary (mismo accent de la seccion Empresa).
                    if (locked)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ProBadge(accentColor: color.tertiary),
                      ),
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
                    _LogoPicker(
                      currentLogoBase64: settings.companyLogoBase64,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Catalogos ──
                _SettingsSection(
                  icon: Icons.inventory_2_rounded,
                  title: EsBO.settingsCatalogos,
                  accentColor: color.secondary,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AvatarIcon(
                          icon: Icons.label_rounded,
                          background: color.secondaryContainer,
                          foreground: color.onSecondaryContainer,
                        ),
                        title: Text(EsBO.settingsFilamentos),
                        subtitle: Text(EsBO.settingsManageFilaments),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: color.onSurfaceVariant),
                        onTap: () => context.push('/settings/filaments'),
                      ),
                    ),
                    const Divider(height: 1, indent: 52),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AvatarIcon(
                          icon: Icons.print_rounded,
                          background: color.tertiaryContainer,
                          foreground: color.onTertiaryContainer,
                        ),
                        title: Text(EsBO.settingsImpresoras),
                        subtitle: Text(EsBO.settingsManagePrinters),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: color.onSurfaceVariant),
                        onTap: () => context.push('/settings/printers'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Restaurar compras (T11) ──
                _SettingsSection(
                  icon: Icons.restore_rounded,
                  title: EsBO.settingsRestorePurchases,
                  accentColor: color.primary,
                  children: [
                    _RestoreButton(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Acerca de ──
                _SettingsSection(
                  icon: Icons.info_outline_rounded,
                  title: EsBO.settingsAbout,
                  accentColor: color.tertiary,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.primary,
                                color.primary.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                            boxShadow: [
                              BoxShadow(
                                color: color.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/3dlogo.png',
                              width: 26, height: 26, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(EsBO.appName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('v0.1.0',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 16, color: color.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.xl),

                // ── Legal (T22) ──
                _SettingsSection(
                  icon: Icons.gavel_rounded,
                  title: EsBO.settingsLegal.toUpperCase(),
                  accentColor: color.tertiary,
                  children: [
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(kPrivacyPolicyUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        EsBO.paywallPrivacyPolicy,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(kTermsOfServiceUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        EsBO.paywallTermsOfService,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
// HEADER — gradiente heroico full-width, sin AppBar
// ─────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
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
          // Icono app grande con sombra
          Container(
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
                  color: color.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset('assets/images/3dlogo.png',
                width: 34, height: 34, fit: BoxFit.contain),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3dCalc',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: color.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v0.1.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 14, color: color.onSurfaceVariant),
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
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.children,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final List<Widget> children;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARRA DE ACENTO IZQUIERDA (4dp) ──
          Container(
            width: 4,
            color: accentColor,
          ),
          // ── CONTENIDO ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: accentColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        title.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Divider(
                    height: 1,
                    color: color.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
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
        return ButtonSegment(
          value: m,
          label: Text(m.label),
          icon: Icon(icon),
        );
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
// AutoSaveField — campo numerico con auto-save
// ─────────────────────────────────────────────────

/// TextField con auto-save on blur.
class _AutoSaveField extends StatefulWidget {
  const _AutoSaveField({
    required this.label,
    required this.helper,
    required this.initialValue,
    required this.validator,
    required this.onSave,
    required this.allowDecimals,
  });

  final String label;
  final String helper;
  final String initialValue;
  final FormFieldValidator<String> validator;
  final ValueChanged<Decimal> onSave;
  final bool allowDecimals;

  @override
  State<_AutoSaveField> createState() => _AutoSaveFieldState();
}

class _AutoSaveFieldState extends State<_AutoSaveField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _AutoSaveField oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return NumericInputField(
      label: widget.label,
      controller: _ctrl,
      allowDecimals: widget.allowDecimals,
      helperText: widget.helper,
      validator: widget.validator,
      onBlur: _handleBlur,
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
  const _CompanyNameField({
    required this.initialValue,
    required this.onSave,
  });

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
        SnackBar(
          content: Text(EsBO.settingsBrandingLockedBody),
          action: SnackBarAction(
            label: EsBO.settingsGoProAction,
            onPressed: () => GoRouter.of(context).push('/paywall'),
          ),
          duration: const Duration(seconds: 4),
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
              border: const OutlineInputBorder(),
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
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      if (!context.mounted) return;
      ref.read(settingsNotifierProvider.notifier).updateCompanyLogo(base64);
      _showSavedSnack(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error('${EsBO.settingsCompanyLogoError}: $e'),
      );
    }
  }

  Future<void> _removeLogo(BuildContext context, WidgetRef ref) async {
    ref.read(settingsNotifierProvider.notifier).updateCompanyLogo(null);
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
        SnackBar(
          content: Text(EsBO.settingsBrandingLockedBody),
          action: SnackBarAction(
            label: EsBO.settingsGoProAction,
            onPressed: () => GoRouter.of(context).push('/paywall'),
          ),
          duration: const Duration(seconds: 4),
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
    final hasLogo = currentLogoBase64 != null &&
        currentLogoBase64!.isNotEmpty;

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
                border: Border.all(
                  color: color.outlineVariant,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLogo
                  ? Image.memory(
                      _base64ToBytes(currentLogoBase64!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
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
            Opacity(
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
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 18, color: color.error),
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
        ref.watch(settingsNotifierProvider).valueOrNull ?? Settings.defaults;
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
              border: OutlineInputBorder(),
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
      ref.read(settingsNotifierProvider.notifier).updateCurrency(selected.code);
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
                          selectedTileColor:
                              color.primaryContainer.withValues(alpha: 0.4),
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
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
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
        SegmentedButton<AppLocale>(
          segments: const [
            ButtonSegment(
              value: AppLocale.es,
              label: Text('ES'),
              icon: Icon(Icons.language, size: 18),
            ),
            ButtonSegment(
              value: AppLocale.en,
              label: Text('EN'),
              icon: Icon(Icons.language, size: 18),
            ),
          ],
          selected: {locale},
          onSelectionChanged: (s) {
            ref.read(localeProvider.notifier).setLocale(s.first);
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Restore purchases button (T11)
// ─────────────────────────────────────────────────

class _RestoreButton extends ConsumerStatefulWidget {
  const _RestoreButton();

  @override
  ConsumerState<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends ConsumerState<_RestoreButton> {
  bool _isRestoring = false;

  Future<void> _handleRestore() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);

    try {
      final result =
          await ref.read(entitlementNotifierProvider.notifier).restore();
      if (!context.mounted) return;
      switch (result) {
        case RestoreActive _:
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(AppSnackBar.success(EsBO.settingsRestoreSuccess));
        case RestoreEmpty _:
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(AppSnackBar.info(
              context,
              EsBO.settingsRestoreEmpty,
            ));
        case RestoreError _:
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(AppSnackBar.info(
              context,
              EsBO.settingsRestoreEmpty,
            ));
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
        label: Text(
          EsBO.settingsRestorePurchases,
        ),
        onPressed: _isRestoring ? null : _handleRestore,
      ),
    );
  }
}
