// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/share/quote_share.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../state/calculator_state.dart';
import 'summary_card.dart';

/// Sticky bar que aparece en la parte inferior de CalculatorPage.
///
/// **Dos estados**:
/// - **Invalid** (`onTap == null`): muestra hint dinamico listando campos
///   faltantes. User sabe que falta sin scrollear. No es tappable.
/// - **Valid** (`onTap != null`): muestra total formateado + flecha. Tap →
///   abre el modal sheet con el resumen completo + acciones.
///
/// **Por que sticky bar + modal (no solo modal automatico)**: el usuario
/// pierde el contexto del form si le tapamos un modal encima apenas escribe
/// el ultimo campo. La bar es siempre visible, no bloquea input, y el modal
/// lo abre el usuario cuando quiere ver el detalle o actuar.
class ResultBottomBar extends StatelessWidget {
  const ResultBottomBar({
    required this.totalText,
    required this.hasDiscount,
    required this.onTap,
    this.emptyHint,
    super.key,
  });

  final String totalText;
  final bool hasDiscount;
  final VoidCallback? onTap;

  /// Texto del hint cuando el form es invalido. Si null, se renderiza la
  /// version con total (caso valido).
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isEmpty = emptyHint != null;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: color.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isEmpty
                        ? color.surfaceContainerHighest
                        : color.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    isEmpty
                        ? Icons.info_outline_rounded
                        : Icons.receipt_long_rounded,
                    color: isEmpty
                        ? color.onSurfaceVariant
                        : color.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEmpty
                            ? EsBO.calcResultBarEmptyHint
                            : EsBO.calcResultBarTapHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isEmpty)
                        Text(
                          emptyHint!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          totalText,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isEmpty && hasDiscount) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      EsBO.calcToggleShowDetail,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (!isEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre el modal sheet con el resumen completo de la cotizacion + acciones.
///
/// Usa [showModalBottomSheet] con `isScrollControlled: true` para que el
/// sheet pueda ocupar casi toda la pantalla cuando el contenido es largo.
/// `useSafeArea: true` evita que el contenido choque con la status bar en
/// tablets.
Future<void> showResultSheet({
  required BuildContext context,
  required CalculatorState state,
  required VoidCallback onSave,
  required VoidCallback onReset,
  required VoidCallback onToggleDetail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetCtx) => ResultSheetContent(
      state: state,
      onSave: onSave,
      onReset: onReset,
      onToggleDetail: onToggleDetail,
    ),
  );
}

/// Contenido del modal sheet. Mantiene la key de captura y el state de
/// "compartiendo..." dentro de este StatefulWidget para que el boton de
/// share muestre un spinner mientras la imagen se genera.
///
/// Es un StatefulWidget regular (no Consumer) porque las acciones (toggle
/// detail, save, reset) llegan como callbacks del parent. Asi el parent
/// conserva la unica fuente de verdad del state via Riverpod.
class ResultSheetContent extends StatefulWidget {
  const ResultSheetContent({
    required this.state,
    required this.onSave,
    required this.onReset,
    required this.onToggleDetail,
    super.key,
  });

  final CalculatorState state;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onToggleDetail;

  @override
  State<ResultSheetContent> createState() => _ResultSheetContentState();
}

class _ResultSheetContentState extends State<ResultSheetContent> {
  // Key para RepaintBoundary del summary card. captureAndShareQuote la usa
  // para encontrar el RenderObject y capturarlo como PNG.
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await captureAndShareQuote(_captureKey);
    } on ShareQuoteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error(e.message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error('${EsBO.calcShareError}: $e'),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final output = state.output;
    if (output == null) {
      // Safety: el sheet no deberia abrirse sin output. Si pasa, mostramos
      // empty para no crashear.
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: Text('—')),
      );
    }
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final meta = computeMeta(state);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                EsBO.calcSheetTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Summary card envuelto en RepaintBoundary para captura.
            // SummaryCard ya tiene la meta info (gramos + tiempo) del Fix #2.
            RepaintBoundary(
              key: _captureKey,
              child: SummaryCard(
                output: output,
                label: state.label,
                discountPct:
                    state.detailDiscountPct?.toStringAsFixed(0) ??
                    state.discountPct,
                showDetail: state.showDetail,
                onToggleDetail: widget.onToggleDetail,
                detailElectricCost: state.detailElectricCost,
                detailBaseCost: state.detailBaseCost,
                detailProfitAmount: state.detailProfitAmount,
                detailTotalFinal: state.detailTotalFinal,
                metaGrams: meta.grams,
                metaTime: meta.time,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Acciones label
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                EsBO.calcSheetActionsLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Action row: Save (primary) + Share (outlined) + Reset (text).
            _ResultActionRow(
              isSharing: _isSharing,
              onSave: () {
                Navigator.of(context).pop();
                widget.onSave();
              },
              onShare: _handleShare,
              onReset: () {
                Navigator.of(context).pop();
                widget.onReset();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de 3 botones al final del sheet: Guardar, Compartir, Restablecer.
class _ResultActionRow extends StatelessWidget {
  const _ResultActionRow({
    required this.isSharing,
    required this.onSave,
    required this.onShare,
    required this.onReset,
  });

  final bool isSharing;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(EsBO.calcBtnSave),
            onPressed: onSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            icon: isSharing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color.primary,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(EsBO.calcBtnShare),
            onPressed: isSharing ? null : onShare,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: EsBO.calcBtnReset,
          onPressed: onReset,
          style: IconButton.styleFrom(
            foregroundColor: color.onSurfaceVariant,
            padding: const EdgeInsets.all(AppSpacing.md),
          ),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

/// Helper de formato: toma el total en formato currency formateado.
/// Wrapper sobre [formatBob] para mantener el call site del bar limpio.
@visibleForTesting
String debugFormatResultTotal(Decimal total) => formatBob(total);
