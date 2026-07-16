/// Indicador visual de "es default" — estrella dorada.
///
/// Usado en filamentos, impresoras y como leading icon en tiles del
/// calculator. Retorna un [SizedBox] vacio si [isDefault] es `false`,
/// por lo que puede colocarse en cualquier slot `leading` sin condicionar.
///
/// Color derivado de [AppTheme.defaultStar].
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DefaultBadge extends StatelessWidget {
  const DefaultBadge({
    super.key,
    this.isDefault = true,
    this.size = 24,
  });

  final bool isDefault;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isDefault) return const SizedBox.shrink();
    return Icon(
      Icons.star_rounded,
      color: AppTheme.defaultStar,
      size: size,
    );
  }
}
