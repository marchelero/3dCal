// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import 'setup_chip.dart';

/// Chips de moneda del paso 1 del flujo de setup.
///
/// Muestra la moneda sugerida según el locale seguida de las monedas
/// comunes deduplicadas, más el chip "Ver más" ([EsBO.setupCurrencySeeAll])
/// que abre la hoja con `WorldCurrency.all`. El tap persiste al instante vía
/// [onSelected] (el notifier de settings hace el resto).
///
/// La moneda actualmente seleccionada SIEMPRE aparece como chip (aunque no
/// esté en sugeridos/comunes — p. ej. elegida desde la hoja "Ver más"), para
/// que la selección sea visible de un vistazo.
///
/// Estilo vía [SetupChip] (fondo opaco + `onSurface`): contraste AA sobre
/// el gradiente del flujo (bug de validación 2026-10-11).
class CurrencyChips extends StatelessWidget {
  const CurrencyChips({
    required this.currentCode,
    required this.suggestedCode,
    required this.onSelected,
    required this.onSeeAll,
    super.key,
  });

  /// Código ISO de la moneda actualmente seleccionada.
  final String currentCode;

  /// Código ISO de la moneda sugerida para el locale activo.
  final String suggestedCode;

  /// Tap en un chip de moneda (código ISO).
  final ValueChanged<String> onSelected;

  /// Tap en el chip "Ver más".
  final VoidCallback onSeeAll;

  /// Monedas comunes mostradas además de la sugerida (deduplicadas).
  static const List<String> _commonCodes = [
    'USD',
    'EUR',
    'ARS',
    'MXN',
    'BRL',
    'COP',
  ];

  @override
  Widget build(BuildContext context) {
    // Sugerida primero; luego comunes sin repetir.
    final codes = <String>[suggestedCode];
    for (final code in _commonCodes) {
      if (!codes.contains(code)) codes.add(code);
    }
    // La seleccionada va al frente si no está en la lista: ningún chip debe
    // quedar "varado" sin reflejar la elección del usuario (bug F2).
    if (!codes.contains(currentCode)) codes.insert(0, currentCode);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final code in codes)
          SetupChip(
            key: ValueKey('setup-currency-chip-$code'),
            label:
                '${WorldCurrency.fromCode(code).symbol} '
                '${WorldCurrency.fromCode(code).code}',
            semanticsLabel: code,
            selected: currentCode == code,
            onTap: () => onSelected(code),
          ),
        SetupChip(
          key: const ValueKey('setup-currency-see-all'),
          label: EsBO.setupCurrencySeeAll,
          selected: false,
          showCheck: false,
          icon: Icons.expand_more_rounded,
          onTap: onSeeAll,
        ),
      ],
    );
  }
}
