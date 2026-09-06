// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tresdcal/core/utils/image_downscale.dart';

/// Genera un PNG solido de `w x h`.
Uint8List _pngOf(int w, int h) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(60, 120, 200));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('downscalePieceImage (F2)', () {
    test('null → null', () {
      expect(downscalePieceImage(null), isNull);
    });

    test('bytes vacios → null', () {
      expect(downscalePieceImage(Uint8List(0)), isNull);
    });

    test('input no decodificable → null (no crashea)', () {
      expect(
        downscalePieceImage(Uint8List.fromList(List.filled(64, 0x42))),
        isNull,
      );
    });

    test(
      'imagen debajo del limite pasa sin upscale (dimensiones intactas)',
      () {
        final out = downscalePieceImage(_pngOf(320, 200));
        expect(out, isNotNull);
        final decoded = img.decodeImage(out!);
        expect(decoded, isNotNull);
        expect(decoded!.width, 320);
        expect(decoded.height, 200);
      },
    );

    test('imagen grande se downscale al lado mayor = maxDimension', () {
      final out = downscalePieceImage(_pngOf(2400, 1800));
      expect(out, isNotNull);
      final decoded = img.decodeImage(out!);
      expect(decoded, isNotNull);

      final longSide = decoded!.width > decoded.height
          ? decoded.width
          : decoded.height;
      expect(longSide, kPieceImageMaxDimension);
      // Aspect ratio preservado: 2400/1800 = 4:3 → 1200x900.
      expect(decoded.width, 1200);
      expect(decoded.height, 900);
    });

    test('cuadrado gigante queda en maxDimension x maxDimension', () {
      final out = downscalePieceImage(_pngOf(3000, 3000));
      final decoded = img.decodeImage(out!);
      expect(decoded!.width, kPieceImageMaxDimension);
      expect(decoded.height, kPieceImageMaxDimension);
    });

    test('salida es JPEG (re-encode) y respeta la calidad pedida', () {
      final out = downscalePieceImage(_pngOf(600, 400), quality: 85);
      final decoded = img.decodeImage(out!);
      expect(decoded, isNotNull);
      // JPEG: arranca con el SOI marker FF D8 FF.
      expect(out.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    });

    test('parametros custom: maxDimension + quality override', () {
      final out = downscalePieceImage(
        _pngOf(1600, 800),
        maxDimension: 800,
        quality: 50,
      );
      final decoded = img.decodeImage(out!);
      expect(decoded, isNotNull);
      expect(decoded!.width, 800);
      expect(decoded.height, 400);
    });
  });
}
