/// Badge compacto "PRO" con candado para controles gateados (free tier).
///
/// Reusable en todos los gates visuales: mode selector del calculator,
/// export CSV y branding en settings. Hereda el patron del badge "Pro"
/// privado de settings (T12), ahora compartido para consistencia visual.
///
/// Uso:
/// ```dart
/// ProBadge()
/// ProBadge(accentColor: theme.colorScheme.tertiary)
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../l10n/es_bo.dart';

/// Badge compacto "PRO" con icono de candado.
///
/// Marca visualmente que un control es Pro (bloqueado para free).
/// Con [Tooltip] + [Semantics] ([EsBO.proLockedTooltip]) para a11y.
///
/// **Tappable (F1)**: el tap del badge abre la PaywallPage ([EsBO]-aware).
/// Si [onTap] se provee, se usa ese en su lugar (ej: pop de un sheet antes
/// de navegar). La navegacion default respeta AC-102: si el entitlement
/// esta cargando o el user ya es Pro, no navega. Para gates dentro de
/// sheets usa [sheetAction] (mismo guard + pop con un solo handler).
///
/// **Tap target (F1/F4)**: el area tappable (InkWell) respeta el minimo de
/// 48x48dp (WCAG 2.5.5) aunque la pill visual siga compacta: la pill queda
/// centrada dentro del area.
class ProBadge extends ConsumerWidget {
  /// Crea el badge con texto y color opcionales (defaults: "PRO" y
  /// `colorScheme.tertiary`).
  const ProBadge({super.key, this.label, this.accentColor, this.onTap});

  /// Texto del badge. Default: [EsBO.proBadgeLabel] ("PRO").
  final String? label;

  /// Color del badge. Default: `theme.colorScheme.tertiary`.
  final Color? accentColor;

  /// Handler custom de tap. Default: navega a `/paywall` (si free y el
  /// entitlement ya resolvio).
  final VoidCallback? onTap;

  /// Navega desde un sheet: cierra el sheet (pop) y abre la PaywallPage
  /// usando el MISMO guard AC-102 que el onTap default (free + resuelto →
  /// navega; pro o entitlement en loading → no hace nada).
  static void sheetAction(BuildContext context, WidgetRef ref) {
    if (!_shouldNavigate(ref)) return;
    Navigator.of(context).pop();
    GoRouter.of(context).push('/paywall');
  }

  /// Guard compartido del onTap default y [sheetAction] (AC-102): NO
  /// navega a /paywall mientras el entitlement esta cargando ni cuando el
  /// user ya es Pro.
  static bool _shouldNavigate(WidgetRef ref) {
    final ent = ref.read(entitlementNotifierProvider);
    if (ent.isLoading || ref.read(isProProvider)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.tertiary;
    final text = label ?? EsBO.proBadgeLabel;

    final handleTap =
        onTap ??
        () {
          if (!_shouldNavigate(ref)) return;
          GoRouter.of(context).push('/paywall');
        };

    return Semantics(
      label: EsBO.proLockedTooltip,
      button: true,
      image: true,
      child: Tooltip(
        message: EsBO.proLockedTooltip,
        // F1/F4: el InkWell cubre al menos 48x48dp (ConstraintBox como
        // child) y la pill visual queda centrada adentro, compacta.
        // Los paddings de las filas que lo hostean absorben el alto extra.
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: handleTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
