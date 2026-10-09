// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tresdcal/core/export/pdf_export.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';

void main() {
  CalculationOutput output() => CalculationOutput.simple(
    materialCost: Decimal.fromInt(100),
    discountAmount: Decimal.zero,
    totalPrice: Decimal.fromInt(100),
  );

  Future<int> build({String? logo}) async {
    final bytes = await buildQuotePdfBytes(
      isPro: true,
      companyLogoBase64: logo,
      output: output(),
      materials: const [],
      totalHours: Decimal.one,
      discountPct: Decimal.zero,
      regularFont: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
    );
    return bytes.length;
  }

  group('buildQuotePdfBytes — guard de logo base64 (T1-4)', () {
    test('logo corrupto NO crashea y genera un PDF no vacio', () async {
      // '!' y '-' no son validos en base64: base64Decode lanzaria sin guard.
      final length = await build(logo: 'esto-no-es-base64!!!');
      expect(length, greaterThan(0));
    });

    test('base64 valido pero NO imagen se omite sin crashear', () async {
      // 'aGVsbG8=' == "hello": base64 valido, pero no es una imagen
      // decodificable -> pw.MemoryImage lanzaria sin el guard.
      final length = await build(logo: 'aGVsbG8=');
      expect(length, greaterThan(0));
    });

    test('sin logo genera PDF igual', () async {
      final length = await build();
      expect(length, greaterThan(0));
    });
  });
}
