# Reporte — Release gates: URLs legales, keystore, sqlite3_flutter_libs (3/3)

**Fecha**: 2026-10-09 · **Rama**: `main` · **Suite**: **971/971** · **Analyze**: **0 issues**
**Scope**: los 3 items que bloqueaban la publicación pública, listados en
`2026-10-08_tier2-a11y-sec-docs.report.md` §Release gates (SEC-12, auditoría #1, auditoría #4).

## Resumen

| Gate | Hallazgo | Acción | Verificación |
|---|---|---|---|
| 1. URLs legales (SEC-12) | `u3dcal.bo` no resuelve DNS (dominio muerto); sitio no tenía páginas legales | Privacy publicada por el dueño en Google Sites `calc3dprivacy`; ambas constantes apuntan ahí (decisión del dueño) | HTTP 200 verificado en sesión; 971/971 + analyze 0 |
| 2. Keystore fuera del repo (auditoría #1) | Claves **NUNCA** estuvieron en git (historial completo vacío, cualquier ruta/nombre); `android/.gitignore` ya cubre `key.properties` + `**/*.jks` | Hardening: `*.jks` agregado al `.gitignore` raíz (cubre rutas fuera de `android/`) | `git check-ignore` ✓ ambos; `security-audit --type secrets` PASS; grep de historial solo muestra el loader de `key.properties` en `build.gradle.kts` (sin passwords hardcodeados) |
| 3. `sqlite3_flutter_libs` eol (auditoría #4) | **Falso positivo parcial**: `0.6.0+eol` es un *tombstone* intencional del autor (README: "this package no longer does anything"); el proyecto YA está en `sqlite3` 3.x = migración pedida, HECHA; `drift_flutter 0.3.1` lo exige `^0.6.0+eol` transitivo | Dep **directa eliminada** de `pubspec.yaml` (guidance upstream: "remove this package from your dependencies after adopting version 3.x"); queda transitiva con misma versión | `pub get` OK → `dependency: transitive`, `0.6.0+eol` (mismo sha256); 971/971 + analyze 0 |

## Detalle

### Gate 1 — URLs legales (SEC-12) ✅
- `kPrivacyPolicyUrl` = `https://sites.google.com/view/calc3dprivacy/p%C3%A1gina-principal`
  (verificado en sesión: HTTP 200, contenido = "Políticas de Privacidad" de 3D Cal,
  6 secciones, contacto `marcheloalbis@gmail.com`).
- `kTermsOfServiceUrl` = misma página — **decisión explícita del dueño** (2026-10-09):
  el sitio no tiene página de Términos (`/terminos` y `/terms` → 404) y se optó por
  apuntar a la misma URL mientras no exista una propia.
- `docs/notes/store-compliance.md` actualizado (tarea de publicación marcada [x]).
- **USER TASK pendiente (listing Play Console)**: copiar estas URLs en el formulario
  de Play Console (Data safety / IAP); crear página propia de Términos cuando se quiera
  separar y actualizar `kTermsOfServiceUrl`.

### Gate 2 — Keystore ✅
- `android/key.properties` + `android/upload-keystore.jks` existen en disco, NUNCA
  trackeados (`git log --all --diff-filter=A -- "*.jks" "*.keystore" "*key.properties*"` vacío).
- Ignorados por `android/.gitignore` (`key.properties`, `**/*.jks`) — verificado con
  `git check-ignore -v`; **nuevo**: `*.jks` en `.gitignore` raíz (línea Secrets).
- `build.gradle.kts` solo lee credenciales del archivo (L37-42), sin valores en código.
- `security-audit --type secrets --severity low`: **PASS** (0 issues).
- Recomendación operativa (no bloquea): mantener una copia del `.jks` + `key.properties`
  en un gestor de contraseñas/offline — el disco local es el único backup actual.

### Gate 3 — `sqlite3_flutter_libs` ✅
- Evidencia upstream (cache pub, `sqlite3_flutter_libs-0.6.0+eol/README.md`):
  > "Starting from version 0.6.0, this package no longer does anything… remove this
  > package from your dependencies after adopting version 3.x of `package:sqlite3`."
- `drift_flutter 0.3.1` (latest) lo declara `^0.6.0+eol` con comentario: existe para
  impedir resolver 0.5.x (build scripts viejos). **No se puede ni debe quitar lo transitivo.**
- Proyecto en `sqlite3: ^3.5.2` (dev) / `3.5.2` en lock = rama 3.x ✓.
- Cambio: `pubspec.yaml` −1 línea; `pubspec.lock` `direct main` → `transitive`,
  versión idéntica (`0.6.0+eol`, sha256 sin cambio).

## Verificación
- `flutter test`: **971/971** (tras cambio de pubspec) y **971/971** (tras cambio de URLs).
- `flutter analyze`: **No issues found!** (26.6s / 99.3s).
- `security-audit` (secrets): PASS.

## Estado de commit
**SIN COMMIT** — pendiente verbo explícito. Archivos tocados: `.gitignore`,
`pubspec.yaml`, `pubspec.lock`, `lib/core/constants/app_constants.dart`,
`docs/notes/store-compliance.md` + este reporte + snapshots de sesión.

## Fuera de alcance / deferred
- Página propia de Términos (decisión del dueño: misma URL por ahora).
- `sqlite3` 3.5.2 → 3.7.0 y `drift` 2.34.4 → 2.35.2 (updates disponibles, no requeridos
  por gate; hacer en ronda de upgrades con suite completa).
- Tokenizar `Color(0x)`, DB indexes, 62 paquetes con updates → rondas futuras.
