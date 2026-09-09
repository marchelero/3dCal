// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../domain/printer_catalog.dart';
import '../notifiers/printers_notifier.dart';

/// Valor sentinela del item "Otro..." del dropdown de marca.
const String _kBrandOther = '__brand_other__';

/// Valor sentinela del item "Otro..." del dropdown de modelo.
const String _kModelOther = '__model_other__';

/// Selector parametrico de impresora: Marca (catalogo) -> Modelo (catalogo
/// de esa marca) -> Watts auto-completado (editable).
///
/// Reemplaza el par `BrandSelectorField + TextFormField(modelo)` en los forms
/// de impresora. Recibe los 3 controllers para que el form padre conserve la
/// validacion y el guardado intactos.
///
/// Comportamiento:
/// - **Marca**: dropdown = `catalogBrands()` ∪ marcas ya registradas por el
///   usuario (del `printersNotifierProvider`) ∪ sentinel "Otro...".
/// - **Modelo**: dropdown parametrico = `catalogModels(marca)` ∪ "Otro...".
///   Elegir un modelo del catalogo auto-completa el watts (editable).
/// - **"Otro..." en marca**: desactiva la cascada -> campos manuales de
///   marca y modelo (watts manual).
/// - **"Otro..." en modelo**: campo modelo manual, watts vacio (requerido).
/// - **Edicion**: si los valores pre-cargados estan en el catalogo se
///   muestran en los dropdowns; si no, campos manuales. NUNCA pisa el watts
///   pre-cargado (A5).
class PrinterCatalogSelector extends ConsumerStatefulWidget {
  const PrinterCatalogSelector({
    super.key,
    required this.brandController,
    required this.modelController,
    required this.wattsController,
    this.enabled = true,
    this.compact = false,
  });

  /// Marca. El valor siempre vive en este controller.
  final TextEditingController brandController;

  /// Modelo/name. El valor siempre vive en este controller.
  final TextEditingController modelController;

  /// Watts (consumo promedio W). Se auto-llena al elegir un modelo del
  /// catalogo; el usuario puede editarlo.
  final TextEditingController wattsController;

  final bool enabled;

  /// `true` reduce el spacing (para el stepper del initial config).
  final bool compact;

  @override
  ConsumerState<PrinterCatalogSelector> createState() =>
      _PrinterCatalogSelectorState();
}

class _PrinterCatalogSelectorState
    extends ConsumerState<PrinterCatalogSelector> {
  /// true cuando el usuario eligio "Otro..." en marca.
  bool _forceBrandOther = false;

  /// true cuando el usuario eligio "Otro..." en modelo.
  bool _forceModelOther = false;

  /// Marcas registradas por el usuario (domain impresora, no cross-domain).
  Set<String> _registeredBrands(WidgetRef ref) {
    final brands = <String>{};
    final printers = ref.watch(printersNotifierProvider).value;
    for (final p in printers ?? const <PrinterProfile>[]) {
      final b = p.brand;
      if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
    }
    return brands;
  }

  /// Opciones de marca ordenadas: catalogo + registradas del usuario.
  List<String> _brandOptions(WidgetRef ref) {
    final all = <String>{...catalogBrands(), ..._registeredBrands(ref)};
    return all.toList()..sort();
  }

  String? _validateModel(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    if (v.trim().length > 100) return EsBO.filamentMax100;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final options = _brandOptions(ref);
    final currentBrand = widget.brandController.text.trim();
    final brandManual =
        _forceBrandOther ||
        (currentBrand.isNotEmpty && !options.contains(currentBrand));

    final modelOptions = catalogModels(currentBrand);
    final currentModel = widget.modelController.text.trim();
    final modelManual =
        _forceModelOther ||
        (currentModel.isNotEmpty && !modelOptions.contains(currentModel));

    // Helper bajo watts cuando el modelo actual es del catalogo.
    final modelSpec = findModel(currentBrand, currentModel);
    final showWattsHelper =
        modelSpec != null && widget.wattsController.text.trim().isNotEmpty;

    final spacing = widget.compact ? AppSpacing.md : AppSpacing.lg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBrandField(options),
        SizedBox(height: spacing),
        _buildModelField(
          hasBrand: currentBrand.isNotEmpty && !brandManual,
          brandManual: brandManual,
          modelManual: modelManual,
          models: modelOptions,
        ),
        if (showWattsHelper) ...[
          SizedBox(height: spacing),
          _buildWattsHelper(modelSpec),
        ],
      ],
    );
  }

  Widget _buildBrandField(List<String> options) {
    final current = widget.brandController.text.trim();
    final manual =
        _forceBrandOther || (current.isNotEmpty && !options.contains(current));

    if (manual) {
      return TextFormField(
        controller: widget.brandController,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: EsBO.filamentBrand,
          helperText: EsBO.brandSelectorManualHelper,
        ),
        textInputAction: TextInputAction.next,
      );
    }

    return DropdownButtonFormField<String>(
      key: const ValueKey('catalog-brand-dropdown'),
      initialValue: current.isNotEmpty && options.contains(current)
          ? current
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: EsBO.filamentBrand,
        helperText: EsBO.printerBrandHelper,
      ),
      hint: Text(EsBO.printerCatalogBrandHint),
      items: [
        for (final b in options) DropdownMenuItem(value: b, child: Text(b)),
        DropdownMenuItem(
          value: _kBrandOther,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(EsBO.brandSelectorOther),
            ],
          ),
        ),
      ],
      onChanged: widget.enabled
          ? (String? v) {
              if (v == _kBrandOther) {
                setState(() {
                  _forceBrandOther = true;
                  _forceModelOther = false;
                  widget.brandController.clear();
                  widget.modelController.clear();
                  widget.wattsController.clear();
                });
              } else if (v != null) {
                setState(() {
                  _forceBrandOther = false;
                  _forceModelOther = false;
                  widget.brandController.text = v;
                  widget.modelController.clear();
                  widget.wattsController.clear();
                });
              }
            }
          : null,
    );
  }

  Widget _buildModelField({
    required bool hasBrand,
    required bool brandManual,
    required bool modelManual,
    required List<String> models,
  }) {
    // Marca "Otro..." (o marca custom en edicion): modelo siempre manual,
    // sin cascada.
    if (brandManual) {
      return TextFormField(
        controller: widget.modelController,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: EsBO.printerModel,
          helperText: EsBO.printerCatalogModelHint,
        ),
        textInputAction: TextInputAction.next,
        validator: _validateModel,
      );
    }

    // Sin marca elegida: dropdown de modelo deshabilitado/vacio.
    if (!hasBrand) {
      return DropdownButtonFormField<String>(
        key: ValueKey('catalog-model-dropdown-empty'),
        initialValue: null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: EsBO.printerModel,
          helperText: EsBO.printerCatalogModelHint,
        ),
        hint: Text(EsBO.printerCatalogSelectModel),
        items: const [],
        onChanged: null,
        validator: _validateModel,
      );
    }

    final current = widget.modelController.text.trim();
    if (modelManual) {
      return TextFormField(
        controller: widget.modelController,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: EsBO.printerModel,
          helperText: EsBO.printerCatalogModelHint,
        ),
        textInputAction: TextInputAction.next,
        validator: _validateModel,
      );
    }

    final brand = widget.brandController.text.trim();
    return DropdownButtonFormField<String>(
      key: ValueKey('catalog-model-dropdown-$brand'),
      initialValue: current.isNotEmpty && models.contains(current)
          ? current
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: EsBO.printerModel,
        helperText: models.isEmpty
            ? EsBO.printerCatalogNoModels
            : EsBO.printerCatalogModelHint,
      ),
      hint: Text(EsBO.printerCatalogSelectModel),
      items: [
        for (final m in models) DropdownMenuItem(value: m, child: Text(m)),
        DropdownMenuItem(
          value: _kModelOther,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(EsBO.brandSelectorOther),
            ],
          ),
        ),
      ],
      onChanged: widget.enabled
          ? (String? v) {
              if (v == _kModelOther) {
                setState(() {
                  _forceModelOther = true;
                  widget.modelController.clear();
                  widget.wattsController.clear();
                });
              } else if (v != null) {
                setState(() {
                  _forceModelOther = false;
                  widget.modelController.text = v;
                  final spec = findModel(brand, v);
                  if (spec != null) {
                    widget.wattsController.text = spec.watts.toString();
                  }
                });
              }
            }
          : null,
      validator: _validateModel,
    );
  }

  Widget _buildWattsHelper(PrinterModelSpec spec) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final suffix = spec.isEstimated ? EsBO.printerWattsEstimated : '';
    return Padding(
      padding: EdgeInsets.only(
        top: widget.compact ? AppSpacing.xxs : AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: color.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${EsBO.printerWattsAutoHelper}$suffix',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
