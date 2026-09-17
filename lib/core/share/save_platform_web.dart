// ignore_for_file: public_member_api_docs

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Descarga [imageBytes] como archivo PNG via el navegador.
///
/// Crea un Blob, genera una ObjectURL, simula click en un anchor con
/// atributo download, y revoca la URL para liberar memoria.
Future<void> downloadImage(Uint8List imageBytes, String filename) async {
  // Convertir Uint8List → JSArrayBuffer para el Blob constructor de package:web.
  final data = imageBytes.buffer.toJS;
  final blob = web.Blob(
    [data].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
