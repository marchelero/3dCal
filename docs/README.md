# Project Docs

Single landing for all project-generated documentation. Anything `.opencode/` produces (PRDs, plans, reports, audits, sessions, recovery state, instincts) lives here. Pack docs (the README/config of the opencode starter pack itself) stay in `.opencode/manual/` and are kept separate on purpose.

## What's in here

| Path | What | When to read |
|------|------|--------------|
| `PROJECT.md` | Auto-generated project context (stack, structure, conventions) | Session start, onboarding |
| `AGENTS_INDEX.md` | Auto-generated index of all 69 agents | Picking the right subagent |
| `prds/` | Product Requirements Docs (output of `/prd` or `/flow-feature`) | Before planning or implementing |
| `plans/` | Implementation plans (output of `/plan`) | Before coding |
| `reports/` | Execution reports (output of `/orchestrate`, `/verify`, etc.) | After a flow finishes |
| `audits/` | Audit verdicts (output of `/audit-report`) | Cross-checking report vs PRD |
| `sessions/` | Session-end snapshots (auto + manual via `/session-end`) | Resuming work |
| `state/` | Recovery state for resumable flows (machine-local) | Mid-flow crash recovery |
| `instincts/` | Learned project patterns (auto via `/learn`) | Pattern review |

## Conventions

- **Naming**: `{YYYY-MM-DD_HHMM}-{slug}.{ext}` for all generated files.
- **Sessions & instincts** are machine-local (gitignored). PRDs, plans, reports, audits are tracked.
- **Regeneration**: `PROJECT.md` and `AGENTS_INDEX.md` regenerate from source via the CLIs in `.opencode/bin/`.

Full conventions in `.opencode/CONVENTIONS.md`.

## Quick start

```bash
# Regenerate indexes
node .opencode/bin/build-agents-index.js
node .opencode/bin/build-skills-index.js
node .opencode/bin/refresh-project.js --dry-run

# Smoke test the pack
node .opencode/bin/smoke-test.js
```
