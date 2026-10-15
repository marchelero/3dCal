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
import '../../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../../../../onboarding/presentation/domain/featured_printer_presets.dart';
import '../../../../onboarding/presentation/widgets/printer_preset_card.dart';
import '../notifiers/printers_notifier.dart';
import '../widgets/printer_catalog_selector.dart';

/// Form de impresora (catálogo in-app). Réplica del DISEÑO del paso 2 del
/// setup (`PrinterStep`) adaptado a página de formulario múltiple:
///
/// - Colapsable "Impresoras populares" con grid de [PrinterPresetCard]
///   (2 columnas adaptables vía LayoutBuilder). Tap a un preset LLENA el
///   form de abajo (marca, modelo, watts, vida útil) y COLAPSA la sección
///   (mismo patrón que el setup).
/// - Form en card opaca `surfaceContainerLow` (radius 16, borde
///   outlineVariant 0.6 alpha): [PrinterCatalogSelector] + watts.
/// - Sub-colapsable "Otros datos (opcional)": costo de compra (Decimal),
///   vida útil y horas de uso. Envuelto en `Material(transparent)` porque
///   si no el Container padre tapa los ink splashes (assert de framework).
/// - **Diferencia con el setup**: es una página con guardado múltiple — NO
///   colapsa a tarjeta saved tras guardar; el botón "Guardar" (siempre
///   visible, con validación de form en tap) y la semántica create/update
///   del notifier se conservan intactos. Con `existing` se pre-cargan todos
///   los campos (incl. opcionales) y el colapsable de presets arranca
///   colapsado para no distraer de la edición.
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
  late final TextEditingController _currentHoursCtrl;
  late bool _isDefault;
  bool _saving = false;

  /// Controller del colapsable "Impresoras populares": al elegir un preset
  /// se colapsa para que el foco quede en el form lleno con sus datos
  /// (mismo patrón que `PrinterStep`).
  final _popularCtrl = ExpansibleController();

  /// Preset elegido en el grid (borrador UI-local — BUG-006); resalta la
  /// tarjeta seleccionada hasta que el usuario cambie el form.
  FeaturedPrinterPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _wattsCtrl = TextEditingController(
      text: p == null ? '' : p.averageWatts.toString(),
    );
    _costCtrl = TextEditingController(
      text: p?.purchaseCost == null ? '' : _costText(p!.purchaseCost!),
    );
    _lifeCtrl = TextEditingController(
      text: p?.usefulLifeHours == null ? '' : p!.usefulLifeHours!.toString(),
    );
    _currentHoursCtrl = TextEditingController(
      text: p?.currentHours == null ? '' : p!.currentHours!.toString(),
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
    _currentHoursCtrl.dispose();
    _popularCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  /// Texto pre-cargado del costo (double de drift → sin cola de ceros).
  static String _costText(double cost) {
    final d = Decimal.parse(cost.toString());
    return d == d.truncate() ? d.truncate().toString() : d.toString();
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

  /// Tap a un preset del grid: LLENA el form (marca, modelo, watts, vida
  /// útil — default 7500 si el preset no trae) y COLAPSA la sección
  /// "Impresoras populares". La persistencia ocurre al tocar "Guardar"
  /// (semántica create/update del notifier intacta).
  void _selectPreset(FeaturedPrinterPreset preset) {
    _brandCtrl.text = preset.brand;
    _nameCtrl.text = preset.model;
    _wattsCtrl.text = preset.watts.toString();
    _lifeCtrl.text = (preset.usefulLifeHours ?? 7500).toString();
    // BUG-006: _selectedPreset es estado UI-local (resaltado del grid); el
    // guardado real ocurre vía notifier al tocar "Guardar".
    setState(() => _selectedPreset = preset);
    // Colapsa el colapsable de populares (no-op si ya está colapsado).
    if (_popularCtrl.isExpanded) _popularCtrl.collapse();
  }

  /// true cuando el preset coincide con el elegido en esta sesión o con la
  /// impresora en edición (resaltado del grid).
  bool _isPresetSelected(FeaturedPrinterPreset preset) {
    final selected = _selectedPreset;
    if (selected != null &&
        selected.brand == preset.brand &&
        selected.model == preset.model) {
      return true;
    }
    final existing = widget.existing;
    return existing != null &&
        existing.name == preset.model &&
        (existing.brand ?? '') == preset.brand;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(printersNotifierProvider.notifier);
    final name = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final watts = int.parse(_wattsCtrl.text.trim());
    final cost = _costCtrl.text.trim().isEmpty
        ? null
        : Decimal.parse(_costCtrl.text.trim().replaceAll(',', '.'));
    final life = _lifeCtrl.text.trim().isEmpty
        ? null
        : int.parse(_lifeCtrl.text.trim());
    final currentHours = _currentHoursCtrl.text.trim().isEmpty
        ? null
        : int.parse(_currentHoursCtrl.text.trim());
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
          currentHours: currentHours,
          clearAmortization: cost == null && life == null,
        );
      } else {
        await notifier.create(
          name: name,
          brand: brand.isEmpty ? null : brand,
          averageWatts: watts,
          asDefault: _isDefault,
          purchaseCost: cost,
          usefulLifeHours: life,
          currentHours: currentHours,
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

  /// true si el sub-colapsable "Otros datos" debe arrancar abierto: en
  /// edición con algún campo opcional cargado (para que el pre-cargado sea
  /// visible sin tener que desplegarlo a mano).
  bool get _extraInitiallyExpanded {
    final p = widget.existing;
    if (p == null) return false;
    return p.purchaseCost != null ||
        p.usefulLifeHours != null ||
        (p.currentHours ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;
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
                // Colapsable "Impresoras populares" (mismo patrón que el
                // paso 2 del setup). Arranca colapsado en edición para no
                // distraer de la impresora existente. Material (no
                // DecoratedBox): el ExpansionTile pinta su ListTile/ink
                // sobre el Material más cercano con color de fondo.
                Material(
                  color: color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: const ValueKey('printer-form-popular'),
                    controller: _popularCtrl,
                    initiallyExpanded: !_isEdit,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    iconColor: color.onSurface,
                    textColor: color.onSurface,
                    title: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: color.secondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            EsBO.setupPrinterPopular,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2 columnas incluso en ventanas delgadas: el ancho de
                      // las tarjetas se adapta al espacio disponible. 1 sola
                      // columna (ancho completo) solo en el caso extremo
                      // (< 280px).
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = AppSpacing.md;
                          final available = constraints.maxWidth;
                          final twoColumns = available >= 280;
                          final cardWidth = twoColumns
                              ? (available - gap) / 2
                              : available;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final preset in featuredPresets())
                                PrinterPresetCard(
                                  key: ValueKey(
                                    'printer-form-preset-'
                                    '${preset.brand}-${preset.model}',
                                  ),
                                  width: cardWidth,
                                  brand: preset.brand,
                                  model: preset.model,
                                  watts: preset.watts,
                                  selected: _isPresetSelected(preset),
                                  onTap: () => _selectPreset(preset),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Card del form: opaca (labels/helpers onSurface) con el
                // mismo estilo que la card "Personalizada" del setup.
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
                      PrinterCatalogSelector(
                        compact: true,
                        brandController: _brandCtrl,
                        modelController: _nameCtrl,
                        wattsController: _wattsCtrl,
                        usefulLifeHoursController: _lifeCtrl,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NumericInputField(
                        label: EsBO.printerWatts,
                        controller: _wattsCtrl,
                        allowDecimals: false,
                        helperText: EsBO.printerWattsHelper,
                        textInputAction: TextInputAction.next,
                        validator: _requiredWatts,
                      ),
                      // Otros datos (opcional): costo de compra, vida útil
                      // y horas de uso — no bloquean el guardado. Material
                      // transparente propio: el ExpansionTile pinta su
                      // ListTile/ink sobre el Material más cercano; sin este
                      // wrapper el color del Container padre tapa los
                      // efectos (assert de framework "ListTile background
                      // color or ink splashes may be invisible").
                      // Nota: con la sección plegada sus campos no están en
                      // el árbol, así que sus validadores no corren al
                      // guardar (aceptable: son mutuamente consistentes
                      // cuando se editan juntos en la misma sección).
                      Material(
                        type: MaterialType.transparency,
                        child: ExpansionTile(
                          key: const ValueKey('printer-form-extra'),
                          initiallyExpanded: _extraInitiallyExpanded,
                          tilePadding: EdgeInsets.zero,
                          iconColor: color.onSurface,
                          textColor: color.onSurface,
                          title: Row(
                            children: [
                              Icon(
                                Icons.more_horiz_rounded,
                                size: 20,
                                color: color.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  EsBO.setupPrinterExtra,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Costo de compra (opcional, Decimal).
                            NumericInputField(
                              label: EsBO.printerPurchaseCost,
                              controller: _costCtrl,
                              allowDecimals: true,
                              helperText: EsBO.printerPurchaseCostHelper,
                              textInputAction: TextInputAction.next,
                              validator: _validateCost,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Vida util estimada (horas). Se auto-carga del
                            // catalogo al elegir modelo/preset.
                            NumericInputField(
                              label: EsBO.printerUsefulLifeHours,
                              controller: _lifeCtrl,
                              allowDecimals: false,
                              helperText: EsBO.printerUsefulLifeHoursHelper,
                              textInputAction: TextInputAction.next,
                              validator: _validateLife,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Horas acumuladas de uso.
                            NumericInputField(
                              label: EsBO.printerCurrentHours,
                              controller: _currentHoursCtrl,
                              allowDecimals: false,
                              helperText: EsBO.printerCurrentHoursHelper,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
