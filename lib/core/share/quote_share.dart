// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
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
    throw ShareQuoteException(EsBO.shareErrorNotRendered);
  }
  final renderObject = ctx.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw ShareQuoteException(EsBO.shareErrorNoRegion);
  }
  final boundary = renderObject;

  final image = await boundary.toImage(pixelRatio: 3);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw ShareQuoteException(EsBO.shareErrorEncode);
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

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(imageBytes, mimeType: 'image/png', name: filename),
      ],
      text: EsBO.calcShareText,
      subject: EsBO.calcShareSubject,
    ),
  );
}

/// Guarda la imagen de la cotizacion en la galeria del dispositivo o la
/// descarga via browser en web.
///
/// En **mobile** usa [gal] (via [GallerySaver]) internamente. En Android el
/// permiso WRITE_EXTERNAL_STORAGE es requerido solo para API <= 29
/// (declarado en el manifest main junto con `requestLegacyExternalStorage`);
/// desde API 30 el guardado va por MediaStore sin permiso. En iOS requiere
/// NSPhotoLibraryAddUsageDescription.
///
/// En **web** usa conditional import para descargar via Blob + AnchorElement
/// (download attribute del navegador).
///
/// Los bytes se guardan como PNG (el name se pasa sin extension). El plugin
/// [gal] no devuelve un resultado de exito: los fallos se propagan como
/// [GalException] (que envuelve la [PlatformException] nativa) y se mapean a
/// [ShareQuoteException] con el mensaje de error del plugin.
Future<void> saveQuoteImage(
  Uint8List imageBytes, {
  GallerySaver gallerySaver = const GallerySaver(),
}) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  if (kIsWeb) {
    await downloadImage(imageBytes, 'cotizacion_3dcalc_$timestamp.png');
    return;
  }

  try {
    await gallerySaver.saveImage(
      imageBytes,
      name: 'cotizacion_3dcalc_$timestamp',
    );
  } on GalException catch (e) {
    throw ShareQuoteException(_saveErrorMessage(e.platformException.message));
  } on PlatformException catch (e) {
    throw ShareQuoteException(_saveErrorMessage(e.message));
  } catch (_) {
    throw ShareQuoteException(EsBO.shareErrorSaveGallery);
  }
}

String _saveErrorMessage(Object? pluginMessage) {
  if (pluginMessage is String && pluginMessage.isNotEmpty) {
    return EsBO.shareErrorSaveWithMessage(pluginMessage);
  }
  return EsBO.shareErrorSaveGallery;
}

/// Seam para guardar bytes de imagen en la galeria del dispositivo.
///
/// La implementacion por defecto usa el plugin [gal]. Es extensible por
/// override en tests para cubrir el mapeo de errores sin platform channels.
class GallerySaver {
  const GallerySaver();

  /// Guarda [imageBytes] en la galeria con el nombre [name].
  ///
  /// El plugin [gal] no devuelve un resultado de exito: los fallos se
  /// propagan como [GalException] (envuelve la [PlatformException] nativa).
  Future<void> saveImage(Uint8List imageBytes, {required String name}) {
    return Gal.putImageBytes(imageBytes, name: name);
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
