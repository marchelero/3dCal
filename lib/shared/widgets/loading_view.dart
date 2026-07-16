/// Spinner centrado con texto opcional debajo.
///
/// Usar en `AsyncValue.when(loading: ...)`.
/// Para contenido conocido (listas, cards), prefiere [HomePageSkeleton]
/// o [ListPageSkeleton] de `skeleton_widget.dart`.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message, this.useSkeleton = false});

  final String? message;

  /// Si true, muestra skeleton simulado (por defecto false, usa spinner).
  final bool useSkeleton;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
