// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme_mode_provider.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
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
              padding: const EdgeInsets.all(24),
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
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AutoSaveField(
                  label: EsBO.settingsProfitBase,
                  helper: EsBO.settingsProfitBaseHelper,
                  initialValue: settings.profitBase.toString(),
                  allowDecimals: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final n = int.tryParse(v.trim());
                    if (n == null) return 'Numero invalido';
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
                const SizedBox(height: 16),
                _AutoSaveField(
                  label: EsBO.settingsKwhRate,
                  helper: EsBO.settingsKwhRateHelper,
                  initialValue: settings.kwhRate.toString(),
                  allowDecimals: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final n =
                        Decimal.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null) return 'Numero invalido';
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
        const SizedBox(height: 24),

        // === Apariencia ===
        SectionHeader(
          icon: Icons.palette_rounded,
          title: 'Apariencia',
          accentColor: color.secondary,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _ThemeModeSelector(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // === Catalogos ===
        SectionHeader(
          icon: Icons.inventory_2_rounded,
          title: EsBO.settingsCatalogos,
          accentColor: color.secondary,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.label_rounded,
                      color: color.onSecondaryContainer, size: 20),
                ),
                title: const Text(EsBO.settingsFilamentos),
                subtitle: const Text('Gestiona tus filamentos'),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.print_rounded,
                      color: color.onTertiaryContainer, size: 20),
                ),
                title: const Text(EsBO.settingsImpresoras),
                subtitle: const Text('Registra tus impresoras'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: color.onSurfaceVariant),
                onTap: () => context.push('/settings/printers'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // === Acerca de ===
        SectionHeader(
          icon: Icons.info_outline_rounded,
          title: EsBO.settingsAbout,
          accentColor: color.tertiary,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
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
                        const SizedBox(height: 2),
                        Text('v0.1.0',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: color.onSurfaceVariant),
                    const SizedBox(width: 8),
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
        const SizedBox(height: 32),
      ],
      ),
    );
  }

  void _showSavedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(EsBO.settingsSaved),
          duration: Duration(seconds: 1),
        ),
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
