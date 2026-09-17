// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/section_header.dart';
import '../state/calculator_state.dart';
import 'printer_selector_dialog.dart';

/// Chip animado que muestra el total calculado en el AppBar.
/// Siempre visible (no se tapa con el teclado). Tap abre el sheet
/// de resultado con el desglose completo y acciones.
class TotalChip extends StatefulWidget {
  const TotalChip({
    super.key,
    required this.totalText,
    required this.hasDiscount,
    required this.onTap,
  });

  final String totalText;
  final bool hasDiscount;
  final VoidCallback onTap;

  @override
  State<TotalChip> createState() => _TotalChipState();
}

class _TotalChipState extends State<TotalChip>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;

  @override
  void initState() {
    super.initState();
    // Pulse sutil una sola vez cuando aparece el total por primera vez.
    _pulseCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
          )
          ..forward().then((_) {
            _pulseCtrl?.dispose();
            _pulseCtrl = null;
          });
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chip = Semantics(
      button: true,
      label: '${EsBO.calcResultBarTapHint}: ${widget.totalText}',
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: cs.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.totalText,
                style: AppTheme.num(
                  theme.textTheme.labelLarge ?? const TextStyle(),
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.hasDiscount) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onError,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );

    // Pulse sutil al primer render.
    if (_pulseCtrl != null) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeOutBack),
        ),
        child: chip,
      );
    }
    return chip;
  }
}

/// Peek preview de la seccion "Otros" cuando esta colapsado.
///
/// Muestra los labels de los 4 campos en una fila compacta y atenuada.
/// Si [locked] es true (usuario free), agrega un overlay sutil con icono
/// de candado y un borde punteado para sugerir que hay contenido bloqueado.
class OtrosPeekPreview extends StatelessWidget {
  const OtrosPeekPreview({super.key, required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.45);

    final labels = [
      EsBO.calcFieldLabor,
      EsBO.calcFieldPostProcess,
      EsBO.calcFieldFailure,
      EsBO.calcFieldWaste,
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: locked
              ? Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        child: Row(
          children: [
            // Labels en fila envolvente
            Expanded(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: labels.map((label) {
                  return Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: dimColor,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }).toList(),
              ),
            ),
            if (locked) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: cs.primary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rubrica impresa: header de seccion + contenido, sin caja de card.
///
/// Dentro de la hoja de plano, cada rubrica es un titulo
/// con su regla de cota ([SectionHeader]) seguido del contenido. Sin card
/// anidada: la hoja ya ES el documento.
class RubricSection extends StatelessWidget {
  const RubricSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(icon: icon, title: title),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// Parte entera del porcentaje para los labels l10n (p.ej. escalón 10 %
/// → "10"). Si el valor no es entero, redondea (display only; el cálculo
/// usa siempre el Decimal exacto).
int pctInt(Decimal? value) =>
    value == null ? 0 : value.round().toBigInt().toInt();

/// Líneas compactas del lote mayorista (feature A — Hito 1).
///
/// Se muestran arriba de la barra de total SOLO cuando aplica un escalón de
/// descuento por cantidad (N=1 sin escalón → flujo visual idéntico a antes):
/// - Subtotal: $X (base antes de descuentos)
/// - Descuento por cantidad (X%) −$monto
/// - Subtotal parcial: $Y
/// - Descuento manual (Y%) −$monto (si hay)
/// - Total: $Z
class BatchLines extends StatelessWidget {
  const BatchLines({super.key, required this.state, required this.currency});

  final CalculatorState state;
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final manualAmount = state.manualDiscountAmount;
    // Subtotal antes de descuentos: lotTotal + batchDiscount + manualDiscount
    final subtotalBefore = state.lotTotal +
        state.batchDiscountAmount +
        manualAmount;
    // Subtotal después del descuento por cantidad
    final subtotalAfterBatch = state.lotTotal + manualAmount;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtotal antes de descuentos
          _subtotalRow(
            context,
            label: EsBO.calcSubtotal,
            amount: subtotalBefore,
          ),
          if (state.batchDiscountAmount > Decimal.zero) ...[
            const SizedBox(height: AppSpacing.xs),
            _discountRow(
              context,
              label: EsBO.calcDetailBatchDiscount(
                pctInt(state.batchAppliedPercent),
              ),
              amount: state.batchDiscountAmount,
            ),
          ],
          if (manualAmount > Decimal.zero) ...[
            const SizedBox(height: AppSpacing.xs),
            _subtotalRow(
              context,
              label: EsBO.calcSubtotal,
              amount: subtotalAfterBatch,
            ),
            const SizedBox(height: AppSpacing.xs),
            _discountRow(
              context,
              label: EsBO.calcDetailManualDiscount(
                pctInt(state.detailDiscountPct),
              ),
              amount: manualAmount,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          // Total final
          _totalRow(
            context,
            label: EsBO.calcTotalFinal,
            amount: state.lotTotal,
          ),
        ],
      ),
    );
  }

  Widget _subtotalRow(BuildContext context, {required String label, required Decimal amount}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatCurrency(amount, currency),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _discountRow(BuildContext context, {required String label, required Decimal amount}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '-${formatCurrency(amount, currency)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _totalRow(BuildContext context, {required String label, required Decimal amount}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatCurrency(amount, currency),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Indicador de impresora activa: muestra nombre/watts o CTA para crear una.
class PrinterIndicator extends ConsumerWidget {
  const PrinterIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activePrinter = ref.watch(activePrinterProvider);
    final printersAsync = ref.watch(printersListProvider);
    final printers = printersAsync.value ?? <PrinterProfile>[];

    return Semantics(
      button: true,
      label: activePrinter != null
          ? '${EsBO.calcPrinterPrefix}${activePrinter.name}'
          : '${EsBO.calcNoPrinter}. ${EsBO.calcPrinterEmptyCta}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: printers.isEmpty
            ? () => context.push('/settings/printers/new')
            : () => showPrinterSelectorDialog(context, ref, printers: printers),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.print_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: activePrinter != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activePrinter.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            activePrinter.brand != null &&
                                    activePrinter.brand!.isNotEmpty
                                ? '${activePrinter.brand} · ${activePrinter.averageWatts} W'
                                : '${activePrinter.averageWatts} W',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            EsBO.calcNoPrinter,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            EsBO.calcPrinterEmptyHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            EsBO.calcPrinterEmptyCta,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
