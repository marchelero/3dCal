# Reporte — Fusión de botones: Compartir + Guardar imagen (AS-2026)

**Fecha**: 2026-09-11 · **Estado**: 608/608 tests verdes · analyze: 0 issues
**Alcance**: UX del result sheet — un solo botón que guarda la imagen en la galería (o descarga en web) y a la par abre el menú de compartir. Fila de acciones 5 → 4 botones.

## Pedido del usuario (textual)

> "quiero fusionar 2 opciones: la de guardar imagen y la de compartir, en una sola opción que haga las dos cosas: que te baje automáticamente la imagen y a la par te aparezca el menú para compartir. Así reducimos un botón."

## Implementación

1. **`_handleShareAndSave()`** en `_ResultSheetContentState` — captura los bytes UNA sola vez (`captureQuoteImageBytes(_captureKey)`) y ejecuta ambas acciones a la par con `Future.wait`:
   - `_trySaveImage(bytes, errors)` → `saveQuoteImage(bytes, gallerySaver: widget.gallerySaver)`
   - `_tryShareImage(bytes, errors)` → `shareQuoteImage(bytes)`
   - **Errores parciales**: cada rama corre en su propio try/catch; el fallo de UNA no mata la que funcionó. Los mensajes se acumulan y el feedback muestra la primera falla (`ShareQuoteException.message` o `EsBO.calcShareError`), `debugPrint` antes del feedback.
   - **Éxito**: `kIsWeb ? commonImageDownloaded : commonImageSavedGallery` vía `_showSaveFeedback` (patrón AC-402: messenger del sheet capturado antes del async + fallback al `rootMessenger` de la página si el sheet se cierra en vuelo).
   - Guard anti-doble-tap `_inFlight` + `_isBusy` idéntico a los demás handlers.
   - Se eliminaron `_handleShare` y `_handleSave` (código muerto → rompía analyze).
2. **`_ActionIconRow`** 5 → 4 botones: Guardar cotización, Compartir PDF, **Compartir y guardar** (fusionado), Restablecer. El fusionado conserva `Icons.share_rounded` (no rompe la búsqueda por icono en tests) con color primario e `isBusy`.
3. **i18n — string nuevo `calcBtnShareSave`** en los 6 locales (interfaz `app_strings.dart` con doc + proxy estático en `es_bo.dart` + impl en las 6):
   - es: 'Compartir y guardar' · en: 'Share and save' · pt: 'Compartilhar e salvar' · fr: 'Partager et enregistrer' · de: 'Teilen und speichern'
4. **`pubspec.yaml`**: `share_plus_platform_interface: ^6.1.0` en dev_dependencies (requerido por lint `depend_on_referenced_packages`; mismo patrón que `image_picker_platform_interface`).

## Tests

- `test/unit/result_sheet_test.dart`: test 'muestra 4 botones de accion icon-only' actualizado a los 4 tooltips reales post-fusión; test nuevo 'boton fusionado comparte+guarda existe y arranca enabled' (tooltip `calcBtnShareSave` + IconButton habilitado). El test existente del icono `share_rounded` pasó sin cambios.
- `test/widget/quote_save_flow_test.dart`: adaptado — ese archivo ejercitaba el botón "Guardar imagen" del sheet (fusionado); ahora apunta al botón fusionado con un `SharePlatform` fake (seam oficial de share_plus 12) para aislar la rama save. El "Guardar imagen" del detalle (`CalculationDetailPage`) NO se tocó.

## Verificación

- `flutter analyze` → 0 issues
- `flutter test test/unit/result_sheet_test.dart` → 21/21 verde
- `flutter test` (suite completa) → **608/608 verde**, sin failures

## Arquitectura / decisiones

- **No-goals cumplidos**: NO se tocaron `quote_share.dart`, `gallery_saver_test.dart`, ni los otros botones (Guardar historial, PDF, Reset). Sin commits.
- **Nota**: el working tree mezcla esta tarea con la feature previa del historial avanzado (aún sin commitear).