---
description: "Create implementation plan with risk assessment (HIGH/MEDIUM/LOW), dependencies, y phases. Use for complex features o refactors que necesitan desglose de tareas antes de implementar. WAIT for confirmation before code."
agent: planner
---

# Plan Command

Create a detailed implementation plan for: $ARGUMENTS

## Your Task

1. **Restate Requirements** - Clarify what needs to be built
2. **Identify Risks** - Surface potential issues, blockers, and dependencies
3. **Create Step Plan** - Break down implementation into phases
4. **Wait for Confirmation** - MUST receive user approval before proceeding

## Output Format

### Requirements Restatement
[Clear, concise restatement of what will be built]

### Implementation Phases
[Phase 1: Description]
- Step 1.1
- Step 1.2
...

[Phase 2: Description]
- Step 2.1
- Step 2.2
...

### Dependencies
[List external dependencies, APIs, services needed]

### Risks
- HIGH: [Critical risks that could block implementation]
- MEDIUM: [Moderate risks to address]
- LOW: [Minor concerns]

### Estimated Complexity
[HIGH/MEDIUM/LOW with time estimates]

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes/no/modify)

---

**CRITICAL**: Do NOT write any code until the user explicitly confirms with "yes", "proceed", or similar affirmative response.

---

## Post-Plan: Audit al Implementar

Despues de que el plan sea aprobado y se implemente, el flujo termina idealmente con `/verify` que auto-genera un report (ver `/verify` command). Si no se corre verify, documentar manualmente:

1. Al cerrar la implementacion, generar `docs/reports/{YYYY-MM-DD_HHMM}-{name}.report.md` referenciando el plan.
2. Ofrecer: "¿Audito contra el PRD origen con `/audit-report {name}`? (s/n)".

El auditor verifica que TODOS los milestones del PRD (no solo los del plan) quedaron cumplidos.

**Cuando aplicar**: planes que producen cambios de codigo, especialmente cuando hay un PRD origen.
**Cuando NO aplicar**: planes de investigacion, planes descartados, planes revertidos.

---

## State Persistence (REQUIRED)

This flow writes to `docs/state/` so it can be resumed after interruption. See `docs/state/README.md` for the schema.

``bash
# At flow start
node .opencode/bin/state.js init plan "" [<prd-path>]
# Capture the printed path as 

# After each phase
node .opencode/bin/state.js update "" <phase> '{"agentsInvoked":["..."],"filesModified":["..."]}'

# On success
node .opencode/bin/state.js complete ""

# On error
node .opencode/bin/state.js fail "" "<error message>"
``

The flow is resumable: if interrupted, `/session-start` detects active states in `docs/state/` and offers to resume from `currentPhase`.