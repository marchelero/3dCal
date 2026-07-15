---
description: "Enforce TDD workflow estricto (RED → GREEN → REFACTOR) con 80%+ coverage. Use when implementing new features, fixing non-trivial bugs, o refactoring critical logic — tests antes que codigo."
agent: tdd-guide
---

# TDD Command

Implement the following using strict test-driven development: $ARGUMENTS

## TDD Cycle (MANDATORY)

```
RED → GREEN → REFACTOR → REPEAT
```

1. **RED**: Write a failing test FIRST
2. **GREEN**: Write minimal code to pass the test
3. **REFACTOR**: Improve code while keeping tests green
4. **REPEAT**: Continue until feature complete

## Your Task

### Step 1: Define Interfaces (SCAFFOLD)
- Define TypeScript interfaces for inputs/outputs
- Create function signature with `throw new Error('Not implemented')`

### Step 2: Write Failing Tests (RED)
- Write tests that exercise the interface
- Include happy path, edge cases, and error conditions
- Run tests - verify they FAIL

### Step 3: Implement Minimal Code (GREEN)
- Write just enough code to make tests pass
- No premature optimization
- Run tests - verify they PASS

### Step 4: Refactor (IMPROVE)
- Extract constants, improve naming
- Remove duplication
- Run tests - verify they still PASS

### Step 5: Check Coverage
- Target: 80% minimum
- 100% for critical business logic
- Add more tests if needed

## Coverage Requirements

| Code Type | Minimum |
|-----------|---------|
| Standard code | 80% |
| Financial calculations | 100% |
| Authentication logic | 100% |
| Security-critical code | 100% |

## Test Types to Include

- **Unit Tests**: Individual functions
- **Edge Cases**: Empty, null, max values, boundaries
- **Error Conditions**: Invalid inputs, network failures
- **Integration Tests**: API endpoints, database operations

---

**MANDATORY**: Tests must be written BEFORE implementation. Never skip the RED phase.

---

## Post-TDD: Audit

Despues de cerrar el ciclo TDD (RED → GREEN → REFACTOR → coverage >= 80%):

1. Generar `docs/reports/{YYYY-MM-DD_HHMM}-{name}.report.md` con:
   - Status: `COMPLETADO`
   - Coverage: output real de `npm run test:coverage`
   - Criterios PRD: los que el TDD cubre (tests existentes, cobertura)
2. Ofrecer: "¿Audito contra el PRD origen con `/audit-report {name}`? (s/n)".

El auditor verifica que la cobertura reportada es real y que los tests cubren los criterios del PRD, no solo line coverage.

**Cuando aplicar**: TDD de features nuevas con PRD, TDD de bug fixes criticos, TDD de logica de negocio.
**Cuando NO aplicar**: TDD de prototipos, spikes, o cambios exploratorios.
