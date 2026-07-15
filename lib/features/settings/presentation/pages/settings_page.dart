// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/es_bo.dart';
import '../../domain/settings.dart';
import '../notifiers/settings_notifier.dart';

/// Pagina `/settings` (Sprint 7 — Plan §7A).
///
/// **Secciones**:
/// 1. Parametros globales: profit base (%), kWh rate (BOB/kWh). Auto-save on
///    blur via [FocusNode] listener. No boton "Guardar" explicito.
/// 2. Catalogos: ListTile "Filamentos" → `/settings/filaments`, "Impresoras"
///    → `/settings/printers`.
/// 3. Acerca de: nota de privacidad local-only. (package_info_plus no se
///    instalo para no inflar deps en MVP; el versionado sale de pubspec.)
///
/// **Comportamiento**:
/// - Las validaciones se aplican al perder foco. Si el valor es invalido,
///   se muestra el error y NO se persiste.
/// - Los valores persistidos en DB se reflejan inmediatamente via Riverpod
///   (el notifier emite AsyncValue.data con el nuevo state).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(EsBO.settingsTitle)),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // === Parametros globales ===
        Text(
          EsBO.settingsGlobalParams,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
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
            ref.read(settingsNotifierProvider.notifier).updateProfitBase(v);
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
            final n = Decimal.tryParse(v.trim().replaceAll(',', '.'));
            if (n == null) return 'Numero invalido';
            if (n < Decimal.parse('0.10') || n > Decimal.parse('5.00')) {
              return 'Rango: 0.10-5.00';
            }
            return null;
          },
          onSave: (v) {
            ref.read(settingsNotifierProvider.notifier).updateKwhRate(v);
            _showSavedSnack(context);
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        // === Catalogos ===
        Text(
          EsBO.settingsCatalogos,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text(EsBO.settingsFilamentos),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/filaments'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text(EsBO.settingsImpresoras),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/printers'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        // === Acerca de ===
        Text(
          EsBO.settingsAbout,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(EsBO.appName, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(EsBO.settingsPrivacy),
              ],
            ),
          ),
        ),
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

/// TextFormField con auto-save on blur.
///
/// **Comportamiento**:
/// - Valida en cada cambio (mensaje de error visible).
/// - Al perder foco, si el valor es valido, llama [onSave] con el Decimal parseado.
/// - Si el valor es invalido, NO llama [onSave] (el error queda visible).
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
    // Si el initialValue cambia (settings cargados despues), actualizar
    // el controller. No sobrescribir si el user esta editando activamente.
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
    // Blur → validar y guardar.
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
            border: const OutlineInputBorder(),
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
