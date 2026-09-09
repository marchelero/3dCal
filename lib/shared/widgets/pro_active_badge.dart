/// Badge "PRO" de estado activo + sheet de beneficios.
///
/// Pill compacta: texto "PRO" + check verificado (estilo "Nike"). Se muestra
/// SOLO cuando el entitlement es Pro (auto-oculta si free). Al tocar, abre
/// la sheet con los beneficios de Pro (misma que usaba settings, ahora
/// compartida para home + settings).
///
/// Uso:
/// ```dart
/// const ProActiveBadge()
/// ```
// ignore_for_file: public_member_api_docs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/entitlement/data/payment_service.dart';
import '../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../l10n/es_bo.dart';
import 'app_snack_bar.dart';

/// Badge de estado PRO activo: "PRO" + check verificado.
///
/// Auto-oculta (SizedBox.shrink) si el usuario NO es Pro. Tappable: abre la
/// sheet de beneficios ([showProSheet]).
class ProActiveBadge extends ConsumerWidget {
  const ProActiveBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    if (!isPro) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final canRestore = ref.watch(paymentServiceProvider).isAvailable;

    return Semantics(
      label: EsBO.proBadgeLabel,
      button: true,
      child: Tooltip(
        message: EsBO.settingsProUnlocked,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => showProSheet(context, canRestore: canRestore),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: color.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  EsBO.proBadgeLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.verified_rounded, size: 16, color: color.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre el modal con toda la info de los beneficios de Pro.
void showProSheet(BuildContext context, {required bool canRestore}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => ProSheetBody(canRestore: canRestore),
  );
}

/// Contenido del modal de Pro: titulo, estado activo y lista de beneficios.
class ProSheetBody extends StatelessWidget {
  const ProSheetBody({super.key, required this.canRestore});

  final bool canRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EsBO.settingsProTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                EsBO.settingsProUnlocked,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                EsBO.settingsProNoAdditionalPurchase,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                EsBO.settingsProFutureUpdates,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...EsBO.paywallFeatures.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: color.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          benefit,
                          style: TextStyle(color: color.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (canRestore)
                RestoreButton(label: EsBO.settingsProRestorePurchase)
              else
                Text(
                  EsBO.paywallUnavailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de restaurar compras (T11).
class RestoreButton extends ConsumerStatefulWidget {
  const RestoreButton({super.key, this.label});

  final String? label;

  @override
  ConsumerState<RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends ConsumerState<RestoreButton> {
  bool _isRestoring = false;

  Future<void> _handleRestore() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);

    try {
      final result = await ref
          .read(entitlementNotifierProvider.notifier)
          .restore();
      if (!mounted) return;
      if (result is RestoreActive) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.success(EsBO.settingsRestoreSuccess));
      } else if (result is RestoreEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.info(context, EsBO.settingsRestoreEmpty));
      } else if (result is RestoreError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.error(EsBO.settingsRestoreError));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: _isRestoring
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.restore_rounded, size: 18),
        label: Text(widget.label ?? EsBO.settingsProRestorePurchase),
        onPressed: _isRestoring ? null : _handleRestore,
      ),
    );
  }
}

