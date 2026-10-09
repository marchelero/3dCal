# LATEST.md

**Última sesión: 2026-10-09** — Release gates (3/3) RESUELTOS tras Tier 2 (6/6),
Tier 1 (4/4) y Tier 0 (8 fixes). Suite **971/971**, analyze **0 issues**.
Commits de Tier 0/1/2 ya pusheados: `33a2d44`, `dd85004`, `cf3c065`. **Esta sesión SIN commit**.

- **Logrado (release gates, 3/3)**:
  - URLs legales: Privacy publicada en Google Sites `calc3dprivacy` (HTTP 200 verificado);
    `kPrivacyPolicyUrl`/`kTermsOfServiceUrl` actualizadas (terms = misma página, decisión
    del dueño — sin página propia de Términos aún).
  - Keystore: claves nunca en el historial de git; `*.jks` agregado al `.gitignore` raíz;
    `security-audit` secrets PASS.
  - `sqlite3_flutter_libs`: tombstone `0.6.0+eol` confirmado intencional (proyecto ya en
    sqlite3 3.x); dep directa eliminada de `pubspec.yaml` → transitiva (misma versión).
- **Tests**: **971/971** (2 corridas). `flutter analyze` → **No issues found!**.
- **Commit de esta sesión**: NO (pendiente de verbo explícito). Tocados: `.gitignore`,
  `pubspec.yaml/.lock`, `lib/core/constants/app_constants.dart`,
  `docs/notes/store-compliance.md`, reporte + snapshots.
- **USER TASK**: pegar URLs de privacy/terms en Play Console; (opcional) página propia
  de Términos.
- **También 2026-10-09 (sesión paralela) — F5 amortización fuera del costo/reportes**:
  motor `coreBase` sin amortización (total idéntico con/sin precio de compra/vida útil),
  `amortizationCost`=0, sin filas en PDF/imagen/detalle; 11 archivos + 3 tests.
  Detalle: `docs/sessions/2026-10-09_f5-excluye-amortizacion.md`.
- Reporte: `docs/reports/2026-10-09_release-gates.report.md`.
- Tier 2: `docs/reports/2026-10-08_tier2-a11y-sec-docs.report.md` ·
  Tier 1: `docs/reports/2026-10-08_tier1-deuda-tecnica.report.md` ·
  Tier 0: `docs/reports/2026-10-08_tier0-fixes-verificados.report.md`.
- Detalle: `docs/sessions/2026-10-08_tier2-a11y-sec-docs.md` + `2026-10-09_release-gates.md`
  + `2026-10-09_f5-excluye-amortizacion.md`.
