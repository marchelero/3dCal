---
description: "Analyze instincts acumulados y propone evolved structures (skill merges, agent splits, project-to-global promotions). Use when hay >20 instincts y queres detectar patterns que ya ameritan su propia skill/agent."
agent: build
---

# Evolve Command

Analyze and evolve instincts via opencode-native CLI: $ARGUMENTS

## Your Task

```bash
node .opencode/bin/instinct.js evolve $ARGUMENTS
```

## Supported Args

- no args: analysis only
- `--domain <name>`: filter by category
- `--generate`: also write candidates to `.opencode/instincts/evolved/candidates.json`

## Behavior Notes

- Uses project + global instincts for analysis.
- Shows skill/command/agent candidates from trigger and domain clustering.
- Shows project → global promotion candidates.
- Output path: `.opencode/instincts/evolved/candidates.json` (with `--generate`)
