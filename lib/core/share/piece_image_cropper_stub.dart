// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:image_cropper/image_cropper.dart';

/// Stub para web: mantiene el flujo pick-without-crop (los bytes vienen de
/// memoria, no de un path local, y el setup web del cropper esta fuera del
/// alcance Android del PRD).
Future<Uint8List?> cropPieceImage({
  required Uint8List sourceBytes,
  ImageCropper? cropper,
}) async {
  return sourceBytes;
}
