# Reporte: legal y pantalla de carga

## Alcance

- Settings abre Privacy Policy y Terms of Service dentro de la app.
- Ambos documentos cambian entre español e inglés con el locale de la app.
- Splash usa un fondo fijo y limita el ancho del logo, especialmente en web.

## Verificación

- `flutter analyze`: pasa sin issues.
- `flutter build web --release --no-wasm-dry-run`: pasa.
- `flutter test`: queda un fallo preexistente en `settings_page_test.dart` (tap ambiguo sobre dos `FilledButton` en el test de restauración); no está causado por estas rutas ni por la localización legal.

## Nota legal

El texto incluido es una base informativa. Debe revisarlo asesoría legal y completar responsable, contacto, jurisdicción, retención y proveedores antes de publicar.
