// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

/// Vista de estado vacio: icono + mensaje + CTA opcional.
///
/// Usar cuando una lista no tiene datos o una accion inicial no se hizo.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
  });

  final IconData icon;
  final String message;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color.outline),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 16),
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
