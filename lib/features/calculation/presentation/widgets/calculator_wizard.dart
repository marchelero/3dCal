// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/es_bo.dart';

/// Chrome visual del cotizador-wizard (rediseño 2026-09): barra de pasos
/// ([CalcWizardStepBar]) y pie de navegación ([CalcWizardFooter]).
///
/// Son widgets puros (sin estado de negocio): el dueno ([CalculatorPage])
/// sostiene el indice del paso y los callbacks. El indice es estado efimero
/// de UI (setState permitido por las Non-Negotiables del proyecto).

// ============================================================
// STEP BAR
// ============================================================

/// Barra de pasos numerados y chiqueables del wizard del cotizador.
///
/// Cada segmento muestra circulo numerado + nombre del paso; el activo va
/// resaltado con una subrayado de color. Tap en cualquier segmento salta a
/// ese paso (sin validacion: el usuario puede navegar libremente).
class CalcWizardStepBar extends StatelessWidget {
  const CalcWizardStepBar({
    super.key,
    required this.labels,
    required this.current,
    required this.onTapStep,
  });

  /// Nombres de los pasos (orden del wizard).
  final List<String> labels;

  /// Indice del paso visible (0-based).
  final int current;

  /// Callback al tocar un paso (indice 0-based).
  final ValueChanged<int> onTapStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _StepSegment(
                index: i,
                label: labels[i],
                isActive: i == current,
                isDone: i < current,
                onTap: () => onTapStep(i),
                numberColor: cs,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepSegment extends StatelessWidget {
  const _StepSegment({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.onTap,
    required this.numberColor,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isDone;
  final VoidCallback onTap;
  final ColorScheme numberColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final badgeBg = isActive
        ? cs.primary
        : isDone
        ? cs.primaryContainer
        : cs.surfaceContainerHighest;
    final badgeFg = isActive
        ? cs.onPrimary
        : isDone
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      label: '${index + 1}. $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone && !isActive
                          ? Icon(Icons.check_rounded, size: 14, color: badgeFg)
                          : Text(
                              '${index + 1}',
                              style: AppTheme.num(
                                theme.textTheme.labelSmall ?? const TextStyle(),
                                color: badgeFg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: 3,
                width: 32,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FOOTER
// ============================================================

/// Pie de navegacion del wizard: dos botones espejo (flecha atras | flecha
/// adelante, ambos IconButton.outlined con tooltip) y contador de paso en
/// el medio. La flecha adelante se deshabilita en el ultimo paso (igual
/// que atras en el primero): no hay "ver cotizacion" aca porque la barra
/// de total fija que vive arriba ya lo ofrece.
class CalcWizardFooter extends StatelessWidget {
  const CalcWizardFooter({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;

  bool get _isLastStep => step >= totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Atras — icono (tooltip accesible), disabled en el primer paso.
          IconButton.outlined(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            tooltip: EsBO.configBack,
            onPressed: step > 0 ? onBack : null,
          ),
          const Spacer(),
          // Contador de paso (centrado).
          Text(
            EsBO.configStepCounter(step + 1, totalSteps),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          // Adelante — espejo exacto de Atras: solo la flecha derecha, con
          // tooltip 'Siguiente' (accesibilidad + ancla de tests). Disabled
          // en el ultimo paso.
          IconButton.outlined(
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            tooltip: EsBO.onboardingNext,
            onPressed: _isLastStep ? null : onNext,
          ),
        ],
      ),
    );
  }
}
