/// Fila label + valor monetario formateado.
///
/// Usado en home y dashboard para los bloques de totales (cotizado, vendido,
/// etc). El valor usa `FontFeature.tabularFigures()` para alinear cifras.
///
/// - [value] ya viene formateado por el caller (ej: `formatBob(...)`).
/// - [valueColor] define el color del valor (default: `onSurface`).
/// - [isBold] aumenta el peso a w700 (default: w600).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = valueColor ?? theme.colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          // M2: cifras monetarias usan JetBrains Mono + tabular para
          // alineacion perfecta en columnas. La familia base sigue siendo
          // Inter (heredada del textTheme), solo override en el TextStyle.
          style: GoogleFonts.jetBrainsMono(
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
