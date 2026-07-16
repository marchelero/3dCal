/// Card de seccion: [Card] M3 + [SectionHeader] + contenido.
///
/// Wrapper reutilizable para agrupar inputs/UI logic en bloques con titulo.
/// Usado en calculator, settings, dashboard. Internamente usa
/// [SectionHeader] para mantener consistencia visual.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'section_header.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: icon,
              title: title,
              accentColor: accentColor,
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
