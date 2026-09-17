// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/filament_color_palette.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import 'filament_selector_dialog.dart';
import 'material_management.dart';

/// Filament row compacto para Express.
class ExpressFilamentRow extends ConsumerWidget {
  const ExpressFilamentRow({
    super.key,
    required this.labelCtrl,
    required this.priceCtrl,
    required this.gramsCtrl,
    required this.showValidation,
    required this.onChanged,
  });
  final TextEditingController labelCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController gramsCtrl;
  final bool showValidation;
  final ValueChanged<MaterialUpdate> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.value ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final hasFilaments = filaments.isNotEmpty;
    final hasLabel = labelCtrl.text.isNotEmpty;
    final colorMatches = filaments.where((f) => f.name == labelCtrl.text);
    final selectedColor = colorMatches.isEmpty
        ? null
        : colorFromHex(colorMatches.first.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
          if (hasFilaments)
            Semantics(
              button: true,
              label: EsBO.calcSelectFilament,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.xs),
                onTap: () async {
                  final filament = await showFilamentSelectorDialog(context, ref, filaments: filaments);
                  if (filament != null) {
                    labelCtrl.text = filament.name;
                    priceCtrl.text = filament.pricePerBobbin.toStringAsFixed(2);
                    gramsCtrl.text = filament.gramsPerBobbin.toStringAsFixed(0);
                    onChanged(MaterialUpdate(
                      label: filament.name, weight: '',
                      pricePerBobbin: filament.pricePerBobbin.toStringAsFixed(2),
                      gramsPerBobbin: filament.gramsPerBobbin.toStringAsFixed(0),
                    ));
                  }
                },
                child: InputDecorator(
                  isEmpty: !hasLabel,
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
                        child: Text(labelCtrl.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(child: NumericInputField(label: EsBO.calcFieldSpoolPrice, controller: priceCtrl, onChanged: (_) => onChanged(_emit()), suffix: currency.symbol, showValidation: showValidation)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: NumericInputField(label: EsBO.calcFieldSpoolGrams, controller: gramsCtrl, onChanged: (_) => onChanged(_emit()), suffix: 'g', showValidation: showValidation)),
              ],
            ),
          if (hasLabel || defaultFilament != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (hasLabel)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadii.xs)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${currency.symbol}${priceCtrl.text}', style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                      Text(' / ${gramsCtrl.text}g', style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                    ]),
                  ),
                const Spacer(),
                if (defaultFilament != null && labelCtrl.text != defaultFilament.name)
                  CatalogActionChip(
                    icon: Icons.star_rounded,
                    label: EsBO.calcMaterialUse(defaultFilament.name),
                    maxWidth: 180,
                    onTap: () {
                      labelCtrl.text = defaultFilament.name;
                      priceCtrl.text = defaultFilament.pricePerBobbin.toStringAsFixed(2);
                      gramsCtrl.text = defaultFilament.gramsPerBobbin.toStringAsFixed(0);
                      onChanged(MaterialUpdate(label: defaultFilament.name, weight: '', pricePerBobbin: defaultFilament.pricePerBobbin.toStringAsFixed(2), gramsPerBobbin: defaultFilament.gramsPerBobbin.toStringAsFixed(0)));
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  MaterialUpdate _emit() => MaterialUpdate(label: labelCtrl.text, weight: '', pricePerBobbin: priceCtrl.text, gramsPerBobbin: gramsCtrl.text);
}

/// Action chip generico para catalogos.
class CatalogActionChip extends StatelessWidget {
  const CatalogActionChip({super.key, required this.icon, required this.label, required this.onTap, this.maxWidth});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
      ),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Swatch circular del color del filamento.
class FilamentColorSwatch extends StatelessWidget {
  const FilamentColorSwatch({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWhite = color.toARGB32() == 0xFFFFFFFF;
    return Container(
      width: 16, height: 16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isWhite ? cs.outline : cs.outlineVariant, width: 1)),
    );
  }
}
