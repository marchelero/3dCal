// ignore_for_file: public_member_api_docs
//
// T7 — Unit tests del picker de imagen de pieza (SC6: validacion V1/V3).
//
// El picker real usa `ImagePicker.pickImage` sobre el platform interface
// (`ImagePickerPlatform.instance`). Faked aqui para no tocar method channels.
// El decoder real (`dart:ui` instantiateImageCodec) NO corre en un `test`
// plano (requiere binding/engine); por eso el seam `isDecodable` se inyecta
// en los casos de validacion (V1) y solo el happy-path usa el decoder real
// dentro de `tester.runAsync`.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tresdcal/core/share/quote_image_picker.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Fake del platform interface. Retorna [_result] en `getImage`; el
/// `pickPieceImage` no consulta `supportsImageSource`, asi que basta con
/// fakedar el path de pick.
class _FakePickerPlatform extends ImagePickerPlatform {
  _FakePickerPlatform(this._result);

  final XFile? _result;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return _result;
  }
}

/// 1x1 transparent PNG (valido, generado externamente).
const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=';

XFile _fileFromBase64(String base64) =>
    XFile.fromData(base64Decode(base64), mimeType: 'image/png');

void main() {
  // El platform interface es un singleton global: restaurar el original
  // despues de cada test para no contaminar otros files.
  void withPlatform(ImagePickerPlatform fake) {
    final original = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = fake;
    addTearDown(() => ImagePickerPlatform.instance = original);
  }

  group('pickPieceImage', () {
    test('imagen valida (PNG 1x1) → devuelve los bytes', () async {
      withPlatform(_FakePickerPlatform(_fileFromBase64(_tinyPngBase64)));

      final bytes = await pickPieceImage(
        source: ImageSource.gallery,
        isDecodable: (_) async => true,
      );

      expect(bytes, isNotNull);
      expect(bytes, equals(base64Decode(_tinyPngBase64)));
    });

    test('usuario cancela (picker null) → retorna null sin error', () async {
      withPlatform(_FakePickerPlatform(null));

      final bytes = await pickPieceImage(
        source: ImageSource.gallery,
        isDecodable: (_) async => true,
      );

      expect(bytes, isNull);
    });

    test('bytes > 5 MB → PieceImageException (quoteImageTooLarge)', () async {
      final oversized = Uint8List(kMaxPieceImageBytes + 1);
      withPlatform(_FakePickerPlatform(XFile.fromData(oversized)));

      await expectLater(
        pickPieceImage(
          source: ImageSource.gallery,
          isDecodable: (_) async => true,
        ),
        throwsA(
          isA<PieceImageException>().having(
            (e) => e.message,
            'message',
            EsBO.quoteImageTooLarge,
          ),
        ),
      );
    });

    test('bytes > 5 MB → error aun con decoder valido', () async {
      final oversized = Uint8List(kMaxPieceImageBytes + 1);
      withPlatform(_FakePickerPlatform(XFile.fromData(oversized)));

      await expectLater(
        pickPieceImage(
          source: ImageSource.gallery,
          isDecodable: (_) async => true,
        ),
        throwsA(isA<PieceImageException>()),
      );
    });

    test('formato no decodificable → PieceImageException '
        '(quoteImageInvalidFormat)', () async {
      final garbage = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      withPlatform(_FakePickerPlatform(XFile.fromData(garbage)));

      await expectLater(
        pickPieceImage(
          source: ImageSource.gallery,
          isDecodable: (_) async => false,
        ),
        throwsA(
          isA<PieceImageException>().having(
            (e) => e.message,
            'message',
            EsBO.quoteImageInvalidFormat,
          ),
        ),
      );
    });

    testWidgets('decoder real: PNG valido decodifica dentro de runAsync', (
      tester,
    ) async {
      withPlatform(_FakePickerPlatform(_fileFromBase64(_tinyPngBase64)));

      final bytes = await tester.runAsync(
        () => pickPieceImage(source: ImageSource.gallery),
      );

      expect(bytes, isNotNull);
    });
  });
}
