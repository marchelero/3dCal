// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/es_bo.dart';
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // === Parametros globales ===
        _SectionHeader(
          icon: Icons.tune_rounded,
          title: EsBO.settingsGlobalParams,
          color: color.primary,
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

        // === Catalogos ===
        _SectionHeader(
          icon: Icons.inventory_2_rounded,
          title: EsBO.settingsCatalogos,
          color: color.secondary,
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
        _SectionHeader(
          icon: Icons.info_outline_rounded,
          title: EsBO.settingsAbout,
          color: color.tertiary,
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

/// Header de seccion con icono.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// TextFormField con auto-save on blur.
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
  late final FocusNode _focus;
  final _formKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _focus = FocusNode();
    _focus.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _AutoSaveField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_focus.hasFocus) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.removeListener(_handleFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focus.hasFocus) return;
    final field = _formKey.currentState;
    if (field == null) return;
    if (!field.validate()) return;
    final raw = _ctrl.text.trim().replaceAll(',', '.');
    final parsed = Decimal.tryParse(raw);
    if (parsed == null) return;
    widget.onSave(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _formKey,
      initialValue: _ctrl.text,
      validator: widget.validator,
      builder: (state) {
        return TextFormField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: state.hasError ? null : widget.helper,
            errorText: state.errorText,
          ),
          keyboardType: TextInputType.numberWithOptions(
            decimal: widget.allowDecimals,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              widget.allowDecimals ? RegExp('[0-9.,]') : RegExp('[0-9]'),
            ),
          ],
          onChanged: (v) => state.didChange(v),
        );
      },
    );
  }
}
