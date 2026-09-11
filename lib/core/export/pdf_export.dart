/// Exporta la cotizacion actual a PDF.
///
/// Usa el paquete `pdf` (Dart PDF) para generar un documento vectorial
/// con los mismos datos que la QuoteImageTemplate.
///
/// Diseno profesional:
/// - Barra de color superior (accent bar)
/// - Header con logo + branding + metadata de cotizacion
/// - Seccion tecnica (peso + tiempo) en ambos modos
/// - Total hero con fondo colorido
/// - Tabla de materiales estilo profesional
/// - Desglose con filas alternadas y subtotales marcados
/// - Footer con atribucion
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

/// Branding forzado para usuarios Free.
const String kFreeDefaultCompanyName = '3dCalc';

/// Dias de validez de la oferta (se imprime como "valido hasta").
const int kQuoteValidDays = 15;

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

// ── API publica ─────────────────────────────────────────────────────

/// Genera un PDF con el resumen de cotizacion y lo comparte via share sheet.
Future<void> shareQuotePdf({
  required bool isPro,
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  WorldCurrency currency = WorldCurrency.bob,
  bool showDetail = true,
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
  int quantity = 1,
  Decimal? totalGrams,
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
    showDetail: showDetail,
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
    quantity: quantity,
    totalGrams: totalGrams,
    regularFont: regularFont,
    boldFont: boldFont,
  );

  await Printing.sharePdf(
    bytes: pdfBytes,
    filename: EsBO.pdfFileName,
    subject: EsBO.pdfShareSubject,
  );
}

/// Genera los bytes del PDF de cotizacion.
///
/// Reutilizable para share, print, preview.
///
/// - [isPro] gatea el branding: si false, el PDF usa "3dCalc" + sin logo.
/// - [showDetail] controla si el PDF incluye el desglose interno de costos.
/// - [metaGrams] / [metaTime] peso total y tiempo (muetra en ambos modos).
/// - [regularFont] / [boldFont] son inyectables para tests.
Future<Uint8List> buildQuotePdfBytes({
  required bool isPro,
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  WorldCurrency currency = WorldCurrency.bob,
  bool showDetail = true,
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
  int quantity = 1,
  Decimal? totalGrams,
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
  final hasMaterials = materials.isNotEmpty;
  final qty = quantity < 1 ? 1 : quantity;
  final qtyD = Decimal.fromInt(qty);
  // El output siempre viene como precio UNITARIO.
  final unitPrice = output.totalPrice;
  final displayTotal = unitPrice * qtyD;

  // Valores escalados para el desglose (unit x quantity).
  final dMaterialCost = output.materialCost * qtyD;
  final dElectricCost = output.electricCost * qtyD;
  final dAmortizationCost = output.amortizationCost * qtyD;
  final dLaborCost = output.laborCost * qtyD;
  final dPostProcessCost = output.postProcessCost * qtyD;
  final dBaseCost = output.baseCost * qtyD;
  final dFailureCost = output.failureCost * qtyD;
  final dMarkupCost = output.markupCost * qtyD;
  final dProfitAmount = output.profitAmount * qtyD;
  final dDiscountAmount = output.discountAmount * qtyD;

  // Gramos: usar totalGrams directo (calculado desde CalculationMaterial en el caller).
  final effectiveGrams = totalGrams != null && totalGrams > Decimal.zero
      ? '${NumberFormat.decimalPattern('es_BO').format(totalGrams.toDouble())} g'
      : metaGrams;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── 1. Accent bar ──
            _accentBar(),
            pw.SizedBox(height: 16),

            // ── 2. Header: logo + branding | numero + fechas ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (branding.logo != null)
                        pw.Container(
                          width: 40,
                          height: 40,
                          margin: const pw.EdgeInsets.only(right: 12),
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
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
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
                      ),
                    ],
                  ),
                ),
                if (quoteNumber != null ||
                    quoteDate != null ||
                    validUntil != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
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
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        if (quoteDate != null) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '${EsBO.pdfDatePrefix}${_fmtDate(quoteDate)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                        if (validUntil != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${EsBO.pdfValidUntilPrefix}${_fmtDate(validUntil)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(height: 1, color: _borderLight),
            pw.SizedBox(height: 16),

            // ── 3. Piece name + client ──
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
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),

            // ── 4. Piece photo ──
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

            // ── 5. Meta info: horas + descuento + peso/tiempo (ambos modos) ──
            pw.SizedBox(height: 8),
            _buildMetaBox(
              totalHours: totalHours,
              discountPct: discountPct,
              metaGrams: effectiveGrams,
              metaTime: metaTime,
            ),
            pw.SizedBox(height: 16),

            // ── 6. Total price hero ──
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 18,
              ),
              decoration: pw.BoxDecoration(
                color: _accentColor,
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(8),
                ),
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
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        _fmt(displayTotal, currency),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  if (quantity > 1) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$quantity u. × ${_fmt(unitPrice, currency)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ── 7. Detail breakdown (solo si showDetail) ──
            if (showDetail) ...[
              _sectionHeader(EsBO.detailBreakdown),
              pw.SizedBox(height: 8),
              _dataRow(
                EsBO.pdfMaterialCosts,
                _fmt(dMaterialCost, currency),
                altBackground: true,
              ),
              _dataRow(
                EsBO.pdfElectricity,
                _fmt(dElectricCost, currency),
              ),
              if (output.amortizationCost > Decimal.zero)
                _dataRow(
                  EsBO.calcDetailAmortization,
                  _fmt(dAmortizationCost, currency),
                  altBackground: true,
                ),
              if (output.laborCost > Decimal.zero)
                _dataRow(
                  EsBO.calcDetailLabor,
                  _fmt(dLaborCost, currency),
                ),
              if (output.postProcessCost > Decimal.zero)
                _dataRow(
                  EsBO.calcDetailPostProcess,
                  _fmt(dPostProcessCost, currency),
                  altBackground: true,
                ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 2),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: _borderLight, width: 0.5),
                  ),
                ),
                child: _dataRow(
                  EsBO.calcDetailBase,
                  _fmt(dBaseCost, currency),
                  bold: true,
                ),
              ),
              if (output.failureCost > Decimal.zero)
                _dataRow(
                  EsBO.calcDetailFailure,
                  _fmt(dFailureCost, currency),
                  altBackground: true,
                ),
              if (output.markupCost > Decimal.zero)
                _dataRow(
                  EsBO.calcFieldWaste,
                  _fmt(dMarkupCost, currency),
                ),
              if (output.profitAmount > Decimal.zero)
                _dataRow(
                  EsBO.calcDetailProfit,
                  _fmt(dProfitAmount, currency),
                  valueColor: _successColor,
                  altBackground: true,
                ),
              if (hasDiscount)
                _dataRow(
                  EsBO.calcLabelDiscount,
                  '-${_fmt(dDiscountAmount, currency)}',
                  valueColor: _errorColor,
                ),

              // Total final con linea
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: _accentLight,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      EsBO.pdfTotalUpper,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    pw.Text(
                      _fmt(displayTotal, currency),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // ── 8. Materials table ──
              if (hasMaterials) ...[
                _sectionHeader(EsBO.pdfMaterialsSection),
                pw.SizedBox(height: 8),
                // Header row
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                          EsBO.calcSectionMaterials,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      pw.Text(
                        EsBO.pdfTotalUpper,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Material rows
                for (var i = 0; i < materials.length; i++)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: i.isOdd ? _bgSubtle : null,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          materials[i].label,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _textPrimary,
                          ),
                        ),
                        pw.Text(
                          _fmt(materials[i].cost * qtyD, currency),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 14),
              ],
            ],

            // ── 7b. Discount summary (modo basico sin showDetail) ──
            if (!showDetail && hasDiscount) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: _errorColor, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  children: [
                    _dataRow(
                      EsBO.quoteNoDiscount,
                      _fmt(
                        displayTotal + dDiscountAmount,
                        currency,
                      ),
                    ),
                    _dataRow(
                      EsBO.quoteDiscountPct(discountPct.toDouble().round()),
                      '-${_fmt(dDiscountAmount, currency)}',
                      valueColor: _errorColor,
                      strikeThrough: true,
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: _borderLight, width: 0.5),
                        ),
                      ),
                      child: pw.SizedBox(height: 4),
                    ),
                    _dataRow(
                      EsBO.calcTotalWithDiscount,
                      _fmt(displayTotal, currency),
                      bold: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
            ],

            // ── 9. Notes + Conditions ──
            if (notes != null && notes.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
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

            // ── 10. Footer ──
            pw.Spacer(),
            pw.Container(height: 1, color: _borderLight),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  EsBO.quoteGeneratedWith,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: _textMuted,
                  ),
                ),
                if (quoteNumber != null)
                  pw.Text(
                    '${EsBO.pdfQuoteNumber}'
                    '${quoteNumber.toString().padLeft(4, '0')}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _textMuted,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}
