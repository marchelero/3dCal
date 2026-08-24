// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/export/pdf_export.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/share/quote_share.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
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
    ref.watch(localeProvider);
    final calc = ref.watch(_calculationByIdProvider(calcId));

    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.calcDetailTitle),
        actions: [
          IconButton(
            tooltip: EsBO.calcDuplicateAction,
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: calc == null
                ? null
                : () async {
                    try {
                      await ref
                          .read(calculationsNotifierProvider.notifier)
                          .duplicate(
                            calcId,
                            pieceNameSuffix: EsBO.calcDuplicateSuffix,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        AppSnackBar.success(EsBO.calcDuplicateSuccess),
                      );
                    } catch (e) {
                      if (e is HistoryCapReachedException) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            AppSnackBar.info(
                              context,
                              EsBO.historyCapReachedBody,
                              actionLabel: EsBO.calculatorGoProAction,
                              onAction: () => context.push('/paywall'),
                            ),
                          );
                        return;
                      }
                      debugPrint('Duplicate quote failed: $e');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        AppSnackBar.error(EsBO.calcDuplicateError),
                      );
                    }
                  },
          ),
          IconButton(
            tooltip: EsBO.calcDetailDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: calc == null
                ? null
                : () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: EsBO.calcDetailDeleteTitle,
                      message: EsBO.calcDetailDeleteConfirm,
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
              label: Text(EsBO.calcDetailReuse),
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
  int _quantity = 1;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.calcShareError}: $e'));
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
      final msg = kIsWeb
          ? EsBO.commonImageDownloaded
          : EsBO.commonImageSavedGallery;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.success(msg));
    } on ShareQuoteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(e.message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.calcShareError}: $e'));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleSharePdf() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final calc = widget.calc;
      final materialsAsync = ref.read(_materialsOfProvider(calc.id));
      final materials = materialsAsync.value ?? <CalculationMaterial>[];
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.value ?? Settings.defaults;
      final printer = ref.read(activePrinterProvider);
      final result = _recomputeOutput(calc, materials, settings, printer);
      if (result == null) return;
      await shareQuotePdf(
        isPro: ref.read(isProProvider),
        output: result.output,
        materials: result.breakdown,
        totalHours: Decimal.parse(calc.totalHours.toStringAsFixed(2)),
        discountPct: Decimal.parse(calc.discountPercentage.toStringAsFixed(2)),
        showDetail: _showDetail,
        companyName: settings.companyName,
        companyLogoBase64: settings.companyLogoBase64,
        pieceName: calc.pieceName,
        clientName: calc.clientName,
        quoteNumber: calc.id,
        quoteDate: calc.createdAt.toLocal(),
        validUntil: calc.createdAt.toLocal().add(
          const Duration(days: kQuoteValidDays),
        ),
        notes: calc.notes,
        conditions: calc.conditions,
      );
    } catch (e) {
      debugPrint('Quote PDF share failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error(EsBO.commonPdfExportError));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handlePrint() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final calc = widget.calc;
      final materialsAsync = ref.read(_materialsOfProvider(calc.id));
      final materials = materialsAsync.value ?? <CalculationMaterial>[];
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.value ?? Settings.defaults;
      final printer = ref.read(activePrinterProvider);
      final result = _recomputeOutput(calc, materials, settings, printer);
      if (result == null) return;
      final pdfBytes = await buildQuotePdfBytes(
        isPro: ref.read(isProProvider),
        output: result.output,
        materials: result.breakdown,
        totalHours: Decimal.parse(calc.totalHours.toStringAsFixed(2)),
        discountPct: Decimal.parse(calc.discountPercentage.toStringAsFixed(2)),
        showDetail: _showDetail,
        companyName: settings.companyName,
        companyLogoBase64: settings.companyLogoBase64,
        pieceName: calc.pieceName,
        clientName: calc.clientName,
        quoteNumber: calc.id,
        quoteDate: calc.createdAt.toLocal(),
        validUntil: calc.createdAt.toLocal().add(
          const Duration(days: kQuoteValidDays),
        ),
        notes: calc.notes,
        conditions: calc.conditions,
      );
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      debugPrint('Quote PDF print failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error(EsBO.commonPrintError));
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
    final currency = ref.watch(selectedCurrencyProvider);
    final printer = ref.watch(activePrinterProvider);

    final materials = materialsAsync.value ?? <CalculationMaterial>[];
    final settings = settingsAsync.value ?? Settings.defaults;

    // Recompute output + detail values from stored data + current settings.
    final result = _recomputeOutput(calc, materials, settings, printer);

    return MaxWidthScrollView(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        shrinkWrap: true,
        children: [
          // === Header card (hero) ===
          // Sin Hero: el vuelo desde el icono 44x44 de la lista hacia este
          // card grande encajaba el contenido en el frame inicial del flight
          // y producia RenderFlex overflow al entrar al detalle.
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
                mainAxisSize: MainAxisSize.min,
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
                          label: Text(EsBO.calcDetailSold),
                          backgroundColor: color.tertiaryContainer,
                          labelStyle: TextStyle(
                            color: color.onTertiaryContainer,
                          ),
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
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: color.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${EsBO.calcDialogClient}: ${calc.clientName}',
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
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          DateFormat(
                            'dd MMM yyyy · HH:mm',
                          ).format(calc.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                      if (calc.totalHours > 0) ...[
                        const SizedBox(width: AppSpacing.lg),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: color.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${calc.totalHours.toStringAsFixed(1)} h',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
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
          Text(
            EsBO.calcSectionMaterials,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          materialsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('${EsBO.commonError}: $e'),
            data: (ms) {
              if (ms.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      EsBO.calcNoMaterials,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (var i = 0; i < ms.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
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
                                  Text(
                                    ms[i].label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    '${ms[i].weightGrams.toStringAsFixed(0)} g · '
                                    'BOB ${ms[i].pricePerBobbinSnapshot.toStringAsFixed(2)} / '
                                    '${ms[i].gramsPerBobbinSnapshot.toStringAsFixed(0)} g',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              // BUG-009-display fix: guard contra division
                              // por cero (gramsPerBobbinSnapshot == 0 en datos
                              // legacy/corruptos) que producia Infinity/NaN.
                              formatCurrency(
                                ms[i].gramsPerBobbinSnapshot <= 0
                                    ? Decimal.zero
                                    : Decimal.parse(
                                        (ms[i].weightGrams *
                                                ms[i].pricePerBobbinSnapshot /
                                                ms[i].gramsPerBobbinSnapshot)
                                            .toStringAsFixed(2),
                                      ),
                                currency,
                              ),
                              style: GoogleFonts.jetBrainsMono(
                                textStyle: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
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
          Text(
            EsBO.detailBreakdown,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _Row(
                    label: EsBO.calcDetailMaterial,
                    value: formatCurrency(
                      Decimal.parse(
                        calc.materialCostSnapshot.toStringAsFixed(2),
                      ),
                      currency,
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
                            EsBO.detailDiscountPct(
                              calc.discountPercentage.round(),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: color.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            // BUG-001 fix: el descuento real se calcula sobre
                            // totalFinal (no materialCost) — debe coincidir con
                            // calculation_engine.dart:84 para que el cliente
                            // vea el mismo numero en el detalle y en el PDF.
                            // totalFinal = baseCost + failureCost + markupCost
                            //              + profitAmount (ver F1 engine).
                            '-${formatCurrency(Decimal.parse(((calc.baseCostSnapshot + calc.failureCostSnapshot + calc.markupCostSnapshot + calc.profitAmountSnapshot) * calc.discountPercentage / 100).toStringAsFixed(2)), currency)}',
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
                        EsBO.calcDetailTotal,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatCurrency(
                            Decimal.parse(
                              calc.totalPriceSnapshot.toStringAsFixed(2),
                            ),
                            currency,
                          ),
                          style: GoogleFonts.jetBrainsMono(
                            textStyle: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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

          // === Selector PRO de Cantidad ===
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Cantidad de Piezas',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            if (!ref.watch(isProProvider)) const ProBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cotizar por lote / volumen',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: _quantity > 1
                        ? () {
                            if (!ref.read(isProProvider)) {
                              context.push('/paywall');
                            } else {
                              setState(() => _quantity--);
                            }
                          }
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      '$_quantity',
                      style: AppTheme.num(
                        theme.textTheme.titleMedium ?? const TextStyle(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      if (!ref.read(isProProvider)) {
                        context.push('/paywall');
                      } else {
                        setState(() => _quantity++);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // === Quote image preview (capturable) ===
          if (result != null) ...[
            Text(
              EsBO.detailPreview,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  detailLaborCost: result.laborCost,
                  detailPostProcessCost: result.postProcessCost,
                  detailBaseCost: result.baseCost,
                  detailFailureCost: result.failureCost,
                  detailMarkupCost: result.markupCost,
                  detailProfitAmount: result.profitAmount,
                  detailTotalFinal: result.totalFinal,
                  metaGrams: result.metaGrams,
                  metaTime: result.metaTime,
                  companyName: settings.companyName,
                  companyLogoBase64: settings.companyLogoBase64,
                  currency: currency,
                  quantity: _quantity,
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
                    icon: Icons.share_rounded,
                    tooltip: EsBO.calcBtnShare,
                    color: color.primary,
                    isBusy: _isBusy,
                    onPressed: _isBusy ? null : _handleShare,
                  ),
                  _DetailActionIcon(
                    icon: Icons.download_rounded,
                    tooltip: EsBO.commonSaveImage,
                    color: color.primary,
                    isBusy: _isBusy,
                    onPressed: _isBusy ? null : _handleSave,
                  ),
                  _DetailActionIcon(
                    icon: Icons.picture_as_pdf_rounded,
                    tooltip: EsBO.commonExportPdf,
                    color: color.error,
                    isBusy: _isBusy,
                    onPressed: _isBusy ? null : _handleSharePdf,
                  ),
                  _DetailActionIcon(
                    icon: Icons.print_rounded,
                    tooltip: EsBO.commonPrint,
                    color: AppTheme.greenSuccess,
                    isBusy: _isBusy,
                    onPressed: _isBusy ? null : _handlePrint,
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
                  label: Text(
                    calc.isSold
                        ? EsBO.calcDetailMarkPending
                        : EsBO.calcDetailMarkSold,
                  ),
                  onPressed: () async {
                    await ref
                        .read(calculationsNotifierProvider.notifier)
                        .toggleSold(calc.id, !calc.isSold);
                  },
                ),
              ),
            ],
          ),
          // Padding bottom para FAB + bottom inset.
          SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Reconstruye [CalculationOutput] + valores detallados desde datos
/// guardados en DB + settings actuales.
///
/// Usa current settings para electricidad/ganancia — mismo approach que
/// [CalculatorNotifier._recompute] y el prefill de CalculatorPage.
///
/// Retorna null si materials aun no cargaron.
({
  CalculationOutput output,
  List<MaterialCostBreakdown> breakdown,
  Decimal electricCost,
  Decimal laborCost,
  Decimal postProcessCost,
  Decimal baseCost,
  Decimal failureCost,
  Decimal markupCost,
  Decimal profitAmount,
  Decimal totalFinal,
  String? metaGrams,
  String? metaTime,
})?
_recomputeOutput(
  Calculation calc,
  List<CalculationMaterial> materials,
  Settings settings,
  PrinterProfile? printer,
) {
  if (materials.isEmpty && calc.materialCostSnapshot <= 0) return null;

  final materialCost = Decimal.parse(
    calc.materialCostSnapshot.toStringAsFixed(2),
  );
  final hours = Decimal.parse(calc.totalHours.toStringAsFixed(2));
  final discountPct = calc.discountPercentage > 0
      ? Decimal.parse(calc.discountPercentage.toStringAsFixed(2))
      : Decimal.zero;

  // Per-material breakdown
  final breakdown = <MaterialCostBreakdown>[];
  var totalGrams = Decimal.zero;
  for (final m in materials) {
    final weight = Decimal.parse(m.weightGrams.toStringAsFixed(2));
    final price = Decimal.parse(m.pricePerBobbinSnapshot.toStringAsFixed(2));
    final grams = Decimal.parse(m.gramsPerBobbinSnapshot.toStringAsFixed(2));
    final cost = grams > Decimal.zero
        ? (weight * price / grams).toDecimal(scaleOnInfinitePrecision: 12)
        : Decimal.zero;
    breakdown.add(MaterialCostBreakdown(label: m.label, cost: cost));
    totalGrams += weight;
  }

  // F1 formula with current settings + snapshots
  final watts = printer?.averageWatts ?? 0;
  final electricCost = hours > Decimal.zero && watts > 0
      ? (Decimal.fromInt(watts) *
                hours *
                settings.kwhRate /
                Decimal.fromInt(1000))
            .toDecimal()
      : Decimal.zero;
  final laborCost = hours * settings.laborRate;
  final postProcessCost = settings.postProcessRate > Decimal.zero
      ? (materialCost * settings.postProcessRate / Decimal.fromInt(100))
            .toDecimal()
      : Decimal.zero;
  final baseCost = materialCost + electricCost + laborCost + postProcessCost;
  final failureCost = settings.failureRate > Decimal.zero
      ? (baseCost * settings.failureRate / Decimal.fromInt(100)).toDecimal()
      : Decimal.zero;
  final costWithFailure = baseCost + failureCost;
  final markupCost = settings.markupOnMaterials > Decimal.zero
      ? (materialCost * settings.markupOnMaterials / Decimal.fromInt(100))
            .toDecimal()
      : Decimal.zero;
  final totalBeforeProfit = costWithFailure + markupCost;
  final profitAmount = settings.profitBase > Decimal.zero
      ? (totalBeforeProfit * settings.profitBase / Decimal.fromInt(100))
            .toDecimal()
      : Decimal.zero;
  final totalFinal = totalBeforeProfit + profitAmount;

  // Discount on totalFinal
  final discountOnTotalFinal = discountPct > Decimal.zero
      ? (totalFinal * discountPct / Decimal.fromInt(100)).toDecimal()
      : Decimal.zero;
  final totalPrice = totalFinal - discountOnTotalFinal;

  final output = CalculationOutput(
    materialCost: materialCost,
    electricCost: electricCost,
    laborCost: laborCost,
    postProcessCost: postProcessCost,
    baseCost: baseCost,
    failureCost: failureCost,
    costWithFailure: costWithFailure,
    markupCost: markupCost,
    totalBeforeProfit: totalBeforeProfit,
    profitAmount: profitAmount,
    totalFinal: totalFinal,
    discountAmount: discountOnTotalFinal,
    totalPrice: totalPrice,
    totalOriginal: totalFinal,
  );

  // Meta
  final totalMinutes = (hours * Decimal.fromInt(60)).toBigInt();
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
    output: output,
    breakdown: breakdown,
    electricCost: electricCost,
    laborCost: laborCost,
    postProcessCost: postProcessCost,
    baseCost: baseCost,
    failureCost: failureCost,
    markupCost: markupCost,
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
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(AppSpacing.md),
      ),
      icon: isBusy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
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

final _calculationByIdProvider = Provider.family<Calculation?, int>((ref, id) {
  final list = ref.watch(calculationsNotifierProvider).value;
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
