/// Header de seccion: icono + titulo en una fila.
///
/// Usado como intro visual de bloques en pages (settings, calculator,
/// dashboard). El color del icono y del texto usan [accentColor] (default:
/// `colorScheme.primary`).
///
/// Sigue el tamano y peso del `textTheme.titleSmall` para consistencia con
/// la densidad M3.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
