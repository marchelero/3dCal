// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// Pills de progreso conectadas del flujo de setup (5 decisiones).
///
/// - Completado (índice anterior al actual): círculo blanco con check.
/// - Actual: pill blanco resaltado (más ancho).
/// - Pendiente: círculo translúcido.
/// Cada pill es tappable → [onTap] con su índice (AC-09: navegación sin
/// botones "Siguiente"). Accesible con `EsBO.configStepCounter(i+1, total)`.
class ProgressPills extends StatelessWidget {
  const ProgressPills({
    required this.current,
    required this.onTap,
    this.total = 5,
    super.key,
  });

  /// Índice de página actual (0-based). Si es >= [total] se considera el
  /// cierre y todas las pills quedan completadas.
  final int current;

  /// Total de pills (decisiones del flujo).
  final int total;

  /// Callback al tocar una pill con su índice.
  final ValueChanged<int> onTap;

  bool _isCompleted(int index) => index < current || current >= total;

  bool _isCurrent(int index) => index == current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: EsBO.configStepCounter(
        current >= total ? total : current + 1,
        total,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: _isCompleted(i) ? 0.9 : 0.35,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            _ProgressPill(
              index: i,
              total: total,
              completed: _isCompleted(i),
              current: _isCurrent(i),
              onTap: () => onTap(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.index,
    required this.total,
    required this.completed,
    required this.current,
    required this.onTap,
  });

  final int index;
  final int total;
  final bool completed;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: current,
      label: EsBO.configStepCounter(index + 1, total),
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('setup-progress-pill-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: current ? 28 : (completed ? 12 : 10),
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: current
                ? Colors.white
                : completed
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.35),
          ),
          child: completed && !current
              ? const Icon(Icons.check_rounded, size: 10, color: Colors.black87)
              : null,
        ),
      ),
    );
  }
}
