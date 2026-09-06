# PRD: Mejoras post-pruebas — PRO clickeable, imagen en historial, crop al cargar, notificación de guardado

> Generated 2026-09-05_2353 desde petición del usuario:
> "quiero que en todos los lugares que diga PRO al hacer click me abra el modal para comprar... cuando guardo imagenes existe la posibilidad de que en el historial se guarde tambien la imagen... cuando cargo una imagen existe la posibilidad de que me permita editar o recortar... cuando guardo mi cotizacion como imagen no veo la notificacion de que se acaba de guardar."

## Status
APPROVED — implemented and verified (2026-09-05). Code review: APPROVE-WITH-FIXES → all 6 fixes applied. All ACs passed (see AC coverage in review). Tests: 474 passed / 22 pre-existing baseline failures (unrelated: kDefaultProfitBasePercentage 0 vs 200%).

## Context

3dCal es calculadora de precios para impresión 3D, 100% local (sin backend, sin auth). Android/iOS/web, Flutter + Riverpod + drift (schemaVersion 8). Hallazgos verificados en codebase:

1. **PRO no clickeable**: `ProBadge` (`lib/shared/widgets/pro_badge.dart`, l.24) es StatelessWidget **puramente visual** (sin onTap). Se renderiza en 5 sitios: `result_sheet.dart:645`, `calculator_page.dart:1095` (sección "Otros") y `:2003` (`_ModePill` Avanzado), `calculation_detail_page.dart:673`, `settings_page.dart:114`. Las acciones *al lado* (botones +/−, header onTap, pill onTap, TextField) ya llevan a `/paywall` — el badge en sí no. El paywall existe (`paywall_page.dart`, ruta `/paywall` en `app_router.dart:118-122`); patrón de apertura: `GoRouter.of(context).push('/paywall')`; desde un sheet se hace `pop()` primero (patrón `result_sheet.dart:655-657`).

2. **Imagen efímera**: la foto de la pieza vive solo en `_pieceImageBytes` (memoria del state de `_ResultSheetContentState`, `result_sheet.dart:334`). La tabla `calculations` **no tiene columna de imagen**. Al guardar en historial (`calculator_notifier.save()` l.335-375 → `calculation_repository._insertInTransaction` l.126-183) la imagen se pierde. El template `QuoteImageTemplate` y el PDF sí saben renderizar la imagen si se les pasa (`quote_image_template.dart:125-150`, `pdf_export.dart:88/146/276-283`). La imagen persiste únicamente para el logo de empresa (base64 TEXT en tabla `settings`).

3. **Crop inexistente**: pick actual en `_handlePickImage` (`result_sheet.dart:366-387`) → `pickPieceImage(source)` → `setState(_pieceImageBytes = bytes)`. Sin edición.

4. **SnackBar de guardado invisible**: `_handleSave` (`result_sheet.dart:447-472`) sí muestra `AppSnackBar.success` (l.458-460) — pero el sheet modal sigue abierto y el SnackBar queda **detrás de la ruta modal** (invisible). Además `if (!mounted) return;` (l.454) descarta la notificación si el usuario cierra el sheet durante el guardado. En la página de detalle (`calculation_detail_page.dart:164-186`) el SnackBar sí se ve.

## Decisiones tomadas (confirmadas con el usuario)

- Alcance editor de imagen: **recortar + rotar** (image_cropper, Android).
- Plataforma objetivo de pruebas: **Android** (móvil).
- Historial: **miniatura en lista + imagen en detalle** (asumido, no respondido).
- Badges PRO: **click en badge abre paywall en todos los sitios** (asumido, no respondido).

## Feature 1 — Badges/indicadores PRO clickeables → paywall

### Objetivo
Todo lugar donde aparezca "PRO" (badge, pill) responde al tap abriendo el flujo de compra existente.

### RF
- **RF1-1**: `ProBadge` gana un `onTap` (default: push `/paywall`); se envuelve en `InkWell` manteniendo `Tooltip`/`Semantics` existentes.
- **RF1-2**: Los 5 sitios pasan el badge clickeable sin romper la interacción *al lado* (botones +/−, header, pill, TextField siguen funcionando igual, sin doble push).
- **RF1-3**: Desde el result sheet (modal) el tap hace `pop()` del sheet primero y luego push `/paywall` (patrón existente).
- **RF1-4**: Web: `/paywall` redirige a `/settings` (comportamiento heredado, sin cambios en este PRD).

### AC (Acceptance Criteria)
- AC-101: En los 5 sitios (result_sheet, "Otros", pill Avanzado, detalle, settings), tap sobre el badge PRO → navega a `/paywall` (Android). Verificación: `paywall_navigation_test.dart` ampliado + widget test. Prioridad: Required.
- AC-102: Con `isProProvider == true`, el tap en el badge no navega a paywall (no debe ofrecer comprar a quien ya tiene PRO). Verificación: widget test. Prioridad: Required.
- AC-103: La interacción adyacente existente (botones +/−, header de sección, pill de modo, campo de empresa) sigue funcionando sin doble navegación. Verificación: tests existentes pasan. Prioridad: Required.

## Feature 2 — Persistir imagen de la pieza en el historial

### Objetivo
Al guardar una cotización con foto de pieza, la imagen queda persistida y visible en el historial (lista y detalle).

### RF
- **RF2-1**: Migración drift **schemaVersion 8 → 9**: columna `pieceImageBlob` (`BLOB` nullable) en `calculations`. Migración aditiva, no destructiva; datos existentes intactos.
- **RF2-2**: `calculator_notifier.save()` acepta `Uint8List? pieceImageBytes` y lo persiste en la transacción (`_insertInTransaction`).
- **RF2-3**: Downscale antes de persistir: máx 1200px lado mayor + JPEG q85 (paquete `image`, puro Dart) para no inflar la BD. Imagen nula/no decodificable → se guarda sin imagen (no bloquea el guardado).
- **RF2-4**: Lista de historial (`calculations_list_page.dart`): thumbnail (~40px, `Image.memory`) cuando la entrada tiene imagen.
- **RF2-5**: Detalle (`calculation_detail_page.dart`): al cargar la cotización, la imagen persistida se muestra en la vista previa y viaja al exportar PNG/PDF (el template/PDF ya lo soportan).
- **RF2-6**: Cotizaciones antiguas (sin imagen) se renderizan idéntico a hoy (sin thumbnail, sin imagen en detalle).

### AC
- AC-201: Guardar cotización con foto → la entrada en historial muestra thumbnail y el detalle muestra la imagen. Verificación: widget test + manual. Prioridad: Required.
- AC-202: Guardar cotización sin foto → sin thumbnail, detalle sin imagen (igual que hoy). Verificación: tests existentes pasan. Prioridad: Required.
- AC-203: Migración 8→9 preserva todas las filas y columnas existentes; cotizaciones con blob `NULL` elegibles. Verificación: test de migración (patrón `migration_v5_to_v6_test.dart`). Prioridad: Required.
- AC-204: Historial cap gratis (10) sigue aplicando sin cambios de comportamiento. Verificación: `history_cap_test.dart` pasa. Prioridad: Required.
- AC-205: Exportar PNG/PDF desde detalle de una cotización con imagen guardada incluye la imagen. Verificación: test unit quote_image_template/pdf_export. Prioridad: Required.

## Feature 3 — Recortar + rotar al cargar la imagen

### Objetivo
Al elegir una foto (galería o cámara) para la cotización, el usuario puede recortarla y rotarla antes de adjuntarla.

### RF
- **RF3-1**: Tras `pickPieceImage(source)` en `_handlePickImage` (`result_sheet.dart:366-387`), se abre editor `image_cropper` (`CropImage` / `CropImage with `CropAspectRatio` libre y rotación habilitada).
- **RF3-2**: Confirmar crop → los bytes recortados reemplazan a `_pieceImageBytes`. Cancelar → no se adjunta imagen (sin error, sin SnackBar; flujo vuelve al estado previo).
- **RF3-3**: Error de crop (no soportado / fallo) → `AppSnackBar.error` con mensaje existente de picker fallido; no se adjunta.
- **RF3-4**: Setup Android: registrar `CropImageActivity` en `AndroidManifest.xml` según la versión de `image_cropper` que se resuelva (verificación en implementación).

### AC
- AC-301: Elegir imagen → se abre el editor con la imagen y control de rotación. Verificación: unit test con seam/fake del cropper. Prioridad: Required.
- AC-302: Confirmar → imagen recortada adjuntada; aparece en preview/template. Verificación: unit + widget test. Prioridad: Required.
- AC-303: Cancelar → nada adjuntado, sin SnackBar de error. Verificación: unit test. Prioridad: Required.
- AC-304: El flujo sin imagen (share directo) no se ve afectado. Verificación: tests existentes pasan. Prioridad: Required.

## Feature 4 — Notificación visible al guardar cotización como imagen

### Objetivo
El usuario SIEMPRE ve confirmación al guardar la cotización como imagen desde el result sheet.

### RF
- **RF4-1**: Fix de visibilidad: el SnackBar de éxito (result_sheet) se muestra **por encima del sheet** (envolver el contenido del sheet en un `Scaffold` local con su propio `ScaffoldMessenger`, o equivalente que garantice visibilidad sobre la ruta modal).
- **RF4-2**: Capturar el messenger **antes** del `await` de captura/guardado para que la notificación se muestre incluso si el usuario cierra el sheet durante el guardado (reemplaza el `if (!mounted) return;` que tragaba la notificación).
- **RF4-3**: Path B (detail page) ya funciona — sin cambios de comportamiento.
- **RF4-4**: Los errores (ShareQuoteException, genérico) mantienen su SnackBar de error visible bajo el mismo fix.

### AC
- AC-401: Guardar imagen desde el result sheet (sheet abierto) → SnackBar de éxito **visible** inmediatamente. Verificación: widget test (`quote_save_flow_test.dart` — rama de éxito, hoy solo cubre error). Prioridad: Required.
- AC-402: Si el usuario cierra el sheet mientras se guarda → igualmente aparece la confirmación de éxito al completarse. Verificación: widget test. Prioridad: Required.
- AC-403: Error al guardar → SnackBar de error visible (cubre resultado idéntico al actual). Verificación: test existente pasa. Prioridad: Required.

## Requerimientos No Funcionales

- **RNF-1 — Storage**: imagen persistida como BLOB en drift local (no-backend). Downscale RF2-3 limita crecimiento de BD. Web: drift usa IndexedDB — BLOB soportado; comportamiento esperado equivalente (fuera del alcance de pruebas de este PRD, que es Android).
- **RNF-2 — Permisos**: sin permisos nuevos en Android (crop = activity propia de image_cropper; image_picker ya delegado al photo picker del sistema).
- **RNF-3 — Dependencias**: agregar `image_cropper` (y `image` para downscale si no está ya transitiva). `image_picker` ya existe. `image_cropper` requiere activity en `AndroidManifest.xml` (verificar versión exacta en implementación).
- **RNF-4 — i18n**: strings nuevos (ej. "Editar imagen" / tooltips) van a `l10n/` (`app_strings.dart` + `es_bo.dart` + `en_us.dart` + resto de locales), convención existente.
- **RNF-5 — Tests**: unit (repo persistencia blob, downscale, cropper seam), widget (list thumbnail, detail imagen, snackbar éxito visible), integración migración 8→9. `flutter analyze` + `flutter test` verdes.
- **RNF-6 — Rendimiento**: downscale antes de persistir; la lista de historial NO carga bytes de imagen para filas sin imagen; thumbnails con decode acotado.

## Success Criteria

El trabajo está completo cuando TODOS los siguientes son verdaderos:

- [ ] **SC1**: Tap en cualquier badge/PRO (5 sitios) abre el paywall (o no hace nada si ya es PRO); tests de navegación pasan.
- [ ] **SC2**: Guardar cotización con foto → thumbnail en lista + imagen en detalle; cotizaciones viejas sin imagen intactas; migración v9 verificada por test.
- [ ] **SC3**: Elegir imagen abre editor crop+rotar; confirmar adjunta la imagen editada; cancelar no adjunta nada.
- [ ] **SC4**: Guardar cotización como imagen desde el result sheet muestra SnackBar de éxito visible (sheet abierto o cerrado durante el guardado).
- [ ] **SC5**: `flutter analyze` sin issues y `flutter test` todo verde.

## Fuera de alcance

- Cambiar el redirect web de `/paywall` → `/settings`.
- Editor completo (brillo, contraste, filtros).
- Compartir la imagen del historial como archivo separado.
- Sync/cloud de imágenes (no-backend).
- iOS (mismo código, pero verificación de manifest no incluida en este PRD).

## Open Questions

- Versión exacta de `image_cropper` compatible con el Flutter del proyecto y su setup Android — resolver en implementación (docs-lookup).
- Tamaño de downscale: 1200px/q85 es default propuesto; ajustable si el usuario prefiere más calidad.