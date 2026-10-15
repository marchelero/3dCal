// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/filament_color_field.dart';
import '../../../../../shared/widgets/k3d_brands.dart';
import '../../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../../../../onboarding/presentation/widgets/setup_chip.dart';
import '../notifiers/filaments_notifier.dart';

/// Form de filamento (catálogo in-app). Réplica del DISEÑO del paso 3 del
/// setup (`FilamentStep`) adaptada a página de formulario múltiple:
///
/// - Chips de marca ([SetupChip] sobre `kKnownFilamentBrands` + chip
///   "Otro..." que muestra un TextField manual) — reemplazan al
///   `BrandSelectorField` del form viejo (mismo estilo que el setup).
/// - Card opaca `surfaceContainerLow` (radius 16, borde outlineVariant 0.6
///   alpha) con los DOS campos de marca/alias siempre visibles (marca
///   solo-lectura con chip, editable en "Otro..."; usuario 2026-10-11:
///   "ambos inputs deberían estar" — nunca se mezclan), [FilamentColorField],
///   precio (Decimal) y gramos.
/// - **Diferencia con el setup**: es una página con guardado múltiple — NO
///   colapsa a tarjeta saved tras guardar; el botón "Guardar" (siempre
///   visible, con validación de form en tap) y la semántica create/update
///   del notifier se conservan intactos. El campo "Nombre" sigue siendo
///   editable (el setup lo auto-genera; aquí el usuario lo elige).
class FilamentFormPage extends ConsumerStatefulWidget {
  const FilamentFormPage({super.key, this.existing, this.onSaved});

  /// Si se pasa, la pagina entra en modo edicion y pre-rellena los campos.
  final Filament? existing;

  /// Callback opcional que se ejecuta al guardar con exito. Si es null, hace pop.
  final VoidCallback? onSaved;

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
  String? _color;

  bool _saving = false;

  /// true cuando el usuario toca el chip "Otro..." (o la marca existente no
  /// está en `kKnownFilamentBrands`, caso edición): muestra el TextField
  /// manual de marca.
  bool _showManualBrand = false;

  /// Foco del campo manual de marca ("Otro..."): al tocar el chip se
  /// solicita para abrir el teclado y hacer evidente que el campo apareció
  /// (bug 2026-10-11: "no hacía nada el botón Otros").
  final _manualBrandFocus = FocusNode();

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
    _color = f?.color;
    // Edición con marca fuera del set conocido → arranca en modo manual.
    _showManualBrand =
        (f?.brand ?? '').isNotEmpty && !kKnownFilamentBrands.contains(f!.brand);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    _manualBrandFocus.dispose();
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
          color: _color,
          updateColor: true,
        );
      } else {
        await notifier.create(
          name: name,
          brand: brand.isEmpty ? null : brand,
          pricePerBobbin: Decimal.parse(priceStr),
          gramsPerBobbin: Decimal.parse(gramsStr),
          asDefault: _isDefault,
          color: _color,
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
      debugPrint('Filament save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.filamentErrorSave));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? EsBO.filamentEdit : EsBO.filamentNew),
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
                // Chips de marca (mismo patrón que el paso 3 del setup):
                // SetupChip opaco con contraste AA + "Otro..." para ingreso
                // manual.
                _BrandChips(
                  selectedBrand: _brandCtrl.text.trim(),
                  manualSelected: _showManualBrand,
                  onSelected: (brand) =>
                      // BUG-006: el texto del controller es estado UI-local;
                      // el setState refleja la selección del chip al
                      // instante y el listener del controller repinta.
                      setState(() {
                        _brandCtrl.text = brand;
                        _showManualBrand = false;
                      }),
                  onManual: () {
                    // Bug 2026-10-11: "Otro..." "no hacía nada" — el campo
                    // manual aparecía sin foco y con la marca del chip
                    // anterior adentro (idéntico a lo que ya se veía). Se
                    // limpia la selección, se muestra el campo vacío y se
                    // abre el teclado.
                    setState(() {
                      _showManualBrand = true;
                      _brandCtrl.clear();
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _manualBrandFocus.requestFocus();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Card opaca para los campos de form: sus labels/helpers
                // usan onSurface/onSurfaceVariant (mismo estilo que la card
                // de filamento del setup).
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Los DOS campos siempre visibles (usuario
                      // 2026-10-11: "ambos inputs deberían estar"): marca
                      // y alias nunca se mezclan. Con chip la marca es
                      // solo-lectura (la llena el chip); en modo "Otro..."
                      // es editable. Obligatoria siempre (antes solo en
                      // modo manual, y el form se podía guardar sin
                      // marca).
                      TextFormField(
                        key: const ValueKey('filament-form-brand-field'),
                        controller: _brandCtrl,
                        readOnly: !_showManualBrand,
                        focusNode: _showManualBrand ? _manualBrandFocus : null,
                        decoration: InputDecoration(
                          labelText: EsBO.filamentBrand,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _requiredText,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: EsBO.filamentName,
                          helperText: EsBO.filamentNameHelper,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _requiredText,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilamentColorField(
                        value: _color,
                        onChanged: (v) => setState(() => _color = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      NumericInputField(
                        label: EsBO.filamentPrice(currency.symbol),
                        controller: _priceCtrl,
                        allowDecimals: true,
                        helperText: EsBO.filamentPriceHelper,
                        textInputAction: TextInputAction.next,
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Gramos por bobina (default 1000 en create).
                      NumericInputField(
                        label: EsBO.filamentGrams,
                        controller: _gramsCtrl,
                        allowDecimals: false,
                        helperText: EsBO.filamentGramsHelper,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  title: Text(EsBO.filamentDefaultToggle),
                  subtitle: Text(EsBO.filamentDefaultSubtitle),
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

/// Chips de marca del filamento (`kKnownFilamentBrands`) + "Otro..." para
/// ingreso manual. Mismo estilo [SetupChip] que el paso 3 del setup.
class _BrandChips extends StatelessWidget {
  const _BrandChips({
    required this.selectedBrand,
    required this.onSelected,
    required this.onManual,
    this.manualSelected = false,
  });

  final String selectedBrand;
  final ValueChanged<String> onSelected;
  final VoidCallback onManual;

  /// true cuando el modo manual ("Otro...") está activo: el chip se
  /// resalta con primaryContainer para que el estado sea visible.
  final bool manualSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final brand in kKnownFilamentBrands)
          SetupChip(
            key: ValueKey('filament-form-brand-$brand'),
            label: brand,
            selected: selectedBrand == brand,
            onTap: () => onSelected(brand),
          ),
        SetupChip(
          key: const ValueKey('filament-form-brand-other'),
          label: EsBO.brandSelectorOther,
          selected: manualSelected,
          showCheck: false,
          onTap: onManual,
        ),
      ],
    );
  }
}
