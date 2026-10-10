# LATEST.md

**Última sesión: 2026-10-09 (tarde)** — Ronda de upgrades de stack CERRADA:
drift **2.34.4→2.35.2** (fixes web), drift_dev **2.34.0→2.35.1**, sqlite3 **3.5.2→3.7.0**,
flutter_riverpod **3.3.2→3.4.3** (decisión del dueño; cadena analyzer13⇒lint3.1.9⇒riverpod3.4.3),
riverpod_generator 4.0.9, riverpod_lint 3.1.9. Web assets (`drift_worker.js`/`sqlite3.wasm`)
refrescados del release drift-2.35.2. Solo cambió `app_database.g.dart` (cosmético, sin schema).

- **Verificación**: `flutter test` **971/971** · `flutter analyze` **0 issues** ·
  `flutter build web` **EXIT=0**. **SIN COMMIT** (pendiente de verbo).
- **Pendiente**: commit/push; smoke test web manual en navegador antes de deploy.
- Detalle: `docs/sessions/2026-10-09_dep-upgrades-drift235-riverpod343.md`.

## Mismo día — ya commiteados y pusheados

- **`8fd49ab`** chore: release gates 3/3 (URLs legales Google Sites, `*.jks` gitignore,
  sqlite3_flutter_libs transitivo). USER TASK: URLs en Play Console + backup offline `.jks`.
- **`d489725`** fix: F5 amortización fuera del costo/reportes (sesión paralela).
- Tier 2/1/0: `cf3c065`, `dd85004`, `33a2d44`.
- Reportes: `docs/reports/2026-10-09_release-gates.report.md`, `2026-10-08_tier2-a11y-sec-docs.report.md`,
  `2026-10-08_tier1-deuda-tecnica.report.md`, `2026-10-08_tier0-fixes-verificados.report.md`.
- Snapshots: `docs/sessions/2026-10-09_{dep-upgrades-drift235-riverpod343,release-gates,f5-excluye-amortizacion}.md`
  + `2026-10-08_tier2-a11y-sec-docs.md`.
