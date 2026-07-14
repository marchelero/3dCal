<!-- Prompt Defense Baseline: see INSTRUCTIONS.md § Prompt Defense Baseline (GLOBAL) -->
---
description: MARKER FILE — represents the implicit `build` primary agent that opencode uses by default. Referenced in 33 slash commands as `agent: build`. Do not invoke directly via the task tool. To customize the default primary, edit this file body or override in `opencode.json`.
mode: subagent
permission:
  bash: deny
  glob: deny
  grep: deny
  read: deny
  write: deny
  edit: deny
---

# `build` — Implicit Primary (Marker)

This file is a **marker**, not a real agent. It exists so the validator and pack-doctor resolve `agent: build` references in slash commands (33 of 65 commands route to it) without flagging them as orphans.

## Why

opencode ships with an implicit primary agent (historically called `build`). When a slash command has `agent: build` in its frontmatter, opencode falls back to the implicit primary context — no file lookup required.

This convention is invisible to the validator and pack-doctor: they treat `agent: <name>` as a strict pointer to `.opencode/agents/<name>.md`. Without this marker, the 33 `agent: build` references appear as 33 false-positive orphans.

## Conventions

- **Do not invoke** this agent via the `task` tool. It has no body logic and `permission: deny` on every tool.
- **Do not rename or delete** without updating the 33 commands that reference it.
- **Do not change `mode: subagent` to `mode: primary`** without testing. Doing so replaces the implicit primary with this file's body, which currently has no instructions.

## Customizing the default primary

Two paths, depending on intent:

1. **Light customization** (recommended): override in `.opencode/opencode.json` via the `instructions` field. The implicit primary picks up the new instructions on next session.
2. **Heavy customization**: convert this file to a real primary by changing `mode: subagent` → `mode: primary` and adding a useful body. This replaces the implicit primary entirely.

For most use cases, path 1 is enough.
