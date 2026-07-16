// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../notifiers/printers_notifier.dart';

/// Form de impresora. Espejo de [FilamentFormPage] sin `brand` ni Decimal.
class PrinterFormPage extends ConsumerStatefulWidget {
  const PrinterFormPage({super.key, this.existing});

  final PrinterProfile? existing;

  @override
  ConsumerState<PrinterFormPage> createState() => _PrinterFormPageState();
}

class _PrinterFormPageState extends ConsumerState<PrinterFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _wattsCtrl;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _wattsCtrl = TextEditingController(
      text: p == null ? '' : p.averageWatts.toString(),
    );
    _isDefault = p?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _wattsCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  String? _requiredText(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    if (v.trim().length > 100) return 'Maximo 100 caracteres';
    return null;
  }

  String? _requiredWatts(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    final n = int.tryParse(v.trim());
    if (n == null) return EsBO.commonInvalidNumber;
    if (n < 0) return 'Debe ser >= 0';
    return null;
  }

  void _setDefault(bool v) {
    setState(() => _isDefault = v);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(printersNotifierProvider.notifier);
    final name = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final watts = int.parse(_wattsCtrl.text.trim());
    try {
      if (_isEdit) {
        await notifier.updatePrinter(
          id: widget.existing!.id,
          name: name,
          brand: brand.isEmpty ? null : brand,
          averageWatts: watts,
          asDefault: _isDefault,
        );
      } else {
        await notifier.create(
          name: name,
          brand: brand.isEmpty ? null : brand,
          averageWatts: watts,
          asDefault: _isDefault,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? '${EsBO.commonEdit} impresora'
            : '${EsBO.commonNew} impresora'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: MaxWidthScrollView(
            maxWidth: 600,
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  helperText: 'Ej: Ender 3 V2',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: _requiredText,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  helperText: 'Ej: Creality, Anycubic',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              NumericInputField(
                label: 'Consumo promedio (W)',
                controller: _wattsCtrl,
                allowDecimals: false,
                helperText: 'Tipico 100-300 W',
                textInputAction: TextInputAction.done,
                validator: _requiredWatts,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Marcar como default'),
                subtitle: const Text(
                  'Se usara en nuevas cotizaciones. '
                  'Solo una impresora puede ser default.',
                ),
                value: _isDefault,
                onChanged: _saving ? null : _setDefault,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text(EsBO.commonSave),
                onPressed: _saving ? null : _save,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
