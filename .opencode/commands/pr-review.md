---
description: "Review a GitHub pull request with parallel specialist agents (code, security, types, tests) and emit a unified verdict"
agent: build
---

# PR Review Command

Review a GitHub pull request end-to-end: fetch the diff, dispatch specialist reviewers in parallel, then synthesize one actionable verdict. `$ARGUMENTS` may be a PR number, PR URL, or omitted (review the current branch's open PR).

## Prerequisites

- `gh` CLI authenticated and on PATH.
- The PR is open in the current repo.
- The diff is fetchable (no uncommitted secrets, no huge binary blobs).

## Your Task

### Step 1 — Resolve the PR

If `$ARGUMENTS` is empty:
```bash
gh pr view --json number,title,baseRefName,headRefName,additions,deletions,changedFiles,author
```

Otherwise parse the number/URL and run the same with the explicit argument.

Display a 1-line header:
```
[pr-review] PR #<num> "<title>" by <author> — +<a> -<d> across <n> files
```

### Step 2 — Gather Diff and Context

```bash
gh pr diff <num> > /tmp/pr-<num>.diff
gh pr view <num> --json files --jq '.files[].path' > /tmp/pr-<num>.files
```

Also fetch the list of changed files for routing. Detect language and stack from file extensions:

| Extension | Stack |
|-----------|-------|
| `.ts`, `.tsx`, `.js`, `.jsx` | TypeScript / JavaScript |
| `.py` | Python |
| `.go` | Go |
| `.rs` | Rust |
| `.java`, `.kt` | Java / Kotlin |
| `.cs` | C# |
| `.swift` | Swift |
| `.cpp`, `.cc`, `.h` | C++ |
| `.dart` | Dart / Flutter |
| `.rb` | Ruby |
| `.php` | PHP |
| `.sql` | SQL (DB) |
| `.tf` | Terraform (Infra) |

### Step 3 — Dispatch Reviewers in Parallel

Run these agents **in the same message** (one tool call block) so they execute concurrently:

1. **`code-reviewer`** — general quality, readability, naming, error handling, immutability, complexity. ALWAYS.
2. **`security-reviewer`** — secrets, injection, auth, validation, OWASP Top 10. ALWAYS.
3. **Stack-specific reviewer** — pick from the table above:
   - TS/JS → `typescript-reviewer`
   - Python → `python-reviewer`
   - Go → `go-reviewer`
   - Rust → `rust-reviewer`
   - Java/Kotlin → `java-reviewer` or `kotlin-reviewer`
   - C# → `csharp-reviewer`
   - Swift → `swift-reviewer`
   - C++ → `cpp-reviewer`
   - Dart/Flutter → `flutter-reviewer`
   - Ruby → (no dedicated reviewer; route to `code-reviewer` with Ruby awareness)
   - PHP → `php-reviewer`
4. **`pr-test-analyzer`** — verifies test coverage, behavioral coverage, and that new logic has tests.
5. **`silent-failure-hunter`** — catches swallowed errors, bad fallbacks, missing error propagation. ALWAYS.

Skip a reviewer if its domain is clearly not present (e.g. no security-sensitive code → still run `security-reviewer`, never skip it).

Each reviewer reads `/tmp/pr-<num>.diff` and the relevant files in place. They emit findings in the standard format (see their agent descriptions).

### Step 4 — Synthesize

After all reviewers return, dedupe findings (same issue found by 2+ reviewers → mention both, keep one canonical entry). Group by severity:

```text
[pr-review] PR #<num> — VERDICT: <APPROVE | WARN | BLOCK>

CRITICAL (must fix before merge):
1. [security-reviewer + code-reviewer] <file>:<line> — <issue>
2. ...

HIGH (should fix before merge):
1. ...

MEDIUM (consider fixing):
1. ...

LOW (optional polish):
1. ...

Top 3 actions:
1. <most impactful fix>
2. <second>
3. <third>

Reviewers consulted: code, security, typescript, pr-test, silent-failure
```

### Verdict Rules

- **BLOCK** if any CRITICAL finding.
- **WARN** if any HIGH but no CRITICAL.
- **APPROVE** if no CRITICAL or HIGH.

## Behavior Notes

- This command is read-only. Never modify files. Never push. Never merge.
- Do not rebase or run `git` mutating commands.
- If a reviewer is unavailable, note it and continue — do not block the verdict.
- Truncate individual reviewer outputs to 200 lines max. The synthesizer should never see a 5K-line raw dump.
- If the diff is > 3000 lines, warn the user and offer to review file-by-file instead.

## When to Use

- After opening a PR and before requesting human review.
- As a pre-merge gate in a team workflow.
- After a large feature is ready and you want a second opinion before notifying the team.

## When NOT to Use

- For typo fixes or 1-line docs changes.
- For PRs that are still draft and not yet ready for feedback (the reviewers will be noisy).
- For PRs that are pure refactors with no logic change (use `refactor-cleaner` directly).
