// ignore_for_file: public_member_api_docs
//
// T13 — PDF branding gate (Free vs Pro).
//
// Two layers of coverage:
//
// 1. `resolveBranding()` — pure helper, fast, comprehensive text logic.
// 2. `buildQuotePdfBytes()` — full PDF integration. El content stream esta
//    FlateDecode compressed, asi que verificamos el gate via la presencia
//    del image XObject (logo) y el tamano relativo del PDF. La logica de
//    texto vive en `resolveBranding` y se cubre arriba.
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tresdcal/core/export/pdf_export.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';

CalculationOutput _output() => CalculationOutput.simple(
  materialCost: Decimal.fromInt(12),
  discountAmount: Decimal.zero,
  totalPrice: Decimal.fromInt(36),
);

/// 1x1 transparent PNG en base64 (valido, generado externamente).
/// Suficiente para ejercitar el path de logo sin necesitar un asset real.
const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=';

/// Cuenta los image XObjects del PDF (cada `/Subtype /Image` es una imagen
/// embebida: logo de empresa y/o foto de pieza).
int _countImageXObjects(Uint8List pdfBytes) {
  final text = latin1.decode(pdfBytes, allowInvalid: true);
  return RegExp(r'/Subtype\s*/Image').allMatches(text).length;
}

/// True si el PDF contiene al menos un image XObject (logo embebido).
bool _hasImageXObject(Uint8List pdfBytes) => _countImageXObjects(pdfBytes) > 0;

void main() {
  // Helvetica default fonts para evitar rootBundle asset loading en unit tests.
  // (El path real carga Roboto desde assets/fonts; tests inyectan fallback.)
  final helv = pw.Font.helvetica();
  final helvBold = pw.Font.helveticaBold();

  group('resolveBranding (T13 gate, pure helper)', () {
    test('isPro=true: usa companyName + logo del caller', () {
      final r = resolveBranding(
        isPro: true,
        companyName: 'Mi Empresa',
        companyLogoBase64: 'logo-base64',
      );
      expect(r.name, 'Mi Empresa');
      expect(r.logo, 'logo-base64');
    });

    test('isPro=true con companyName null: cae a "3dCalc" sin logo', () {
      final r = resolveBranding(
        isPro: true,
        companyName: null,
        companyLogoBase64: null,
      );
      expect(r.name, '3dCalc');
      expect(r.logo, isNull);
    });

    test('isPro=true con companyName vacio: cae a "3dCalc" sin logo', () {
      final r = resolveBranding(
        isPro: true,
        companyName: '',
        companyLogoBase64: 'logo',
      );
      expect(r.name, '3dCalc');
      expect(r.logo, 'logo');
    });

    test(
      'isPro=false: ignora companyName del user, fuerza "3dCalc" + sin logo',
      () {
        final r = resolveBranding(
          isPro: false,
          companyName: 'Mi Empresa Custom',
          companyLogoBase64: 'should-be-ignored',
        );
        expect(r.name, '3dCalc');
        expect(r.logo, isNull);
      },
    );

    test(
      'isPro=false con companyName null: igual fuerza "3dCalc" + sin logo',
      () {
        final r = resolveBranding(
          isPro: false,
          companyName: null,
          companyLogoBase64: null,
        );
        expect(r.name, '3dCalc');
        expect(r.logo, isNull);
      },
    );

    test('isPro=false con string vacio: igual fuerza "3dCalc"', () {
      final r = resolveBranding(
        isPro: false,
        companyName: '',
        companyLogoBase64: 'logo',
      );
      expect(r.name, '3dCalc');
      expect(r.logo, isNull);
    });
  });

  group('buildQuotePdfBytes — branding gate (T13 integration)', () {
    test('isPro=true con logo: PDF embebe image XObject', () async {
      final bytes = await buildQuotePdfBytes(
        isPro: true,
        output: _output(),
        materials: const [],
        totalHours: Decimal.zero,
        discountPct: Decimal.zero,
        companyName: 'Mi Empresa Pro',
        companyLogoBase64: _tinyPngBase64,
        pieceName: 'Pieza test',
        regularFont: helv,
        boldFont: helvBold,
      );

      expect(bytes.length, greaterThan(500));
      expect(
        _hasImageXObject(bytes),
        isTrue,
        reason: 'Pro PDF debe contener image XObject (logo del user)',
      );
    });

    test('isPro=true sin logo: PDF valido sin image XObject', () async {
      final bytes = await buildQuotePdfBytes(
        isPro: true,
        output: _output(),
        materials: const [],
        totalHours: Decimal.zero,
        discountPct: Decimal.zero,
        companyName: 'Mi Empresa Pro',
        companyLogoBase64: null,
        pieceName: null,
        regularFont: helv,
        boldFont: helvBold,
      );

      expect(bytes.length, greaterThan(500));
      expect(_hasImageXObject(bytes), isFalse);
    });

    test(
      'isPro=false con logo en settings: PDF IGNORA el logo (sin XObject)',
      () async {
        final bytes = await buildQuotePdfBytes(
          isPro: false,
          output: _output(),
          materials: const [],
          totalHours: Decimal.zero,
          discountPct: Decimal.zero,
          // El user tiene logo configurado, pero isPro=false lo ignora.
          companyName: 'Mi Empresa Custom',
          companyLogoBase64: _tinyPngBase64,
          pieceName: null,
          regularFont: helv,
          boldFont: helvBold,
        );

        expect(bytes.length, greaterThan(500));
        expect(
          _hasImageXObject(bytes),
          isFalse,
          reason:
              'Free PDF NO debe contener logo del user aunque este '
              'configurado en settings',
        );
      },
    );

    test(
      'isPro=false produce PDF mas chico que isPro=true (sin logo embebido)',
      () async {
        final proBytes = await buildQuotePdfBytes(
          isPro: true,
          output: _output(),
          materials: const [],
          totalHours: Decimal.zero,
          discountPct: Decimal.zero,
          companyName: 'Mi Empresa Pro',
          companyLogoBase64: _tinyPngBase64,
          pieceName: null,
          regularFont: helv,
          boldFont: helvBold,
        );
        final freeBytes = await buildQuotePdfBytes(
          isPro: false,
          output: _output(),
          materials: const [],
          totalHours: Decimal.zero,
          discountPct: Decimal.zero,
          companyName: 'Mi Empresa Custom',
          companyLogoBase64: _tinyPngBase64,
          pieceName: null,
          regularFont: helv,
          boldFont: helvBold,
        );

        // Free PDF sin logo embebido deberia ser mas chico.
        expect(
          freeBytes.length,
          lessThan(proBytes.length),
          reason: 'Free PDF (sin logo) debe pesar menos que Pro PDF (con logo)',
        );
      },
    );
  });

  group('buildQuotePdfBytes — foto de pieza (SC10)', () {
    test('isPro=false sin foto: 0 image XObjects (regresion)', () async {
      final bytes = await buildQuotePdfBytes(
        isPro: false,
        output: _output(),
        materials: const [],
        totalHours: Decimal.zero,
        discountPct: Decimal.zero,
        pieceName: null,
        regularFont: helv,
        boldFont: helvBold,
      );

      expect(bytes.length, greaterThan(500));
      expect(
        _countImageXObjects(bytes),
        0,
        reason: 'Free sin foto debe tener 0 imagenes embebidas',
      );
    });

    test('isPro=false + foto: 1 image XObject (la foto de la pieza)', () async {
      final bytes = await buildQuotePdfBytes(
        isPro: false,
        output: _output(),
        materials: const [],
        totalHours: Decimal.zero,
        discountPct: Decimal.zero,
        pieceImageBytes: base64Decode(_tinyPngBase64),
        pieceName: null,
        regularFont: helv,
        boldFont: helvBold,
      );

      expect(bytes.length, greaterThan(500));
      expect(
        _countImageXObjects(bytes),
        greaterThanOrEqualTo(1),
        reason: 'Free con foto debe embeber la imagen de la pieza (SC10)',
      );
    });

    test(
      'isPro=true + logo + foto: >= 2 image XObjects (logo y foto)',
      () async {
        final bytes = await buildQuotePdfBytes(
          isPro: true,
          output: _output(),
          materials: const [],
          totalHours: Decimal.zero,
          discountPct: Decimal.zero,
          companyName: 'Mi Empresa Pro',
          companyLogoBase64: _tinyPngBase64,
          pieceImageBytes: base64Decode(_tinyPngBase64),
          pieceName: null,
          regularFont: helv,
          boldFont: helvBold,
        );

        expect(bytes.length, greaterThan(500));
        expect(
          _countImageXObjects(bytes),
          greaterThanOrEqualTo(2),
          reason: 'Pro con logo + foto debe embeber ambas (no confundirse)',
        );
      },
    );
  });

  group('buildQuotePdfBytes — showDetail mode (visibilidad de desglose)', () {
    test(
      'showDetail=false genera PDF basico (mas ligero por omitir desglose)',
      () async {
        final fullBytes = await buildQuotePdfBytes(
          isPro: true,
          output: _output(),
          materials: const [],
          totalHours: Decimal.zero,
          discountPct: Decimal.zero,
          showDetail: true,
          regularFont: helv,
          boldFont: helvBold,
        );

        final basicBytes = await buildQuotePdfBytes(
          isPro: true,
          output: _output(),
          materials: const [],
          totalHours: Decimal.zero,
          discountPct: Decimal.zero,
          showDetail: false,
          regularFont: helv,
          boldFont: helvBold,
        );

        expect(basicBytes.length, greaterThan(300));
        expect(
          basicBytes.length,
          lessThan(fullBytes.length),
          reason: 'PDF sin desglose (showDetail=false) debe ser mas ligero',
        );
      },
    );
  });
}
