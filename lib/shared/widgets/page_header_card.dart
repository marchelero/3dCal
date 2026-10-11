/// Cabecera estandar de las paginas del shell (card compacta).
///
/// Unifica Inicio, Historial, Impresion, Dashboard y Ajustes en una sola
/// tarjeta: banda de cota superior + chip de icono + titulo + subtitulo +
/// badge de plan (PRO/FREE) + acciones opcionales.
///
/// Reglas de la cabecera estandar:
/// - Titulo en `headlineSmall` SIN `toUpperCase()` (evita cortes de palabra
///   como "CONFIGUR/ACIÓN" en moviles), `maxLines: 2` + ellipsis.
/// - Subtitulo: una sola descripcion localizada (sin version de app, sin
///   "Privacidad y datos").
/// - Sin flecha de retroceso salvo que la pagina fue empujada (onBack).
// ignore_for_file: public_member_api_docs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../l10n/es_bo.dart';
import 'plan_sheet.dart';

/// Cabecera/card generica para las paginas principales del shell.
class PageHeaderCard extends ConsumerWidget {
  const PageHeaderCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.accentColor,
    this.iconColor,
    this.onBack,
    this.backTooltip,
    this.actions,
    this.showPlanBadge = true,
    this.semanticsLabel,
  });

  /// Titulo principal (texto localizado tal cual, sin uppercase).
  final String title;

  /// Subtitulo / descripcion corta del modulo.
  final String? subtitle;

  /// Icono del chip estandar (se ignora si se provee [leading]).
  final IconData? icon;

  /// Leading custom (ej: logo de la empresa en Inicio).
  final Widget? leading;

  /// Color de acento de la banda + chip. Default: `colorScheme.primary`.
  final Color? accentColor;

  /// Color del icono del chip. Default: derivado del acento.
  final Color? iconColor;

  /// Muestra la flecha de retroceso solo si la pagina fue empujada.
  final VoidCallback? onBack;

  /// Tooltip de la flecha de retroceso.
  final String? backTooltip;

  /// Acciones opcionales al extremo derecho (antes del badge de plan).
  final Widget? actions;

  /// Muestra el badge PRO/FREE (default true).
  final bool showPlanBadge;

  /// Label de accesibilidad del header (default: [title]).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final accent = accentColor ?? color.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Semantics(
        header: true,
        label: semanticsLabel ?? title,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: color.outlineVariant, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: color.onSurface.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banda de cota superior
              Container(height: 4, decoration: BoxDecoration(color: accent)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Flecha de retorno — solo si la pagina fue empujada.
                    if (onBack != null) ...[
                      IconButton(
                        tooltip: backTooltip,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: onBack,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    // Chip de icono estandar (o leading custom).
                    leading ?? _iconChip(theme, color, accent),
                    const SizedBox(width: AppSpacing.md),
                    // Titulo + subtitulo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: color.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: color.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Acciones + badge de plan
                    if (actions != null || showPlanBadge) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ?actions,
                          if (actions != null && showPlanBadge)
                            const SizedBox(width: AppSpacing.xs),
                          if (showPlanBadge) const PlanTierBadge(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconChip(ThemeData theme, ColorScheme color, Color accent) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor ??
            (accent.computeLuminance() > 0.5 ? Colors.black87 : Colors.white),
        size: 26,
      ),
    );
  }
}

/// Badge compacto de plan en la cabecera: "PRO" (con check) o "FREE".
///
/// - Auto-oculta mientras el entitlement esta en `loading` (AC-007: evita
///   mostrar un falso "FREE" a un Pro real en cold start).
/// - Tappable en ambos estados: abre el detalle del plan (sheet comparativo
///   Gratis vs Pro).
/// - Mas pequeno que el ProActiveBadge clásico: padding sm/2 + labelSmall.
class PlanTierBadge extends ConsumerWidget {
  const PlanTierBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementNotifierProvider);
    if (ent.isLoading) return const SizedBox.shrink();

    final isPro = ref.watch(isProProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final fg = isPro ? color.primary : color.onSurfaceVariant;

    return Semantics(
      label: isPro ? EsBO.settingsPlanStatusPro : EsBO.settingsPlanStatusFree,
      button: true,
      child: Tooltip(
        message: isPro ? EsBO.settingsProUnlocked : EsBO.settingsPlanSectionTitle,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => showPlanSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isPro ? color.primaryContainer : color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: fg.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPro ? EsBO.proBadgeLabel : EsBO.proBadgeLabelFree,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isPro ? color.onPrimaryContainer : fg,
                  ),
                ),
                if (isPro) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.verified_rounded, size: 12, color: color.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
