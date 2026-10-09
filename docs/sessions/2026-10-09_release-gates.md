# Sesión 2026-10-09 — Release gates (detallado)

**Objetivo**: cerrar los 3 gates de publicación listados en el reporte Tier 2 §Release gates.
**Resultado**: 3/3 ✅ · `flutter test` **971/971** · `flutter analyze` **0 issues** · SIN COMMIT.

## Gate 1 — URLs legales (SEC-12)
- Diagnóstico: `u3dcal.bo` no resolvía (transport error en /, /privacy, /terms).
- El dueño publicó Privacy Policy en Google Sites y respondió con la URL:
  `https://sites.google.com/view/calc3dprivacy/p%C3%A1gina-principal` (HTTP 200 verificado;
  contenido = Políticas de Privacidad de 3D Cal, 6 secciones, contacto marcheloalbis@gmail.com).
- `/terminos` y `/terms` en el sitio → 404 (no hay página de Términos).
- **Decisión del dueño**: `kTermsOfServiceUrl` → misma URL de privacidad mientras no exista
  página propia. Ambas constantes actualizadas en `lib/core/constants/app_constants.dart` +
  doc comments con fecha/decisión. `docs/notes/store-compliance.md` marcado [x].

## Gate 2 — Keystore fuera del repo
- `git log --all --diff-filter=A -- "*.jks" "*.keystore" "*key.properties*"` → vacío (nunca
  trackeados, cualquier ruta). `git check-ignore -v` → `android/.gitignore:14 **/*.jks` y
  `android/.gitignore:12 key.properties`.
- Hardening: `*.jks` agregado al `.gitignore` raíz (sección Secrets).
- `build.gradle.kts` solo lee credenciales de `key.properties` (sin valores en código).
- `security-audit --type secrets` → PASS.
- Recomendado (no bloquea): backup offline del `.jks` + `key.properties`.

## Gate 3 — sqlite3_flutter_libs eol
- Lectura upstream (README 0.6.0+eol): paquete es **tombstone no-op**; "remove this package
  from your dependencies after adopting version 3.x of package:sqlite3".
- El proyecto YA usa `sqlite3` 3.5.2 (3.x) → migración pedida, hecha. `drift_flutter 0.3.1`
  lo declara `^0.6.0+eol` (transitivo obligatorio, comenta que existe para bloquear 0.5.x).
- Acción: dep directa eliminada de `pubspec.yaml`; `pubspec.lock` ahora `transitive`,
  misma versión `0.6.0+eol` y mismo sha256.

## Verificación
- `flutter test` **971/971** ×3 corridas en la sesión (post-pubspec, post-URLs, y final
  tras cambios externos). `flutter analyze` **0 issues**.

## ⚠️ Cambios EXTERNOS detectados durante la sesión
- 11 archivos modificados a las 00:45:59–00:46:00 (+ `calculation_output.dart` 00:25)
  por un proceso ajeno a esta sesión: refactor que **saca la amortización de impresora (F5)
  del costo de cotización** (fuera de `coreBase`, de live y de todos los reportes) —
  toca `calculation_engine.dart`, `pdf_export.dart`, `pdf_rate_audit.dart`,
  `calculation_detail_page.dart`, `calculator_notifier.dart`, `detail_section.dart`,
  `quote_image_template.dart`, `calculation_output.dart` y 3 tests.
- Verificado: suite 971/971 + analyze 0 sobre ese estado. **No commiteado** (tampoco hay
  verbo); pendiente confirmar origen con el dueño.

## Estado git
Tocados por ESTA sesión: `.gitignore`, `pubspec.yaml`, `pubspec.lock`,
`lib/core/constants/app_constants.dart`, `docs/notes/store-compliance.md`,
`docs/LATEST.md`, `docs/sessions/LATEST.md`, reporte `2026-10-09_release-gates.report.md`
(+ este snapshot). Externos: los 11 listados arriba.
