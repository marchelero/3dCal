// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/es_bo.dart';
import 'save_platform_stub.dart'
    if (dart.library.html) 'save_platform_web.dart';

/// Excepcion que se lanza cuando la generacion o el share de la imagen falla.
/// Capturada por la UI para mostrar un AppSnackBar al usuario.
class ShareQuoteException implements Exception {
  const ShareQuoteException(this.message);
  final String message;
  @override
  String toString() => 'ShareQuoteException: $message';
}

/// Captura el widget bajo [captureKey] como PNG y retorna los bytes.
///
/// Reusable tanto para compartir como para guardar en galeria.
///
/// **Errores comunes**:
/// - Key no montada todavia → lanza ShareQuoteException.
/// - Key apunta a widget que no es RepaintBoundary → lanza
///   ShareQuoteException.
Future<Uint8List> captureQuoteImageBytes(GlobalKey captureKey) async {
  final ctx = captureKey.currentContext;
  if (ctx == null) {
    throw const ShareQuoteException(
      'El resumen aun no se renderizo. Intenta de nuevo en un momento.',
    );
  }
  final renderObject = ctx.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw const ShareQuoteException(
      'No se encontro la region capturable del resumen.',
    );
  }
  final boundary = renderObject;

  final image = await boundary.toImage(pixelRatio: 3);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw const ShareQuoteException('No se pudo codificar la imagen PNG.');
    }
    return byteData.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Abre el share sheet del sistema operativo con la imagen de la cotizacion.
///
/// Usa [share_plus] internamente, que en Android/iOS muestra el share sheet
/// nativo (con opciones de guardar, enviar por, etc.).
Future<void> shareQuoteImage(Uint8List imageBytes) async {
  final filename =
      'cotizacion_3dcalc_${DateTime.now().millisecondsSinceEpoch}.png';

  await Share.shareXFiles(
    [XFile.fromData(imageBytes, mimeType: 'image/png', name: filename)],
    text: EsBO.calcShareText,
    subject: EsBO.calcShareSubject,
  );
}

/// Guarda la imagen de la cotizacion en la galeria del dispositivo o la
/// descarga via browser en web.
///
/// En **mobile** usa [image_gallery_saver] internamente. Requiere permisos de
/// almacenamiento en Android < 10 (WRITE_EXTERNAL_STORAGE) y
/// NSPhotoLibraryAddUsageDescription en iOS.
///
/// En **web** usa conditional import para descargar via Blob + AnchorElement
/// (download attribute del navegador).
///
/// El plugin mobile guarda como JPG internamente, asi que el name se pasa sin
/// extension para evitar doble extension en Android < 10.
Future<void> saveQuoteImage(Uint8List imageBytes) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  if (kIsWeb) {
    await downloadImage(imageBytes, 'cotizacion_3dcalc_$timestamp.png');
    return;
  }

  final result = await ImageGallerySaver.saveImage(
    imageBytes,
    quality: 100,
    name: 'cotizacion_3dcalc_$timestamp',
  );
  // El plugin retorna Map<String, dynamic>? con las keys:
  //   isSuccess: bool, filePath: String?, errorMessage: String?
  if (result is! Map || result['isSuccess'] != true) {
    final errorMsg = result is Map ? result['errorMessage'] : null;
    throw ShareQuoteException(
      errorMsg is String
          ? 'No se pudo guardar la imagen: $errorMsg'
          : 'No se pudo guardar la imagen en la galeria.',
    );
  }
}

/// Captura el widget bajo [captureKey] como PNG y lo abre en el share sheet
/// del sistema operativo.
///
/// Metodo legacy que combina captura + share. Preferir usar
/// [captureQuoteImageBytes] + [shareQuoteImage] por separado.
Future<void> captureAndShareQuote(GlobalKey captureKey) async {
  final bytes = await captureQuoteImageBytes(captureKey);
  await shareQuoteImage(bytes);
}
