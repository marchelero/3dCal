/// Avatar cuadrado con icono centrado. Patron recurrente de "icono + label".
///
/// Container 40x40 con fondo `primaryContainer` (default) y borde redondeado.
/// Usado como leading icon en ListTiles del calculator (filamentos, impresoras,
/// settings) y en el detail page.
///
/// Tamaños por defecto coinciden con la densidad M3 + theme.
library;

import 'package:flutter/material.dart';

class AvatarIcon extends StatelessWidget {
  const AvatarIcon({
    super.key,
    required this.icon,
    this.background,
    this.foreground,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 10,
  });

  final IconData icon;
  final Color? background;
  final Color? foreground;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: foreground ?? scheme.onPrimaryContainer,
      ),
    );
  }
}
