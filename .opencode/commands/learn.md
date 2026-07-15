---
description: "Extract patterns, learnings, y reusable insights de la sesion actual. Use at end of long sessions o cuando notaste un patron repetido 3+ veces que vale la pena guardar como instinct."
agent: build
---

# Learn Command

Extract patterns, learnings, and reusable insights from the current session: $ARGUMENTS

## Your Task

Analyze the conversation and code changes to extract:

1. **Patterns discovered** - Recurring solutions or approaches
2. **Best practices applied** - Techniques that worked well
3. **Mistakes to avoid** - Issues encountered and solutions
4. **Reusable snippets** - Code patterns worth saving

## Output Format

### Patterns Discovered

**Pattern: [Name]**
- Context: When to use this pattern
- Implementation: How to apply it
- Example: Code snippet

### Best Practices Applied

1. [Practice name]
   - Why it works
   - When to apply

### Mistakes to Avoid

1. [Mistake description]
   - What went wrong
   - How to prevent it

### Suggested Skill Updates

If patterns are significant, suggest updates to:
- `.opencode/AGENTS.md` (global rules — now consolidated, no separate INSTRUCTIONS.md)
- `.agents/skills/coding-standards/SKILL.md`
- `.agents/skills/[domain]/SKILL.md`

## Instinct Format (for continuous-learning-v2)

```json
{
  "trigger": "[situation that triggers this learning]",
  "action": "[what to do]",
  "confidence": 0.7,
  "source": "session-extraction",
  "timestamp": "[ISO timestamp]"
}
```

---

**TIP**: Run `/learn` periodically during long sessions to capture insights before context compaction.
