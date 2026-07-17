// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../../../../core/share/quote_share.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../settings/domain/settings.dart';
import '../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../domain/entities/calculation_output.dart';
import '../notifiers/calculations_notifier.dart';
import '../state/calculator_state.dart' show MaterialCostBreakdown;
import '../widgets/quote_image_template.dart';

/// Detalle de una cotizacion guardada. Readonly — version mejorada.
class CalculationDetailPage extends ConsumerWidget {
  const CalculationDetailPage({super.key, required this.calcId});

  final int calcId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(_calculationByIdProvider(calcId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(EsBO.calcDetailTitle),
        actions: [
          IconButton(
            tooltip: EsBO.calcDetailDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: calc == null
                ? null
                : () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: EsBO.calcDetailDeleteTitle,
                      message: '¿Eliminar definitivamente?',
                    );
                    if (confirm && context.mounted) {
                      await ref
                          .read(calculationsNotifierProvider.notifier)
                          .delete(calcId);
                      if (context.mounted) context.pop();
                    }
                  },
          ),
        ],
      ),
      body: calc == null
          ? const Center(child: CircularProgressIndicator())
          : _Detail(calc: calc),
      floatingActionButton: calc == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.replay_rounded),
              label: const Text(EsBO.calcDetailReuse),
              onPressed: () {
                context.push('/calculator/prefill', extra: calc);
              },
            ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.calc});

  final Calculation calc;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isBusy = false;
  bool _showDetail = false;

  Future<void> _handleShare() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bytes = await captureQuoteImageBytes(_captureKey);
      await shareQuoteImage(bytes);
    } on ShareQuoteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(e.message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error('${EsBO.calcShareError}: $e'),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleSave() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bytes = await captureQuoteImageBytes(_captureKey);
      await saveQuoteImage(bytes);
      if (!mounted) return;
      final msg = kIsWeb ? 'Imagen descargada' : 'Imagen guardada en galería';
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.success(msg));
    } on ShareQuoteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(e.message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error('${EsBO.calcShareError}: $e'),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calc;
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final materialsAsync = ref.watch(_materialsOfProvider(calc.id));
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final printer = ref.watch(defaultPrinterProvider);

    final materials = materialsAsync.valueOrNull ?? <CalculationMaterial>[];
    final settings = settingsAsync.valueOrNull ?? Settings.defaults;

    // Recompute output + detail values from stored data + current settings.
    final result = _recomputeOutput(calc, materials, settings, printer);

    return MaxWidthScrollView(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        shrinkWrap: true,
        children: [
        // === Header card (hero) ===
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.primaryContainer,
                color.primaryContainer.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.xxxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      calc.pieceName ?? EsBO.calcDetailNoName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (calc.isSold)
                    Chip(
                      label: const Text(EsBO.calcDetailSold),
                      backgroundColor: color.tertiaryContainer,
                      labelStyle: TextStyle(color: color.onTertiaryContainer),
                      avatar: Icon(
                        Icons.check_circle_rounded,
                        color: color.tertiary,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              if (calc.clientName != null && calc.clientName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: color.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Cliente: ${calc.clientName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: color.onPrimaryContainer.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm')
                        .format(calc.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  if (calc.totalHours > 0) ...[
                    const SizedBox(width: AppSpacing.lg),
                    Icon(Icons.timer_outlined,
                        size: 14, color: color.onPrimaryContainer.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '${calc.totalHours.toStringAsFixed(1)} h',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // === Materiales ===
        Text('Materiales',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        materialsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (ms) {
            if (ms.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('Sin materiales.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant)),
                ),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < ms.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: color.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ms[i].label,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500)),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${ms[i].weightGrams.toStringAsFixed(0)} g · '
                                  'BOB ${ms[i].pricePerBobbinSnapshot.toStringAsFixed(2)} / '
                                  '${ms[i].gramsPerBobbinSnapshot.toStringAsFixed(0)} g',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatBob(Decimal.parse(
                              (ms[i].weightGrams *
                                      ms[i].pricePerBobbinSnapshot /
                                      ms[i].gramsPerBobbinSnapshot)
                                  .toStringAsFixed(2),
                            )),
                            style: GoogleFonts.jetBrainsMono(
                              textStyle: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // === Desglose ===
        Text('Desglose',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _Row(
                  label: 'Costo material',
                  value: formatBob(
                    Decimal.parse(
                      calc.materialCostSnapshot.toStringAsFixed(2),
                    ),
                  ),
                ),
                if (calc.discountPercentage > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: color.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Descuento (${calc.discountPercentage.toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '-${formatBob(Decimal.parse((calc.materialCostSnapshot * calc.discountPercentage / 100).toStringAsFixed(2)))}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatBob(
                          Decimal.parse(
                            calc.totalPriceSnapshot.toStringAsFixed(2),
                          ),
                        ),
                        style: GoogleFonts.jetBrainsMono(
                          textStyle: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // === Quote image preview (capturable) ===
        if (result != null) ...[
          Text('Vista previa',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: RepaintBoundary(
              key: _captureKey,
              child: QuoteImageTemplate(
                output: result.output,
                label: calc.pieceName ?? '',
                discountPct: calc.discountPercentage.toStringAsFixed(0),
                showDetail: _showDetail,
                detailMaterialBreakdown: result.breakdown,
                detailElectricCost: result.electricCost,
                detailBaseCost: result.baseCost,
                detailProfitAmount: result.profitAmount,
                detailTotalFinal: result.totalFinal,
                metaGrams: result.metaGrams,
                metaTime: result.metaTime,
                companyName: settings.companyName,
                companyLogoBase64: settings.companyLogoBase64,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Toggle detail (outside RepaintBoundary)
          Align(
            child: TextButton.icon(
              icon: Icon(
                _showDetail
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
              ),
              label: Text(
                _showDetail
                    ? EsBO.calcToggleHideDetail
                    : EsBO.calcToggleShowDetail,
              ),
              onPressed: () => setState(() => _showDetail = !_showDetail),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Share / Save actions
          Center(
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _DetailActionIcon(
                  icon: Icons.ios_share_rounded,
                  tooltip: 'Compartir imagen',
                  color: color.primary,
                  isBusy: _isBusy,
                  onPressed: _isBusy ? null : _handleShare,
                ),
                _DetailActionIcon(
                  icon: Icons.download_rounded,
                  tooltip: 'Guardar imagen',
                  color: color.primary,
                  isBusy: _isBusy,
                  onPressed: _isBusy ? null : _handleSave,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // === Acciones ===
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: Icon(
                  calc.isSold
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(calc.isSold ? EsBO.calcDetailMarkPending : EsBO.calcDetailMarkSold),
                onPressed: () async {
                  await ref
                      .read(calculationsNotifierProvider.notifier)
                      .toggleSold(calc.id, !calc.isSold);
                },
              ),
            ),
          ],
        ),
        // Padding bottom para FAB.
        const SizedBox(height: 80),
      ],
      ),
    );
  }
}

/// Reconstruye [CalculationOutput] + valores detallados desde datos
/// guardados en DB + settings actuales.
///
/// Usa current settings para electricidad/ganancia — mismo approach que
/// [CalculatorNotifier._recompute] y [PrefilledCalculatorPage].
///
/// Retorna null si materials aun no cargaron.
({CalculationOutput output, List<MaterialCostBreakdown> breakdown,
  Decimal electricCost, Decimal baseCost, Decimal profitAmount,
  Decimal totalFinal, String? metaGrams, String? metaTime})?
_recomputeOutput(
  Calculation calc,
  List<CalculationMaterial> materials,
  Settings settings,
  PrinterProfile? printer,
) {
  if (materials.isEmpty && calc.materialCostSnapshot <= 0) return null;

  final materialCost =
      Decimal.parse(calc.materialCostSnapshot.toStringAsFixed(2));
  final hours = Decimal.parse(calc.totalHours.toStringAsFixed(2));
  final discountPct = calc.discountPercentage > 0
      ? Decimal.parse(calc.discountPercentage.toStringAsFixed(2))
      : Decimal.zero;

  // Per-material breakdown
  final breakdown = <MaterialCostBreakdown>[];
  var totalGrams = Decimal.zero;
  for (final m in materials) {
    final weight = Decimal.parse(m.weightGrams.toStringAsFixed(2));
    final price =
        Decimal.parse(m.pricePerBobbinSnapshot.toStringAsFixed(2));
    final grams =
        Decimal.parse(m.gramsPerBobbinSnapshot.toStringAsFixed(2));
    final cost = grams > Decimal.zero
        ? (weight * price / grams).toDecimal()
        : Decimal.zero;
    breakdown.add(MaterialCostBreakdown(label: m.label, cost: cost));
    totalGrams += weight;
  }

  // Detail values (electricity + profit) with current settings
  final watts = printer?.averageWatts ?? 0;
  final electricCost = hours > Decimal.zero && watts > 0
      ? (Decimal.fromInt(watts) * hours * settings.kwhRate /
              Decimal.fromInt(1000))
          .toDecimal()
      : Decimal.zero;
  final baseCost = materialCost + electricCost;
  final profitAmount =
      (baseCost * settings.profitBase / Decimal.fromInt(100)).toDecimal();
  final totalFinal = baseCost + profitAmount;

  // Discount on totalFinal
  final discountOnTotalFinal = discountPct > Decimal.zero
      ? (totalFinal * discountPct / Decimal.fromInt(100)).toDecimal()
      : Decimal.zero;
  final totalPrice = totalFinal - discountOnTotalFinal;

  // Meta
  final totalMinutes =
      (hours * Decimal.fromInt(60)).toBigInt();
  String? timeStr;
  if (totalMinutes > BigInt.zero) {
    final hh = totalMinutes ~/ BigInt.from(60);
    final mm = totalMinutes.remainder(BigInt.from(60));
    timeStr = '${hh.toInt()}h ${mm.toInt()}m';
  }
  final gramsStr = totalGrams > Decimal.zero
      ? '${NumberFormat.decimalPattern('es_BO').format(totalGrams.toDouble())} g'
      : null;

  return (
    output: CalculationOutput(
      materialCost: materialCost,
      discountAmount: discountOnTotalFinal,
      totalPrice: totalPrice,
    ),
    breakdown: breakdown,
    electricCost: electricCost,
    baseCost: baseCost,
    profitAmount: profitAmount,
    totalFinal: totalFinal,
    metaGrams: gramsStr,
    metaTime: timeStr,
  );
}

/// Boton circular icono, usado en la fila de acciones de imagen.
class _DetailActionIcon extends StatelessWidget {
  const _DetailActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.isBusy = false,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 22,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(AppSpacing.md),
      ),
      icon: isBusy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            )
          : Icon(icon, color: color, size: 22),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              textStyle: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _calculationByIdProvider =
    Provider.family<Calculation?, int>((ref, id) {
  final list = ref.watch(calculationsNotifierProvider).valueOrNull;
  if (list == null) return null;
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

final _materialsOfProvider =
    FutureProvider.family<List<CalculationMaterial>, int>((ref, id) {
  final repo = ref.watch(calculationRepositoryProvider);
  return repo.materialsOf(id);
});
