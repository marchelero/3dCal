// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';

/// Tarjeta grande de idioma para el paso 0 del flujo de setup.
///
/// Muestra el nombre nativo del idioma (proper noun, no se traduce) con
/// feedback de selección: scale sutil + checkmark. El tap dispara [onTap]
/// (el `LocaleNotifier` persiste; el rebuild global lo hace `app.dart`).
/// Accesibilidad: `Semantics(button, selected)`.
class LanguageOptionCard extends StatelessWidget {
  const LanguageOptionCard({
    required this.name,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Nombre nativo del idioma (ej: "Español", "English").
  final String name;

  /// Si esta tarjeta es el idioma actualmente seleccionado.
  final bool selected;

  /// Callback al tocar la tarjeta.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Material(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(
                  color: selected ? color.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? color.primary : Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.language_rounded,
                    color: selected ? color.primary : Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
