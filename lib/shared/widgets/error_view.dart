/// Vista de error con icono + mensaje + boton "Reintentar" opcional.
///
/// Usar en `AsyncValue.when(error: ...)` para que todas las paginas
/// tengan el mismo look & feel ante fallos.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/es_bo.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.details,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.xxxl),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: color.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color.onSurface,
                  ),
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(EsBO.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
