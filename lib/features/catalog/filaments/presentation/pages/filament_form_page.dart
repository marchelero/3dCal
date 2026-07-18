// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../notifiers/filaments_notifier.dart';

/// Form de filamento. Modo create (sin `existing`) o edit (con `existing`).
///
/// **Comportamiento**:
/// - AppBar cambia titulo segun modo.
/// - 4 campos: nombre, marca (opcional), precio bobina (BOB), gramos por bobina.
/// - Switch "Marcar como default". En modo edicion, refleja estado actual.
/// - Save: valida localmente (no vacio, > 0) y delega al notifier.
class FilamentFormPage extends ConsumerStatefulWidget {
  const FilamentFormPage({super.key, this.existing});

  /// Si se pasa, la pagina entra en modo edicion y pre-rellena los campos.
  final Filament? existing;

  @override
  ConsumerState<FilamentFormPage> createState() => _FilamentFormPageState();
}

class _FilamentFormPageState extends ConsumerState<FilamentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _gramsCtrl;
  late bool _isDefault;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _brandCtrl = TextEditingController(text: f?.brand ?? '');
    _priceCtrl = TextEditingController(
      text: f == null ? '' : f.pricePerBobbin.toStringAsFixed(2),
    );
    _gramsCtrl = TextEditingController(
      text: f == null ? '1000' : f.gramsPerBobbin.toStringAsFixed(0),
    );
    _isDefault = f?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  void _setDefault(bool v) {
    setState(() => _isDefault = v);
  }

  String? _requiredNumber(String? v, {bool integer = false}) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    final cleaned = v.trim().replaceAll(',', '.');
    final parsed = Decimal.tryParse(cleaned);
    if (parsed == null) return EsBO.commonInvalidNumber;
    if (parsed <= Decimal.zero) return EsBO.filamentMustBePositive;
    if (integer && parsed != parsed.toBigInt().toDecimal()) {
      return EsBO.filamentMustBeInteger;
    }
    return null;
  }

  String? _requiredText(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    if (v.trim().length > 100) return EsBO.filamentMax100;
    return null;
  }

  String? _optionalText(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > 100) return EsBO.filamentMax100;
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(filamentsNotifierProvider.notifier);
    final name = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim().replaceAll(',', '.');
    final gramsStr = _gramsCtrl.text.trim().replaceAll(',', '.');
    try {
      if (_isEdit) {
        await notifier.updateFilament(
          id: widget.existing!.id,
          name: name,
          brand: brand.isEmpty ? null : brand,
          pricePerBobbin: Decimal.parse(priceStr),
          gramsPerBobbin: Decimal.parse(gramsStr),
          asDefault: _isDefault,
        );
      } else {
        await notifier.create(
          name: name,
          brand: brand.isEmpty ? null : brand,
          pricePerBobbin: Decimal.parse(priceStr),
          gramsPerBobbin: Decimal.parse(gramsStr),
          asDefault: _isDefault,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error guardando: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(selectedCurrencyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? '${EsBO.commonEdit} filamento'
            : '${EsBO.commonNew} filamento'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: MaxWidthScrollView(
            maxWidth: 600,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.filamentName,
                  helperText: EsBO.filamentNameHelper,
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: _requiredText,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _brandCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.filamentBrand,
                  helperText: EsBO.filamentBrandHelper,
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: _optionalText,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.filamentPrice(currency.symbol),
                  helperText: EsBO.filamentPriceHelper,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: _requiredNumber,
              ),
              const SizedBox(height: AppSpacing.lg),
              NumericInputField(
                label: EsBO.filamentGrams,
                controller: _gramsCtrl,
                allowDecimals: false,
                helperText: EsBO.filamentGramsHelper,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                title: Text(EsBO.filamentDefaultToggle),
                subtitle: const Text(
                  'Se usara en nuevas cotizaciones. '
                  'Solo un filamento puede ser default.',
                ),
                value: _isDefault,
                onChanged: _saving ? null : _setDefault,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(EsBO.commonSave),
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
