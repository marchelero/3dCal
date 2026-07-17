// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme_mode_provider.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/avatar_icon.dart';
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text('Error cargando ajustes: $e'),
            ),
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

    return MaxWidthScrollView(
      maxWidth: 640,
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
                      label: EsBO.settingsKwhRate,
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

                // ── Empresa ──
                _SettingsSection(
                  icon: Icons.business_rounded,
                  title: EsBO.settingsCompany,
                  accentColor: color.tertiary,
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
                        title: const Text(EsBO.settingsFilamentos),
                        subtitle: const Text(EsBO.settingsManageFilaments),
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
                        title: const Text(EsBO.settingsImpresoras),
                        subtitle: const Text(EsBO.settingsManagePrinters),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: color.onSurfaceVariant),
                        onTap: () => context.push('/settings/printers'),
                      ),
                    ),
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
                          child: const Icon(Icons.calculate_rounded,
                              color: Colors.white, size: 26),
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
            child: const Icon(Icons.calculate_rounded,
                color: Colors.white, size: 34),
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
class _CompanyNameField extends StatefulWidget {
  const _CompanyNameField({
    required this.initialValue,
    required this.onSave,
  });

  final String initialValue;
  final ValueChanged<String> onSave;

  @override
  State<_CompanyNameField> createState() => _CompanyNameFieldState();
}

class _CompanyNameFieldState extends State<_CompanyNameField> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            helperText: EsBO.settingsCompanyNameHelper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          onTapOutside: (_) {
            final value = _ctrl.text;
            if (value.trim().isNotEmpty) _handleBlur(value);
          },
        ),
      ],
    );
  }
}

/// Logo picker: muestra logo actual + botones pick/remove.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
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
            // Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: Text(EsBO.settingsCompanyLogoPick),
                  onPressed: () => _pickLogo(context, ref),
                ),
                if (hasLogo)
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: color.error),
                    label: Text(
                      EsBO.settingsCompanyLogoRemove,
                      style: TextStyle(color: color.error),
                    ),
                    onPressed: () => _removeLogo(context, ref),
                  ),
              ],
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
