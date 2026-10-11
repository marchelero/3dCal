/// Bottom sheet comparativo Gratis vs Pro (detalle del plan).
///
/// Extraido de `settings_page.dart` para poder abrirlo desde la cabecera
/// estandar ([PageHeaderCard]) de cualquier pagina del shell, manteniendo
/// las mismas ValueKeys testeables:
/// - `settingsPlanSheet` (cuerpo del sheet)
/// - `settingsPlanStatusBadge` (pill de estado)
/// - `settingsPlanUnlockCta` (CTA de desbloqueo, solo free)
// ignore_for_file: public_member_api_docs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../features/settings/presentation/widgets/settings_widgets.dart';
import '../../l10n/es_bo.dart';

/// Clave del badge de estado (testeable desde el widget test).
const _planStatusBadgeKey = ValueKey('settingsPlanStatusBadge');

/// Clave del CTA de desbloqueo (testeable desde el widget test).
const _planUnlockCtaKey = ValueKey('settingsPlanUnlockCta');

/// Abre el bottom sheet con el comparador Gratis vs Pro.
void showPlanSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const PlanSheetBody(),
  );
}

/// Contenido del sheet: estado + CTA (solo free) + listas Gratis/Pro.
class PlanSheetBody extends ConsumerWidget {
  const PlanSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final resolved = !ent.isLoading;

    final stateTitle = isPro
        ? EsBO.settingsPlanProHeading
        : EsBO.settingsPlanFreeHeading;

    return SafeArea(
      key: const ValueKey('settingsPlanSheet'),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Cabecera: icono + estado ──
              Row(
                children: [
                  IconBadge(
                    icon: Icons.workspace_premium_rounded,
                    background: color.primaryContainer,
                    foreground: color.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      resolved ? stateTitle : EsBO.settingsPlanSectionTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (resolved) PlanStatusBadge(isPro: isPro),
                ],
              ),
              // ── Mensaje ya-Pro o CTA desbloquear ──
              if (resolved && isPro) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  EsBO.settingsPlanAlreadyPro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
              if (resolved && !isPro) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: _planUnlockCtaKey,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(EsBO.settingsPlanUnlockCta),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/paywall');
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const CardDivider(),
              const SizedBox(height: AppSpacing.lg),

              // ── Lista Gratis ──
              Text(
                EsBO.settingsPlanFreeHeading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...EsBO.settingsPlanFreeFeatures.map(
                (f) => PlanFeatureRow(text: f, color: color),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Subsección Pro: todo lo de Gratis, y además ──
              Text(
                EsBO.settingsPlanProHeading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                EsBO.settingsPlanProIncludes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...EsBO.settingsPlanProFeatures.map(
                (f) => PlanFeatureRow(text: f, color: color, accent: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill de estado de plan: "PRO" (con check) o "Gratis".
class PlanStatusBadge extends StatelessWidget {
  const PlanStatusBadge({required this.isPro, super.key});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final bg = isPro ? color.primaryContainer : color.surfaceContainerHighest;
    final fg = isPro ? color.onPrimaryContainer : color.onSurfaceVariant;

    return Semantics(
      label: isPro ? EsBO.settingsPlanStatusPro : EsBO.settingsPlanStatusFree,
      child: Container(
        key: _planStatusBadgeKey,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPro ? EsBO.settingsPlanStatusPro : EsBO.settingsPlanStatusFree,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: fg,
              ),
            ),
            if (isPro) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.verified_rounded, size: 16, color: color.primary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de feature con check. [accent] tiñe el check con el color primario.
class PlanFeatureRow extends StatelessWidget {
  const PlanFeatureRow({
    required this.text,
    required this.color,
    this.accent = false,
    super.key,
  });

  final String text;
  final ColorScheme color;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: accent ? color.primary : color.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: color.onSurface)),
          ),
        ],
      ),
    );
  }
}
