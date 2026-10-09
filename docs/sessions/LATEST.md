# Sesión 2026-10-09 — Release gates (3/3) — CERRADO

**Última sesión: 2026-10-09** — los 3 gates de publicación resueltos.
Suite **971/971**, analyze **0 issues**. **Sin commit** (pendiente de verbo explícito).

- **Logrado (3/3)**:
  - Gate 1 SEC-12 URLs legales: `u3dcal.bo` muerto → Privacy publicada por el dueño en
    Google Sites (`sites.google.com/view/calc3dprivacy/página-principal`, HTTP 200
    verificado); `kPrivacyPolicyUrl` y `kTermsOfServiceUrl` ambas apuntan ahí
    (**decisión del dueño**: sin página propia de Términos aún — `/terminos` 404).
    `docs/notes/store-compliance.md` actualizado.
  - Gate 2 keystore: claves **nunca** en el historial de git (cualquier ruta/nombre);
    `android/.gitignore` ya cubría `key.properties` + `**/*.jks`; hardening nuevo:
    `*.jks` en `.gitignore` raíz. `security-audit` secrets **PASS**. Recomendado:
    backup offline del `.jks` (único disco actual).
  - Gate 3 `sqlite3_flutter_libs`: **falso positivo parcial** — `0.6.0+eol` es tombstone
    intencional (paquete no-op; proyecto ya en `sqlite3` 3.x = migración hecha;
    `drift_flutter 0.3.1` lo exige `^0.6.0+eol` transitivo). Dep directa eliminada de
    `pubspec.yaml` según guidance upstream → queda `transitive`, misma versión/sha.
- **Tests**: 971 → **971** (2 corridas: tras pubspec y tras URLs). Analyze → **0**.
- **USER TASK pendiente**: copiar URLs de privacy/terms en Play Console; página propia
  de Términos (opcional, actualiza `kTermsOfServiceUrl`).
- **Commit**: NO (falta verbo). Tocados: `.gitignore`, `pubspec.yaml/.lock`,
  `app_constants.dart`, `docs/notes/store-compliance.md`, reporte + snapshots.
- Reporte: `docs/reports/2026-10-09_release-gates.report.md`.
- Sesión previa: `docs/sessions/2026-10-08_tier2-a11y-sec-docs.md`
  (Tier 2 6/6, commiteado `cf3c065`; Tier 1 `dd85004`; Tier 0 `33a2d44`).
- Reportes: `docs/reports/2026-10-08_tier2-a11y-sec-docs.report.md`,
  `2026-10-08_tier1-deuda-tecnica.report.md`, `2026-10-08_tier0-fixes-verificados.report.md`.
- **Siguiente sugerido**: `/flow-security` (ofrecido 2026-10-09, aún sin respuesta) o
  ronda de upgrades (`drift 2.35`, `sqlite3 3.7`) / publicación Play Console.

## También 2026-10-09 — F5: amortización fuera del costo y de los reportes (sin commit)

Sesión paralela (mismo día, otro flujo): la amortización de la impresora ya **no entra en
`coreBase`** (express ni avanzado) ni aparece en PDF / imagen PNG / detalle en pantalla.
`amortizationCost` de salida queda en 0; campos y params se conservan (sólo cambian valores).
Archivos: los 11 de `lib/` + `test/` del refactor (ver detalle de riesgos y mapeo A1..A5).
`flutter analyze` **0 issues** · `flutter test` **971/971** · **NO commit**.
Detalle: `docs/sessions/2026-10-09_f5-excluye-amortizacion.md`.
Advertencia: **no** correr `dart format --line-length 100` sobre el repo (el repo está a 80;
a 100 reescribe archivos enteros).
