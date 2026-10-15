// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// Abre la hoja inferior con TODAS las monedas (`WorldCurrency.all`).
///
/// Patrón de los sheets existentes en settings (`useSafeArea` +
/// `isScrollControlled`). La selección invoca [onSelected] y cierra.
Future<void> showCurrencyPickerSheet(
  BuildContext context, {
  required String currentCode,
  required ValueChanged<WorldCurrency> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) =>
        _CurrencyPickerSheet(currentCode: currentCode, onSelected: onSelected),
  );
}

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({
    required this.currentCode,
    required this.onSelected,
  });

  final String currentCode;
  final ValueChanged<WorldCurrency> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Material propio: los ListTile pintan su fondo/ink sobre el Material
      // ancestro (si no, Flutter avisa "ink splashes may be invisible").
      child: Material(
        color: color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    size: 20,
                    color: color.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EsBO.configCurrency,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: EsBO.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                itemCount: WorldCurrency.all.length,
                itemBuilder: (context, index) {
                  final currency = WorldCurrency.all[index];
                  final selected = currency.code == currentCode;
                  return ListTile(
                    key: ValueKey('setup-currency-option-${currency.code}'),
                    leading: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: selected ? color.primary : color.outlineVariant,
                    ),
                    title: Text('${currency.code} — ${currency.name}'),
                    trailing: Text(
                      currency.symbol,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      onSelected(currency);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
