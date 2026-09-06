// ignore_for_file: public_member_api_docs
//
// AC-301 — Unit tests del editor de recorte/rotacion de la foto de pieza
// (F3). `cropPieceImage` escribe los bytes a un temp file, llama al editor
// nativo (image_cropper) y limpia el temp SIEMPRE (finally).
//
// El editor real abre una activity (uCrop / TOCropViewController) → no
// corre en tests. Se fakeda subclasificando `ImageCropper` (su `cropImage`
// es un metodo de instancia NO final que delega al platform interface).
// El fake lee el source en el MOMENTO de la llamada — asi se verifica que
// el temp file existia y tenia los bytes del source antes del finally.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tresdcal/core/share/piece_image_cropper.dart';

/// Fake del editor nativo. Emula "recortar" persistiendo [result] en un
/// temp file y devolviendo un [CroppedFile] real (dart:io).
class _FakeCropper extends ImageCropper {
  _FakeCropper({this.result, this.error});

  /// Bytes del resultado "recortado"; null simula cancelacion del editor.
  final Uint8List? result;
  final Exception? error;

  String? lastSourcePath;
  Uint8List? lastSourceBytes;
  ImageCompressFormat? lastFormat;
  int? lastQuality;
  bool lastFreeAndroidAspect = false;

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    lastSourcePath = sourcePath;
    // Leer el source AHORA (dentro de la llamada): el temp dir del codigo
    // bajo test se limpia en el finally posterior a este return.
    lastSourceBytes = await File(sourcePath).readAsBytes();
    lastFormat = compressFormat;
    lastQuality = compressQuality;
    for (final s in uiSettings ?? const <PlatformUiSettings>[]) {
      if (s is AndroidUiSettings) {
        lastFreeAndroidAspect = s.lockAspectRatio != true;
      }
    }
    final e = error;
    if (e != null) throw e;
    if (result == null) return null;
    // Emula al plugin: el resultado persiste en cache del sistema (temp
    // SEPARADO del source, que el codigo bajo test limpia en el finally).
    final dir = await Directory.systemTemp.createTemp('3dcal_test_result_');
    final out = File('${dir.path}${Platform.pathSeparator}result.jpg');
    await out.writeAsBytes(result!, flush: true);
    return CroppedFile(out.path);
  }
}

/// Directorio temporal creado por el codigo bajo test (el que contiene el
/// archivo fuente que se le paso al editor). Debe desaparecer tras el
/// finally de `cropPieceImage`.
Directory _tmpRootOf(_FakeCropper cropper) =>
    Directory(cropper.lastSourcePath!).parent;

void main() {
  final source = Uint8List.fromList(List<int>.generate(64, (i) => i));
  final cropped = Uint8List.fromList(List<int>.generate(32, (i) => i * 3));

  test('confirmar el recorte devuelve los bytes del resultado', () async {
    final cropper = _FakeCropper(result: cropped);

    final result = await cropPieceImage(sourceBytes: source, cropper: cropper);

    expect(result, equals(cropped));
  });

  test('el editor recibe el source completo, JPG q90 y aspect libre', () async {
    final cropper = _FakeCropper(result: cropped);

    await cropPieceImage(sourceBytes: source, cropper: cropper);

    expect(cropper.lastSourceBytes, equals(source));
    expect(cropper.lastFormat, ImageCompressFormat.jpg);
    expect(cropper.lastQuality, 90);
    expect(cropper.lastFreeAndroidAspect, isTrue);
  });

  test('el temp dir del source se elimina despues del confirm', () async {
    final cropper = _FakeCropper(result: cropped);

    await cropPieceImage(sourceBytes: source, cropper: cropper);

    expect(
      _tmpRootOf(cropper).existsSync(),
      isFalse,
      reason: 'el finally debe limpiar el temp (source ya leido)',
    );
  });

  test('cancelar el editor → null sin error y temp limpio', () async {
    final cropper = _FakeCropper();

    final result = await cropPieceImage(sourceBytes: source, cropper: cropper);

    expect(result, isNull);
    expect(cropper.lastSourceBytes, isNotNull);
    expect(_tmpRootOf(cropper).existsSync(), isFalse);
  });

  test('error del editor → se propaga y temp limpio', () async {
    final cropper = _FakeCropper(error: Exception('crop boom'));

    await expectLater(
      cropPieceImage(sourceBytes: source, cropper: cropper),
      throwsA(isA<Exception>()),
    );

    expect(_tmpRootOf(cropper).existsSync(), isFalse);
  });

  test('default (sin seam) usa el ImageCropper real', () async {
    // Sin seam el codigo crea `ImageCropper()` y delega al platform
    // interface real; en el test env eso no esta registrado con un handler
    // → MissingPluginException (o similar), NUNCA un error de API.
    await expectLater(cropPieceImage(sourceBytes: source), throwsA(anything));
  });
}
