---
prd: docs/prds/2026-08-10_0106-imagen-cotizacion.prd.md
status: DRAFT
created: 2026-08-10_0130
---

# Implementation Plan: Adjuntar imagen a la cotización (foto de la pieza)

## Overview

El usuario puede adjuntar UNA foto de la pieza (galería o cámara) a la cotización **en el momento del envío**, desde el sheet de resultado (`ResultSheetContent`). La foto es **efímera** (Q1 cerrado: no se persiste, cero migración drift), se renderiza dentro de `QuoteImageTemplate` (imagen compacta centrada bajo el membrete, máx 224×132 — feedback usuario: "más pequeña, que no ocupe todo") y viaja en **PNG y PDF** (Q2 cerrado: paridad). Es funcionalidad **Free** (Q3 cerrado: sin gate, sin entitlements).

El estado de la imagen vive en el `StatefulWidget` del sheet (`Uint8List? _pieceImageBytes`), consistente con `_isBusy` existente. El PNG la incluye automáticamente porque el template está dentro del `RepaintBoundary`; el PDF la recibe por parámetro y la incrusta con `pw.MemoryImage`.

## Requirements

- RF1: control "Agregar imagen" en `ResultSheetContent` → opciones Galería / Cámara (Cámara oculta si `supportsImageSource` = false, ej. web desktop).
- RF2/RF3: `ImagePicker.pickImage` con `maxWidth: 1024, maxHeight: 1024, imageQuality: 85` (patrón `_LogoPicker` ampliado).
- RF4: preview dentro de `QuoteImageTemplate` (dentro del RepaintBoundary) → aparece en PNG y en la vista previa.
- RF5: Cambiar / Quitar (reversible, opcional, no bloquea envío).
- RF6: los 5 flujos existentes (Guardar en historial, Compartir PNG, Guardar PNG, Compartir PDF, Reset) sin cambios de comportamiento.
- RF7: feedback con `_isBusy` + `AppSnackBar.error` (patrón `_handleShare`).
- RF8: strings en `l10n/` (app_strings + es_bo + en_us).
- V1 (formato decodificable), V2 (1024×1024), V3 (~5 MB), V4 (opcional).

## Architecture Changes

| Archivo | Cambio |
|---|---|
| `lib/l10n/app_strings.dart` | +8 getters nuevos (sección Quote Image) |
| `lib/l10n/es_bo.dart` / `lib/l10n/en_us.dart` | implementaciones de los 8 strings |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription` + ajustar `NSPhotoLibraryUsageDescription` |
| `lib/core/share/quote_image_picker.dart` (**NUEVO**) | picker + validación (formato/tamaño), con seams para tests |
| `lib/core/export/pdf_export.dart` | param `pieceImageBytes` en `shareQuotePdf` + `buildQuotePdfBytes`; render hero |
| `lib/features/calculation/presentation/widgets/quote_image_template.dart` | param `pieceImageBytes` (Uint8List?) + imagen compacta centrada 224×132 |
| `lib/features/calculation/presentation/widgets/result_sheet.dart` | state `_pieceImageBytes` + control Agregar/Cambiar/Quitar + pasar bytes a template y PDF |
| `test/unit/piece_image_picker_test.dart` (**NUEVO**) | unit tests del picker |
| `test/unit/pdf_export_test.dart` | +tests de imagen en PDF |
| `test/unit/result_sheet_test.dart` | +widget tests adjuntar/quitar/validación/captura |

**NO se tocan** (Q1 efímero): `calculation_detail_page.dart`, `app_database.dart`, migraciones drift, `calculation_detail` flows. SC11 → N/A, decisión registrada.

## Implementation Steps

### Phase 1: Fundación (2 tareas paralelas)

1. **Strings i18n** (File: `lib/l10n/app_strings.dart`, `lib/l10n/es_bo.dart`, `lib/l10n/en_us.dart`)
   - Action: agregar a la interfaz `AppStrings` (sección nueva `// === Quote image (foto de la pieza) ===`) y a ambas implementaciones:
     - `quoteImageAdd` → "Agregar imagen" / "Add image"
     - `quoteImageGallery` → "Galería" / "Gallery"
     - `quoteImageCamera` → "Cámara" / "Camera"
     - `quoteImageChange` → "Cambiar" / "Change"
     - `quoteImageRemove` → "Quitar" / "Remove"
     - `quoteImageTooLarge` → "La imagen supera los 5 MB y no se adjuntó." / "Image exceeds 5 MB and was not attached."
     - `quoteImageInvalidFormat` → "Formato de imagen no válido (se admiten JPEG, PNG o WebP)." / "Invalid image format (JPEG, PNG or WebP only)."
     - `quoteImageError` → "No se pudo obtener la imagen" / "Could not get the image"
   - Why: RF8/SC9 — cero literales hardcodeados.
   - Dependencies: None
   - Risk: Low

2. **Config iOS** (File: `ios/Runner/Info.plist`)
   - Action: agregar `<key>NSCameraUsageDescription</key><string>3dCalc necesita acceso a la cámara para adjuntar fotos a la cotización.</string>`. Ajustar el string de `NSPhotoLibraryUsageDescription` existente (hoy dice "seleccionar el logo de la empresa") a algo neutro que cubra pieza+logo, ej. "3dCalc necesita acceso a la galería para seleccionar imágenes y adjuntarlas a la cotización." No duplicar keys.
   - Why: RNF2/SC8 — sin el string la app crashea en iOS al abrir cámara.
   - Dependencies: None
   - Risk: Low (validación real requiere macOS/CI, ver T10)

### Phase 2: Núcleo picker + validación (1 archivo nuevo)

3. **Crear `quote_image_picker.dart`** (File: `lib/core/share/quote_image_picker.dart` — NUEVO)
   - Action:
     - `class PieceImageException implements Exception { const PieceImageException(this.message); final String message; }` (patrón `ShareQuoteException`).
     - Constante `const int kMaxPieceImageBytes = 5 * 1024 * 1024;`
     - `Future<Uint8List?> pickPieceImage({required ImageSource source, ImagePicker? picker, Future<bool> Function(Uint8List)? isDecodable})`:
       1. `final p = picker ?? ImagePicker();`
       2. `final XFile? file = await p.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);` — **`imageQuality: 85` es clave**: fuerza re-encode a JPEG en iOS (evita HEIC, que el paquete `pdf` NO decodifica en `pw.MemoryImage`) y reduce bytes (V3). V2 (1024×1024) cumple la regla de dimensiones del PRD.
       3. `if (file == null) return null;` (cancelación, sin error — RF2).
       4. `final bytes = await file.readAsBytes();`
       5. `if (bytes.length > kMaxPieceImageBytes) throw PieceImageException(EsBO.quoteImageTooLarge);` (V3)
       6. Validar decodificación: `final ok = await (isDecodable ?? _defaultIsDecodable)(bytes); if (!ok) throw PieceImageException(EsBO.quoteImageInvalidFormat);` (V1)
       7. `return bytes;`
     - `_defaultIsDecodable`: `try { final codec = await ui.instantiateImageCodec(bytes); codec.dispose(); return true; } catch (_) { return false; }` (import `dart:ui as ui`).
   - Why: lógica pura, testeable sin widgets; los seams `picker`/`isDecodable` siguen el patrón `GallerySaver` (RNF6). `isDecodable` inyectable evita depender del engine de decodificación dentro de `flutter_test` (que requiere `tester.runAsync` para `instantiateImageCodec`).
   - Dependencies: Step 1 (mensajes l10n)
   - Risk: Medium — `instantiateImageCodec` en tests requiere `runAsync`; por eso el seam.

### Phase 3: PDF con imagen (1 archivo)

4. **Threading de bytes en PDF** (File: `lib/core/export/pdf_export.dart`)
   - Action:
     - Agregar `Uint8List? pieceImageBytes` como param opcional al final de `shareQuotePdf` y `buildQuotePdfBytes` (no tocar `resolveBranding` ni su orden de params — evita romper call sites).
      - En `buildQuotePdfBytes`, entre el bloque de fecha y el total hero (posición análoga al template):
        ```dart
        if (pieceImageBytes != null) ...[
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Container(
              width: 220,
              height: 110, // imagen compacta (feedback usuario 2026-08-10: "más pequeña, que no ocupe todo")
              child: pw.Image(
                pw.MemoryImage(pieceImageBytes), // acepta Uint8List crudo (JPEG/PNG)
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
        ],
        ```
      - `shareQuotePdf` pasa el param a `buildQuotePdfBytes`.
    - Why: Q2 cerrado = la foto va en el PDF. `pw.MemoryImage` es el mismo mecanismo que ya usa el logo (RNF4); la foto llega como JPEG por el `imageQuality: 85` del Step 3.
    - Dependencies: None (solo para compilar con el param nuevo; el render no depende de l10n)
    - Risk: Low — 110pt centrado con `BoxFit.contain` no desborda A4 ni con detalle expandido; test con detalle on (T8).

### Phase 4: Template hero (1 archivo)

5. **Hero de foto en template** (File: `lib/features/calculation/presentation/widgets/quote_image_template.dart`)
   - Action:
     - Agregar param `final Uint8List? pieceImageBytes;` (import `dart:typed_data` ya existe).
      - En `build`, entre el `_divider` del membrete y el bloque `Label` (A3: "imagen compacta bajo el membrete, antes del label"):
        ```dart
        if (pieceImageBytes != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 224, // ~56% del template 400px: imagen compacta, no hero
                  maxHeight: 132, // feedback usuario 2026-08-10: "más pequeña, que no ocupe todo"
                ),
                child: Image.memory(
                  pieceImageBytes!,
                  key: const Key('quote-piece-image'), // target para tests (SC2/SC4/SC5)
                  fit: BoxFit.contain, // foto completa visible, sin crop
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        ```
    - Why: RF4 — el template está dentro del RepaintBoundary, así que el PNG capturado (SC4) la incluye sin tocar `quote_share.dart`. `BoxFit.contain` + `Center` + cota 224×132 = la foto se ve completa, centrada y no domina la cotización (paridad visual con el PDF de 220×110pt).
    - Dependencies: None
    - Risk: Low (el `errorBuilder` evita crash si los bytes se corrompieran; la validación de V1 ya ocurre antes en el Step 3)

### Phase 5: Wiring del sheet (1 archivo)

6. **State + control en ResultSheetContent** (File: `lib/features/calculation/presentation/widgets/result_sheet.dart`)
   - Action:
     - State nuevo: `Uint8List? _pieceImageBytes;` junto a `_isBusy` (import `dart:typed_data` + `package:image_picker/image_picker.dart` + `package:image_picker/image_picker.dart` para `ImageSource` + `quote_image_picker.dart`).
     - `Future<void> _handlePickImage(ImageSource source)`: guard `_isBusy`, setBusy, `final bytes = await pickPieceImage(source: source, ...)`; `null` → cancel (no-op); setState `_pieceImageBytes = bytes`; `on PieceImageException` → `AppSnackBar.error(e.message)`; `catch` genérico → `AppSnackBar.error('${EsBO.quoteImageError}: $e')`; `finally` setBusy false. (RF7, patrón `_handleShare`).
     - `void _handleRemoveImage()` → `setState(() => _pieceImageBytes = null);` (RF5, reversible).
     - `Future<void> _handlePickFromDialog()`: `showModalBottomSheet` con 2 ListTile (Galería/Cámara). **Cámara oculta si no soportada**: evaluar `await ImagePicker().supportsImageSource(ImageSource.camera)` ANTES de mostrar el sheet (o cachear en un `late Future<bool>` del state) — en web desktop devuelve false (RF1/SC1).
     - UI: entre el `RepaintBoundary` y el toggle detail (FUERA del boundary — no debe salir en el PNG), una sección compacta:
       - Sin imagen: `TextButton.icon(Icons.add_a_photo_rounded, EsBO.quoteImageAdd)` → `_handlePickFromDialog`.
       - Con imagen: `Row` con `TextButton.icon(Icons.swap_horiz_rounded, EsBO.quoteImageChange)` → diálogo; `TextButton.icon(Icons.delete_outline_rounded, EsBO.quoteImageRemove, color error)` → `_handleRemoveImage`.
     - Pasar `pieceImageBytes: _pieceImageBytes` a `QuoteImageTemplate` y a `shareQuotePdf(pieceImageBytes: _pieceImageBytes)` en `_handleSharePdf` (RF6/Q2).
   - Why: RF1/RF4/RF5/RF6/RF7 — el state vive en el StatefulWidget local del sheet (constraint Riverpod respetada: es state efímero de UI, mismo patrón que `_isBusy`).
   - Dependencies: Steps 3, 4, 5
   - Risk: Medium — `supportsImageSource` es async; asegurar que el snapshot del sheet no dependa de él (se evalúa al abrir el diálogo, no en build).

### Phase 6: Tests

7. **Unit tests del picker** (File: `test/unit/piece_image_picker_test.dart` — NUEVO)
   - Action: fake `ImagePickerPlatform.instance` (sobre `pickImage` del platform interface) que devuelve `XFile.fromData(...)` con:
     - PNG 1×1 válido (reusar `_tinyPngBase64` de `pdf_export_test.dart`) → `pickPieceImage` devuelve los bytes.
     - bytes > 5 MB → `throwsA(isA<PieceImageException>() con mensaje quoteImageTooLarge)`.
     - garbage bytes + `isDecodable: (_) async => false` → `PieceImageException` con mensaje quoteImageInvalidFormat (V1 sin depender del engine).
     - picker que devuelve `null` → retorna `null` (cancelación sin error).
   - Why: SC6 (V1/V3) a nivel unit; seam `isDecodable` evita `runAsync`.
   - Dependencies: Step 3
   - Risk: Low

8. **Tests de PDF** (File: `test/unit/pdf_export_test.dart`)
   - Action: helper `int _countImageXObjects(Uint8List)` (contar ocurrencias de `/Subtype /Image`; el actual `_hasImageXObject` se puede refactorizar sobre él). Tests:
     - `isPro: false` sin foto → 0 XObjects (regresión).
     - `isPro: false` + `pieceImageBytes` (tiny PNG) → ≥ 1 XObject (SC10: el PDF incluye la foto).
     - `isPro: true` + logo + foto → ≥ 2 XObjects (logo + foto, no confundir).
   - Why: SC10 — verificable en unit sin renderizar; mismo approach del gate de branding actual.
   - Dependencies: Step 4
   - Risk: Low

9. **Widget tests del sheet** (File: `test/unit/result_sheet_test.dart` — extender; o `test/widget/piece_image_attach_test.dart` si crece)
   - Action (fake `ImagePickerPlatform.instance` para no tocar channels reales):
     - **SC1**: `ResultSheetContent` muestra control "Agregar imagen"; tap → bottom sheet con "Galería" y "Cámara". Con fake cuyo `supportsImageSource(camera)` = false → solo "Galería".
     - **SC2**: fake devuelve tiny PNG → tras attach, `find.byKey(Key('quote-piece-image'))` presente dentro del `QuoteImageTemplate` (preview visible).
     - **SC5**: attach → tap "Quitar" → key ausente.
     - **SC6**: fake devuelve garbage + `isDecodable: false` → `AppSnackBar.error` visible y key ausente (no se adjunta).
     - **SC4**: captura real: `tester.runAsync(() async { final b1 = await captureQuoteImageBytes(key); ... })` — capturar con y sin foto y `expect(b1, isNot(equals(b2)))`. (Opcional más fuerte: `decodeImageFromList` y samplear un pixel de la zona hero para verificar que no es color plano del template — requiere `runAsync`.)
   - Why: SC1/SC2/SC4/SC5/SC6 — cubre el ciclo completo adjuntar→preview→capturar→quitar.
   - Dependencies: Step 6 (y Steps 3-5 por transitividad)
   - Risk: Medium — captura `toImage` en widget tests solo funciona dentro de `runAsync`; documentar en comentario del test.

### Phase 7: Verificación

10. **Verificación final** (comandos)
    - Action:
      - `flutter analyze` → cero issues (SC12).
      - `dart format --set-exit-if-changed lib test` (SC12).
      - `flutter test` → suite completa verde, incluye regresión de `quote_save_flow_test.dart` y `gallery_saver_test.dart` (SC7).
      - `flutter build web` → sanity web (picker web + `supportsImageSource`).
      - `flutter build apk --debug` → sanity Android.
      - `flutter build ios --no-codesign` → **solo en macOS/CI** (SC8); en Windows dev box documentar como paso de CI.
    - Why: SC7/SC8/SC12.
    - Dependencies: Steps 1-9
    - Risk: Low

## Testing Strategy

- **Unit**: `test/unit/piece_image_picker_test.dart` (nuevo, validación V1/V3), `test/unit/pdf_export_test.dart` (XObject count, SC10).
- **Widget**: `test/unit/result_sheet_test.dart` — SC1 (control + visibilidad Cámara), SC2 (preview), SC5 (quitar), SC6 (snackbar error), SC4 (captura PNG con/sin foto vía `runAsync`).
- **Regresión**: suite existente completa (`result_sheet_test.dart`, `quote_save_flow_test.dart`, `gallery_saver_test.dart`, `pdf_export_test.dart`) — SC7 exige los 5 flujos intactos.
- **Comandos**: `flutter test test/unit/piece_image_picker_test.dart` → `flutter test test/unit/pdf_export_test.dart` → `flutter test test/unit/result_sheet_test.dart` → `flutter test` (full) → `flutter analyze` → `dart format --set-exit-if-changed lib test` → `flutter build web` / `flutter build apk --debug` → `flutter build ios --no-codesign` (CI/macOS).

## Risks & Mitigations

| Riesgo | Mitigación |
|---|---|
| **Memoria iOS al capturar PNG con foto**: template 400px + imagen compacta 224×132 lógicos → con `pixelRatio: 3` el framebuffer ≈ 1200×1560×4B ≈ 7 MB (menos que el hero 4:3 original por el rediseño compacto) | Foto capada a 1024px (V2) + `imageQuality: 85`; mantener pixelRatio 3; si OOM en device real, bajar a 2 en `captureQuoteImageBytes` (tocar `quote_share.dart` solo si se confirma) |
| **HEIC de cámara iOS no decodifica en `pw.MemoryImage`** (paquete `pdf` no lo soporta) | `imageQuality: 85` fuerza re-encode JPEG en iOS desde el picker (Step 3) + validación V1 antes de adjuntar |
| **PDF desborda A4** con detalle expandido + hero 180pt | `BoxFit.contain` + alto fijo; test con detalle on (T8); si desborda, bajar a 140pt |
| `instantiateImageCodec` en flutter_test requiere `runAsync` | Seam `isDecodable` inyectable (Step 3) para unit tests; tests de captura real usan `tester.runAsync` |
| `supportsImageSource` async → parpadeo del diálogo | Evaluar antes de abrir el bottom sheet, no en `build` |
| SC8 (build iOS) no verificable en Windows dev box | Documentar como paso de CI/macOS; el plist se revisa estáticamente (sin key duplicada, string presente) |

## Success Criteria (mapeo PRD → tareas)

| Criterio | Cubierto por |
|---|---|
| SC1 — control + Cámara oculta donde no aplica | T6 (UI) + T9 (widget test) |
| SC2 — picker Galería + preview en template | T3, T5 (hero) + T9 |
| SC3 — cámara Android/iOS | T3 (`ImageSource.camera`) + T2 (iOS plist) + build APK/iOS (T10); integration test en device queda como follow-up opcional |
| SC4 — PNG incluye foto | T5 (hero dentro del RepaintBoundary) + T9 (captura con/sin foto) |
| SC5 — quitar restaura sin foto | T6 (`_handleRemoveImage`) + T9 |
| SC6 — >5 MB / no decodificable → error | T3 (validación) + T7 (unit) + T9 (widget snackbar) |
| SC7 — enviar sin imagen = hoy | T6 (param opcional, flows intactos) + suite regresión (T10) |
| SC8 — iOS build con plist OK | T2 + T10 (CI/macOS) |
| SC9 — strings externalizados | T1 + grep de literales en T10 |
| SC10 — PDF incluye foto | T4 + T8 (`/Subtype /Image` count) |
| SC11 — persistencia (Q1) | **N/A** — Q1 cerrado en "efímera": sin migración, `calculation_detail_page.dart` sin cambios. Decisión registrada en este plan |
| SC12 — analyze/format/suite verde | T10 |

## Out of Scope (confirmado)

- Persistencia en historial / columna `quoteImageBase64` / migración drift v5→v6 (Q1 = efímera).
- Gate Pro / paywall / `_showLockedSnack` (Q3 = Free).
- `calculation_detail_page.dart` (la foto no sobrevive guardar/reabrir).
- Múltiples imágenes, edición/crop, watermark.
