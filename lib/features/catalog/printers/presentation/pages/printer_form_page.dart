// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/brand_selector_field.dart';
import '../../../../../shared/widgets/k3d_brands.dart';
import '../../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../notifiers/printers_notifier.dart';

/// Form de impresora. Espejo de [FilamentFormPage] sin `brand` ni Decimal.
class PrinterFormPage extends ConsumerStatefulWidget {
  const PrinterFormPage({super.key, this.existing, this.onSaved});

  final PrinterProfile? existing;
  final VoidCallback? onSaved;

  @override
  ConsumerState<PrinterFormPage> createState() => _PrinterFormPageState();
}

class _PrinterFormPageState extends ConsumerState<PrinterFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _wattsCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _lifeCtrl;
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
    // F5: campos opcionales de amortizacion (vacio = sin linea).
    _costCtrl = TextEditingController(
      text: p?.purchaseCost == null ? '' : p!.purchaseCost!.toString(),
    );
    _lifeCtrl = TextEditingController(
      text: p?.usefulLifeHours == null ? '' : p!.usefulLifeHours!.toString(),
    );
    _isDefault = p?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _wattsCtrl.dispose();
    _costCtrl.dispose();
    _lifeCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  String? _requiredText(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    if (v.trim().length > 100) return EsBO.filamentMax100;
    return null;
  }

  String? _requiredWatts(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    final n = int.tryParse(v.trim());
    if (n == null) return EsBO.commonInvalidNumber;
    if (n < 0) return EsBO.printerMustBeNonNegative;
    return null;
  }

  /// Costo de compra (F5): opcional. Vacio o > 0 valido.
  String? _validateCost(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = Decimal.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return EsBO.commonInvalidNumber;
    if (n <= Decimal.zero) return EsBO.printerMustBeNonNegative;
    return null;
  }

  /// Vida util en horas (F5): opcional. Con costo presente debe ser >= 1.
  String? _validateLife(String? v) {
    if (v == null || v.trim().isEmpty) {
      // Sin costo → vacio ok. Con costo → requerida.
      final hasCost = _costCtrl.text.trim().isNotEmpty;
      return hasCost ? EsBO.printerLifePositiveIfCost : null;
    }
    final n = int.tryParse(v.trim());
    if (n == null) return EsBO.commonInvalidNumber;
    if (n < 1) return EsBO.printerLifePositiveIfCost;
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
    // F5: null si vacio (sin linea de amortizacion).
    final cost = _costCtrl.text.trim().isEmpty
        ? null
        : Decimal.parse(_costCtrl.text.trim().replaceAll(',', '.'));
    final life = _lifeCtrl.text.trim().isEmpty
        ? null
        : int.parse(_lifeCtrl.text.trim());
    try {
      if (_isEdit) {
        await notifier.updatePrinter(
          id: widget.existing!.id,
          name: name,
          brand: brand.isEmpty ? null : brand,
          averageWatts: watts,
          asDefault: _isDefault,
          purchaseCost: cost,
          usefulLifeHours: life,
        );
      } else {
        await notifier.create(
          name: name,
          brand: brand.isEmpty ? null : brand,
          averageWatts: watts,
          asDefault: _isDefault,
          purchaseCost: cost,
          usefulLifeHours: life,
        );
      }
      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!.call();
        } else {
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('Printer save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.printerErrorSave));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? EsBO.printerEdit : EsBO.printerNew)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: MaxWidthScrollView(
            maxWidth: 600,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
                BrandSelectorField(
                  domain: BrandDomain.printer,
                  controller: _brandCtrl,
                  label: EsBO.filamentBrand,
                  helperText: EsBO.printerBrandHelper,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.printerModel,
                    helperText: EsBO.printerModelHelper,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _requiredText,
                ),
                const SizedBox(height: AppSpacing.lg),
                NumericInputField(
                  label: EsBO.printerWatts,
                  controller: _wattsCtrl,
                  allowDecimals: false,
                  helperText: EsBO.printerWattsHelper,
                  textInputAction: TextInputAction.next,
                  validator: _requiredWatts,
                ),
                const SizedBox(height: AppSpacing.lg),
                // F5: amortizacion (opcional). Ambos vacios → sin linea.
                NumericInputField(
                  label: EsBO.printerPurchaseCost,
                  controller: _costCtrl,
                  allowDecimals: true,
                  helperText: EsBO.printerPurchaseCostHelper,
                  textInputAction: TextInputAction.next,
                  validator: _validateCost,
                ),
                const SizedBox(height: AppSpacing.lg),
                NumericInputField(
                  label: EsBO.printerUsefulLifeHours,
                  controller: _lifeCtrl,
                  allowDecimals: false,
                  helperText: EsBO.printerUsefulLifeHoursHelper,
                  textInputAction: TextInputAction.done,
                  validator: _validateLife,
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  title: Text(EsBO.filamentDefaultToggle),
                  subtitle: Text(EsBO.printerDefaultSubtitle),
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
