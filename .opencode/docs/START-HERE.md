# Start Here

> 5-minute orientation to the opencode starter pack. Read this first; everything else is discoverable.

## What this is

A portable, zero-deps starter pack for [opencode](https://opencode.ai):

- **69 agents** — specialist roles (reviewers, builders, planners, domain experts)
- **14 skills** — on-demand reference material (patterns, checklists, frameworks)
- **65 commands** — slash-commands for common flows (`/plan`, `/prd`, `/code-review`, etc.)
- **9 bin scripts** — local CLIs (`context.js`, `instinct.js`, `build-agents-index.js`)

No `package.json` at the project root. No build step. Drop the `.opencode/` folder in any repo and it works.

## The 80/20: 6 things to know

| # | What | When |
|---|------|------|
| 1 | `/help` | Get an overview of commands and how to use this pack |
| 2 | `/list-agents` | See the full agent catalog with descriptions |
| 3 | `/list-skills` | See the full skill catalog with triggers |
| 4 | `/prd <request>` | Start any non-trivial feature (PRD-first) |
| 5 | `/plan <prd-path>` | Turn a PRD into a phased implementation plan |
| 6 | `/verify` | Validate the result against the original PRD |

## Common flows

### I have an idea, want to build it

```
/prd "user profile editing with avatar upload"
  → produces .opencode/prds/2026-06-30-1430-profile.prd.md
  → asks clarifying questions, builds Intention Map

/plan .opencode/prds/2026-06-30-1430-profile.prd.md
  → produces phased implementation plan with risks
  → wait for confirmation

/tdd "implement profile edit form"
  → strict RED → GREEN → REFACTOR
  → 80%+ coverage required

/verify
  → runs lint + typecheck + tests
  → produces .opencode/reports/{ts}-{slug}.report.md

/audit-report profile
  → crosses report against PRD, emits PASS/PASS-WITH-NITS/FAIL
```

### I just wrote code, want it reviewed

```
/code-review
  → runs code-reviewer + security-reviewer + typescript-reviewer in parallel
  → severity-grouped findings with exact file:line

# or for a PR
/pr-review 42
  → fetches PR diff via gh
  → dispatches 5 reviewers in parallel
  → unified verdict: APPROVE | WARN | BLOCK
```

### Something is broken

```
/build-fix
  → runs build-error-resolver with minimal diffs
  → only fixes build/type errors, no architectural changes

# or for merge conflicts
/merge-conflict
  → classifies conflicts (both-added, both-modified, logic-divergence, etc.)
  → proposes resolution + validates with typecheck + tests
```

### I want to refactor safely

```
/refactor-clean
  → runs refactor-cleaner (knip, depcheck, ts-prune)
  → identifies dead code, duplicates, unused exports
  → safe removal with verification
```

### I want to migrate something (DB, framework, monorepo)

```
@migration-planner "migrate from REST to GraphQL"
  → produces migration plan with strategy, phases, rollback
  → risk register + data integrity checks
```

### I want to discover what exists

```
/list-agents                       # all 69 agents
/list-agents react                 # filter by keyword
/list-agents "Language Reviewers"  # filter by category
/list-skills                       # all 14 skills
```

## Mental model: 4 layers

The pack uses a 4-layer memory architecture to keep your context window lean:

| Layer | What | When | Size |
|-------|------|------|------|
| 1 | `AGENTS.md` + `INSTRUCTIONS.md` + `PROJECT.md` | always | ~2K tokens |
| 2 | `LATEST.md` session snapshot | `/session-start` | ~1-3K tokens |
| 3 | Skills (on-demand), specific files, sub-agents | when needed | variable |
| 4 | Full git history, all PRDs, instincts | never (disk only) | unlimited |

**Rule**: anything that can live on disk → disk. Only "live" things go in context.

## The agents you should know by name

These are the agents you'll see most often. Each has a focused specialty and a short context footprint.

| Agent | Use when |
|-------|----------|
| `prd-agent` | Any non-trivial feature, before any other agent |
| `planner` | Turn a goal/PRD into a phased plan |
| `code-reviewer` | After writing code, always |
| `security-reviewer` | After auth, input handling, secrets, payments |
| `code-architect` | Design before code on a non-trivial feature |
| `code-explorer` | Understand an unfamiliar codebase |
| `tdd-guide` | Enforce test-first on new code |
| `silent-failure-hunter` | Catch swallowed errors and bad fallbacks |
| `migration-planner` | DB/framework/monorepo migrations |
| `report-auditor` | Cross-check a report against the source PRD |

For the full catalog: `/list-agents` or `.opencode/AGENTS_INDEX.md`.

## The skills you should know

Skills are loaded on-demand. You don't need to call them — they're triggered by your request's keywords. The `skill-router` skill has the full trigger map.

Most commonly auto-loaded:

- `frontend-patterns` — React/JSX/TSX patterns (any UI work)
- `backend-patterns` — server-side layered architecture (any API work)
- `api-design` — REST/GraphQL contracts
- `security-review` — OWASP Top 10, secrets, injection
- `task-decomposition` — turn a PRD into a DAG of tasks
- `verification-loop` — post-change validation
- `coding-standards` — shared floor (naming, immutability, code quality)

For the full catalog: `/list-skills` or `.opencode/skills/INDEX.md`.

## Conventions (enforced, not optional)

These 4 behaviors are enforced by the pack:

1. **PRD-first** — non-trivial work starts with a PRD via `/prd`. Skip only for one-liners, pure Q&A, or explicit user opt-out.
2. **Caveman mode** — responses use compact prose by default. Override with `stop caveman` or `normal mode`.
3. **Session memory** — `/session-end` writes a snapshot. Don't end sessions with important context unrecorded.
4. **No destructive actions without consent** — `git commit`, `git push`, `rm -rf`, `DROP TABLE` need explicit verbs.

See `.opencode/AGENTS.md` for the full list.

## How to extend

Add a new agent:
```bash
# Create .opencode/agents/<name>.md
# Required frontmatter:
#   description (1-line, triggers: "Use when...")
#   mode: subagent
#   permission: { edit: deny }   # minimum
node .opencode/bin/validate-frontmatter.js    # check
node .opencode/bin/build-agents-index.js       # refresh catalog
```

Add a new skill:
```bash
mkdir .opencode/skills/<name>
# Create <name>/SKILL.md
# Required frontmatter:
#   name: <name>
#   description (third person, "Use when...")
# Optional: triggers: [react, hooks, jsx]
node .opencode/bin/build-skills-index.js       # refresh catalog
```

Add a new command:
```bash
# Create .opencode/commands/<name>.md
# Frontmatter:
#   description: "..."
#   agent: <which agent to dispatch>
```

## When something goes wrong

| Symptom | Fix |
|---------|-----|
| "agent not found" | Restart opencode (`Ctrl+C`, `opencode .`) |
| Skills/agents not loading | `node .opencode/bin/validate-frontmatter.js` |
| AGENTS_INDEX.md missing | `node .opencode/bin/build-agents-index.js` |
| Junk in catalog | Edit the agent/skill description |
| Want to start fresh | `/session-end` then close + reopen |
| Pack feels heavy | `node .opencode/bin/context.js` |

## See also

- `.opencode/AGENTS.md` — full rules and pack structure
- `.opencode/INSTRUCTIONS.md` — global instructions (security, code style, git workflow)
- `.opencode/docs/SURFACES.md` — when to use agent vs skill vs command
- `.opencode/CHANGELOG.md` — version history
