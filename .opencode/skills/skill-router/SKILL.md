---
name: skill-router
description: Use this skill when the primary agent needs to decide which skill to load for a user request, or when the user asks "what skill should I use for X". Maps request keywords and intent to the right skill from the catalog. Load this BEFORE guessing or asking the user to clarify.
triggers: [skill, skills, route, routing, trigger, catalog, which skill, what skill, load, knowledge]
---

# Skill Router

Decide which skill to load for a user request. This is the routing layer between "user said something" and "agent knows the right patterns".

## When to Activate

- The primary agent is unsure which skill applies to the current request
- The user explicitly asks "what skill should I use for X"
- The request spans multiple domains and could match several skills
- A new skill has been added and the agent needs to know when to use it

## Routing Process

### Step 1 — Extract the Intent

From the user's request, identify:
- The **action verb** (build, review, fix, document, deploy, test, refactor)
- The **domain noun** (UI, API, database, security, config, CI, test, deployment)
- Any **explicit technology** mentioned (React, Express, Postgres, Kubernetes, etc.)

### Step 2 — Match Against Triggers

Use the table below. Multiple matches are fine — load up to 3 relevant skills.

### Step 3 — Load the Top Match

If only one skill matches, load it.
If multiple match, load the most specific (framework-specific beats language-specific beats general).

## Trigger Map

| If the request mentions... | Load |
|---------------------------|------|
| React, JSX, TSX, hooks, useState, useEffect, useMemo, useCallback, form, prop drilling, render, component, Suspense, Context | `frontend-patterns` |
| Express, FastAPI, NestJS, Spring, repository pattern, service layer, DI, dependency injection, transaction, controller, middleware, auth, validation | `backend-patterns` |
| REST, GraphQL, endpoint, route URL, status code, pagination, API contract, version, rate limit, API design | `api-design` |
| auth, password, JWT, session, CSRF, XSS, SQL injection, secret, OWASP, vulnerability, sanitize, CORS, encryption | `security-review` |
| test, TDD, RED, GREEN, REFACTOR, coverage, jest, pytest, vitest, mock, unit test, integration test | `tdd-workflow` |
| error, exception, try/catch, retry, circuit breaker, error message, log error, throw, error boundary | `error-handling` |
| library, framework, API docs, version, example code, latest, deprecated, alternatives | `documentation-lookup` |
| MCP, model-context-protocol, server, tool definition, resource, prompt, stdio | `mcp-server-patterns` |
| commit, branch, PR, merge, rebase, conflict, git workflow, cherry-pick, bisect, stash | `git-workflow` |
| verify, check, audit, validate, regression, post-change, after implementing | `verification-loop` |
| PRD, requirement, acceptance criteria, scope, objective, success criteria, intention map | `intent-driven-development` |
| task graph, dependency, DAG, parallel work, work breakdown, sprint, estimate | `task-decomposition` |
| naming, immutability, code quality, lint, formatting, KISS, DRY, YAGNI, complexity | `coding-standards` |

## Decision Examples

| User says | Load |
|-----------|------|
| "build a React form with validation" | `frontend-patterns` (React) + `backend-patterns` (validation flow) |
| "add JWT auth to my Express API" | `backend-patterns` + `security-review` |
| "review this code" | `code-reviewer` agent (NOT a skill — different surface) |
| "how do I use Prisma" | `documentation-lookup` (Prisma → Context7) |
| "write tests for this function" | `tdd-workflow` |
| "plan a DB migration" | `task-decomposition` + (delegate to `migration-planner` agent) |
| "fix this git conflict" | `git-workflow` + (delegate to `merge-conflict` command) |
| "is this endpoint secure" | `security-review` + `api-design` (status codes / contract) |

## Anti-Patterns

- **Loading all skills** — never load all 13. Pick the top 1-3 by trigger match.
- **Loading a skill that doesn't match** — if a request is about deployment, don't load `frontend-patterns` because there's a "config" trigger.
- **Skipping the router when uncertain** — if 0 skills match, ask the user or load `intent-driven-development` to clarify.
- **Treating the router as optional** — for ambiguous requests, this skill prevents the primary agent from guessing and producing wrong-context output.

## Integration

- This skill is loaded on-demand. It does NOT auto-load on every request.
- The primary agent loads it when it sees trigger words or when the request is ambiguous.
- For tool-based discovery, see `.opencode/skills/INDEX.md` (auto-generated).

## When NOT to Activate

- The user has already named the skill: "load `api-design`" → no router needed.
- The request is a single specific tool invocation: "run `npm test`" → no skill needed.
- Pure Q&A about the pack itself ("how many skills are there") → use `bin/build-skills-index.js` directly.
