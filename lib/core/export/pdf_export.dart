/// Exporta la cotizacion actual a PDF.
///
/// Usa el paquete `pdf` (Dart PDF) para generar un documento vectorial
/// con los mismos datos que la QuoteImageTemplate.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../features/calculation/domain/entities/calculation_output.dart';
import '../../features/calculation/presentation/state/calculator_state.dart';
import '../../l10n/es_bo.dart';
import '../money/currency_formatter.dart';

/// Branding forzado para usuarios Free.
///
/// El footer "Generado con 3dCalc" sigue diciendo "3dCalc" para Free y Pro
/// (es atribucion de la app, no branding del user).
const String kFreeDefaultCompanyName = '3dCalc';

/// Shorthand: formatea un Decimal con simbolo Bs para PDF.
String _fmt(Decimal v) => formatBob(v);

/// Resuelve el branding efectivo del PDF segun el estado Pro del user.
///
/// - **Pro** ([isPro] == true): usa el [companyName] y [companyLogoBase64]
///   del caller. Si el user no configuro nombre, cae a [kFreeDefaultCompanyName]
///   (mismo fallback que el resto de la app).
/// - **Free** ([isPro] == false): IGNORA el companyName del user y fuerza
///   el nombre generico de la app + sin logo. La razon es que el branding
///   profesional (logo + nombre de empresa) es un feature Pro (ver plan
///   T13, gates SC1).
///
/// Retorna un record con `name` (no-null, listo para `pw.Text`) y `logo`
/// (null si no hay logo que renderizar).
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

/// Genera un PDF con el resumen de cotizacion y lo comparte via share sheet.
Future<void> shareQuotePdf({
  required bool isPro,
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  String? companyName,
  String? companyLogoBase64,
  String? pieceName,
  pw.Font? regularFont,
  pw.Font? boldFont,
}) async {
  final pdfBytes = await buildQuotePdfBytes(
    isPro: isPro,
    output: output,
    materials: materials,
    totalHours: totalHours,
    discountPct: discountPct,
    companyName: companyName,
    companyLogoBase64: companyLogoBase64,
    pieceName: pieceName,
    regularFont: regularFont,
    boldFont: boldFont,
  );

  // XFile.fromData sin escribir a disco para compat mobile + web + desktop.
  await Share.shareXFiles(
    [XFile.fromData(pdfBytes, name: EsBO.pdfFileName)],
    subject: EsBO.pdfShareSubject,
  );
}

/// Genera los bytes del PDF de cotizacion.
///
/// Reutilizable para share, print, preview.
///
/// - [isPro] gatea el branding: si false, el PDF usa "3dCalc" + sin logo
///   (ignora [companyName] y [companyLogoBase64]).
/// - [regularFont] / [boldFont] son inyectables para tests (evitan
///   `rootBundle.load`); en runtime se cargan desde `assets/fonts/`.
Future<Uint8List> buildQuotePdfBytes({
  required bool isPro,
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  String? companyName,
  String? companyLogoBase64,
  String? pieceName,
  pw.Font? regularFont,
  pw.Font? boldFont,
}) async {
  final branding = resolveBranding(
    isPro: isPro,
    companyName: companyName,
    companyLogoBase64: companyLogoBase64,
  );

  final regular = regularFont ?? pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final bold = boldFont ?? pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: regular,
      bold: bold,
    ),
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
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
                    pw.Text(branding.name,
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.Text(EsBO.calcSheetTitle,
                        style: pw.TextStyle(
                            fontSize: 14, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Piece name
            if (pieceName != null && pieceName.isNotEmpty)
              pw.Text(pieceName,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            // Date
            pw.Text(
                '${EsBO.pdfDatePrefix}${DateTime.now().toLocal().toString().split('.')[0]}',
                style:
                    pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),

            // Total price hero
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(EsBO.calcTotalFinal,
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(_fmt(output.totalPrice),
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Breakdown
            pw.Text(EsBO.detailBreakdown,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _row(EsBO.pdfMaterialCosts, _fmt(output.materialCost)),
            if (output.electricCost > Decimal.zero)
              _row(EsBO.pdfElectricity, _fmt(output.electricCost)),
            if (output.laborCost > Decimal.zero)
              _row(EsBO.calcDetailLabor, _fmt(output.laborCost)),
            if (output.postProcessCost > Decimal.zero)
              _row(EsBO.calcDetailPostProcess, _fmt(output.postProcessCost)),
            _row(EsBO.calcDetailBase, _fmt(output.baseCost), bold: true),
            if (output.failureCost > Decimal.zero)
              _row(EsBO.calcDetailFailure, _fmt(output.failureCost)),
            if (output.markupCost > Decimal.zero)
              _row(EsBO.calcFieldWaste, _fmt(output.markupCost)),
            if (output.profitAmount > Decimal.zero)
              _row(EsBO.calcDetailProfit, _fmt(output.profitAmount)),
            if (output.discountAmount > Decimal.zero)
              _row(EsBO.calcLabelDiscount, '-${_fmt(output.discountAmount)}'),
            pw.Divider(),
            _row(EsBO.pdfTotalUpper, _fmt(output.totalPrice), bold: true),

            pw.SizedBox(height: 16),

            // Materials
            if (materials.isNotEmpty) ...[
              pw.Text(EsBO.calcSectionMaterials,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              for (final m in materials)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${m.label}: ${_fmt(m.cost)}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
            ],

            pw.SizedBox(height: 8),

            // Meta
            if (totalHours > Decimal.zero)
              pw.Text('${EsBO.pdfHoursPrefix}${totalHours.toStringAsFixed(2)}h',
                  style: pw.TextStyle(fontSize: 10)),
            if (discountPct > Decimal.zero)
              pw.Text(EsBO.pdfDiscountPct(discountPct.toDouble().round()),
                  style: pw.TextStyle(fontSize: 10)),

            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Footer
            pw.Text(EsBO.quoteGeneratedWith,
                style: pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey500)),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _row(String label, String formatted, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(formatted,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    ),
  );
}
