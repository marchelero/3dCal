// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/export/pdf_export.dart';
import '../../../../core/export/pdf_rate_audit.dart';
import '../../../../core/export/quote_report_variant.dart';
import '../../../../core/money/currency.dart';
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
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/partial_save_badge.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../../../settings/domain/discount_tier.dart';
import '../../../settings/domain/settings.dart';
import '../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../domain/batch_discount_resolver.dart';
import '../../domain/calculation_engine.dart';
import '../../domain/entities/calculation_output.dart';
import '../../domain/lot_totals.dart';
import '../notifiers/calculations_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/quote_image_template.dart';
import '../widgets/report_variant_selector.dart';

/// Cifras del lote resueltas por [_DetailState._lotFigures]: fuente unica
/// del hero, el desglose, la imagen y el PDF del detalle (HIGH-01/02,
/// MED-10 de la auditoria 2026-10-04).
typedef _LotFigures =
    ({
      Decimal unitTotal,
      Decimal batchPct,
      Decimal batchAmount,
      Decimal lotTotal,
      Decimal manualAmount,
    });

/// Detalle de una cotizacion guardada (readonly).
///
/// Nueva vista centrada en el resumen de lo que tuvo la cotizacion:
/// hero con foto + total efectivo, KPIs (tiempo/peso/ganancia), desglose
/// completo, materiales, notas/condiciones y el reporte exportable.
class CalculationDetailPage extends ConsumerWidget {
  const CalculationDetailPage({super.key, required this.calcId});

  final int calcId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final calcAsync = ref.watch(_calculationByIdProvider(calcId));

    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.calcDetailTitle),
        // Editar disponible para TODA cotizacion (borradora o definitiva).
        // Antes solo el banner de borrador tenia boton Editar, asi que una
        // cotizacion ya guardada no se podia editar desde el detalle.
        actions: [
          if (calcAsync.value != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: EsBO.calcEditAction,
              onPressed: () => unawaited(
                context.push('/calculator/edit', extra: calcAsync.value),
              ),
            ),
        ],
      ),
      body: calcAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: EsBO.historyErrorLoad,
          details: e.toString(),
          onRetry: () => ref.invalidate(_calculationByIdProvider(calcId)),
        ),
        data: (c) => c == null ? const Center(child: Text('—')) : _Detail(calc: c),
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

  /// Variante del reporte (pantalla, PDF, PNG e impresion) elegida para esta
  /// cotizacion. Se deriva del modo guardado: el selector solo ofrece las 2
  /// variantes del eje correspondiente.
  late QuoteReportVariant _reportVariant = (widget.calc.isAdvanced
      ? QuoteReportVariant.clientAdvanced
      : QuoteReportVariant.clientSimple);

  /// Cantidad mostrada/editable (lotes). Arranca con la cantidad guardada para
  /// que preview/export coincidan con lo saved.
  late int _quantity = widget.calc.quantity < 1 ? 1 : widget.calc.quantity;
  late final TextEditingController _quantityCtrl = TextEditingController(
    text: '$_quantity',
  );

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  // === Handlers de exportacion ===

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

  /// Genera el PDF de la cotizacion y abre el menu de compartir (mail,
  /// WhatsApp, etc.). Distinto de "Imprimir": mismo PDF, pero aca se envia
  /// a otra app en vez de ir a la impresora. Gratis (PRD SC6); en Free sale
  /// con branding "3dCalc".
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
      // PDF con precio UNITARIO. El PDF maneja quantity para display.
      final result = _recomputeOutput(
        calc,
        materials,
        settings,
        printer,
        quantity: 1,
      );
      if (result == null) return;
      final totalGrams = materials.fold(
        Decimal.zero,
        (Decimal sum, m) => sum + _money(m.weightGrams),
      );
      final timedMaterials = _pdfMaterialBreakdown(materials, result.breakdown);
      // HIGH-01/MED-10: mismo calculo de lote que la pantalla.
      final lot = _lotFigures(
        calc: calc,
        settings: settings,
        tiers: _currentTiers(),
        unitOutput: result.output,
      );

      await shareQuotePdf(
        isPro: ref.read(isProProvider),
        output: result.output,
        materials: result.breakdown,
        totalHours: _money(calc.totalHours),
        discountPct: _money(calc.discountPercentage),
        currency: ref.read(selectedCurrencyProvider),
        variant: _reportVariant,
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
        pieceImageBytes: calc.pieceImageBlob,
        metaGrams: result.metaGrams,
        metaTime: result.metaTime,
        materialMetaBreakdown: timedMaterials,
        quantity: _quantity,
        totalGrams: totalGrams,
        batchDiscountPct: lot.batchPct > Decimal.zero ? lot.batchPct : null,
        batchDiscountAmount: lot.batchAmount > Decimal.zero
            ? lot.batchAmount
            : null,
        lotTotal: lot.lotTotal,
        manualDiscountAmount: lot.manualAmount,
        rateAudit: result.rateAudit,
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
      final result = _recomputeOutput(
        calc,
        materials,
        settings,
        printer,
        quantity: 1,
      );
      if (result == null) return;
      final totalGrams = materials.fold(
        Decimal.zero,
        (Decimal sum, m) => sum + _money(m.weightGrams),
      );
      // HIGH-01/MED-10: mismo calculo de lote que la pantalla.
      final lot = _lotFigures(
        calc: calc,
        settings: settings,
        tiers: _currentTiers(),
        unitOutput: result.output,
      );
      final pdfBytes = await buildQuotePdfBytes(
        isPro: ref.read(isProProvider),
        output: result.output,
        materials: result.breakdown,
        totalHours: _money(calc.totalHours),
        discountPct: _money(calc.discountPercentage),
        currency: ref.read(selectedCurrencyProvider),
        variant: _reportVariant,
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
        pieceImageBytes: calc.pieceImageBlob,
        metaGrams: result.metaGrams,
        metaTime: result.metaTime,
        materialMetaBreakdown: _pdfMaterialBreakdown(
          materials,
          result.breakdown,
        ),
        quantity: _quantity,
        totalGrams: totalGrams,
        batchDiscountPct: lot.batchPct > Decimal.zero ? lot.batchPct : null,
        batchDiscountAmount: lot.batchAmount > Decimal.zero
            ? lot.batchAmount
            : null,
        lotTotal: lot.lotTotal,
        manualDiscountAmount: lot.manualAmount,
        rateAudit: result.rateAudit,
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

  /// Desglose por material para el PDF (v15).
  List<PdfMaterialMetaItem> _pdfMaterialBreakdown(
    List<CalculationMaterial> materials,
    List<MaterialCostBreakdown> unitCosts,
  ) {
    return [
      for (var i = 0; i < materials.length; i++)
        PdfMaterialMetaItem(
          label: materials[i].label,
          weightGrams:
              '${NumberFormat.decimalPattern('es_BO').format(materials[i].weightGrams)} g',
          timeStr: (materials[i].useOwnTime ?? false)
              ? _timeTextFromMinutes(
                  (materials[i].materialHours ?? 0) * 60 +
                      (materials[i].materialMinutes ?? 0),
                )
              : null,
          unitCost: i < unitCosts.length ? unitCosts[i].cost : null,
        ),
    ];
  }

  static String? _timeTextFromMinutes(double totalMinutes) {
    final rounded = totalMinutes.round();
    if (rounded <= 0) return null;
    return '${rounded ~/ 60}h ${rounded % 60}m';
  }

  // === Build ===

  /// Numeros del lote para la cantidad mostrada (HIGH-01/MED-10).
  ///
  /// Con la cantidad ORIGINAL guardada usa el monto de escalón persistido
  /// (fidelidad al historial). Con cantidad editada (solo Pro) resuelve el
  /// escalón vigente para la nueva N sobre los costos base snapshot — el
  /// descuento guardado de otra cantidad ya no aplica.
  _LotFigures _lotFigures({
    required Calculation calc,
    required Settings settings,
    required List<DiscountTier> tiers,
    required CalculationOutput? unitOutput,
  }) {
    final n = _quantity < 1 ? 1 : _quantity;
    final qtyD = Decimal.fromInt(n);
    final unitTotal = _money(calc.totalPriceSnapshot);
    final savedQty = calc.quantity < 1 ? 1 : calc.quantity;
    final Decimal batchPct;
    final Decimal batchAmount;
    if (n == savedQty) {
      batchAmount = LotTotals.parseBatchAmount(calc.batchDiscountAmount);
      batchPct =
          Decimal.tryParse(calc.batchDiscountPercent ?? '') ?? Decimal.zero;
    } else {
      final tier = BatchDiscountResolver.resolve(quantity: n, tiers: tiers);
      batchPct = tier?.percent ?? Decimal.zero;
      batchAmount = LotTotals.batchAmount(
        base: _money(calc.baseCostSnapshot),
        failure: _money(calc.failureCostSnapshot),
        markup: _money(calc.markupCostSnapshot),
        pct: batchPct,
        quantity: n,
      );
    }
    // HIGH-03: el piso usa el snapshot real (filas F2+); las viejas (0)
    // caen al Settings actual, misma politica que `resolveRates`.
    final minimumCharge = calc.minimumChargeSnapshot > 0
        ? _money(calc.minimumChargeSnapshot)
        : settings.minimumCharge;
    final lotTotal = LotTotals.total(
      unitTotal: unitTotal,
      quantity: n,
      batchDiscount: batchAmount,
      minimumCharge: minimumCharge,
    );
    return (
      unitTotal: unitTotal,
      batchPct: batchPct,
      batchAmount: batchAmount,
      lotTotal: lotTotal,
      manualAmount: (unitOutput?.discountAmount ?? Decimal.zero) * qtyD,
    );
  }

  /// Tiers vigentes para [_lotFigures] (sync con Settings → escalones).
  List<DiscountTier> _currentTiers() =>
      ref.read(discountTiersProvider).value ?? const <DiscountTier>[];

  @override
  Widget build(BuildContext context) {
    final calc = widget.calc;
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final materialsAsync = ref.watch(_materialsOfProvider(calc.id));
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final printer = ref.watch(activePrinterProvider);
    final isPro = ref.watch(isProProvider);

    final materials = materialsAsync.value ?? <CalculationMaterial>[];
    final settings = settingsAsync.value ?? Settings.defaults;
    final result = _recomputeOutput(calc, materials, settings, printer);

    final qtyD = Decimal.fromInt(_quantity);
    // Valores UNITARIOS guardados como snapshot (fieles al historial).
    // HIGH-01 fix (auditoria 2026-10-04): el TOTAL efectivo resta el
    // descuento mayorista del lote (y re-resuelve el escalon si la
    // cantidad fue editada) — antes mostraba `unit x qty` inflado vs la
    // calculadora en vivo y el PDF.
    final lot = _lotFigures(
      calc: calc,
      settings: settings,
      tiers: ref.watch(discountTiersProvider).value ?? const <DiscountTier>[],
      unitOutput: result?.output,
    );
    final unitTotal = lot.unitTotal;
    final effectiveTotal = lot.lotTotal;
    final materialUnit = _money(calc.materialCostSnapshot);
    final electricUnit = _money(calc.electricCostSnapshot);
    final amortizationUnit = _money(calc.amortizationCostSnapshot);
    final laborUnit = _money(calc.laborCostSnapshot);
    final postProcessUnit = _money(calc.postProcessCostSnapshot);
    final extrasUnit = result?.extrasCost ?? Decimal.zero;
    final baseUnit = _money(calc.baseCostSnapshot);
    final failureUnit = _money(calc.failureCostSnapshot);
    final markupUnit = _money(calc.markupCostSnapshot);
    final profitUnit = _money(calc.profitAmountSnapshot);
    final discountUnit = result?.output.discountAmount ?? Decimal.zero;

    final totalGrams = materials.fold<Decimal>(
      Decimal.zero,
      (sum, m) => sum + _money(m.weightGrams),
    ) * qtyD;
    final totalMinutes =
        CalculatorState.decimalHoursToMinutes(_money(calc.totalHours)) *
            _quantity;
    final timeText = _formatMinutes(totalMinutes);
    final profit = profitUnit * qtyD;

    return Column(
      children: [
        Expanded(
          child: MaxWidthScrollView(
            maxWidth: 720,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                if (calc.isPartial) ...[
                  _PartialBanner(
                    // Habilitado solo mientras siga siendo borrador (no
                    // guardado con Guardar -> cliente + notas).
                    onEdit: calc.isPartial
                        ? () => unawaited(
                            context.push('/calculator/edit', extra: calc),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _HeroCard(
                  calc: calc,
                  currency: currency,
                  unitTotal: unitTotal,
                  effectiveTotal: effectiveTotal,
                  quantity: _quantity,
                  printerName: calc.printerNameSnapshot ?? printer?.name,
                ),
                const SizedBox(height: AppSpacing.md),
                _quantityCard(context, isPro),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.timer_outlined,
                        value: timeText,
                        label: EsBO.pdfSummaryTotalTime,
                        color: color.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.monitor_weight_outlined,
                        value: '${_formatGrams(totalGrams)} g',
                        label: EsBO.pdfSummaryTotalWeight,
                        color: color.tertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.trending_up_rounded,
                        value: formatCurrency(profit, currency),
                        label: EsBO.calcDetailProfit,
                        color: color.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  icon: Icons.receipt_long_outlined,
                  title: EsBO.detailBreakdown,
                  semanticLabel: EsBO.detailBreakdown,
                  child: Column(
                    children: [
                      _Row(
                        label: EsBO.calcDetailMaterial,
                        value: formatCurrency(materialUnit * qtyD, currency),
                      ),
                      if (materials.length > 1)
                        for (final m in result?.breakdown ??
                            const <MaterialCostBreakdown>[])
                          _Row(
                            label: m.label,
                            value: formatCurrency(m.cost * qtyD, currency),
                            indent: true,
                          ),
                      _Row(
                        label: EsBO.calcDetailEnergy,
                        value: formatCurrency(electricUnit * qtyD, currency),
                      ),
                      if (amortizationUnit > Decimal.zero)
                        _Row(
                          label: EsBO.calcDetailAmortization,
                          value: formatCurrency(
                            amortizationUnit * qtyD,
                            currency,
                          ),
                        ),
                      if (laborUnit > Decimal.zero)
                        _Row(
                          label: EsBO.calcDetailModeling,
                          value: formatCurrency(laborUnit * qtyD, currency),
                        ),
                      if (postProcessUnit > Decimal.zero)
                        _Row(
                          label: EsBO.calcDetailPostProcess,
                          value: formatCurrency(postProcessUnit * qtyD, currency),
                        ),
                      if (extrasUnit > Decimal.zero)
                        _Row(
                          label: calc.extraLabel.isNotEmpty
                              ? '${EsBO.calcExtraExtras} (${calc.extraLabel})'
                              : EsBO.calcExtraExtras,
                          value: formatCurrency(extrasUnit * qtyD, currency),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      _Row(
                        label: EsBO.calcDetailBase,
                        value: formatCurrency(baseUnit * qtyD, currency),
                        emphasis: true,
                      ),
                      if (failureUnit > Decimal.zero)
                        _Row(
                          label: EsBO.calcDetailFailure,
                          value: formatCurrency(failureUnit * qtyD, currency),
                        ),
                      if (markupUnit > Decimal.zero)
                        _Row(
                          label: EsBO.calcDetailMarkup,
                          value: formatCurrency(markupUnit * qtyD, currency),
                        ),
                      _Row(
                        label: EsBO.calcDetailProfit,
                        value: formatCurrency(profitUnit * qtyD, currency),
                        color: color.primary,
                        emphasis: true,
                      ),
                      // HIGH-01 fix: fila del escalon mayorista (antes el
                      // desglose "sumaba" al total inflado sin mostrarla).
                      if (lot.batchAmount > Decimal.zero)
                        _Row(
                          label: EsBO.calcDetailBatchDiscount(
                            lot.batchPct.toDouble().round(),
                          ),
                          value: '-${formatCurrency(lot.batchAmount, currency)}',
                          color: color.error,
                        ),
                      if (discountUnit > Decimal.zero)
                        _Row(
                          label:
                              '${EsBO.calcLabelDiscount} (${calc.discountPercentage.round()}%)',
                          value:
                              '-${formatCurrency(discountUnit * qtyD, currency)}',
                          color: color.error,
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      _Row(
                        label: _quantity > 1
                            ? '${EsBO.calcDetailTotal} ($_quantity u.)'
                            : EsBO.calcDetailTotal,
                        value: formatCurrency(effectiveTotal, currency),
                        big: true,
                        emphasis: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _materialsCard(context, materials, currency),
                if ((calc.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    icon: Icons.sticky_note_2_outlined,
                    title: EsBO.pdfNotesTitle,
                    child: Text(
                      calc.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                if ((calc.conditions ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    icon: Icons.gavel_rounded,
                    title: EsBO.pdfConditionsTitle,
                    child: Text(
                      calc.conditions!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _reportCard(calc, materials, result, currency, settings, lot),
                SizedBox(
                  height: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        ),
        _footer(context),
      ],
    );
  }

  // === Secciones ===

  Widget _quantityCard(BuildContext context, bool isPro) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Card(
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
                        EsBO.detailQuantityLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (!isPro) const ProBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    EsBO.detailQuantitySubtitle,
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
                      if (!isPro) {
                        context.push('/paywall');
                      } else {
                        setState(() => _quantity--);
                        _quantityCtrl.text = '$_quantity';
                      }
                    }
                  : null,
            ),
            SizedBox(
              width: 64,
              child: TextFormField(
                key: const ValueKey('detail_quantity_input'),
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTheme.num(
                  theme.textTheme.titleMedium ?? const TextStyle(),
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  border: OutlineInputBorder(),
                  suffixText: 'u.',
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed == null) return; // texto intermedio ("", "0x")
                  final clamped = parsed.clamp(1, kMaxQuantity);
                  if (clamped == _quantity) return;
                  // MED-10 fix (auditoria 2026-10-04): el gate Pro estaba en
                  // los botones +/- pero no en el teclado; un Free tipeaba
                  // "10" y veia total x10. Se rechaza la edicion y se
                  // re-sincroniza el controller con la cantidad guardada.
                  if (!isPro) {
                    _quantityCtrl.text = '$_quantity';
                    context.push('/paywall');
                    return;
                  }
                  setState(() => _quantity = clamped);
                },
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                if (!isPro) {
                  context.push('/paywall');
                } else {
                  setState(() => _quantity++);
                  _quantityCtrl.text = '$_quantity';
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _materialsCard(
    BuildContext context,
    List<CalculationMaterial> materials,
    WorldCurrency currency,
  ) {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.category_outlined,
      title: EsBO.calcSectionMaterials,
      child: materials.isEmpty
          ? Text(
              EsBO.calcNoMaterials,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < materials.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 44, endIndent: 8),
                  _MaterialTile(
                    index: i + 1,
                    material: materials[i],
                    currency: currency,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _reportCard(
    Calculation calc,
    List<CalculationMaterial> materials,
    ({
      CalculationOutput output,
      List<MaterialCostBreakdown> breakdown,
      Decimal electricCost,
      Decimal amortizationCost,
      Decimal laborCost,
      Decimal postProcessCost,
      Decimal extrasCost,
      Decimal baseCost,
      Decimal failureCost,
      Decimal markupCost,
      Decimal profitAmount,
      Decimal totalFinal,
      String? metaGrams,
      String? metaTime,
      PdfRateAudit rateAudit,
    })?
    result,
    WorldCurrency currency,
    Settings settings,
    _LotFigures lot,
  ) {
    return SectionCard(
      icon: Icons.picture_as_pdf_outlined,
      title: EsBO.detailReportTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportVariantSelector(
            selected: _reportVariant,
            isAdvanced: calc.isAdvanced,
            onChanged: (v) => setState(() => _reportVariant = v),
          ),
          if (result != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: RepaintBoundary(
                key: _captureKey,
                child: QuoteImageTemplate(
                  output: result.output,
                  label: calc.pieceName ?? '',
                  discountPct: calc.discountPercentage.toStringAsFixed(0),
                  variant: _reportVariant,
                  detailMaterialBreakdown: result.breakdown,
                  materialMetaBreakdown: _pdfMaterialBreakdown(
                    materials,
                    result.breakdown,
                  ),
                  rateAudit: result.rateAudit,
                  detailElectricCost: result.electricCost,
                  detailAmortizationCost: result.amortizationCost,
                  detailLaborCost: result.laborCost,
                  detailPostProcessCost: result.postProcessCost,
                  detailExtrasCost: result.extrasCost,
                  extraLabel: calc.extraLabel,
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
                  pieceImageBytes: calc.pieceImageBlob,
                  // HIGH-02 fix (auditoria 2026-10-04): antes no se pasaba
                  // `lotTotal` ni `manualDiscountAmount` y el template
                  // reconstruia Subtotal/Total inflados (sumaba un escalon
                  // que nunca habia restado). Ahora recibe los MISMOS
                  // numeros que la pantalla y el PDF (_lotFigures).
                  batchDiscountPct: lot.batchPct > Decimal.zero
                      ? lot.batchPct
                      : null,
                  batchDiscountAmount: lot.batchAmount > Decimal.zero
                      ? lot.batchAmount
                      : null,
                  lotTotal: lot.lotTotal,
                  manualDiscountAmount: lot.manualAmount,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Acciones de export agrupadas 2x2 por tipo:
          //   PDF    → Compartir PDF · Imprimir
          //   Imagen → Compartir img · Guardar img
          // (antes: 1 full-width + fila de 3; ocupaba mucho espacio vertical).
          Row(
            children: [
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: EsBO.detailActionShareReport,
                  isBusy: _isBusy,
                  // HIGH-04 fix (auditoria 2026-10-04): el PRD de monetizacion
                  // (SC6 + matriz de features) dice "Export PDF disponible en
                  // FREE (con branding 3dCalc)". El gate de Pro aca
                  // contradecia la PRD y era inconsistente con la calculadora
                  // (result_sheet) y con "Imprimir" (sin gate). Se quita.
                  onPressed: _isBusy
                      ? null
                      : () => unawaited(_handleSharePdf()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.print_rounded,
                  label: EsBO.commonPrint,
                  isBusy: _isBusy,
                  onPressed: _isBusy ? null : _handlePrint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.share_rounded,
                  label: EsBO.calcBtnShare,
                  isBusy: _isBusy,
                  onPressed: _isBusy ? null : _handleShare,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailActionButton(
                  icon: Icons.download_rounded,
                  label: EsBO.commonSaveImage,
                  isBusy: _isBusy,
                  onPressed: _isBusy ? null : _handleSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Elimina la cotizacion (con confirmacion) y vuelve al historial.
  Future<void> _handleDelete() async {
    final confirm = await showConfirmDialog(
      context,
      title: EsBO.calcDetailDeleteTitle,
      message: EsBO.calcDetailDeleteConfirm,
    );
    if (!confirm || !mounted) return;
    try {
      await ref
          .read(calculationsNotifierProvider.notifier)
          .delete(widget.calc.id);
      if (mounted) context.pop();
    } catch (e) {
      // Sin esto el `unawaited(_handleDelete())` del footer se tragaba el
      // error: el usuario tocaba "Eliminar", no pasaba nada y no volvia.
      debugPrint('Quote delete failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.commonErrorGeneric));
    }
  }

  /// Alterna vendida/pendiente e invalida el provider del detalle.
  void _handleToggleSold() {
    final calc = widget.calc;
    unawaited(
      ref
          .read(calculationsNotifierProvider.notifier)
          .toggleSold(calc.id, !calc.isSold),
    );
    ref.invalidate(_calculationByIdProvider(calc.id));
  }

  /// Barra inferior fija con 3 acciones, solo iconos con micro-descripcion.
  /// Orden: Reusar · Marcar vendida · Eliminar. Todos usan el color por
  /// defecto de la barra (sin dorado ni rojo) para verse uniformes.
  /// "Editar" vive en el banner de borrador (arriba) y los exports del
  /// reporte (compartir/guardar imagen e imprimir) en su seccion.
  Widget _footer(BuildContext context) {
    final calc = widget.calc;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FooterAction(
                    icon: Icons.replay_rounded,
                    label: EsBO.calcDetailReuse,
                    onPressed: () => unawaited(
                      context.push('/calculator/prefill', extra: calc),
                    ),
                  ),
                ),
                Expanded(
                  child: _FooterAction(
                    icon: calc.isSold
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    label: calc.isSold
                        ? EsBO.calcDetailMarkPending
                        : EsBO.calcDetailMarkSold,
                    onPressed: _handleToggleSold,
                  ),
                ),
                Expanded(
                  child: _FooterAction(
                    icon: Icons.delete_outline_rounded,
                    label: EsBO.calcDetailDelete,
                    onPressed: () => unawaited(_handleDelete()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero del detalle: foto (si hay) + nombre + cliente + fecha + total efectivo.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.calc,
    required this.currency,
    required this.unitTotal,
    required this.effectiveTotal,
    required this.quantity,
    this.printerName,
  });

  final Calculation calc;
  final WorldCurrency currency;
  final Decimal unitTotal;
  final Decimal effectiveTotal;
  final int quantity;
  final String? printerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onC = cs.onPrimaryContainer;
    final blob = calc.pieceImageBlob;
    final client = calc.clientName;
    final printer = printerName;
    final name = (calc.pieceName == null || calc.pieceName!.isEmpty)
        ? EsBO.calcDetailNoName
        : calc.pieceName!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xxxl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primaryContainer,
              cs.primaryContainer.withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (blob != null)
              Image.memory(
                blob,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: onC,
                          ),
                        ),
                      ),
                      if (calc.isSold) const _SoldChip(),
                    ],
                  ),
                  if (client != null && client.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _metaRow(
                      Icons.person_outline_rounded,
                      '${EsBO.calcDialogClient}: $client',
                      onC,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _metaRow(
                    Icons.calendar_today_rounded,
                    DateFormat(
                      'dd MMM yyyy · HH:mm',
                    ).format(calc.createdAt.toLocal()),
                    onC,
                  ),
                  if (printer != null && printer.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _metaRow(Icons.print_outlined, printer, onC),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: onC.withValues(alpha: 0.18), height: 1),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EsBO.calcDetailTotal,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: onC.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (quantity > 1) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$quantity × ${formatCurrency(unitTotal, currency)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onC.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatCurrency(effectiveTotal, currency),
                            style: GoogleFonts.jetBrainsMono(
                              textStyle: theme.textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: onC,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text, Color onC) {
    return Row(
      children: [
        Icon(icon, size: 14, color: onC.withValues(alpha: 0.75)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onC.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip "Vendida" del hero.
class _SoldChip extends StatelessWidget {
  const _SoldChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: cs.tertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            EsBO.calcDetailSold,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile compacta de KPI (tiempo / peso / ganancia).
class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  textStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de material dentro de la seccion "Materiales".
class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.index,
    required this.material,
    required this.currency,
  });

  final int index;
  final CalculationMaterial material;
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final grams = material.gramsPerBobbinSnapshot;
    final cost = grams <= 0
        ? Decimal.zero
        : _money(
            material.weightGrams *
                material.pricePerBobbinSnapshot /
                grams,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Center(
              child: Text(
                '$index',
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
                  material.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_formatGrams(_money(material.weightGrams))} g · '
                  '${currency.code} '
                  '${material.pricePerBobbinSnapshot.toStringAsFixed(2)} / '
                  '${material.gramsPerBobbinSnapshot.toStringAsFixed(0)} g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatCurrency(cost, currency),
            style: GoogleFonts.jetBrainsMono(
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner de cotizacion parcial (autoguardado incompleto).
///
/// Incluye el acceso a "Editar" para completar el borrador. Queda deshabilitado
/// cuando la cotizacion ya se guardo con la opcion Guardar (cliente + notas),
/// que es justamente cuando deja de ser parcial.
class _PartialBanner extends StatelessWidget {
  const _PartialBanner({required this.onEdit});

  /// Accion de edicion. Null deshabilita el boton.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PartialSaveBadge(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  EsBO.calcPartialAutoSaved,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              FilledButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(EsBO.calcEditAction),
                // El theme define minimumSize = Size(infinity, 52) (botones
                // full-width). Dentro de un Row el ancho es libre, asi que
                // hay que pisar el minimo para que no resuelva w=Infinity.
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            EsBO.calcPartialCompleteHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accion de la barra inferior del detalle: solo icono + micro-descripcion,
/// con tooltip. Color default: `onSurfaceVariant`.
class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurfaceVariant;
    final enabled = onPressed != null;
    final effective = base.withValues(alpha: enabled ? 1 : 0.4);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: effective),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: effective,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boton con icono + label para las acciones secundarias del reporte.
class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Tooltip(
      message: label,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
        ),
        child: isBusy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Fila label + valor del desglose.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.color,
    this.indent = false,
    this.emphasis = false,
    this.big = false,
  });

  final String label;
  final String value;
  final Color? color;

  /// Sub-fila de material (sangria + cursiva).
  final bool indent;

  /// Fila de subtotal/ganancia (mayor contraste, peso w600).
  final bool emphasis;

  /// Fila de total (tipografia grande).
  final bool big;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = (big
            ? theme.textTheme.titleMedium
            : theme.textTheme.bodyMedium)
        ?.copyWith(
          color: indent
              ? theme.colorScheme.onSurfaceVariant
              : color ?? theme.colorScheme.onSurface,
          fontStyle: indent ? FontStyle.italic : null,
          fontWeight: emphasis || big ? FontWeight.w600 : null,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // LOW-12: el valor monetario sin protección — montos de 19+
          // caracteres desbordaban la fila en pantallas angostas.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  textStyle: (big
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        fontWeight: big ? FontWeight.bold : FontWeight.w600,
                        color: color ?? theme.colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Xh Ym" / "Ym" / "—" desde minutos totales.
String _formatMinutes(int minutes) {
  if (minutes <= 0) return '—';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h <= 0) return '${m}m';
  return '${h}h ${m}m';
}

/// Formatea gramos con separador de miles (es_BO).
String _formatGrams(Decimal grams) =>
    NumberFormat.decimalPattern('es_BO').format(grams.toDouble());

/// Convierte un double de dominio a [Decimal] con 2 decimales (display).
Decimal _money(double value) => Decimal.parse(value.toStringAsFixed(2));

/// Reconstruye [CalculationOutput] + valores detallados desde datos
/// guardados en DB + settings actuales.
///
/// **Single source of truth**: delega a [CalculationEngine.computeFromSnapshot]
/// para la formula.
///
/// [quantity]: multiplica todos los montos y las metricas (gramos/tiempo)
/// para reportar valores EFECTIVOS del lote (default 1 = unitario).
///
/// Retorna null si materials aun no cargaron.
({
  CalculationOutput output,
  List<MaterialCostBreakdown> breakdown,
  Decimal electricCost,
  Decimal amortizationCost,
  Decimal laborCost,
  Decimal postProcessCost,
  Decimal extrasCost,
  Decimal baseCost,
  Decimal failureCost,
  Decimal markupCost,
  Decimal profitAmount,
  Decimal totalFinal,
  String? metaGrams,
  String? metaTime,
  PdfRateAudit rateAudit,
})?
_recomputeOutput(
  Calculation calc,
  List<CalculationMaterial> materials,
  Settings settings,
  PrinterProfile? printer, {
  int quantity = 1,
}) {
  if (materials.isEmpty && calc.materialCostSnapshot <= 0) return null;
  final qty = quantity < 1 ? 1 : quantity;
  final qtyD = Decimal.fromInt(qty);

  // Per-material breakdown + MaterialSnapshot list for engine
  final snapshots = <MaterialSnapshot>[];
  var totalGrams = Decimal.zero;
  final breakdown = <MaterialCostBreakdown>[];
  for (final m in materials) {
    final weight = _money(m.weightGrams);
    final price = _money(m.pricePerBobbinSnapshot);
    final grams = _money(m.gramsPerBobbinSnapshot);
    final cost = grams > Decimal.zero
        ? (weight * price / grams).toDecimal(scaleOnInfinitePrecision: 12)
        : Decimal.zero;
    breakdown.add(MaterialCostBreakdown(label: m.label, cost: cost * qtyD));
    totalGrams += weight * qtyD;
    snapshots.add(
      MaterialSnapshot(
        weightGrams: m.weightGrams,
        pricePerBobbinSnapshot: m.pricePerBobbinSnapshot,
        gramsPerBobbinSnapshot: m.gramsPerBobbinSnapshot,
      ),
    );
  }

  // Delegar la formula al engine centralizado
  final output = CalculationEngine.computeFromSnapshot(
    materials: snapshots,
    materialCostSnapshot: calc.materialCostSnapshot,
    totalHours: calc.totalHours,
    printerWattsSnapshot: calc.printerWattsSnapshot,
    kwhRateSnapshot: calc.kwhRateSnapshot,
    laborRateSnapshot: calc.laborRateSnapshot,
    postProcessRateSnapshot: calc.postProcessRateSnapshot,
    failureRateSnapshot: calc.failureRateSnapshot,
    markupOnMaterialsSnapshot: calc.markupOnMaterialsSnapshot,
    profitBaseSnapshot: calc.profitBaseSnapshot,
    discountPercentage: calc.discountPercentage,
    amortizationCostSnapshot: calc.amortizationCostSnapshot,
    fallbackKwhRate: settings.kwhRate,
    fallbackLaborRate: settings.laborRate,
    fallbackPostProcessRate: settings.postProcessRate,
    fallbackFailureRate: settings.failureRate,
    fallbackMarkupOnMaterials: settings.markupOnMaterials,
    fallbackProfitBase: settings.profitBase,
    fallbackPrinterWatts: printer?.averageWatts ?? 0,
    quantity: qty,
    // HIGH-03 fix (auditoria 2026-10-04): el piso de cargo minimo tambien se
    // aplica en la ruta snapshot (snapshot real > 0 gana; filas viejas caen
    // al Settings actual, misma politica que las demas tasas).
    minimumChargeSnapshot: calc.minimumChargeSnapshot,
    fallbackMinimumCharge: settings.minimumCharge,
    // v17: overrides per-cotizacion. Filas pre-v17 tienen los defaults que
    // reproducen el calculo legacy; filas v17+ honran los modos guardados.
    modelingModeRaw: calc.modelingMode,
    modelingPct: calc.modelingValue,
    modelingFixed: calc.modelingValue,
    postprocModeRaw: calc.postprocMode,
    postprocPct: calc.postprocValue,
    postprocFixed: calc.postprocValue,
    extraCostModeRaw: calc.extraMode,
    extraCostPct: calc.extraValue,
    extraCostFixed: calc.extraValue,
  );
  if (output == null) return null;

  // Meta
  final hours = _money(calc.totalHours);
  final totalMinutes = BigInt.from(
    CalculatorState.decimalHoursToMinutes(hours) * qty,
  );
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
    electricCost: output.electricCost,
    amortizationCost: output.amortizationCost,
    laborCost: output.laborCost,
    postProcessCost: output.postProcessCost,
    extrasCost: output.extrasCost,
    baseCost: output.baseCost,
    failureCost: output.failureCost,
    markupCost: output.markupCost,
    profitAmount: output.profitAmount,
    totalFinal: output.totalFinal,
    metaGrams: gramsStr,
    metaTime: timeStr,
    rateAudit: PdfRateAudit.fromRates(
      // Misma politica snapshot -> fallback que aplico el engine, para que
      // la tabla de auditoria muestre las tasas que realmente se usaron.
      rates: CalculationEngine.resolveRates(
        kwhRateSnapshot: calc.kwhRateSnapshot,
        laborRateSnapshot: calc.laborRateSnapshot,
        postProcessRateSnapshot: calc.postProcessRateSnapshot,
        failureRateSnapshot: calc.failureRateSnapshot,
        markupOnMaterialsSnapshot: calc.markupOnMaterialsSnapshot,
        profitBaseSnapshot: calc.profitBaseSnapshot,
        fallbackKwhRate: settings.kwhRate,
        fallbackLaborRate: settings.laborRate,
        fallbackPostProcessRate: settings.postProcessRate,
        fallbackFailureRate: settings.failureRate,
        fallbackMarkupOnMaterials: settings.markupOnMaterials,
        fallbackProfitBase: settings.profitBase,
        fallbackPrinterWatts: printer?.averageWatts ?? 0,
        amortizationCostSnapshot: calc.amortizationCostSnapshot,
        printerWattsSnapshot: calc.printerWattsSnapshot,
      ),
      printerName: calc.printerNameSnapshot ?? printer?.name,
      profitAmount: output.profitAmount,
      baseCost: output.baseCost,
      totalFinal: output.totalFinal,
      totalHours: hours,
    ),
  );
}

final _calculationByIdProvider =
    StreamProvider.autoDispose.family<Calculation?, int>((ref, id) {
      // Stream de drift (no Future cacheado): al volver del calculator el
      // autosave del borraor ya escribio la fila y el provider emite el
      // snapshot nuevo. Un FutureProvider quedaba stale hasta salir y
      // volver a entrar al detalle.
      final repo = ref.watch(calculationRepositoryProvider);
      return repo.watchById(id);
    });

final _materialsOfProvider =
    StreamProvider.autoDispose.family<List<CalculationMaterial>, int>((
      ref,
      id,
    ) {
      // Idem: el autosave del parcial reemplaza materiales (delete+insert);
      // el stream mantiene el desglose del detalle al dia.
      final repo = ref.watch(calculationRepositoryProvider);
      return repo.watchMaterialsOf(id);
    });
