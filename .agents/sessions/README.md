# Sessions

One file per work session. Used by `/session-start` (read) and `/session-end` (write).

## Convention

- **One file per session** — never overwrite an existing snapshot
- **Filename**: `YYYY-MM-DD-{slug}.md` where slug is a kebab-case summary (max 50 chars)
- **LATEST.md** — copy of the most recent snapshot, always overwritten by `/session-end`. Used by `/session-start` to find the latest without scanning.

## Lifecycle

```
/session-start (or auto on first action)
  ↓ reads PROJECT.md + LATEST.md
  ↓ reports compact summary
  ↓ waits for user direction
  ↓ [user works in this session]
/session-end
  ↓ reviews session
  ↓ writes YYYY-MM-DD-{slug}.md
  ↓ overwrites LATEST.md
  ↓ [next session reads from LATEST.md]
```

## When to skip

- Trivial one-message sessions (Q&A, no code changes)
- User says "skip snapshot"
- Inside a `/verify` or `/checkpoint` flow (those save their own state)

## Cleanup

Old snapshots are kept for archaeology. Optional: archive snapshots older than 90 days to `.agents/sessions/archive/`.
