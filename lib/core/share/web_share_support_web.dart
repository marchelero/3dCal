import 'package:web/web.dart' as web;

/// Chequea si el browser actual implementa la Web Share API (fail-fast del
/// share en web).
///
/// Canary minimo: invoca `navigator.canShare` con un [web.ShareData] de solo
/// texto. Si el metodo no existe en este browser (NoSuchMethodError /
/// JSException) o la API esta bloqueada (permiso / policy), devuelve `false`
/// para que [shareQuoteImage] falle temprano con un mensaje claro — en vez
/// de caer al fallback de share_plus (que en Chrome/Windows puede colgar o
/// descargar duplicado cuando la imagen ya fue guardada).
bool webShareFilesAvailable() {
  try {
    return web.window.navigator.canShare(web.ShareData(text: 'probe'));
  } catch (_) {
    return false;
  }
}
