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
import '../../../../shared/widgets/section_header.dart';
import '../../domain/settings.dart';
import '../notifiers/settings_notifier.dart';

/// Pagina `/settings` con secciones visuales y mejor organizacion.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(EsBO.settingsTitle),
      ),
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

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return MaxWidthScrollView(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shrinkWrap: true,
        children: [
        // === Parametros globales ===
        SectionHeader(
          icon: Icons.tune_rounded,
          title: EsBO.settingsGlobalParams,
          accentColor: color.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
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
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // === Apariencia ===
        SectionHeader(
          icon: Icons.palette_rounded,
          title: EsBO.settingsAppearance,
          accentColor: color.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // === Empresa ===
        SectionHeader(
          icon: Icons.business_rounded,
          title: EsBO.settingsCompany,
          accentColor: color.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _CompanySection(settings: settings),
        const SizedBox(height: AppSpacing.xxl),

        // === Catalogos ===
        SectionHeader(
          icon: Icons.inventory_2_rounded,
          title: EsBO.settingsCatalogos,
          accentColor: color.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(Icons.label_rounded,
                      color: color.onSecondaryContainer, size: 20),
                ),
                title: const Text(EsBO.settingsFilamentos),
                subtitle: const Text(EsBO.settingsManageFilaments),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: color.onSurfaceVariant),
                onTap: () => context.push('/settings/filaments'),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(Icons.print_rounded,
                      color: color.onTertiaryContainer, size: 20),
                ),
                title: const Text(EsBO.settingsImpresoras),
                subtitle: const Text(EsBO.settingsManagePrinters),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: color.onSurfaceVariant),
                onTap: () => context.push('/settings/printers'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // === Acerca de ===
        SectionHeader(
          icon: Icons.info_outline_rounded,
          title: EsBO.settingsAbout,
          accentColor: color.tertiary,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                      child: Icon(Icons.calculate_rounded,
                          color: color.onPrimaryContainer, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(EsBO.appName,
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xxs),
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
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
      ),
    );
  }

  void _showSavedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.success(EsBO.settingsSaved),
      );
  }
}


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

/// TextField con auto-save on blur.
///
/// Reemplaza la version anterior que mantenia FocusNode + FormField + filter
/// manualmente. Ahora delega todo eso a [NumericInputField] y solo conserva
/// el ciclo de vida del controller + la logica de save (validate -> parse
/// Decimal -> onSave).
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
    // Re-correr el validador: si falla, no guardar.
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
// Company section
// ──────────────────────────────────────────────

/// Seccion "Empresa" en settings: nombre de la empresa + logo.
class _CompanySection extends ConsumerWidget {
  const _CompanySection({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Company name field ──
            _CompanyNameField(
              initialValue: settings.companyName,
              onSave: (value) {
                ref.read(settingsNotifierProvider.notifier).updateCompanyName(value);
                _showSavedSnack(context);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Logo picker ──
            _LogoPicker(
              currentLogoBase64: settings.companyLogoBase64,
            ),
          ],
        ),
      ),
    );
  }

  static void _showSavedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.success(EsBO.settingsSaved));
  }
}

/// TextField para el nombre de la empresa con auto-save on blur.
/// Recibe [onSave] callback desde el padre ConsumerWidget.
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
