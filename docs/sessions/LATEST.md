# Sesión 2026-10-10 — Remediación de brechas AC-001..AC-014 — CERRADO

**Última sesión: 2026-10-10** — 14/14 criterios del PRD de remediación, con tests
primero. Suite **999/999**, analyze **0 issues**, **build web OK**. **Sin commit**
(falta verbo).

- **PRD**: `docs/prds/2026-10-10_1600-gap-remediation.prd.md` · **Plan**:
  `docs/plans/2026-10-10_1615-gap-remediation.plan.md`.
- **Reporte**: `docs/reports/2026-10-10_gap-remediation.report.md` ·
  **Auditoría**: `docs/audits/2026-10-10_gap-remediation.audit.md`.
- **Destacados**: AC-001 tope de cantidad; AC-002 validación de gramos; AC-003
  identidad del borrador parcial (`partialId`); AC-004 **nuevo**
  `LocalDataWipeService` + sección «Borrar datos» en Settings (confirmación,
  preserva Pro/locale/tema/HMAC, reinicia onboarding); AC-008 manifest PWA;
  AC-010 **nuevo** CI en PR; AC-011 **nuevo** test migración v1/v2/v3→v17;
  AC-012 checklist sandbox; AC-005/006/007/009 l10n ×6.
- **Pendiente**: commit/push (solo con verbo); al commitear el CI usar
  `git add -f .github/workflows/ci.yml` (`.github/` está en `.gitignore`);
  ejecutar `/audit-report` para inyectar `## Auditoria`; smoke manual de CI;
  acciones externas del dueño (Términos en Play Console, sandbox, Data Safety).
- Detalle: `docs/sessions/2026-10-10_gap-remediation.md`.

## Día previo — Upgrades de stack y release gates (commiteados)

- **2026-10-09 (tarde)**: drift 2.35.2 + riverpod 3.4.3 + sqlite3 3.7.0; web
  assets refrescados (smoke web manual pendiente). Detalle:
  `2026-10-09_dep-upgrades-drift235-riverpod343.md`.
- **`8fd49ab` chore:** release gates 3/3 — URLs legales → Google Sites
  calc3dprivacy (terms = misma página), `*.jks` en `.gitignore` raíz,
  `sqlite3_flutter_libs` directa→transitiva. Detalle: `2026-10-09_release-gates.md`.
- **`d489725` fix:** F5 amortización fuera del costo y de los reportes.
  Detalle: `2026-10-09_f5-excluye-amortizacion.md`.
- Commits previos: `cf3c065` (Tier 2), `dd85004` (Tier 1), `33a2d44` (Tier 0).
- USER TASK: pegar URLs privacy/terms en Play Console; backup offline del `.jks`.
- Formato: NO correr `dart format --line-length 100` (repo va a 80).
