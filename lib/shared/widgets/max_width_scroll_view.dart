import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

/// Wrapper que limita el ancho del contenido en viewports anchos.
///
/// - En viewports angostos (< [breakpoint]): el child ocupa el ancho completo.
/// - En viewports anchos (>= [breakpoint]): el child se centra horizontalmente
///   con `maxWidth` (default 720dp para forms, 960dp para detail pages).
///
/// Usar envolviendo el `child` de un `ListView`/`SingleChildScrollView`:
///
/// ```dart
/// SingleChildScrollView(
///   padding: const EdgeInsets.all(16),
///   child: MaxWidthScrollView(
///     maxWidth: 720,
///     child: Column(...),
///   ),
/// )
/// ```
class MaxWidthScrollView extends StatelessWidget {
  const MaxWidthScrollView({
    required this.child,
    this.maxWidth = 720,
    this.breakpoint = 720,
    super.key,
  });

  /// Contenido a renderizar (centrado si el viewport es >= breakpoint).
  final Widget child;

  /// Ancho maximo del child en dp. Default 720 (forms).
  final double maxWidth;

  /// Ancho del viewport a partir del cual se aplica el centrado. Default 720.
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return child;
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
