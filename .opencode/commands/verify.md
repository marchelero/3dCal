---
description: "Run verification loop consolidado: typecheck + lint + tests + coverage + build + security. Auto-genera report si PASS. Use before committing significant changes, o como gate pre-PR."
agent: build
---

# Verify Command

Run verification loop to validate the implementation: $ARGUMENTS

## Your Task

Execute comprehensive verification:

1. **Type Check**: `npx tsc --noEmit`
2. **Lint**: `npm run lint`
3. **Unit Tests**: `npm test`
4. **Integration Tests**: `npm run test:integration` (if available)
5. **Build**: `npm run build`
6. **Coverage Check**: Verify 80%+ coverage

## Verification Checklist

### Code Quality
- [ ] No TypeScript errors
- [ ] No lint warnings
- [ ] No console.log statements
- [ ] Functions < 50 lines
- [ ] Files < 800 lines

### Tests
- [ ] All tests passing
- [ ] Coverage >= 80%
- [ ] Edge cases covered
- [ ] Error conditions tested

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities

### Build
- [ ] Build succeeds
- [ ] No warnings
- [ ] Bundle size acceptable

## Verification Report

### Summary
- Status: PASS: PASS / FAIL: FAIL
- Score: X/Y checks passed

### Details
| Check | Status | Notes |
|-------|--------|-------|
| TypeScript | PASS:/FAIL: | [details] |
| Lint | PASS:/FAIL: | [details] |
| Tests | PASS:/FAIL: | [details] |
| Coverage | PASS:/FAIL: | XX% (target: 80%) |
| Build | PASS:/FAIL: | [details] |

### Action Items
[If FAIL, list what needs to be fixed]

---

**NOTE**: Verification loop should be run before every commit and PR.

---

## Post-Verify: Auto-Snapshot Report

**MANDATORY** cuando el verify pasa Y hubo cambios reales desde el ultimo verify.

### Cuando aplica auto-snapshot

- Status final: **PASS** (todo verde) o **PASS-WITH-NITS** (1-2 nits, 0 fail).
- Hubo archivos modificados: `git diff --name-only HEAD~1` no vacio.
- Existe un PRD activo: `.opencode/prds/*.prd.md` con status != COMPLETADO.

### Cuando NO aplica

- Status final: **FAIL** (primero arreglar).
- No hubo cambios desde el ultimo verify.
- No hay PRD activo (trabajo de mantenimiento sin PRD).

### Comportamiento

Al pasar verify:

1. Generar automaticamente `.opencode/reports/{YYYY-MM-DD_HHMM}-{kebab-name}.report.md` con:
   - Status: `COMPLETADO`
   - Agentes usados: solo `build` (verify)
   - Criterios PRD: marcar como PASS los que el verify cubre (build, tests, lint, typecheck)
   - Skills usadas: `verification-loop`
   - Archivos modificados: output de `git diff --name-only HEAD~1`
2. Preguntar UNA vez: "Report generado. ¿Audito contra el PRD origen con `/audit-report {name}`? (s/n)".
3. Si `s` → invocar `/audit-report`. Si `n` → respetar.

Esto evita que un verify exitoso quede sin trazabilidad.
