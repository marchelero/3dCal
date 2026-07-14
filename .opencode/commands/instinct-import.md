---
description: "Import instincts from external JSON files (exports de otros proyectos o de team). Deduplica, ajusta confidence ×0.8, merge to target scope. Use when arrancas un proyecto nuevo y queres traer patterns ya aprendidos."
agent: build
---

# Instinct Import Command

Import instincts via opencode-native CLI: $ARGUMENTS

## Your Task

```bash
node .opencode/bin/instinct.js import $ARGUMENTS
```

## Usage

```bash
# File import
node .opencode/bin/instinct.js import path/to/instincts.json

# To project scope (default: global)
node .opencode/bin/instinct.js import ./instincts.json --scope project
```

## Import Format

Expected JSON structure:

```json
{
  "instincts": [
    {
      "trigger": "[situation description]",
      "action": "[recommended action]",
      "confidence": 0.7,
      "category": "coding",
      "source": "imported"
    }
  ],
  "metadata": {
    "version": "1.0",
    "exported": "2025-01-15T10:00:00Z",
    "author": "username"
  }
}
```

## Import Process

1. **Validate format** - Check JSON structure
2. **Deduplicate** - Skip existing instincts (by ID)
3. **Adjust confidence** - Reduce confidence for imports (×0.8)
4. **Merge** - Add to target scope
5. **Report** - Show import summary

---

**TIP**: Review imported instincts with `/instinct-status` after import.
