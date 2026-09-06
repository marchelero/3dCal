// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Maximo lado mayor (px) al que se downscale la foto de la pieza antes de
/// persistirla en el historial (F2: control de tamano del BLOB).
const int kPieceImageMaxDimension = 1200;

/// Calidad del re-encode JPEG de la foto persistida (F2).
const int kPieceImageJpegQuality = 85;

/// Downscale la foto de la pieza para persistir en el historial (F2).
///
/// - Escala la imagen a max [maxDimension] px en el lado mayor (mantiene
///   aspect ratio). Imagenes mas chicas pasan igual (sin upscale).
/// - Re-encodea todo como JPEG con [quality].
/// - Devuelve `null` si [bytes] es null/vacio o no es decodificable
///   (input invalido → sin foto persistida).
Uint8List? downscalePieceImage(
  Uint8List? bytes, {
  int maxDimension = kPieceImageMaxDimension,
  int quality = kPieceImageJpegQuality,
}) {
  if (bytes == null || bytes.isEmpty) return null;
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  var out = decoded;
  final longSide = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  if (longSide > maxDimension) {
    final scale = maxDimension / longSide;
    out = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: quality));
}
