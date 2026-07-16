// ignore_for_file: public_member_api_docs

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/es_bo.dart';

/// Excepcion que se lanza cuando la generacion o el share de la imagen falla.
/// Capturada por la UI para mostrar un AppSnackBar al usuario.
class ShareQuoteException implements Exception {
  const ShareQuoteException(this.message);
  final String message;
  @override
  String toString() => 'ShareQuoteException: $message';
}

/// Captura el widget bajo [captureKey] como PNG y lo abre en el share sheet
/// del sistema operativo. Pensado para el summary card del calculator.
///
/// **Por que GlobalKey**: el RepaintBoundary se renderiza dentro del modal
/// sheet. Cuando el usuario toca el boton "Compartir", necesitamos el
/// RenderObject actual para pedirle la imagen. GlobalKey es la unica forma
/// de cruzar el boundary del modal sin pasar el context directamente.
///
/// **Errores comunes**:
/// - Key no montada todavia (llamar muy rapido) → lanza ShareQuoteException.
/// - Key apunta a un widget que no es RepaintBoundary → lanza
///   ShareQuoteException con mensaje claro.
///
/// **No es testeable de forma aislada** porque depende de platform channels
/// (path_provider + share_plus). La UI testea que el boton esta + que el tap
/// dispara el flujo.
Future<void> captureAndShareQuote(GlobalKey captureKey) async {
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
  // Asignamos a local con tipo ya reducido para que `toImage` no se queje
  // del nullable check arriba (Dart no achica el tipo a traves del `is!`).
  final boundary = renderObject;

  // pixelRatio=3 → "Retina" en mobile. Si el device tiene menos DPI, sigue
  // funcionando (la imagen sale chica pero valida).
  final image = await boundary.toImage(pixelRatio: 3);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw const ShareQuoteException('No se pudo codificar la imagen PNG.');
    }
    final bytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final filename =
        'cotizacion_3dcal_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    // share_plus 10.x usa la API estatica Share.shareXFiles (no
    // SharePlus.instance.share con ShareParams, eso es 11+).
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: EsBO.calcShareText,
      subject: EsBO.calcShareSubject,
    );
  } finally {
    image.dispose();
  }
}
