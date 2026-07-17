// ignore_for_file: public_member_api_docs, deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

/// Descarga [imageBytes] como archivo PNG via el navegador.
///
/// Crea un Blob, genera una ObjectURL, simula click en un anchor con
/// atributo download, y revoca la URL para liberar memoria.
Future<void> downloadImage(Uint8List imageBytes, String filename) async {
  final blob = html.Blob(<dynamic>[imageBytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
