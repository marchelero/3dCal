// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../state/calculator_state.dart';

/// Selector Express/Advanced.
class ModeSelector extends ConsumerWidget {
  const ModeSelector({super.key, required this.mode, required this.onChanged});

  final CalculatorMode mode;
  final ValueChanged<CalculatorMode> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementNotifierProvider);
    final locked = !ent.isLoading && !ref.watch(isProProvider);
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: EsBO.calcSemanticMode(
        mode == CalculatorMode.express
            ? EsBO.calcModeExpress
            : EsBO.calcModeAdvanced,
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _ModePill(
            icon: Icons.flash_on_rounded,
            label: EsBO.calcModeExpress,
            isActive: mode == CalculatorMode.express,
            onTap: () => onChanged(CalculatorMode.express),
            activeColor: cs.primary,
          ),
          _ModePill(
            icon: Icons.layers_rounded,
            label: EsBO.calcModeAdvanced,
            isActive: mode == CalculatorMode.advanced,
            locked: locked,
            onTap: () => onChanged(CalculatorMode.advanced),
            activeColor: cs.tertiary,
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    this.locked = false,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final effectiveColor = locked && !isActive
        ? cs.onSurfaceVariant.withValues(alpha: 0.5)
        : isActive
        ? activeColor
        : cs.onSurfaceVariant;

    return Material(
      color: isActive
          ? activeColor.withValues(alpha: 0.12)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: BorderSide(
          color: isActive
              ? activeColor.withValues(alpha: 0.4)
              : cs.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: effectiveColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
              if (locked) ...[const SizedBox(width: 4), const ProBadge()],
            ],
          ),
        ),
      ),
    );
  }
}
