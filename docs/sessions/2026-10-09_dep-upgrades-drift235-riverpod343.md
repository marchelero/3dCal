# Sesión 2026-10-09 — Ronda de upgrades: drift 2.35 + riverpod 3.4 + sqlite3 3.7

**Objetivo**: subir `drift` a 2.35 (fixes web IndexedDB/OPFS) y `sqlite3` a 3.7.
**Resultado**: hecho y verificado. **SIN COMMIT** (pendiente de verbo).

## Versiones (antes → después)
| Paquete | Antes | Después |
|---|---|---|
| drift (runtime) | 2.34.4 | **2.35.2** |
| drift_dev | 2.34.0 (pinned) | **2.35.1** (pinned) |
| sqlite3 | 3.5.2 | **3.7.0** |
| sqlparser (transitivo) | 0.44.5 | 0.45.0 |
| flutter_riverpod / riverpod | 3.3.2 (pinned exact) | **3.4.3** (pinned exact) |
| riverpod_generator | 4.0.4 | 4.0.9 |
| riverpod_lint | 3.1.4 | **3.1.9** (también en `analysis_options.yaml` plugins) |
| riverpod_annotation | 4.0.3 | 4.0.7 |
| build_runner | 2.15.1 | 2.15.1 (sin cambio) |
| web assets | drift 2.34-era | **drift_worker.js + sqlite3.wasm del release drift-2.35.2** |

## Cadena de constraints descubierta (por qué riverpod 3.4.3)
- `drift_dev 2.34.0` excluye runtime drift ≥2.35 (`drift: ">=2.30.0 <2.35.0"`).
- Todo `drift_dev ≥2.34.1` exige `analyzer ^13`; `riverpod_generator 4.0.4` exige `analyzer ^12`.
- Único `riverpod_generator` con analyzer 13 = **4.0.9** → `riverpod_analyzer_utils dev.12` →
  `riverpod_lint 3.1.9` → **`riverpod 3.4.3`**. Sin path alternativo (probado: lint 3.1.4–3.1.8,
  generator intermedio, drift_dev 2.34.x — todos bloqueados por analyzer/riverpod).
- **Decisión del dueño (question tool, 2026-10-09)**: subir flutter_riverpod 3.3.2 → 3.4.3
  (minor semver) y completar el set. El pin 3.3.2 venía de un commit rutinario (`31114f7`)
  sin rationale documentado.

## Cambios de código
- `lib/core/database/app_database.g.dart` regenerado con drift_dev 2.35.1 (cosmético:
  genéricos explícitos en table managers, +54/−7). Cero cambios de schema.
- `pubspec.yaml`: `drift ^2.35.0`, `drift_dev 2.35.1`, `sqlite3 ^3.7.0`,
  `flutter_riverpod 3.4.3`, `riverpod_generator 4.0.9`, `riverpod_lint 3.1.9`.
- `analysis_options.yaml`: plugin `riverpod_lint: 3.1.9` (alineado con pubspec).
- `web/drift_worker.js` (360104 B) + `web/sqlite3.wasm` (750007 B) descargados del release
  oficial `drift-2.35.2` (antes: era 2.34, 16/07/2026). `sqlite3mc.wasm` no aplica.

## Verificación
- `flutter pub upgrade` EXIT=0 (30 deps cambiados).
- `dart run build_runner build` EXIT=0 (114s, solo .g.dart cosmético).
- `flutter analyze` → **No issues found!** (con riverpod_lint 3.1.9 activo).
- `flutter test` → **971/971**.
- `flutter build web` → **EXIT=0** (√ Built build\web, 153s).

## Pendientes / riesgos
- **Smoke test web manual** en navegador (los tests corren en NativeDatabase; el worker/wasm
  nuevos solo se ejercitan en browser) antes del próximo deploy web.
- `flutter_riverpod 3.4.x` puede traer nuevos lints de `riverpod_lint 3.1.9` en código futuro.
- Commits anteriores del día: `d489725` (F5), `8fd49ab` (release gates).
- Formato: NO correr `dart format --line-length 100` (repo va a 80 — nota de la sesión F5).
