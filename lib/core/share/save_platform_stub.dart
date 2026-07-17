// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

/// Stub por defecto. En mobile se usa [image_gallery_saver] directamente
/// desde [quote_share.dart]. Esta funcion solo se usa en web via conditional
/// import (save_platform_web.dart).
Future<void> downloadImage(Uint8List imageBytes, String filename) async {
  throw UnsupportedError('downloadImage no implementado en esta plataforma');
}
