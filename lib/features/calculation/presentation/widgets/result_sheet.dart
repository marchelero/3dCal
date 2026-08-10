// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/pdf_export.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/share/quote_share.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/perforation.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import 'calc_meta.dart';
import 'quote_image_template.dart';

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
    final theme = Theme.of(context);
    final isEmpty = emptyHint != null;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: color.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Borde de arranque perforado: la hoja se desprende aqui.
            const Perforation(),
            Semantics(
              button: true,
              label: isEmpty ? emptyHint! : totalText,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // Icono cuadrado con tinta de plano (empty ↔ total)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: isEmpty
                                ? color.outlineVariant
                                : color.primary,
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            key: ValueKey(isEmpty),
                            isEmpty
                                ? Icons.info_outline_rounded
                                : Icons.receipt_long_rounded,
                            color: isEmpty
                                ? color.onSurfaceVariant
                                : color.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    EsBO.calcResultBarEmptyHint.toUpperCase(),
                                    style: AppTheme.num(
                                      theme.textTheme.labelSmall?.copyWith(
                                            letterSpacing: 1.2,
                                          ) ??
                                          const TextStyle(),
                                      color: color.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    emptyHint!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: color.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    EsBO.calcResultBarTapHint.toUpperCase(),
                                    style: AppTheme.num(
                                      theme.textTheme.labelSmall?.copyWith(
                                            letterSpacing: 1.2,
                                          ) ??
                                          const TextStyle(),
                                      color: color.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  // Caja del total con doble regla: el momento
                                  // de la venta.
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: color.onSurface,
                                          width: 2,
                                        ),
                                        bottom: BorderSide(
                                          color: color.onSurface,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: color.onSurface,
                                            width: 1,
                                          ),
                                          bottom: BorderSide(
                                            color: color.onSurface,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            SlideTransition(
                                              position:
                                                  Tween<Offset>(
                                                    begin: const Offset(0, 0.3),
                                                    end: Offset.zero,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.easeOut,
                                                    ),
                                                  ),
                                              child: FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              ),
                                            ),
                                        child: Text(
                                          totalText,
                                          key: ValueKey(totalText),
                                          style: AppTheme.num(
                                            theme.textTheme.titleLarge ??
                                                const TextStyle(),
                                            color: color.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (!isEmpty && hasDiscount) ...[
                        const SizedBox(width: AppSpacing.sm),
                        // Sello de descuento: correccion en tinta roja.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: color.error, width: 1.5),
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            EsBO.calcToggleShowDetail,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color.error,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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
          ],
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
    builder: (sheetCtx) => Consumer(
      builder: (ctx, ref, _) {
        // Usamos el state vivo del provider para que el toggle detail
        // (showDetail) funcione dentro del sheet.
        final liveState = ref.watch(calculatorNotifierProvider);
        final asyncSettings = ref.watch(settingsNotifierProvider);
        final settings = asyncSettings.valueOrNull;
        final currency = ref.watch(selectedCurrencyProvider);
        final isPro = ref.watch(isProProvider);
        return ResultSheetContent(
          state: liveState,
          isPro: isPro,
          companyName: settings?.companyName,
          companyLogoBase64: settings?.companyLogoBase64,
          currency: currency,
          onSave: onSave,
          onReset: onReset,
          onToggleDetail: onToggleDetail,
        );
      },
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
    required this.isPro,
    this.companyName,
    this.companyLogoBase64,
    required this.currency,
    required this.onSave,
    required this.onReset,
    required this.onToggleDetail,
    super.key,
  });

  final CalculatorState state;
  final bool isPro;
  final String? companyName;
  final String? companyLogoBase64;
  final WorldCurrency currency;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onToggleDetail;

  @override
  State<ResultSheetContent> createState() => _ResultSheetContentState();
}

class _ResultSheetContentState extends State<ResultSheetContent> {
  // Key para RepaintBoundary del quote image template. captureQuoteImageBytes
  // lo usa para encontrar el RenderObject y capturarlo como PNG.
  final GlobalKey _captureKey = GlobalKey();
  bool _isBusy = false;

  Future<void> _handleSharePdf() async {
    if (_isBusy) return;
    final state = widget.state;
    final output = state.output;
    if (output == null) return;
    setState(() => _isBusy = true);
    try {
      await shareQuotePdf(
        isPro: widget.isPro,
        output: output,
        materials: state.detailMaterialBreakdown,
        totalHours: state.totalHoursDecimal ?? Decimal.zero,
        discountPct:
            CalculatorState.parseDecimal(state.discountPct) ?? Decimal.zero,
        companyName: widget.companyName,
        companyLogoBase64: widget.companyLogoBase64,
        pieceName: state.label.isNotEmpty ? state.label : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.commonPdfExportError}: $e'));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

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
      // Entrada de sello: UN momento autorado (stamp settle).
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.12, end: 1.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
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
              // Bloque de titulo del plano
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        EsBO.calcSheetTitle.toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quote Image Template (capturable ──
              // Este widget se captura como PNG. NO tiene elementos interactivos.
              // El toggle detail se renderiza fuera del RepaintBoundary.
              RepaintBoundary(
                key: _captureKey,
                child: QuoteImageTemplate(
                  output: output,
                  label: state.label,
                  discountPct:
                      state.detailDiscountPct?.toStringAsFixed(0) ??
                      state.discountPct,
                  showDetail: state.showDetail,
                  detailMaterialBreakdown: state.detailMaterialBreakdown,
                  detailElectricCost: state.detailElectricCost,
                  detailLaborCost: state.detailLaborCost,
                  detailPostProcessCost: state.detailPostProcessCost,
                  detailBaseCost: state.detailBaseCost,
                  detailFailureCost: state.detailFailureCost,
                  detailMarkupCost: state.detailMarkupCost,
                  detailProfitAmount: state.detailProfitAmount,
                  detailTotalFinal: state.detailTotalFinal,
                  metaGrams: meta.grams,
                  metaTime: meta.time,
                  companyName: widget.companyName,
                  companyLogoBase64: widget.companyLogoBase64,
                  currency: widget.currency,
                ),
              ),

              // Toggle detail (fuera del RepaintBoundary para no salir en img)
              const SizedBox(height: AppSpacing.sm),
              Align(
                child: TextButton.icon(
                  icon: Icon(
                    state.showDetail
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 18,
                  ),
                  label: Text(
                    state.showDetail
                        ? EsBO.calcToggleHideDetail
                        : EsBO.calcToggleShowDetail,
                  ),
                  onPressed: widget.onToggleDetail,
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

              // Action row: Guardar cotización + Compartir + Guardar img + Reset.
              _ActionIconRow(
                isBusy: _isBusy,
                onSaveDb: () {
                  Navigator.of(context).pop();
                  widget.onSave();
                },
                onShare: _handleShare,
                onSharePdf: _handleSharePdf,
                onSaveImage: _handleSave,
                onReset: () {
                  Navigator.of(context).pop();
                  widget.onReset();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de 5 botones-sello cuadrados centrados: Guardar, PDF, Compartir,
/// Descargar, Reset.
class _ActionIconRow extends StatelessWidget {
  const _ActionIconRow({
    required this.isBusy,
    required this.onSaveDb,
    required this.onShare,
    required this.onSharePdf,
    required this.onSaveImage,
    required this.onReset,
  });

  final bool isBusy;
  final VoidCallback onSaveDb;
  final VoidCallback onShare;
  final VoidCallback onSharePdf;
  final VoidCallback onSaveImage;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        _ActionIcon(
          icon: Icons.save_rounded,
          tooltip: EsBO.calcBtnSave,
          color: color.primary,
          onPressed: isBusy ? null : onSaveDb,
        ),
        _ActionIcon(
          icon: Icons.picture_as_pdf_rounded,
          tooltip: EsBO.commonSharePdf,
          color: color.error,
          isBusy: isBusy,
          onPressed: isBusy ? null : onSharePdf,
        ),
        _ActionIcon(
          icon: Icons.share_rounded,
          tooltip: EsBO.calcBtnShare,
          color: color.primary,
          isBusy: isBusy,
          onPressed: isBusy ? null : onShare,
        ),
        _ActionIcon(
          icon: Icons.download_rounded,
          tooltip: EsBO.commonSaveImage,
          color: color.primary,
          isBusy: isBusy,
          onPressed: isBusy ? null : onSaveImage,
        ),
        _ActionIcon(
          icon: Icons.refresh_rounded,
          tooltip: EsBO.calcActionReset,
          color: color.onSurfaceVariant,
          onPressed: isBusy ? null : onReset,
        ),
      ],
    );
  }
}

/// Boton-sello cuadrado con icono, usado en [_ActionIconRow].
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
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
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(color: color, width: 1.5),
        ),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(AppSpacing.sm),
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

/// Helper de formato: toma el total en formato currency formateado.
/// Wrapper sobre [formatBob] para mantener el call site del bar limpio.
@visibleForTesting
String debugFormatResultTotal(Decimal total) => formatBob(total);
