---
description: "Analyze git merge conflicts and propose a resolution based on the codebase context (tests, types, recent changes)"
agent: build
---

# Merge Conflict Command

Analyze merge conflicts in the current working tree, understand both sides from the codebase context (tests, types, recent commits), and propose concrete resolutions. `$ARGUMENTS` may specify a file path, or be omitted (analyze all conflicted files).

## Prerequisites

- A merge or rebase is in progress (`git status` shows `unmerged paths`).
- The repo has tests that can be run to validate the resolution.

## Your Task

### Step 1 — Identify the Conflicts

```bash
git status --porcelain | grep -E '^(UU|AA|DD|UU|AU|UA|DU|UD)$'
git diff --name-only --diff-filter=U
```

If no conflicts, report "no merge conflicts detected" and exit.

Display a 1-line header:
```
[merge-conflict] <N> conflicted file(s): <comma-separated list>
```

### Step 2 — For Each Conflicted File

For each file, gather context:

```bash
# The conflict markers and both sides
git show :1:<file>   # common ancestor (base)
git show :2:<file>   # ours (current branch / target of rebase --merge)
git show :3:<file>   # theirs (incoming branch)

# Recent commits touching this file
git log --oneline -10 -- <file>

# The actual conflicted section (between <<<<<<< and >>>>>>>)
```

Then read the file in place to see the conflict markers.

### Step 3 — Classify Each Conflict

Each conflict falls into one of these buckets:

| Bucket | Signal | Resolution |
|--------|--------|------------|
| **Both added same code** | Identical or near-identical on both sides | Keep one copy |
| **Both modified same region** | Both sides have compatible edits | Combine them (interleave lines, preserve both changes) |
| **One side deleted, other modified** | `git show :1:` exists, only one of :2: / :3: has the content | Adopt the modification; if the deletion is intentional, drop the content |
| **Import / format change only** | One side added imports, other reformatted | Keep both intents: imports + reformatted block |
| **Logic divergence** | Both sides changed the function body with different intent | STOP. Read both sides' recent commits (`git log -p <file>`). Ask the user which intent wins. |
| **Generated file** | Path matches `*.lock`, `package-lock.json`, `yarn.lock`, `dist/*`, `build/*` | Delete ours + theirs, regenerate with the package manager |

### Step 4 — Propose Resolution

For each conflicted file, emit a plan:

```text
## <file>

Conflict regions: <N>
Bucket: <classification>
Plan:
  - <line range>: <what to keep / combine>
  - <line range>: <what to drop>

Confidence: HIGH | MEDIUM | LOW
Reasoning: <1-2 lines citing recent commits, tests, or type signatures>

If LOW: ask the user before applying.
```

For HIGH/MEDIUM confidence, you MAY apply the resolution by editing the file in place, then running:

```bash
git add <file>
```

Show the diff of the resolution to the user before staging if confidence is MEDIUM.

For LOW confidence or "Logic divergence" bucket: **STOP and ask the user.** Do not guess.

### Step 5 — Validate

After resolving all conflicts:

```bash
# Type check (if TS/JS)
npx tsc --noEmit

# Run tests
<detected test command: npm test / pytest / go test / cargo test / etc.>

# Lint
<detected linter: eslint / ruff / golangci-lint / etc.>
```

If any check fails, treat the resolution as suspect: report the failure, show the file, and ask the user how to proceed. Do NOT mark conflicts as resolved and continue silently.

### Step 6 — Final Report

```text
[merge-conflict] Resolved <N>/<total> files. <M> require user input.

Applied resolutions:
- <file> — <1-line summary>
- ...

Need user decision:
- <file> — <why>

Validation:
- typecheck: PASS | FAIL
- tests:     PASS | FAIL | N/A
- lint:      PASS | FAIL | N/A
```

## Anti-Patterns

- Do NOT auto-resolve by always taking "ours" or always taking "theirs". This breaks half the time.
- Do NOT resolve "Logic divergence" conflicts without asking. Both branches have intent; the user decides.
- Do NOT stage resolved files before validation runs.
- Do NOT remove conflict markers with `git checkout --ours` / `--theirs` globally. Use them surgically, per conflict, when you know the intent.
- Do NOT run `git commit` after resolving. The user decides when to finalize the merge/rebase.

## When to Use

- After `git merge` produces conflicts.
- During an interactive rebase that requires conflict resolution.
- After a `git pull` that failed with conflicts.

## When NOT to Use

- For non-merge conflicts (e.g. file already modified, can't pull). Use `git stash` first.
- For complex 3-way merges involving renames. Defer to the user.
