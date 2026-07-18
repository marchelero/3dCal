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
import '../money/currency_formatter.dart';

/// Shorthand: formatea un Decimal con simbolo Bs para PDF.
String _fmt(Decimal v) => formatBob(v);

/// Genera un PDF con el resumen de cotizacion y lo comparte via share sheet.
Future<void> shareQuotePdf({
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  String? companyName,
  String? companyLogoBase64,
  String? pieceName,
}) async {
  final pdfBytes = await buildQuotePdfBytes(
    output: output,
    materials: materials,
    totalHours: totalHours,
    discountPct: discountPct,
    companyName: companyName,
    companyLogoBase64: companyLogoBase64,
    pieceName: pieceName,
  );

  // XFile.fromData sin escribir a disco para compat mobile + web + desktop.
  await Share.shareXFiles(
    [XFile.fromData(pdfBytes, name: 'cotizacion_3dcalc.pdf')],
    subject: 'Cotización 3dCalc',
  );
}

/// Genera los bytes del PDF de cotizacion.
///
/// Reutilizable para share, print, preview.
Future<Uint8List> buildQuotePdfBytes({
  required CalculationOutput output,
  required List<MaterialCostBreakdown> materials,
  required Decimal totalHours,
  required Decimal discountPct,
  String? companyName,
  String? companyLogoBase64,
  String? pieceName,
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
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
                if (companyLogoBase64 != null && companyLogoBase64.isNotEmpty)
                  pw.Container(
                    width: 40,
                    height: 40,
                    margin: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(
                      pw.MemoryImage(base64Decode(companyLogoBase64)),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(companyName ?? '3dCalc',
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.Text('Cotización',
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
                'Fecha: ${DateTime.now().toLocal().toString().split('.')[0]}',
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
                  pw.Text('Total',
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
            pw.Text('Desglose',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _row('Costo materiales', _fmt(output.materialCost)),
            if (output.electricCost > Decimal.zero)
              _row('Electricidad', _fmt(output.electricCost)),
            if (output.laborCost > Decimal.zero)
              _row('Mano de obra', _fmt(output.laborCost)),
            if (output.postProcessCost > Decimal.zero)
              _row('Post-procesado', _fmt(output.postProcessCost)),
            _row('Costo base', _fmt(output.baseCost), bold: true),
            if (output.failureCost > Decimal.zero)
              _row('Tasa de falla', _fmt(output.failureCost)),
            if (output.markupCost > Decimal.zero)
              _row('Desperdicio', _fmt(output.markupCost)),
            if (output.profitAmount > Decimal.zero)
              _row('Ganancia', _fmt(output.profitAmount)),
            if (output.discountAmount > Decimal.zero)
              _row('Descuento', '-${_fmt(output.discountAmount)}'),
            pw.Divider(),
            _row('TOTAL', _fmt(output.totalPrice), bold: true),

            pw.SizedBox(height: 16),

            // Materials
            if (materials.isNotEmpty) ...[
              pw.Text('Materiales',
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
              pw.Text('Horas: ${totalHours.toStringAsFixed(2)}h',
                  style: pw.TextStyle(fontSize: 10)),
            if (discountPct > Decimal.zero)
              pw.Text('Descuento: ${discountPct.toStringAsFixed(0)}%',
                  style: pw.TextStyle(fontSize: 10)),

            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Footer
            pw.Text('Generado con 3dCalc',
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
