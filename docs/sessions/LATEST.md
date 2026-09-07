# Ultima sesion

**2026-09-07**: Resuelto el baseline de 22 tests fallidos (suite **497/497 verde**). Causa raiz real: commit `114791e` (31-ago) cambio deliberadamente `kDefaultProfitBasePercentage` 200→0 y `kDefaultKwhRate` 0.7→0 (docstring "vacia para que el usuario la defina"), y ademas cambio la UI del onboarding (filamento opcional→requerido) — pero los tests no se actualizaron. Se corrigieron 4 grupos:

- **G1 (12 tests, baseline profit/kwh)**: `calculation_engine_test` (constants 0), `database_repositories_test` (getProfitBase default 0), `calculator_notifier_test` (6: output 36→12, descuento 24→8, solo-minutos 46.5→15.5, horas+minutos con laborRate para observabilidad, cambiar-settings arranca con 200 y baja a 0, save snapshot 36→12), `calculator_page_test` ($36→$12, descuento $27→$9 / monto $9→$3), `settings_page_test` (campo profit vacio, localizado por label).
- **G2 (6 tests, stepper obsoleto)**: `initial_config_stepper_test` reescrito al flujo actual — filamento REQUERIDO (string `configFilamentOptional` devuelve 'Filamento (requerido)', `_canContinue` exige `_printerSaved && _filamentSaved`, boton "Lo agrego después" eliminado), paso 3 sin defaults precargados (campos vacios) y sin chip "Típico" (vive solo en Ajustes).
- **G3 (2 tests, regresion 44e11d0)**: `full_purchase_flow` + `paywall history cap` fallaban porque `save()` corria `Isolate.run(downscalePieceImage)` que **no resuelve en fake-async de testWidgets** → save #11 nunca insertaba. Fix de CODIGO: nuevo provider `pieceImageDownscalerProvider` en `lib/core/providers.dart` (prod: isolate; web: sincrono); tests overridan con version sincrona.
- **G4 (2 tests, gate visual advanced)**: `calculator_page.dart` `_ModeSelector` ocultaba el label "Avanzado" cuando locked (`label: locked ? null : ...`) → fix: label siempre visible atenuado. `pro_locked_visual_test` actualizado a la implementacion actual (color alpha 0.5, no widget Opacity).

**Tambien confirmado**: el fix del boton tuerca a Settings (ruta `/settings/standalone` + test del stack real) YA estaba commiteado en `44e11d0` (la doc del 5-sep decia PENDIENTE, estaba stale). Nada nuevo pendiente de codigo. `flutter analyze`: 3 warnings pre-existentes.

**PENDIENTE**: probar en Android real (crop+rotar, notificacion de guardado, migracion v8→v9, badges PRO) + commit de este working tree (requiere consentimiento; convencion conventional commits).

Ver: [2026-09-05-mejoras-pro-historial-crop-snackbar.md](2026-09-05-mejoras-pro-historial-crop-snackbar.md) · [PRD](../prds/2026-09-05_2353-mejoras-pro-historial-crop-snackbar.prd.md)