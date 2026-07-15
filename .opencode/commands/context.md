---
description: "Show context budget report — skills, agents, commands, session history, and recommendations. Use when context feels heavy, before starting a long task, or to audit what's loaded."
agent: build
---

# Context Command

Show a context budget report so you (and the user) can see what's loaded, what's available, and what to do about it. Use this when:

- Context feels heavy (lots of files read, lots of skills mentioned)
- Before starting a long task (so you know the starting baseline)
- After a long session (to see what's accumulated)
- When the user asks "how big is the context" or "what's loaded"

## Your Task

Run the opencode-native context budget CLI:

```bash
node .opencode/bin/context.js
```

### Optional flags

| Flag | What it shows |
|------|---------------|
| (none) | Full report: skills + agents + commands + sessions + recommendations |
| `--skills` | Only the skills inventory (catalogo of available skills) |
| `--recommend` | Only the recommendations list |

## Report Output

The CLI outputs:

```
Context Budget Report
=====================

Skills available: 11
  local (.agents/skills): 15
  global (~/.config/...):   0

Agents: 65 (393.3 KB, ~96K tokens if all loaded — DO NOT load all)
Commands: 49 (54.2 KB)
Sessions: 3 (latest: 2026-06-22)

Project (excluding .git and .opencode/node_modules): 1.4 MB

Recommendations:
  - Tool output discipline: use `grep -m 50`, `head -n 100`, and the Read tool with line limits
  - Sub-agents inherit context from primary. Don't re-read a file in a sub-agent if the primary already has it.
  - Last session: 2026-06-22 — run /session-start to resume with minimal context load.
```

## How to Use This Output

After running the CLI:

1. **Quote key numbers** in caveman style back to the user (1-2 lines max).
2. **If recommendations are concerning** (e.g., skills > 8, project > 10 MB), proactively suggest the user run `/session-end` to checkpoint before continuing.
3. **Do NOT load everything** just because the report shows it. The report is for awareness, not for triggering bulk loads.
4. **If the user wants deep dive**, run with `--skills` (catalogo) or `--recommend` (actionable list).

## Behavior Notes

- This command does NOT read the LLM's actual context window. It reports the local environment (what's available, what's been generated).
- Run is cheap (~50ms). Safe to call any time.
- The CLI does not write anything. Pure read.
- For actual token usage, the `dynamic-context-pruning` plugin auto-prunes mid-session; this command is for awareness, not control.

## Integration

- `/session-start` — loads minimal context (Capa 1+2 of the 4-layer hierarchy)
- `/session-end` — writes a snapshot, freeing you to start fresh
- `dynamic-context-pruning` plugin — auto-poda mensajes viejos durante la sesion
- `caveman` mode — respuestas tersas (~75% menos tokens)
