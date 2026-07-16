/// Vista de estado vacio con icono + mensaje + CTA opcional.
///
/// Usar cuando una lista no tiene datos o una accion inicial no se hizo.
library;

import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
    this.subtitle,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: color.secondary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color.onSurface,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 24),
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
  }
}
