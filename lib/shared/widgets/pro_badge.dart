/// Badge compacto "PRO" con candado para controles gateados (free tier).
///
/// Reusable en todos los gates visuales: mode selector del calculator,
/// export CSV y branding en settings. Hereda el patron del badge "Pro"
/// privado de settings (T12), ahora compartido para consistencia visual.
///
/// Uso:
/// ```dart
/// ProBadge()
/// ProBadge(accentColor: theme.colorScheme.tertiary)
/// ```
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/es_bo.dart';

/// Badge compacto "PRO" con icono de candado.
///
/// Marca visualmente que un control es Pro (bloqueado para free).
/// Con [Tooltip] + [Semantics] ([EsBO.proLockedTooltip]) para a11y.
class ProBadge extends StatelessWidget {
  /// Crea el badge con texto y color opcionales (defaults: "PRO" y
  /// `colorScheme.tertiary`).
  const ProBadge({super.key, this.label, this.accentColor});

  /// Texto del badge. Default: [EsBO.proBadgeLabel] ("PRO").
  final String? label;

  /// Color del badge. Default: `theme.colorScheme.tertiary`.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.tertiary;
    final text = label ?? EsBO.proBadgeLabel;
    return Semantics(
      label: EsBO.proLockedTooltip,
      image: true,
      child: Tooltip(
        message: EsBO.proLockedTooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
