# Sesión 2026-10-09 — Ronda de upgrades: drift 2.35 + riverpod 3.4 + sqlite3 3.7 — CERRADO

**Última sesión: 2026-10-09 (tarde)** — upgrades de stack completados y verificados.
Suite **971/971**, analyze **0 issues**, **build web EXIT=0**. **Sin commit** (falta verbo).

- **Versiones**: drift 2.34.4→**2.35.2** (fixes web IndexedDB/OPFS), drift_dev 2.34.0→**2.35.1**,
  sqlite3 3.5.2→**3.7.0**, flutter_riverpod 3.3.2→**3.4.3** (decisión del dueño — cadena de
  constraints lo exigía: analyzer 13 ⇒ riverpod_lint 3.1.9 ⇒ riverpod 3.4.3), riverpod_generator
  4.0.4→4.0.9, riverpod_lint 3.1.4→3.1.9 (+`analysis_options.yaml`), riverpod_annotation→4.0.7.
- **Web assets**: `web/drift_worker.js` + `web/sqlite3.wasm` refrescados del release oficial
  `drift-2.35.2` (la suite NO cubre web → smoke test manual en navegador antes de deploy).
- **Código**: solo `app_database.g.dart` regenerado (cosmético, genéricos explícitos; sin schema).
- **Pendiente**: commit/push; smoke web manual.
- Detalle: `docs/sessions/2026-10-09_dep-upgrades-drift235-riverpod343.md`.

## Mismo día — Release gates (3/3) y F5 (commiteados)

- **`8fd49ab` chore:** release gates 3/3 — URLs legales → Google Sites calc3dprivacy
  (terms = misma página, decisión del dueño), `*.jks` en `.gitignore` raíz, `sqlite3_flutter_libs`
  directa→transitiva (tombstone eol intencional). Detalle: `2026-10-09_release-gates.md`.
- **`d489725` fix:** F5 amortización fuera del costo y de los reportes (sesión paralela).
  Detalle: `2026-10-09_f5-excluye-amortizacion.md`.
- USER TASK: pegar URLs privacy/terms en Play Console; backup offline del `.jks`.
- Commits previos: `cf3c065` (Tier 2), `dd85004` (Tier 1), `33a2d44` (Tier 0).
- Formato: NO correr `dart format --line-length 100` (repo va a 80).
