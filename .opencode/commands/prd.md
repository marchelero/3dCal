---
description: "Generate a PRD via prd-agent. Use for any non-trivial task before planning or implementation. Same as @prd-agent but as a slash command."
agent: build
---

# Prd Command

Same as `@prd-agent` but as a slash command. Triggers the prd-agent to:
1. Verify/create `.agents/PROJECT.md` (project context)
2. Run the Understanding Protocol (active listening, intention map, ambiguity resolution, explicit confirmation)
3. Produce `.opencode/prds/{YYYY-MM-DD_HHMM}-{name}.prd.md` (date+time stamp for chronological sorting)

## Your Task

Dispatch to prd-agent via task tool:

```
task { subagent_type: "prd-agent", prompt: "$ARGUMENTS" }
```

**Wait for prd-agent to finish.** Do not start planning or implementation until the user has confirmed the Intention Map and a PRD file exists.

## When to use

- Any non-trivial task: build, create, add, implement, improve, optimize
- Before `/plan`
- Before `/orchestrate` (it does this automatically as Phase 0)
- Direct invocation when you want only the PRD, not the full plan/implementation
- When the request contains "build X" / "create Y" / "agregar Z" / "implementar W"

## Skippable only for

- Pure Q&A ("what does X do?", "how does Y work?")
- One-liner fixes (typo, comma, single-line change)
- Bug reports with repro steps (criteria are obvious)
- `/code-review` of existing changes
- User explicitly says "skip PRD" / "implementa directo"

## Behavior notes

- prd-agent may ask up to 3 ambiguity questions at a time
- prd-agent writes the PRD to `.opencode/prds/{YYYY-MM-DD_HHMM}-{name}.prd.md` (date+time stamp)
- After PRD confirmed, next step is `/plan .opencode/prds/{YYYY-MM-DD_HHMM}-{name}.prd.md`
- If `.agents/PROJECT.md` is missing, prd-agent auto-generates it from existing project files (README, package.json, etc.)

## Anti-pattern

Never propose a solution (file paths, libraries, patterns) before passing through prd-agent. If the user asks for feature X, the first response is to invoke prd-agent, not "I recommend Y with Z."

## Integration

- `/orchestrate` — invokes prd-agent automatically as Phase 0
- `/plan` — consumes the PRD produced by this command
- `intent-driven-development` skill — loaded by prd-agent during clarification
- `@prd-agent` — direct invocation alternative to this slash command
