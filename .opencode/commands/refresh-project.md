---
description: "Refresh .agents/PROJECT.md from current project state. Scans package.json/pubspec/pyproject/etc to detect stack, conventions, and directory layout. Use when project grows, new module added, or context feels stale."
agent: build
---

# Refresh Project Command

Regenerate `.agents/PROJECT.md` from the current project state. The CLI scans the actual project files (package.json, pubspec.yaml, etc.) and updates the context doc that the prd-agent and other specialists read.

## Your Task

Run the opencode-native refresh CLI:

```bash
node .opencode/bin/refresh-project.js
```

### Optional flags

| Flag | What it does |
|------|--------------|
| (none) | Scan, write, show report |
| `--dry-run` | Scan, show diff, don't write |
| `--check` | Exit 0 if up to date, 1 if stale (no output) |

## When to use

- The project grew (new module, new dep, new folder)
- You added or removed tooling (prettier, eslint, new test framework)
- The stack changed (TypeScript → Dart, Express → Fastify)
- After a long refactor that restructured folders
- Before `/session-end` for a comprehensive save

## Behavior

- **Manual sections preserved** across refreshes: `Non-Negotiables`, `Architecture Notes`, `Open Questions`. The CLI only regenerates `Identity`, `Stack`, `Conventions`, `Directory Layout`, `License`.
- **Backup created automatically** before overwrite: `.agents/PROJECT.md.bak.{timestamp}`.
- **Idempotent**: if PROJECT.md is already up to date, the CLI reports "no changes" and exits.
- **Safe**: never deletes user content. Only updates detected fields (stack name, version, etc.).

## Detection sources

| Stack | File scanned |
|-------|--------------|
| Node/JS/TS | `package.json` |
| Flutter/Dart | `pubspec.yaml` |
| Python | `pyproject.toml` / `requirements.txt` |
| Rust | `Cargo.toml` |
| Go | `go.mod` |
| Java/Kotlin | `pom.xml` / `build.gradle*` |
| Web | `index.html` |
| Description | `README.md` (first paragraph after title) |
| License | `LICENSE` / `LICENSE.md` |
| Conventions | `.eslintrc` / `prettier.config.js` / `tsconfig.json` / `vitest.config.*` / `jest.config.*` / `pytest.ini` / `.github/workflows/` |
| Directory layout | `src/`, `lib/`, `app/`, `pkg/`, `cmd/`, `internal/`, `modules/`, `components/`, `pages/`, `test/`, `tests/` |

## Report format

After running, the CLI outputs:

```
Backup: .agents/PROJECT.md.bak.1719087600000
Updated: .agents/PROJECT.md

--- REPORT ---
Lines added: 12
Lines removed: 8

Sections regenerated: Identity, Stack, Conventions, Directory Layout, License
Sections preserved: Non-Negotiables, Architecture Notes, Open Questions (manual edits kept)
```

If `--dry-run`:
```
--- DRY RUN: would write to .agents/PROJECT.md ---

--- DIFF ---
- L8: - **Name**: (your project name)
+ L8: - **Name**: my-app
- L9: - **Type**: (web app | ...)
+ L9: - **Type**: web-app
...
```

## Integration

- `/session-end` — invokes this automatically (Step 6) and shows the result
- `prd-agent` — reads `.agents/PROJECT.md` for project context (refreshed version gets fresh stack info)
- `/session-start` — loads `.agents/PROJECT.md` (Capa 1 of the 4-layer hierarchy)

## Behavior Notes

- Run is cheap (~100ms).
- Pure local operation. No network.
- Does not touch git (user can decide to commit or not).
- Idempotent — safe to run multiple times in a row.
