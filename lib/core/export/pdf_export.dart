/// Genera el reporte de cotizacion en PDF.
///
/// Usa el paquete `pdf` (Dart PDF) para generar un documento vectorial.
///
/// **4 variantes** ([QuoteReportVariant]) en vez del antiguo toggle binario de
/// detalle. Dos ejes independientes:
///
/// - **Audience**: `client*` (seguro para enviar a un tercero) vs. `internal*`
///   (reporte privado de trabajo). Las variantes de cliente NUNCA imprimen
///   costos internos, tasas ni la impresora.
/// - **Complexity**: simple vs. `advanced` (multi-material, tiempos sueltos por
///   material, sumas y total final por capas).
///
/// El mismo enum gobierna la imagen PNG ([QuoteImageTemplate]) y la
/// impresion, para que los 3 canales no se desincronicen.
///
/// Diseno profesional:
/// - Barra de color superior (accent bar), solo en la pagina 1
/// - Header con logo + branding + metadata de cotizacion (repetido en
///   paginas 2+ en version compacta)
/// - Tabla de materiales con peso y tiempo, con fila TOTAL en las internas
/// - Total hero con fondo colorido
/// - Bloque "Resumen de la cotizacion" en las variantes de cliente
/// - Desglose con filas alternadas y subtotales marcados (internas)
/// - Seccion "Parametros de calculo" con tasas + margenes (internas)
/// - Pie con "Pagina X de Y"
///
/// Todo el contenido se decide por los getters del enum
/// ([QuoteReportVariant.isClientFacing], [showCostDetail], [showRateAudit],
/// [showsMaterialTime], [showsSummaryBlock]) — nunca comparando casos, para
/// que agregar una variante rompa en compilacion y no en silencio.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/calculation/domain/entities/calculation_output.dart';
import '../../features/calculation/presentation/state/calculator_state.dart';
import '../../l10n/es_bo.dart';
import '../money/currency.dart';
import '../money/currency_formatter.dart';
import 'pdf_rate_audit.dart';
import 'quote_report_variant.dart';

/// Branding forzado para usuarios Free.
const String kFreeDefaultCompanyName = '3dCalc';

/// Dias de validez de la oferta (se imprime como "valido hasta").
const int kQuoteValidDays = 15;

/// Una fila de la tabla de materiales del reporte.
///
/// [timeStr] es null cuando ese material usa el tiempo global (no tiene
/// tiempo propio). En las variantes que muestran la columna de tiempo eso se
/// renderiza como el indicador [EsBO.pdfGlobalTime], **nunca** como un 0
/// inventado.
class PdfMaterialMetaItem {
  const PdfMaterialMetaItem({
    required this.label,
    required this.weightGrams,
    this.timeStr,
    this.unitCost,
  });

  final String label;

  /// Peso ya formateado ("120 g").
  final String weightGrams;

  /// Tiempo propio del material ("2h 30m"), o null si usa el global.
  final String? timeStr;

  /// Costo unitario del material (BOB). `null` cuando el caller no lo
  /// resuelve — en ese caso la tabla no imprime columna de costo.
  final Decimal? unitCost;

  /// True cuando el material no tiene tiempo propio.
  bool get usesGlobalTime => timeStr == null;
}

// ── Colores del diseno ──────────────────────────────────────────────

const PdfColor _accentColor = PdfColors.blue800;
const PdfColor _accentLight = PdfColors.blue50;
const PdfColor _accentMedium = PdfColors.blue100;
const PdfColor _textPrimary = PdfColors.grey900;
const PdfColor _textSecondary = PdfColors.grey600;
const PdfColor _textMuted = PdfColors.grey500;
const PdfColor _bgSubtle = PdfColors.grey50;
const PdfColor _borderLight = PdfColors.grey200;
const PdfColor _successColor = PdfColors.green800;
const PdfColor _errorColor = PdfColors.red700;

// ── Helpers ─────────────────────────────────────────────────────────

/// Shorthand: formatea un Decimal con la moneda activa para el PDF.
String _fmt(Decimal v, WorldCurrency currency) => formatCurrency(v, currency);

/// Formatea una fecha como dd/MM/yyyy (sin depender de intl).
String _fmtDate(DateTime d) {
  final local = d.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year}';
}

/// Resuelve el branding efectivo del PDF segun el estado Pro del user.
({String name, String? logo}) resolveBranding({
  required bool isPro,
  String? companyName,
  String? companyLogoBase64,
}) {
  if (!isPro) {
    return (name: kFreeDefaultCompanyName, logo: null);
  }
  return (
    name: (companyName == null || companyName.isEmpty)
        ? kFreeDefaultCompanyName
        : companyName,
    logo: (companyLogoBase64 == null || companyLogoBase64.isEmpty)
        ? null
        : companyLogoBase64,
  );
}

// ── Widget helpers (PDF vectorial) ──────────────────────────────────

/// Barra de acento decorativa (linea fina de color).
pw.Widget _accentBar() => pw.Container(
  height: 4,
  decoration: pw.BoxDecoration(
    color: _accentColor,
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
  ),
);

/// Fila de datos estilizada: label a la izquierda, valor a la derecha.
/// [altBackground] pinta la fila con fondo sutil para alternancia visual.
pw.Widget _dataRow(
  String label,
  String value, {
  bool bold = false,
  bool altBackground = false,
  PdfColor? valueColor,
  bool strikeThrough = false,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    color: altBackground ? _bgSubtle : null,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: _textPrimary,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor ?? _textPrimary,
            decoration: strikeThrough ? pw.TextDecoration.lineThrough : null,
          ),
        ),
      ],
    ),
  );
}

/// Linea divisoria horizontal fina.
pw.Widget _thinDivider({double marginTop = 0, double marginBottom = 0}) =>
    pw.Container(
      margin: pw.EdgeInsets.only(top: marginTop, bottom: marginBottom),
      height: 0.5,
      color: _borderLight,
    );

/// Titulo de seccion con linea sutil debajo.
pw.Widget _sectionHeader(String title) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _accentColor,
          letterSpacing: 1.2,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Container(height: 1, color: _accentMedium),
    ],
  );
}

/// Caja de meta info: horas + descuento en fila 1, peso + tiempo en fila 2.
/// Siempre se muestra (aunque solo tenga horas/descuento).
///
/// El reparto por material **ya no** vive aca (lo maneja la tabla de
/// materiales), aca solo van las cifras globales de la pieza.
pw.Widget _buildMetaBox({
  required Decimal totalHours,
  required Decimal discountPct,
  String? metaGrams,
  String? metaTime,
}) {
  final hasHours = totalHours > Decimal.zero;
  final hasDiscount = discountPct > Decimal.zero;
  final hasGrams = metaGrams != null;
  final hasTime = metaTime != null;

  if (!hasHours && !hasDiscount && !hasGrams && !hasTime) {
    return pw.SizedBox.shrink();
  }

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: pw.BoxDecoration(
      color: _accentLight,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Fila 1: horas + descuento
        if (hasHours || hasDiscount)
          pw.Row(
            children: [
              if (hasHours)
                pw.Text(
                  '${EsBO.pdfHoursPrefix}${totalHours.toStringAsFixed(2)}h',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
              if (hasHours && hasDiscount)
                pw.Text(
                  '   ${EsBO.calcMetaSeparator}   ',
                  style: pw.TextStyle(fontSize: 10, color: _accentColor),
                ),
              if (hasDiscount)
                pw.Text(
                  EsBO.pdfDiscountPct(discountPct.toDouble().round()),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
            ],
          ),
        // Fila 2: peso + tiempo
        if (hasGrams || hasTime) ...[
          if (hasHours || hasDiscount) pw.SizedBox(height: 4),
          pw.Row(
            children: [
              if (hasGrams)
                pw.Text(
                  '${EsBO.pdfWeight}$metaGrams',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
              if (hasGrams && hasTime)
                pw.Text(
                  '   ${EsBO.calcMetaSeparator}   ',
                  style: pw.TextStyle(fontSize: 10, color: _accentColor),
                ),
              if (hasTime)
                pw.Text(
                  '${EsBO.pdfPrintTime}$metaTime',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// Fila de la tabla de materiales.
///
/// Las columnas variables se resuelven acá con [pw.Expanded] proporcional: la
/// columna de texto se lleva el resto del ancho para que los numeros nunca
/// se partan.
pw.Widget _materialRow({
  required String label,
  required String weight,
  required String? time,
  required String? unitCost,
  required String? lotCost,
  required bool altBackground,
}) {
  pw.Widget cell(String? value, {bool bold = false, PdfColor? color}) {
    if (value == null) return pw.SizedBox.shrink();
    return pw.SizedBox(
      width: lotCost != null
          ? 62
          : (unitCost != null ? 78 : (time != null ? 62 : 58)),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _textPrimary,
        ),
      ),
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    color: altBackground ? _bgSubtle : null,
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: _textPrimary),
          ),
        ),
        cell(weight),
        if (time != null) cell(time, color: _accentColor),
        if (unitCost != null) cell(unitCost),
        if (lotCost != null) cell(lotCost, bold: true),
      ],
    ),
  );
}

/// Header de la tabla de materiales, con las columnas que la variante pide.
pw.Widget _materialHeader({
  required bool showTime,
  required bool showUnitCost,
  required bool showLotCost,
}) {
  pw.Widget col(String text, double width) => pw.SizedBox(
    width: width,
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.right,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _accentColor,
      ),
    ),
  );

  final lotWidth = showLotCost ? 62.0 : (showUnitCost ? 78.0 : 0.0);
  final unitWidth = showUnitCost && !showLotCost ? 78.0 : 0.0;
  final timeWidth = showTime ? 62.0 : 0.0;

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: pw.BoxDecoration(
      color: _accentMedium,
      borderRadius: const pw.BorderRadius.only(
        topLeft: pw.Radius.circular(4),
        topRight: pw.Radius.circular(4),
      ),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            EsBO.pdfColumnMaterial,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _accentColor,
            ),
          ),
        ),
        col(EsBO.pdfColumnWeight, 58),
        if (showTime) col(EsBO.pdfColumnTime, timeWidth),
        if (showUnitCost && !showLotCost)
          col(EsBO.pdfColumnUnitCost, unitWidth),
        if (showLotCost) col(EsBO.pdfColumnLotCost, lotWidth),
      ],
    ),
  );
}

/// Fila TOTAL que cierra la tabla de materiales.
///
/// Solo en las variantes internas: sin el desglose de costos, una suma de
/// costos seria informacion sensible para el cliente.
pw.Widget _materialTotalRow({required String lotTotalText}) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: const pw.BoxDecoration(
    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
  ),
  child: pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(
          EsBO.pdfTotalUpper,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
      ),
      pw.SizedBox(width: 62, child: pw.SizedBox.shrink()),
      pw.SizedBox(
        width: 62,
        child: pw.Text(
          lotTotalText,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _accentColor,
          ),
        ),
      ),
    ],
  ),
);

// ── API publica ─────────────────────────────────────────────────────

/// Genera un PDF con el reporte de cotizacion y lo comparte via share sheet.
Future<void> shareQuotePdf({
  required bool isPro,
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  WorldCurrency currency = WorldCurrency.bob,
  QuoteReportVariant variant = QuoteReportVariant.clientSimple,
  String? companyName,
  String? companyLogoBase64,
  String? pieceName,
  String? clientName,
  int? quoteNumber,
  DateTime? quoteDate,
  DateTime? validUntil,
  String? notes,
  String? conditions,
  Uint8List? pieceImageBytes,
  String? metaGrams,
  String? metaTime,
  List<PdfMaterialMetaItem> materialMetaBreakdown = const [],
  int quantity = 1,
  Decimal? totalGrams,
  Decimal? batchDiscountPct,
  Decimal? batchDiscountAmount,
  Decimal? lotTotal,
  Decimal? manualDiscountAmount,
  PdfRateAudit? rateAudit,
  bool? isSold,
  pw.Font? regularFont,
  pw.Font? boldFont,
}) async {
  final pdfBytes = await buildQuotePdfBytes(
    isPro: isPro,
    output: output,
    materials: materials,
    totalHours: totalHours,
    discountPct: discountPct,
    currency: currency,
    variant: variant,
    companyName: companyName,
    companyLogoBase64: companyLogoBase64,
    pieceName: pieceName,
    clientName: clientName,
    quoteNumber: quoteNumber,
    quoteDate: quoteDate,
    validUntil: validUntil,
    notes: notes,
    conditions: conditions,
    pieceImageBytes: pieceImageBytes,
    metaGrams: metaGrams,
    metaTime: metaTime,
    materialMetaBreakdown: materialMetaBreakdown,
    quantity: quantity,
    totalGrams: totalGrams,
    batchDiscountPct: batchDiscountPct,
    batchDiscountAmount: batchDiscountAmount,
    lotTotal: lotTotal,
    manualDiscountAmount: manualDiscountAmount,
    rateAudit: rateAudit,
    isSold: isSold,
    regularFont: regularFont,
    boldFont: boldFont,
  );

  await Printing.sharePdf(
    bytes: pdfBytes,
    filename: EsBO.pdfFileName,
    subject: EsBO.pdfShareSubject,
  );
}

/// Genera los bytes del PDF del reporte de cotizacion.
///
/// Reutilizable para share, print y preview.
///
/// - [isPro] gatea el branding: si false, el PDF usa "3dCalc" + sin logo.
/// - [variant] decide TODO el contenido (ver [QuoteReportVariant]).
/// - [metaGrams] / [metaTime] peso total y tiempo (muestran en todas las
///   variantes).
/// - [rateAudit] alimenta la seccion "Parametros de calculo". Solo se imprime
///   en las variantes internas, y se oculta si viene vacio.
/// - [isSold] imprime el estado de la cotizacion (solo variantes internas).
/// - [regularFont] / [boldFont] son inyectables para tests.
Future<Uint8List> buildQuotePdfBytes({
  required bool isPro,
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  WorldCurrency currency = WorldCurrency.bob,
  QuoteReportVariant variant = QuoteReportVariant.clientSimple,
  String? companyName,
  String? companyLogoBase64,
  String? pieceName,
  String? clientName,
  int? quoteNumber,
  DateTime? quoteDate,
  DateTime? validUntil,
  String? notes,
  String? conditions,
  Uint8List? pieceImageBytes,
  String? metaGrams,
  String? metaTime,
  List<PdfMaterialMetaItem> materialMetaBreakdown = const [],
  int quantity = 1,
  Decimal? totalGrams,
  Decimal? batchDiscountPct,
  Decimal? batchDiscountAmount,
  Decimal? lotTotal,
  Decimal? manualDiscountAmount,
  PdfRateAudit? rateAudit,
  bool? isSold,
  pw.Font? regularFont,
  pw.Font? boldFont,
}) async {
  final branding = resolveBranding(
    isPro: isPro,
    companyName: companyName,
    companyLogoBase64: companyLogoBase64,
  );

  final regular =
      regularFont ??
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold =
      boldFont ??
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final hasDiscount = output.discountAmount > Decimal.zero;
  final qty = quantity < 1 ? 1 : quantity;
  final qtyD = Decimal.fromInt(qty);
  // El output siempre viene como precio UNITARIO.
  final unitPrice = output.totalPrice;
  // Total final: lotTotal si viene del caller (incluye batch + manual);
  // si no, fallback al math legacy (unitPrice x qty).
  final effectiveTotal = lotTotal != null && lotTotal > Decimal.zero
      ? lotTotal
      : unitPrice * qtyD;

  // Descuento manual escalado: manualDiscountAmount si viene del caller;
  // si no, calcular desde output.discountAmount x qty.
  final effectiveManualDiscount =
      manualDiscountAmount ??
      (hasDiscount ? output.discountAmount * qtyD : Decimal.zero);

  // Subtotal antes de descuentos: effectiveTotal + batch + manual.
  // batchDiscountAmount ya viene escalado del caller (BatchLotComposer).
  final effectiveBatchDiscount = batchDiscountAmount ?? Decimal.zero;
  final subtotalBeforeDiscounts =
      effectiveTotal + effectiveBatchDiscount + effectiveManualDiscount;

  final hasBatchDiscount =
      batchDiscountPct != null && batchDiscountPct > Decimal.zero;
  final showsBatchDiscount =
      hasBatchDiscount && effectiveBatchDiscount > Decimal.zero;

  // Valores escalados para el desglose (unit x quantity).
  final dMaterialCost = output.materialCost * qtyD;
  final dElectricCost = output.electricCost * qtyD;
  final dAmortizationCost = output.amortizationCost * qtyD;
  final dLaborCost = output.laborCost * qtyD;
  final dPostProcessCost = output.postProcessCost * qtyD;
  final dBaseCost = output.baseCost * qtyD;
  final dFailureCost = output.failureCost * qtyD;
  final dMarkupCost = output.markupCost * qtyD;
  final dTotalBeforeProfit = output.totalBeforeProfit * qtyD;
  final dProfitAmount = output.profitAmount * qtyD;
  final dTotalFinal = output.totalFinal * qtyD;

  // Gramos: usar totalGrams directo (calculado desde CalculationMaterial en el caller).
  final effectiveGrams = totalGrams != null && totalGrams > Decimal.zero
      ? '${NumberFormat.decimalPattern('es_BO').format(totalGrams.toDouble())} g'
      : metaGrams;

  // ── Filas de la tabla de materiales ──
  // Fuente primaria: `materialMetaBreakdown` (trae peso + tiempo + costo
  // unitario). Fallback: `materials` (solo label + costo), para no romper
  // callers que no pasan el desglose de meta.
  final materialRows = _resolveMaterialRows(
    materialMetaBreakdown: materialMetaBreakdown,
    materials: materials,
    qtyD: qtyD,
    variant: variant,
    currency: currency,
  );
  final showsMaterialTable = materialRows.isNotEmpty;
  final showsMaterialTime = variant.showsMaterialTime;
  final showsMaterialCost = variant.showsMaterialCost;
  // `internalAdvanced` separa costo unitario de costo de lote.
  final showsLotCost = variant == QuoteReportVariant.internalAdvanced;

  final showRateSection =
      variant.showRateAudit && rateAudit != null && !rateAudit.isEmpty;
  final showSummaryBlock = variant.showsSummaryBlock;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),

      // ── Header (se repite en cada pagina; compacto desde la 2) ──
      header: (context) => _buildHeader(
        context: context,
        branding: branding,
        quoteNumber: quoteNumber,
        quoteDate: quoteDate,
        validUntil: validUntil,
      ),

      // ── Footer con paginacion ──
      footer: (context) =>
          _buildFooter(context: context, quoteNumber: quoteNumber),

      build: (context) {
        return <pw.Widget>[
          // ── 1. Piece name + client ──
          if (pieceName != null && pieceName.isNotEmpty) ...[
            pw.Text(
              pieceName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
          ],
          if (clientName != null && clientName.trim().isNotEmpty)
            pw.Text(
              '${EsBO.pdfClientPrefix}${clientName.trim()}',
              style: pw.TextStyle(fontSize: 11, color: _textSecondary),
            ),

          // ── 2. Estado de la cotizacion (solo internas) ──
          if (variant.showCostDetail && isSold != null) ...[
            pw.SizedBox(height: 6),
            _statusChip(isSold: isSold),
          ],

          // ── 3. Piece photo ──
          if (pieceImageBytes != null) ...[
            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Container(
                width: 270,
                height: 135,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderLight),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(
                    pw.MemoryImage(pieceImageBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── 4. Meta info: horas + descuento + peso/tiempo ──
          pw.SizedBox(height: 8),
          _buildMetaBox(
            totalHours: totalHours,
            discountPct: discountPct,
            metaGrams: effectiveGrams,
            metaTime: metaTime,
          ),
          pw.SizedBox(height: 16),

          // ── 5. Total price hero ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 18,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _accentColor, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      EsBO.calcTotalFinal,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    pw.Text(
                      _fmt(effectiveTotal, currency),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                  ],
                ),
                if (qty > 1) ...[
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        '$qty u. x ${_fmt(unitPrice, currency)}',
                        style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // ── 6. Tabla de materiales ──
          // Presente en TODAS las variantes: el cliente tiene derecho a saber
          // que material y cuanto se imprime. Lo que cambia son las columnas.
          if (showsMaterialTable) ...[
            _sectionHeader(EsBO.pdfMaterialsSection),
            pw.SizedBox(height: 8),
            _materialHeader(
              showTime: showsMaterialTime,
              showUnitCost: showsMaterialCost,
              showLotCost: showsLotCost,
            ),
            for (var i = 0; i < materialRows.length; i++)
              _materialRow(
                label: materialRows[i].label,
                weight: materialRows[i].weight,
                time: materialRows[i].time,
                unitCost: materialRows[i].unitCost,
                lotCost: materialRows[i].lotCost,
                altBackground: i.isOdd,
              ),
            if (showsMaterialCost && showsLotCost)
              _materialTotalRow(lotTotalText: _fmt(dMaterialCost, currency)),
            pw.SizedBox(height: 14),
          ],

          // ── 7. Bloque "Resumen de la cotizacion" (variantes de cliente) ──
          // Junta en una sola tabla lo que antes estaba disperso en 3 cajas:
          // peso, tiempo, cantidad, unitario, subtotal, descuentos, total.
          if (showSummaryBlock) ...[
            _sectionHeader(EsBO.pdfSummarySection),
            pw.SizedBox(height: 8),
            if (effectiveGrams != null)
              _dataRow(
                EsBO.pdfSummaryTotalWeight,
                effectiveGrams,
                altBackground: true,
              ),
            if (metaTime != null) _dataRow(EsBO.pdfSummaryTotalTime, metaTime),
            _dataRow(
              EsBO.pdfSummaryQuantity,
              '$qty u.',
              altBackground: effectiveGrams == null && metaTime == null,
            ),
            if (qty > 1)
              _dataRow(EsBO.pdfSummaryUnitPrice, _fmt(unitPrice, currency)),
            _thinDivider(marginTop: 4, marginBottom: 2),
            _dataRow(
              EsBO.pdfNoDiscount,
              _fmt(subtotalBeforeDiscounts, currency),
              bold: true,
              altBackground: true,
            ),
            if (showsBatchDiscount) ...[
              pw.SizedBox(height: 2),
              _dataRow(
                EsBO.calcDetailBatchDiscount(
                  batchDiscountPct.toDouble().round(),
                ),
                '-${_fmt(effectiveBatchDiscount, currency)}',
                valueColor: _errorColor,
              ),
            ],
            if (hasDiscount) ...[
              pw.SizedBox(height: 2),
              _dataRow(
                EsBO.calcDetailManualDiscount(discountPct.toDouble().round()),
                '-${_fmt(effectiveManualDiscount, currency)}',
                valueColor: _errorColor,
              ),
            ],
            _thinDivider(marginTop: 4, marginBottom: 2),
            _dataRow(
              EsBO.calcTotalFinal,
              _fmt(effectiveTotal, currency),
              bold: true,
              valueColor: _accentColor,
            ),
            pw.SizedBox(height: 14),
          ],

          // ── 8. Detail breakdown (solo variantes internas) ──
          if (variant.showCostDetail) ...[
            _sectionHeader(EsBO.detailBreakdown),
            pw.SizedBox(height: 8),
            _dataRow(
              EsBO.pdfMaterialCosts,
              _fmt(dMaterialCost, currency),
              altBackground: true,
            ),
            _dataRow(EsBO.pdfElectricity, _fmt(dElectricCost, currency)),
            if (output.amortizationCost > Decimal.zero)
              _dataRow(
                EsBO.calcDetailAmortization,
                _fmt(dAmortizationCost, currency),
                altBackground: true,
              ),
            if (output.laborCost > Decimal.zero)
              _dataRow(EsBO.calcDetailModeling, _fmt(dLaborCost, currency)),
            if (output.postProcessCost > Decimal.zero)
              _dataRow(
                EsBO.calcDetailPostProcess,
                _fmt(dPostProcessCost, currency),
                altBackground: true,
              ),
            _dataRow(
              EsBO.calcDetailBase,
              _fmt(dBaseCost, currency),
              bold: true,
            ),
            if (output.failureCost > Decimal.zero)
              _dataRow(
                EsBO.calcDetailFailure,
                _fmt(dFailureCost, currency),
                altBackground: true,
              ),
            if (output.markupCost > Decimal.zero)
              _dataRow(EsBO.calcFieldWaste, _fmt(dMarkupCost, currency)),
            if (output.profitAmount > Decimal.zero)
              _dataRow(
                EsBO.calcDetailProfit,
                _fmt(dProfitAmount, currency),
                valueColor: _successColor,
                altBackground: true,
              ),

            // Cierre aritmetico: sin esto el desglose no cuadra a la vista,
            // porque el unico total estaba en el hero de arriba.
            pw.SizedBox(height: 6),
            _thinDivider(),
            pw.SizedBox(height: 2),
            _dataRow(
              EsBO.pdfCostSubtotalClosing,
              _fmt(dTotalBeforeProfit, currency),
              bold: true,
            ),
            if (output.profitAmount > Decimal.zero)
              _dataRow(
                EsBO.calcDetailProfit,
                _fmt(dProfitAmount, currency),
                valueColor: _successColor,
              ),
            _thinDivider(marginTop: 4, marginBottom: 2),
            _dataRow(
              EsBO.pdfTotalBeforeDiscounts,
              _fmt(dTotalFinal, currency),
              bold: true,
              valueColor: _accentColor,
            ),
            pw.SizedBox(height: 14),
          ],

          // ── 9. Discount breakdown (solo variantes internas) ──
          if (variant.showCostDetail &&
              (showsBatchDiscount || hasDiscount)) ...[
            _sectionHeader(EsBO.calcLabelDiscount),
            pw.SizedBox(height: 8),
            _dataRow(
              EsBO.calcSubtotal,
              _fmt(subtotalBeforeDiscounts, currency),
              bold: true,
            ),
            if (showsBatchDiscount) ...[
              pw.SizedBox(height: 2),
              _dataRow(
                EsBO.calcDetailBatchDiscount(
                  batchDiscountPct.toDouble().round(),
                ),
                '-${_fmt(effectiveBatchDiscount, currency)}',
                valueColor: _errorColor,
              ),
            ],
            if (hasDiscount) ...[
              pw.SizedBox(height: 2),
              _dataRow(
                EsBO.calcDetailManualDiscount(discountPct.toDouble().round()),
                '-${_fmt(effectiveManualDiscount, currency)}',
                valueColor: _errorColor,
                strikeThrough: true,
              ),
            ],
            _thinDivider(marginTop: 4, marginBottom: 2),
            _dataRow(
              EsBO.calcTotalFinal,
              _fmt(effectiveTotal, currency),
              bold: true,
            ),
            pw.SizedBox(height: 14),
          ],

          // ── 10. Parametros de calculo (solo variantes internas) ──
          if (showRateSection) ...[
            _sectionHeader(EsBO.pdfRateAuditSection),
            pw.SizedBox(height: 8),
            _buildRateAuditBlock(
              audit: rateAudit,
              currency: currency,
              totalHours: totalHours,
            ),
            pw.SizedBox(height: 14),
          ],

          // ── 11. Notes + Conditions ──
          if (notes != null && notes.trim().isNotEmpty) ...[
            _sectionHeader(EsBO.pdfNotesTitle),
            pw.SizedBox(height: 6),
            pw.Text(
              notes.trim(),
              style: const pw.TextStyle(
                fontSize: 10,
                lineSpacing: 3,
                color: _textPrimary,
              ),
            ),
            pw.SizedBox(height: 10),
          ],
          if (conditions != null && conditions.trim().isNotEmpty) ...[
            _sectionHeader(EsBO.pdfConditionsTitle),
            pw.SizedBox(height: 6),
            pw.Text(
              conditions.trim(),
              style: const pw.TextStyle(
                fontSize: 10,
                lineSpacing: 3,
                color: _textPrimary,
              ),
            ),
          ],
        ];
      },
    ),
  );

  return doc.save();
}

// ── Sub-builders ─────────────────────────────────────────────────────

/// Fila normalizada de la tabla de materiales.
class _MaterialRow {
  const _MaterialRow({
    required this.label,
    required this.weight,
    this.time,
    this.unitCost,
    this.lotCost,
  });

  final String label;
  final String weight;
  final String? time;
  final String? unitCost;
  final String? lotCost;
}

/// Normaliza las filas de la tabla de materiales desde las dos fuentes que
/// aceptan los callers.
///
/// Fuente primaria: [materialMetaBreakdown] (trae peso + tiempo + costo
/// unitario resuelto). Fallback: [materials] (`MaterialCostBreakdown`, solo
/// label + costo) — mantiene funcionando a los callers que no pasan meta.
///
/// Cuando la variante pide columna de costo pero ninguna fila trae costo
/// unitario (fallback sin `unitCost`), se degrada a no imprimirla en vez de
/// imprimir ceros falsos.
List<_MaterialRow> _resolveMaterialRows({
  required List<PdfMaterialMetaItem> materialMetaBreakdown,
  required List<MaterialCostBreakdown> materials,
  required Decimal qtyD,
  required QuoteReportVariant variant,
  required WorldCurrency currency,
}) {
  final wantsTime = variant.showsMaterialTime;
  final wantsCost = variant.showsMaterialCost;

  if (materialMetaBreakdown.isNotEmpty) {
    final anyUnitCost = materialMetaBreakdown.any((m) => m.unitCost != null);
    final showUnitCost = wantsCost && anyUnitCost;
    final rows = materialMetaBreakdown.map((m) {
      final unit = m.unitCost;
      return _MaterialRow(
        label: m.label,
        weight: m.weightGrams,
        // Columna de tiempo: propio si existe, indicador de global si no.
        // Nunca "0h 0m" — ese numero seria mentira.
        time: wantsTime ? (m.timeStr ?? EsBO.pdfGlobalTime) : null,
        unitCost: showUnitCost && unit != null
            ? formatCurrency(unit, currency)
            : null,
        lotCost: showUnitCost && unit != null
            ? formatCurrency(unit * qtyD, currency)
            : null,
      );
    }).toList();
    return rows;
  }

  // Fallback: solo label + costo, sin peso ni tiempo.
  // Ojo: `MaterialCostBreakdown.cost` es UNITARIO (sin cantidad), igual que
  // `output.materialCost`. El costo de lote es el unitario x qty.
  return materials
      .map(
        (b) => _MaterialRow(
          label: b.label,
          weight: '',
          unitCost: wantsCost ? formatCurrency(b.cost, currency) : null,
          lotCost: wantsCost ? formatCurrency(b.cost * qtyD, currency) : null,
        ),
      )
      .toList();
}

/// Header del documento. Compacto desde la pagina 2 para no robarle espacio
/// al contenido cuando el reporte se parte (cotizacion advanced con muchos
/// materiales).
pw.Widget _buildHeader({
  required pw.Context context,
  required ({String name, String? logo}) branding,
  required int? quoteNumber,
  required DateTime? quoteDate,
  required DateTime? validUntil,
}) {
  final isFirstPage = context.pageNumber == 1;
  final logoSize = isFirstPage ? 40.0 : 20.0;
  final titleSize = isFirstPage ? 22.0 : 12.0;
  final metaFontSize = isFirstPage ? 9.0 : 8.0;

  return pw.Container(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Accent bar: solo en la pagina 1.
        if (isFirstPage) ...[_accentBar(), pw.SizedBox(height: 16)],
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (branding.logo != null)
                    pw.Container(
                      width: logoSize,
                      height: logoSize,
                      margin: pw.EdgeInsets.only(right: isFirstPage ? 12 : 8),
                      child: pw.Image(
                        pw.MemoryImage(base64Decode(branding.logo!)),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        branding.name,
                        style: pw.TextStyle(
                          fontSize: titleSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                      if (isFirstPage) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          EsBO.calcSheetTitle.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _accentColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (quoteNumber != null || quoteDate != null || validUntil != null)
              pw.Container(
                padding: pw.EdgeInsets.all(isFirstPage ? 10 : 6),
                decoration: pw.BoxDecoration(
                  color: _bgSubtle,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (quoteNumber != null)
                      pw.Text(
                        '${EsBO.pdfQuoteNumber}'
                        '${quoteNumber.toString().padLeft(4, '0')}',
                        style: pw.TextStyle(
                          fontSize: isFirstPage ? 12 : 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    if (quoteDate != null) ...[
                      pw.SizedBox(height: isFirstPage ? 3 : 1),
                      pw.Text(
                        '${EsBO.pdfDatePrefix}${_fmtDate(quoteDate)}',
                        style: pw.TextStyle(
                          fontSize: metaFontSize,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                    if (validUntil != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${EsBO.pdfValidUntilPrefix}${_fmtDate(validUntil)}',
                        style: pw.TextStyle(
                          fontSize: metaFontSize,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        if (isFirstPage) ...[
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: _borderLight),
          pw.SizedBox(height: 16),
        ] else ...[
          pw.SizedBox(height: 8),
          pw.Container(height: 0.5, color: _borderLight),
          pw.SizedBox(height: 12),
        ],
      ],
    ),
  );
}

/// Pie del documento con numeracion "Pagina X de Y".
pw.Widget _buildFooter({
  required pw.Context context,
  required int? quoteNumber,
}) {
  return pw.Container(
    child: pw.Column(
      children: [
        pw.Container(height: 0.5, color: _borderLight),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              EsBO.quoteGeneratedWith,
              style: pw.TextStyle(fontSize: 8, color: _textMuted),
            ),
            pw.Text(
              EsBO.pdfPageOf(context.pageNumber, context.pagesCount),
              style: pw.TextStyle(fontSize: 8, color: _textMuted),
            ),
            if (quoteNumber != null)
              pw.Text(
                '${EsBO.pdfQuoteNumber}'
                '${quoteNumber.toString().padLeft(4, '0')}',
                style: pw.TextStyle(fontSize: 8, color: _textMuted),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Chip de estado de la cotizacion (solo variantes internas).
pw.Widget _statusChip({required bool isSold}) {
  final color = isSold ? _successColor : _textSecondary;
  final label = isSold
      ? EsBO.calcDetailSold.toUpperCase()
      : EsBO.pdfStatusPending;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(
      color: isSold ? PdfColors.green50 : _bgSubtle,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: color,
        letterSpacing: 0.8,
      ),
    ),
  );
}

/// Seccion "Parametros de calculo": la tabla que permite auditar el desglose.
///
/// Es el motivo de ser de [PdfRateAudit] — con las tasas al lado de los
/// montos, cualquier linea se puede recalcular a mano.
pw.Widget _buildRateAuditBlock({
  required PdfRateAudit audit,
  required WorldCurrency currency,
  required Decimal totalHours,
}) {
  // Formatea un valor como "Bs. 25,00" o "25 %" segun corresponda.
  String money(Decimal? v) => v == null ? '—' : formatCurrency(v, currency);

  String perHour(Decimal? v) => v == null || v <= Decimal.zero
      ? '—'
      : '${formatCurrencyNumber(v)} ${EsBO.pdfRatePerHour}';

  String pct(Decimal? v) => v == null ? '—' : formatPercentage(v);

  // Marca "—" todo lo que no hay dato. Imprimir 0 seria mentir.
  final rows = <(String, String)>[
    if (audit.printerName != null && audit.printerName!.isNotEmpty)
      (
        EsBO.pdfRatePrinter,
        audit.printerWatts != null && audit.printerWatts! > 0
            ? '${audit.printerName} (${audit.printerWatts} W)'
            : audit.printerName!,
      ),
    (
      EsBO.pdfRateKwh,
      audit.kwhRate != null && audit.kwhRate! > Decimal.zero
          ? '${formatCurrencyNumber(audit.kwhRate!)} ${EsBO.pdfRatePerKwh}'
          : '—',
    ),
    (EsBO.pdfRateBillableHours, '${totalHours.toStringAsFixed(2)} h'),
    (EsBO.pdfRateLabor, perHour(audit.laborRate)),
    (EsBO.pdfRateAmortization, perHour(audit.amortizationPerHour)),
    (EsBO.calcDetailPostProcess, pct(audit.postProcessRate)),
    (EsBO.calcDetailFailure, pct(audit.failureRate)),
    (EsBO.calcFieldWaste, pct(audit.markupOnMaterials)),
    (EsBO.calcDetailProfit, pct(audit.profitBase)),
    (EsBO.pdfRateMargin, pct(audit.profitMarginPct)),
    (EsBO.pdfRateMarkupOverCost, pct(audit.markupOverCostPct)),
  ];

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: _bgSubtle,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            color: i.isOdd ? PdfColors.white : null,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  rows[i].$1,
                  style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                ),
                pw.Text(
                  rows[i].$2,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        // Referencia al monto de amortizacion: deja claro que la fila de
        // arriba es un costo/hora derivado, no una tasa configurada.
        if (audit.amortizationPerHour != null &&
            audit.amortizationPerHour! > Decimal.zero)
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: pw.Text(
              '${EsBO.calcDetailAmortization}: ${money(audit.amortizationPerHour)} '
              'x ${totalHours.toStringAsFixed(2)} h = '
              '${formatCurrency(audit.amortizationPerHour! * totalHours, currency)}',
              style: pw.TextStyle(fontSize: 8, color: _textMuted),
            ),
          ),
      ],
    ),
  );
}
