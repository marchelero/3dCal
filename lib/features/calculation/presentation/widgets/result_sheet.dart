// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/export/pdf_export.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/share/piece_image_cropper.dart';
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isEmpty
              ? color.surface
              : color.primaryContainer.withValues(alpha: 0.3),
        ),
        child: Material(
          color: Colors.transparent,
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
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        // Icono cuadrado con tinta de plano (empty ↔ total)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            color: isEmpty
                                ? Colors.transparent
                                : color.primary.withValues(alpha: 0.15),
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
                                  : Icons.calculate_rounded,
                              color: isEmpty
                                  ? color.onSurfaceVariant
                                  : color.primary,
                              size: 20,
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
                                    const SizedBox(height: 2),
                                    Text(
                                      emptyHint!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
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
                                    const SizedBox(height: 2),
                                    // Total con doble regla: el momento
                                    // de la venta.
                                    Text(
                                      totalText,
                                      style: AppTheme.num(
                                        theme.textTheme.titleMedium ??
                                            const TextStyle(),
                                        color: color.onSurface,
                                        fontWeight: FontWeight.bold,
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
                              border: Border.all(
                                color: color.error,
                                width: 1.5,
                              ),
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
                            Icons.chevron_right_rounded,
                            size: 20,
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
  required ValueChanged<Uint8List?> onSave,
  required VoidCallback onReset,
  required VoidCallback onToggleDetail,
  required ValueChanged<String> onDiscountChanged,
  Future<Uint8List?> Function(Uint8List sourceBytes)? pieceImageCropper,
  GallerySaver gallerySaver = const GallerySaver(),
}) {
  // AC-402: mensajero ROOT (page-level), capturado ANTES de abrir el modal.
  // Si el user cierra el sheet mientras un save de imagen (o PDF/share)
  // esta en vuelo, el `ScaffoldMessenger` local del sheet muere con el
  // widget: el feedback de exito/error cae aca como fallback.
  final rootMessenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // F4: ScaffoldMessenger + Scaffold locales como ANCESTROS del contenido
    // del sheet. Asi `ScaffoldMessenger.of(context)` dentro de las acciones
    // resuelve al messenger local y el Scaffold local registra una superficie
    // VISIBLE sobre la hoja modal: los SnackBars (exito/error de save,
    // errores de imagen) se muestran encima del sheet, no ocultos debajo del
    // barrier.
    builder: (sheetCtx) => ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Consumer(
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
              pieceImageCropper: pieceImageCropper,
              gallerySaver: gallerySaver,
              rootMessenger: rootMessenger,
            );
          },
        ),
      ),
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
    this.pieceImageCropper,
    this.gallerySaver = const GallerySaver(),
    this.rootMessenger,
    super.key,
  });

  final CalculatorState state;
  final bool isPro;
  final String? companyName;
  final String? companyLogoBase64;
  final WorldCurrency currency;

  /// Guarda en el historial. Recibe la foto de la pieza adjuntada (o null)
  /// para que el parent la persista (F2): efimera aca, persistida alla.
  final ValueChanged<Uint8List?> onSave;
  final VoidCallback onReset;
  final VoidCallback onToggleDetail;

  /// Escribe el descuento (%) en el notifier (fuente unica de verdad:
  /// state.discountPct → engine → output.discountAmount/output.totalPrice).
  final ValueChanged<String> onDiscountChanged;

  /// Seam (F3): editor de recorte/rotacion de la foto de pieza. Default usa
  /// [cropPieceImage] real (image_cropper). Injectable en tests para evitar
  /// el plugin nativo (misma idea que [ImagePicker] en `pickPieceImage`).
  final Future<Uint8List?> Function(Uint8List sourceBytes)? pieceImageCropper;

  /// Seam (F4): guardado en galeria. Default: [GallerySaver] real (gal).
  /// Injectable en tests para cubrir el flujo de exito sin platform
  /// channels.
  final GallerySaver gallerySaver;

  /// Messengero ROOT de la page (capturado en [showResultSheet] ANTES de
  /// abrir el modal). Fallback AC-402: si el sheet se cierra mientras un
  /// save esta en vuelo, el messenger local muere y el feedback de
  /// exito/error se muestra en este messenger en su lugar.
  final ScaffoldMessengerState? rootMessenger;

  @override
  State<ResultSheetContent> createState() => _ResultSheetContentState();
}

class _ResultSheetContentState extends State<ResultSheetContent> {
  // Key para RepaintBoundary del quote image template. captureQuoteImageBytes
  // lo usa para encontrar el RenderObject y capturarlo como PNG.
  final GlobalKey _captureKey = GlobalKey();
  bool _isBusy = false;
  // BUG-B fix: arranca con la cantidad guardada del state (no hardcodeado a
  // 1). La imagen exportada usa `_quantity` mientras "Guardar" persiste
  // `state.quantity`; ambos caminos deben compartir el mismo valor inicial.
  late int _quantity = widget.state.quantity < 1 ? 1 : widget.state.quantity;
  late final TextEditingController _quantityCtrl = TextEditingController(
    text: '$_quantity',
  );

  /// BUG-008 fix: guard sincrono a nivel de closure contra doble-tap.
  /// `_isBusy` (state) se desactiva visualmente en el siguiente frame,
  /// pero un doble-tap rapido puede disparar el mismo handler dos veces
  /// antes de que el rebuild llegue. `_inFlight` se chequea y se setea
  /// SIN setState (sincronicamente), bloqueando la segunda llamada al
  /// instante.
  bool _inFlight = false;

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
    if (_inFlight) return; // BUG-008: guard sincrono anti-doble-tap.
    _inFlight = true;
    setState(() => _isBusy = true);
    try {
      final bytes = await pickPieceImage(source: source);
      if (bytes == null) return; // cancelacion, sin feedback.
      // F3: recorte/rotacion antes de adjuntar. Cancelar el cropper
      // (null) deja el flujo en el estado previo sin feedback.
      final cropped = widget.pieceImageCropper != null
          ? await widget.pieceImageCropper!(bytes)
          : await cropPieceImage(sourceBytes: bytes);
      if (cropped == null) return;
      setState(() => _pieceImageBytes = cropped);
    } on PieceImageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(e.message));
    } catch (e) {
      debugPrint('Quote image pick failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error(EsBO.quoteImageError));
    } finally {
      _inFlight = false;
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _handleRemoveImage() {
    setState(() => _pieceImageBytes = null);
  }

  Future<void> _handleSharePdf() async {
    if (_inFlight) return; // BUG-008: guard sincrono anti-doble-tap.
    final state = widget.state;
    final output = state.output;
    if (output == null) return;
    _inFlight = true;
    setState(() => _isBusy = true);
    try {
      // Calcular gramos totales desde los materiales del state.
      final gramsDec = state.mode == CalculatorMode.express
          ? CalculatorState.parseDecimal(state.weight) ?? Decimal.zero
          : state.materials.fold(
              Decimal.zero,
              (sum, m) => sum + (CalculatorState.parseDecimal(m.weight) ?? Decimal.zero),
            );
      final totalGrams = gramsDec > Decimal.zero ? gramsDec : null;

      // Calcular meta time.
      final h = CalculatorState.parseDecimal(state.printHours) ?? Decimal.zero;
      final m = CalculatorState.parseDecimal(state.printMinutes) ?? Decimal.zero;
      final totalMinutes = (h * Decimal.fromInt(60) + m).toBigInt();
      String? metaTime;
      if (totalMinutes > BigInt.zero) {
        final hh = totalMinutes ~/ BigInt.from(60);
        final mm = totalMinutes.remainder(BigInt.from(60));
        metaTime = '${hh.toInt()}h ${mm.toInt()}m';
      }

      await shareQuotePdf(
        isPro: widget.isPro,
        output: output,
        materials: state.detailMaterialBreakdown,
        totalHours: state.totalHoursDecimal ?? Decimal.zero,
        discountPct:
            CalculatorState.parseDecimal(state.discountPct) ?? Decimal.zero,
        currency: widget.currency,
        showDetail: state.showDetail,
        companyName: widget.companyName,
        companyLogoBase64: widget.companyLogoBase64,
        pieceName: state.label.isNotEmpty ? state.label : null,
        pieceImageBytes: _pieceImageBytes,
        quantity: _quantity,
        totalGrams: totalGrams,
        metaTime: metaTime,
        batchDiscountPct: state.batchAppliedPercent,
        batchDiscountAmount: state.batchDiscountAmount,
      );
    } catch (e) {
      debugPrint('Quote PDF share failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error(EsBO.commonPdfExportError));
    } finally {
      _inFlight = false;
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Fusion (AS-2026): un solo boton que guarda la imagen EN LA GALERIA y
  /// a la par abre el share sheet. Captura los bytes UNA sola vez y ejecuta
  /// ambas acciones con [Future.wait]. Errores parciales: cada accion corre
  /// en su propio try/catch (via [_trySaveImage]/[_tryShareImage]) para que
  /// el fallo de UNA no mate la que si funciono; el feedback es el mensaje
  /// de la primera falla (si hubo), o el de exito si ambas OK.
  Future<void> _handleShareAndSave() async {
    if (_inFlight) return; // BUG-008: guard sincrono anti-doble-tap.
    _inFlight = true;
    setState(() => _isBusy = true);
    // F4: referenciar el messenger ANTES del async. Con el Scaffold local
    // dentro del sheet, `ScaffoldMessenger.of(context)` resuelve al
    // messenger del sheet → el SnackBar se muestra SOBRE la hoja modal.
    // La referencia capturada sobrevive aunque el sheet se cierre durante
    // el flujo.
    final messenger = ScaffoldMessenger.of(context);
    // AC-402: si el sheet se cierra durante el flujo, ese messenger muere
    // (mounted=false); el fallback es el messenger ROOT de la page.
    final rootMessenger = widget.rootMessenger;
    try {
      // Una sola captura: la imagen PNG es la misma para ambas acciones.
      final bytes = await captureQuoteImageBytes(_captureKey);
      final errors = <String>[];
      await Future.wait<void>([
        _trySaveImage(bytes, errors),
        _tryShareImage(bytes, errors),
      ]);
      if (errors.isNotEmpty) {
        _showSaveFeedback(
          messenger,
          rootMessenger,
          AppSnackBar.error(errors.first),
        );
        return;
      }
      final msg = kIsWeb
          ? EsBO.commonImageDownloaded
          : EsBO.commonImageSavedGallery;
      _showSaveFeedback(messenger, rootMessenger, AppSnackBar.success(msg));
    } on ShareQuoteException catch (e) {
      // Fallo de la captura en si: sin bytes no hay ninguna accion que
      // ejecutar.
      _showSaveFeedback(messenger, rootMessenger, AppSnackBar.error(e.message));
    } catch (e) {
      debugPrint('Quote image capture failed: $e');
      _showSaveFeedback(
        messenger,
        rootMessenger,
        AppSnackBar.error(EsBO.calcShareError),
      );
    } finally {
      _inFlight = false;
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Rama "guardar" del boton fusionado compartir+guardar. Los fallos se
  /// acumulan en [errors] como mensajes de feedback (no se relanzan): la
  /// otra accion sigue corriendo aunque esta falle.
  Future<void> _trySaveImage(Uint8List bytes, List<String> errors) async {
    try {
      await saveQuoteImage(bytes, gallerySaver: widget.gallerySaver);
    } catch (e) {
      debugPrint('Quote image save failed: $e');
      errors.add(e is ShareQuoteException ? e.message : EsBO.calcShareError);
    }
  }

  /// Rama "compartir" del boton fusionado. Idem [_trySaveImage]: falla en
  /// silencio (solo debugPrint + registro del mensaje) sin matar el save.
  ///
  /// **Web**: timeout anti-hang. En Chrome/Windows el pane nativo de share
  /// puede NO resolver nunca; sin esto el `Future.wait` del handler quedaria
  /// colgado y el boton clavado en loading aunque el save ya completo. En
  /// mobile NO hay timeout: la share sheet nativa queda abierta hasta que el
  /// usuario la cierra (UX del boton viejo).
  Future<void> _tryShareImage(Uint8List bytes, List<String> errors) async {
    try {
      final share = shareQuoteImage(bytes);
      if (kIsWeb) {
        await share.timeout(const Duration(seconds: 8));
      } else {
        await share;
      }
    } on TimeoutException {
      // Hang del pane web (Chrome/Windows): la imagen ya quedo guardada por
      // la rama save; el mensaje aclara que el menu de compartir no estaba
      // disponible.
      debugPrint('Quote image share timed out (8s) on web');
      errors.add(EsBO.shareWebUnavailable);
    } catch (e) {
      debugPrint('Quote image share failed: $e');
      errors.add(e is ShareQuoteException ? e.message : EsBO.calcShareError);
    }
  }

  /// Muestra [snackbar] en el messenger del sheet si sigue montado; si el
  /// sheet se cerro durante el save async, cae al messenger ROOT de la
  /// page para que el feedback de exito/error no se pierda (AC-402).
  static void _showSaveFeedback(
    ScaffoldMessengerState sheetMessenger,
    ScaffoldMessengerState? rootMessenger,
    SnackBar snackbar,
  ) {
    if (sheetMessenger.mounted) {
      sheetMessenger.showSnackBar(snackbar);
    } else if (rootMessenger != null && rootMessenger.mounted) {
      rootMessenger.showSnackBar(snackbar);
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

    // La superficie visible para los SnackBars (F4) vive en [showResultSheet]
    // (ScaffoldMessenger + Scaffold como ancestros del contenido).
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      // Entrada de sello: UN momento autorado (stamp settle).
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.12, end: 1),
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
                          fontWeight: FontWeight.w700,
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
                  detailAmortizationCost: state.detailAmortizationCost,
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
                  batchDiscountPct: state.batchAppliedPercent,
                  batchDiscountAmount: state.batchDiscountAmount,
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
              Builder(
                builder: (ctx) {
                  // Consumer: reactivo — si el entitlement resuelve mientras
                  // el sheet esta abierto, el gate se actualiza solo.
                  return Consumer(
                    builder: (ctx, ref, _) {
                      final isPro = ref.watch(isProProvider);
                      final entState = ref.watch(entitlementNotifierProvider);
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
                                      EsBO.resultQuantityLabel,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (locked) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      ProBadge(
                                        onTap: () =>
                                            ProBadge.sheetAction(ctx, ref),
                                      ),
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
                                          _quantityCtrl.text = '$_quantity';
                                          ref
                                              .read(
                                                calculatorNotifierProvider
                                                    .notifier,
                                              )
                                              .setQuantity(_quantity);
                                        }
                                      }
                                    : null,
                              ),
                              SizedBox(
                                width: 64,
                                child: TextFormField(
                                  key: const ValueKey('quantity_input'),
                                  controller: _quantityCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.num(
                                    theme.textTheme.titleMedium ??
                                        const TextStyle(),
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
                                    final parsed = int.tryParse(val) ?? 1;
                                    final clamped = parsed.clamp(
                                      1,
                                      kMaxQuantity,
                                    );
                                    setState(() => _quantity = clamped);
                                    ref
                                        .read(
                                          calculatorNotifierProvider.notifier,
                                        )
                                        .setQuantity(clamped);
                                  },
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
                                    _quantityCtrl.text = '$_quantity';
                                    ref
                                        .read(
                                          calculatorNotifierProvider.notifier,
                                        )
                                        .setQuantity(_quantity);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // ── Descuento por cantidad (feature A, Hito 1) ──
              // Linea informativa: no editable, solo lectura del escalón.
              if (state.showsBatchLine) ...[
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
                        const Icon(
                          Icons.inventory_2_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            EsBO.calcDetailBatchDiscount(
                              state.batchAppliedPercent?.toBigInt().toInt() ?? 0,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '-${formatCurrency(state.batchDiscountAmount, widget.currency)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

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
                          initialValue:
                              (double.tryParse(
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
                            // BUG-013: clamp al maximo definido en constants
                            // (antes hardcodeado a 100, permitia -50% del
                            // total con valores intermedios).
                            widget.onDiscountChanged(
                              parsed
                                  .clamp(0, kMaxDiscountPercentage)
                                  .toString(),
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

              // Action row: Guardar cotización + PDF + Compartir y guardar +
              // Reset (fusion AS-2026: share + save en un solo boton).
              _ActionIconRow(
                isBusy: _isBusy,
                onSaveDb: () {
                  Navigator.of(context).pop();
                  widget.onSave(_pieceImageBytes);
                },
                onShareAndSave: _handleShareAndSave,
                onSharePdf: _handleSharePdf,
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

/// Fila de 4 botones-sello cuadrados centrados: Guardar, PDF, Compartir y
/// guardar (fusionado AS-2026), Reset.
class _ActionIconRow extends StatelessWidget {
  const _ActionIconRow({
    required this.isBusy,
    required this.onSaveDb,
    required this.onShareAndSave,
    required this.onSharePdf,
    required this.onReset,
  });

  final bool isBusy;
  final VoidCallback onSaveDb;
  final VoidCallback onShareAndSave;
  final VoidCallback onSharePdf;
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
        // Fusion AS-2026: compartir + guardar en un solo boton. Conserva el
        // icono de compartir (share_rounded) para no romper la busqueda por
        // icono en tests, con el tooltip nuevo calcBtnShareSave.
        _ActionIcon(
          icon: Icons.share_rounded,
          tooltip: EsBO.calcBtnShareSave,
          color: color.primary,
          isBusy: isBusy,
          onPressed: isBusy ? null : onShareAndSave,
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
