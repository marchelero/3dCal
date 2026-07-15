---
description: "Review code changes for quality (functions <50L, files <800L, no deep nesting, no mutation), security (secrets, injection, validation), and maintainability. Use after writing or modifying code, before committing, o como gate pre-PR."
agent: code-reviewer
---

# Code Review Command

Review code changes for quality, security, and maintainability: $ARGUMENTS

## Your Task

1. **Get changed files**: Run `git diff --name-only HEAD`
2. **Analyze each file** for issues
3. **Generate structured report**
4. **Provide actionable recommendations**

## Check Categories

### Security Issues (CRITICAL)
- [ ] Hardcoded credentials, API keys, tokens
- [ ] SQL injection vulnerabilities
- [ ] XSS vulnerabilities
- [ ] Missing input validation
- [ ] Insecure dependencies
- [ ] Path traversal risks
- [ ] Authentication/authorization flaws

### Code Quality (HIGH)
- [ ] Functions > 50 lines
- [ ] Files > 800 lines
- [ ] Nesting depth > 4 levels
- [ ] Missing error handling
- [ ] console.log statements
- [ ] TODO/FIXME comments
- [ ] Missing JSDoc for public APIs

### Best Practices (MEDIUM)
- [ ] Mutation patterns (use immutable instead)
- [ ] Unnecessary complexity
- [ ] Missing tests for new code
- [ ] Accessibility issues (a11y)
- [ ] Performance concerns

### Style (LOW)
- [ ] Inconsistent naming
- [ ] Missing type annotations
- [ ] Formatting issues

## Report Format

For each issue found:

```
**[SEVERITY]** file.ts:123
Issue: [Description]
Fix: [How to fix]
```

## Decision

- **CRITICAL or HIGH issues**: Block commit, require fixes
- **MEDIUM issues**: Recommend fixes before merge
- **LOW issues**: Optional improvements

---

**IMPORTANT**: Never approve code with security vulnerabilities!

---

## Post-Review: Audit

Despues de cerrar este code review, si hubo un PRD origen (`docs/prds/{name}.prd.md`):

1. Guardar el output del review como `docs/reports/{YYYY-MM-DD_HHMM}-{name}.report.md`.
2. Ofrecer al usuario: "¿Audito contra el PRD origen con `/audit-report {name}`? (s/n)".

El auditor verifica que los hallazgos del review NO rompen criterios del PRD. Si el user acepta, invocar `/audit-report`. Si rechaza, respetar.

**Cuando aplicar**: code reviews de features nuevas, refactors grandes, o cambios que tocan criterios de un PRD existente.
**Cuando NO aplicar**: reviews de typos, format fixes, o cambios sin PRD documentado.
