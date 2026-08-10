// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/export/pdf_export.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/share/quote_image_picker.dart';
import '../../../../core/share/quote_share.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/perforation.dart';
import '../../../../shared/widgets/pro_badge.dart';
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
  required ValueChanged<String> onDiscountChanged,
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
        final settings = asyncSettings.value;
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
          onDiscountChanged: onDiscountChanged,
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
    required this.onDiscountChanged,
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

  /// Escribe el descuento (%) en el notifier (fuente unica de verdad:
  /// state.discountPct → engine → output.discountAmount/output.totalPrice).
  final ValueChanged<String> onDiscountChanged;

  @override
  State<ResultSheetContent> createState() => _ResultSheetContentState();
}

class _ResultSheetContentState extends State<ResultSheetContent> {
  // Key para RepaintBoundary del quote image template. captureQuoteImageBytes
  // lo usa para encontrar el RenderObject y capturarlo como PNG.
  final GlobalKey _captureKey = GlobalKey();
  bool _isBusy = false;
  int _quantity = 1;

  /// Foto de la pieza adjuntada (efimera: solo vive en este sheet, no se
  /// persiste). Se renderiza en el template (PNG) y viaja al PDF.
  Uint8List? _pieceImageBytes;

  Future<void> _handlePickFromDialog() async {
    if (_isBusy) return;
    // Soporte de camara se evalua al abrir (no en build): en web desktop
    // devuelve false y ocultamos la opcion.
    final hasCamera = ImagePicker().supportsImageSource(ImageSource.camera);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(EsBO.quoteImageGallery),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            if (hasCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(EsBO.quoteImageCamera),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _handlePickImage(source);
  }

  Future<void> _handlePickImage(ImageSource source) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bytes = await pickPieceImage(source: source);
      if (bytes == null) return; // cancelacion, sin feedback.
      setState(() => _pieceImageBytes = bytes);
    } on PieceImageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(e.message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.quoteImageError}: $e'));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _handleRemoveImage() {
    setState(() => _pieceImageBytes = null);
  }

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
        showDetail: state.showDetail,
        companyName: widget.companyName,
        companyLogoBase64: widget.companyLogoBase64,
        pieceName: state.label.isNotEmpty ? state.label : null,
        pieceImageBytes: _pieceImageBytes,
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
                  pieceImageBytes: _pieceImageBytes,
                  quantity: _quantity,
                ),
              ),

              // ── Foto de pieza: control (FUERA del RepaintBoundary, no sale
              // en el PNG). Agregar/Cambiar/Quitar — reversible, no bloquea.
              const SizedBox(height: AppSpacing.sm),
              Align(
                child: _pieceImageBytes == null
                    ? TextButton.icon(
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: Text(EsBO.quoteImageAdd),
                        onPressed: _isBusy ? null : _handlePickFromDialog,
                      )
                    : Wrap(
                        spacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              size: 18,
                            ),
                            label: Text(EsBO.quoteImageChange),
                            onPressed: _isBusy ? null : _handlePickFromDialog,
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: Text(EsBO.quoteImageRemove),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            onPressed: _isBusy ? null : _handleRemoveImage,
                          ),
                        ],
                      ),
              ),

              // ── Selector PRO de Cantidad (fuera del RepaintBoundary) ──
              const SizedBox(height: AppSpacing.sm),
              Builder(builder: (ctx) {
                final isPro = ProviderScope.containerOf(ctx).read(isProProvider);
                final entState = ProviderScope.containerOf(ctx).read(entitlementNotifierProvider);
                final locked = !entState.isLoading && !isPro;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.layers_rounded, size: 18),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Cantidad',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (locked) ...[
                                const SizedBox(width: AppSpacing.xs),
                                const ProBadge(),
                              ],
                            ],
                          ),
                        ),
                        IconButton.outlined(
                          icon: const Icon(Icons.remove_rounded),
                          visualDensity: VisualDensity.compact,
                          onPressed: _quantity > 1
                              ? () {
                                  if (locked) {
                                    Navigator.of(ctx).pop();
                                    GoRouter.of(ctx).push('/paywall');
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
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            if (locked) {
                              Navigator.of(ctx).pop();
                              GoRouter.of(ctx).push('/paywall');
                            } else {
                              setState(() => _quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // ── Descuento (Debajo de Cantidad, disponible para todos) ──
              // Fuente unica de verdad: state.discountPct (engine). Escribir
              // aqui actualiza el total, la imagen, el PDF, el draft y la DB.
              const SizedBox(height: AppSpacing.xs),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              EsBO.calcLabelDiscount,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: (double.tryParse(
                                widget.state.discountPct,
                              )?.round() ??
                              0)
                              .toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val) ?? 0;
                            widget.onDiscountChanged(
                              parsed.clamp(0, 100).toString(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
