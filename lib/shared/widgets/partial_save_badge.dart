import 'package:flutter/material.dart';

import '../../l10n/es_bo.dart';

/// Chip que indica que una cotizacion es un borrador parcial (no guardada
/// completamente). Se muestra en la lista de cotizaciones y en el detalle.
class PartialSaveBadge extends StatelessWidget {
  const PartialSaveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 14,
            color: color.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            EsBO.calcPartialBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
