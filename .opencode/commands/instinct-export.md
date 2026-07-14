---
description: "Export instincts filtrados por confidence/category/scope a JSON para sharing. Use when quieres compartir learnings acumulados con team members o importar en otro proyecto."
agent: build
---

# Instinct Export Command

Export instincts via opencode-native CLI: $ARGUMENTS

## Your Task

```bash
node .opencode/bin/instinct.js export $ARGUMENTS
```

## Export Options

| Flag | Default | Description |
|------|---------|-------------|
| `--output FILE` | `./instincts-export.json` | Output file path |
| `--min-confidence N` | `0` | Filter by minimum confidence |
| `--category X` | (all) | Filter by category |
| `--scope X` | `all` | `project`, `global`, or `all` |

## Examples

```bash
# Export all
node .opencode/bin/instinct.js export

# High confidence only
node .opencode/bin/instinct.js export --min-confidence 0.8

# By category
node .opencode/bin/instinct.js export --category coding

# To specific path
node .opencode/bin/instinct.js export --output ./my-instincts.json
```

## Export Format

```json
{
  "instincts": [
    {
      "id": "instinct-123",
      "trigger": "[situation description]",
      "action": "[recommended action]",
      "confidence": 0.85,
      "category": "coding",
      "applications": 10,
      "successes": 9,
      "source": "session-observation"
    }
  ],
  "metadata": {
    "version": "1.0",
    "exported": "2025-01-15T10:00:00Z",
    "author": "username",
    "total": 25,
    "filter": { "min_confidence": 0.8, "category": null, "scope": "all" }
  }
}
```

---

**TIP**: Export high-confidence instincts (>0.8) for better quality shares.
