/// Vista de estado vacio con icono + mensaje + CTA opcional.
///
/// Usar cuando una lista no tiene datos o una accion inicial no se hizo.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
    this.subtitle,
    this.semanticLabel,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  /// Etiqueta semantica opcional. Si se da, el screen reader anuncia este
  /// string como descripcion unificada del estado vacio (mensaje +
  /// subtitulo + CTA) en vez de leer cada parte por separado.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final view = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.xxxl),
              ),
              child: Icon(icon, size: 36, color: color.secondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color.onSurface,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: onCta,
                icon: Icon(ctaIcon ?? Icons.arrow_forward),
                label: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );

    if (semanticLabel == null) return view;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: view,
    );
  }
}
