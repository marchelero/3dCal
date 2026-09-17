// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/filament_color_palette.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../state/calculator_state.dart';
import 'filament_row.dart';
import 'filament_selector_dialog.dart';

/// Controladores de texto para una fila de material.
class MaterialCtrls {
  MaterialCtrls({
    required this.label,
    required this.weight,
    required this.price,
    required this.grams,
  });
  factory MaterialCtrls.empty() => MaterialCtrls(
    label: TextEditingController(),
    weight: TextEditingController(),
    price: TextEditingController(),
    grams: TextEditingController(),
  );
  factory MaterialCtrls.fromRow(MaterialRow r) => MaterialCtrls(
    label: TextEditingController(text: r.label),
    weight: TextEditingController(text: r.weight),
    price: TextEditingController(text: r.pricePerBobbin),
    grams: TextEditingController(text: r.gramsPerBobbin),
  );
  final TextEditingController label;
  final TextEditingController weight;
  final TextEditingController price;
  final TextEditingController grams;
  void dispose() {
    label.dispose();
    weight.dispose();
    price.dispose();
    grams.dispose();
  }
}

/// DTO inmutable para cambios de material.
class MaterialUpdate {
  const MaterialUpdate({
    required this.label,
    required this.weight,
    required this.pricePerBobbin,
    required this.gramsPerBobbin,
  });
  final String label;
  final String weight;
  final String pricePerBobbin;
  final String gramsPerBobbin;
}

/// Fila de material para modo Advanced.
class MaterialRowTile extends ConsumerStatefulWidget {
  const MaterialRowTile({
    super.key,
    required this.index,
    required this.labelCtrl,
    required this.weightCtrl,
    required this.priceCtrl,
    required this.gramsCtrl,
    required this.onChanged,
    required this.deletable,
    required this.onRemove,
    this.showValidation = false,
    this.isKeyWeight = false,
  });
  final int index;
  final TextEditingController labelCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController gramsCtrl;
  final ValueChanged<MaterialUpdate> onChanged;
  final bool deletable;
  final VoidCallback onRemove;
  final bool showValidation;
  final bool isKeyWeight;

  @override
  ConsumerState<MaterialRowTile> createState() => _MaterialRowTileState();
}

class _MaterialRowTileState extends ConsumerState<MaterialRowTile> {
  String _selectedFilamentName = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.value ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final hasCatalog = filaments.isNotEmpty;
    final colorMatches = filaments.where((f) => f.name == _selectedFilamentName);
    final selectedColor = colorMatches.isEmpty
        ? null
        : colorFromHex(colorMatches.first.color);

    return Semantics(
      container: true,
      label: EsBO.calcMaterialTitle(widget.index + 1),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: cs.outlineVariant),
            bottom: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: AppTheme.num(
                        theme.textTheme.labelMedium ?? const TextStyle(),
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  EsBO.calcMaterialTitle(widget.index + 1),
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                if (widget.deletable)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: EsBO.calcMaterialRemove(widget.index + 1),
                    onPressed: widget.onRemove,
                    style: IconButton.styleFrom(foregroundColor: cs.error),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: widget.labelCtrl,
                    decoration: InputDecoration(
                      labelText: EsBO.calcFieldLabel,
                      hintText: EsBO.calcFieldLabelHelper,
                      isDense: true,
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                    ),
                    onChanged: (v) => _emit(),
                  ),
                ),
                if (hasCatalog) const SizedBox(width: AppSpacing.sm),
                if (hasCatalog)
                  Expanded(
                    flex: 3,
                    child: Semantics(
                      button: true,
                      label: EsBO.calcSelectFilament,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        onTap: () async {
                          final filament = await showFilamentSelectorDialog(
                            context, ref, filaments: filaments,
                          );
                          if (filament != null) _loadFromFilament(filament);
                        },
                        child: InputDecorator(
                          isEmpty: _selectedFilamentName.isEmpty,
                          decoration: InputDecoration(
                            labelText: EsBO.calcFieldFilament,
                            hintText: EsBO.calcSelectFilament,
                            prefixIcon: const Icon(Icons.inventory_2_rounded, size: 18),
                            suffixIcon: const Icon(Icons.expand_more_rounded),
                            isDense: true,
                          ),
                          child: Row(
                            children: [
                              if (selectedColor != null) ...[
                                FilamentColorSwatch(color: selectedColor),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Expanded(
                                child: Text(
                                  _selectedFilamentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (hasCatalog && defaultFilament != null &&
                _selectedFilamentName != defaultFilament.name) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: CatalogActionChip(
                  icon: Icons.star_rounded,
                  label: EsBO.calcMaterialUse(defaultFilament.name),
                  maxWidth: 180,
                  onTap: () => _loadFromFilament(defaultFilament),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: NumericInputField(
                    label: EsBO.calcFieldWeight,
                    controller: widget.weightCtrl,
                    onChanged: (v) => _emit(),
                    suffix: 'g',
                    isKey: widget.isKeyWeight,
                    keyHint: EsBO.calcKeyWeightHint,
                    showValidation: widget.showValidation,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (_selectedFilamentName.isNotEmpty && widget.priceCtrl.text.isNotEmpty)
                  MaterialCostChip(
                    price: widget.priceCtrl.text,
                    grams: widget.gramsCtrl.text,
                    currency: currency,
                  )
                else ...[
                  Expanded(
                    child: NumericInputField(
                      label: EsBO.calcFieldSpoolPrice,
                      controller: widget.priceCtrl,
                      onChanged: (v) => _emit(),
                      suffix: currency.symbol,
                      showValidation: widget.showValidation,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: NumericInputField(
                      label: EsBO.calcFieldSpoolGrams,
                      controller: widget.gramsCtrl,
                      onChanged: (v) => _emit(),
                      suffix: 'g',
                      showValidation: widget.showValidation,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _emit() {
    widget.onChanged(MaterialUpdate(
      label: widget.labelCtrl.text,
      weight: widget.weightCtrl.text,
      pricePerBobbin: widget.priceCtrl.text,
      gramsPerBobbin: widget.gramsCtrl.text,
    ));
  }

  void _loadFromFilament(Filament f) {
    setState(() => _selectedFilamentName = f.name);
    widget.priceCtrl.text = f.pricePerBobbin.toStringAsFixed(2);
    widget.gramsCtrl.text = f.gramsPerBobbin.toStringAsFixed(0);
    _emit();
  }
}

/// Chip compacto de costo de filamento.
class MaterialCostChip extends StatelessWidget {
  const MaterialCostChip({
    super.key,
    required this.price,
    required this.grams,
    required this.currency,
  });
  final String price;
  final String grams;
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currency.symbol}$price',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer, fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' / ${grams}g',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
