// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:image_cropper/image_cropper.dart';

import 'piece_image_cropper_stub.dart'
    if (dart.library.io) 'piece_image_cropper_io.dart'
    as impl;

/// Abre el editor de recorte/rotacion (image_cropper) sobre los bytes de la
/// imagen de pieza ya validados por [pickPieceImage].
///
/// - Confirma (Done) → devuelve los bytes del resultado recortado.
/// - Cancela → devuelve `null` (sin error): la UI no adjunta nada y el
///   flujo vuelve al estado previo.
/// - Fallo del editor → lanza excepcion (la UI muestra AppSnackBar.error).
///
/// En **web** el editor no se inicia (los bytes no viven en un path local y
/// el setup del websocket/cropperjs esta fuera de alcance): se devuelven los
/// mismos bytes sin recortar, conservando el comportamiento pick-without-crop.
///
/// [cropper] es un seam inyectable para tests (la plataforma real requiere
/// el plugin nativo). Misma idea que [ImagePicker] en `pickPieceImage`.
Future<Uint8List?> cropPieceImage({
  required Uint8List sourceBytes,
  ImageCropper? cropper,
}) {
  return impl.cropPieceImage(sourceBytes: sourceBytes, cropper: cropper);
}
