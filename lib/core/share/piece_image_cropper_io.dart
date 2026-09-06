// ignore_for_file: public_member_api_docs

import 'dart:io';
import 'dart:typed_data';

import 'package:image_cropper/image_cropper.dart';

import '../../l10n/es_bo.dart';

/// Implementacion io (Android/iOS): escribe los bytes a un archivo temporal,
/// abre el editor nativo (uCrop / TOCropViewController) sobre ese path y
/// devuelve los bytes del resultado. El archivo temporal se elimina siempre
/// (finally) — el plugin persiste el resultado en cache del sistema.
Future<Uint8List?> cropPieceImage({
  required Uint8List sourceBytes,
  ImageCropper? cropper,
}) async {
  final dir = await Directory.systemTemp.createTemp('3dcal_crop_');
  final source = File('${dir.path}${Platform.pathSeparator}piece.jpg');
  try {
    await source.writeAsBytes(sourceBytes, flush: true);
    final cropped = await (cropper ?? ImageCropper()).cropImage(
      sourcePath: source.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: EsBO.quoteImageEditToolbar,
          // Aspect ratio libre (uCrop no bloquea por default): el usuario
          // puede recortar con la forma que necesite.
          lockAspectRatio: false,
        ),
      ],
    );
    if (cropped == null) return null;
    return await cropped.readAsBytes();
  } finally {
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // Limpieza best-effort: el archivo quedara en el temp dir del sistema.
    }
  }
}
