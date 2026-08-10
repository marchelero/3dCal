// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../l10n/es_bo.dart';

/// Limite maximo de bytes de la imagen de pieza (~5 MB).
const int kMaxPieceImageBytes = 5 * 1024 * 1024;

/// Excepcion de la imagen de pieza. Capturada por la UI para mostrar un
/// AppSnackBar al usuario (mismo patron que [ShareQuoteException]).
class PieceImageException implements Exception {
  const PieceImageException(this.message);
  final String message;
  @override
  String toString() => 'PieceImageException: $message';
}

/// Pide una imagen de la pieza (galeria o camara) y la valida.
///
/// - V2: limita a 1024x1024 al pickear.
/// - `imageQuality: 85` fuerza re-encode a JPEG en iOS (evita HEIC, que el
///   paquete `pdf` no decodifica en `pw.MemoryImage`) y reduce los bytes.
/// - V3: > [kMaxPieceImageBytes] lanza [PieceImageException].
/// - V1: si [isDecodable] (o el decoder default) devuelve false, lanza
///   [PieceImageException].
///
/// [picker] / [isDecodable] son seams inyectables para tests (patron
/// [GallerySaver]): el decoder real (`dart:ui` instantiateImageCodec) no
/// completa en un `test` plano, solo dentro de `tester.runAsync`.
///
/// Retorna `null` si el usuario cancela la seleccion (sin error).
Future<Uint8List?> pickPieceImage({
  required ImageSource source,
  ImagePicker? picker,
  Future<bool> Function(Uint8List)? isDecodable,
}) async {
  final p = picker ?? ImagePicker();
  final file = await p.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  if (bytes.length > kMaxPieceImageBytes) {
    throw PieceImageException(EsBO.quoteImageTooLarge);
  }

  final ok = await (isDecodable ?? _defaultIsDecodable)(bytes);
  if (!ok) {
    throw PieceImageException(EsBO.quoteImageInvalidFormat);
  }

  return bytes;
}

/// Decoder default: intenta decodificar los bytes con el engine de Flutter.
/// Devuelve false si el formato no es una imagen decodificable.
Future<bool> _defaultIsDecodable(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    codec.dispose();
    return true;
  } catch (_) {
    return false;
  }
}
