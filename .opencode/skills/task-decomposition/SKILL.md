---
name: task-decomposition
description: Use this skill when a PRD, plan, or high-level goal needs to be broken down into a directed acyclic graph (DAG) of executable tasks. Covers work breakdown structure, dependency analysis, parallelization opportunities, and effort estimation. Use intent-driven-development to define the criteria first, then this skill to structure the work.
triggers: [task graph, dependency, DAG, parallel, work breakdown, sprint, estimate]
origin: starter-pack
---

# Task Decomposition

Convert a goal, PRD, or plan into a graph of tasks with explicit dependencies. The output is a DAG that a planner, agent, or human can execute in the right order with maximum parallelism.

## When to Activate

- A PRD is approved and the work needs to be split into tasks
- A user request is large enough that the order of operations matters
- You need to identify which tasks can run in parallel and which block each other
- Effort estimation is needed before committing to a sprint
- A `planner` or `code-architect` agent needs a structured input to consume

## Core Principle

**Tasks are nodes, dependencies are edges.** If B depends on A, B cannot start until A is done. Parallel tasks share no dependency edge.

## Decomposition Process

### Step 1 — Identify the Leaves

List the smallest observable outcomes. Ask: "If I had to demo progress tomorrow, what could I show?" Each leaf is a candidate task.

Bad: "build the auth system" (too coarse)
Good: "create users table", "add password hashing", "implement login endpoint", "add session middleware", "write login tests"

### Step 2 — Find the Critical Path

For each task, identify what MUST exist before it can start. The longest chain of dependencies is the critical path — that chain determines the minimum time to ship.

### Step 3 — Mark Parallelization

Tasks that do not depend on each other can run in parallel. Group them into "swim lanes" by what they share (e.g. "DB work", "API work", "UI work", "test infra").

### Step 4 — Estimate Effort

Use T-shirt sizes, not hours:

| Size | Meaning | Typical Duration |
|------|---------|------------------|
| XS | < 30 min, trivial | typo, config tweak |
| S | 30 min – 2 hours | add a field, write a single test |
| M | 2 – 6 hours | new endpoint, new component |
| L | 0.5 – 2 days | new service, new feature with tests |
| XL | 3+ days | split into smaller tasks |

If a task is XL, decompose it further. No task should be XL in a final plan.

### Step 5 — Assign Owners and Verify

Each task gets:
- **Owner** — agent or human role
- **Verification** — how we know it's done (test, typecheck, manual check, observable behavior)

## Output Format

Produce the DAG as YAML so it can be parsed by `planner` or stored in a plan file:

```yaml
goal: <one-line description of the overall objective>
critical_path: [T1, T3, T7]   # the longest dependency chain
total_effort: M                # sum of task sizes (rough)
parallel_groups:
  - [T1, T2]                   # can run simultaneously
  - [T4, T5, T6]               # can run simultaneously
  - [T3]                       # blocked by T1+T2
  - [T7]                       # blocked by T3, T4, T5, T6

tasks:
  - id: T1
    title: <verb-noun, observable>
    size: S
    depends_on: []
    owner: database-reviewer
    verify: <observable success criterion>
    files_hint: [<paths likely to be touched>]

  - id: T2
    title: ...
    size: M
    depends_on: []
    owner: backend-patterns skill + planner
    verify: ...
    files_hint: [...]

  - id: T3
    title: ...
    size: M
    depends_on: [T1, T2]
    ...
```

## Rules

### Task Granularity

- One task = one PR or one commit. If it cannot be reviewed as a unit, it is too big.
- Each task has observable verification. "Refactor X" is not a task unless the refactor's outcome is testable.
- No task should touch > 10 files. If it does, split it.

### Dependency Hygiene

- If A and B are independent, do not artificially order them. Artificial ordering wastes time.
- If A "logically" comes before B but B does not actually need A, drop the edge.
- A task can depend on a "group" only if it actually needs all of them. Be specific.

### Parallelization

- Two tasks can run in parallel ONLY if they do not share files OR shared files are not modified by both.
- If two tasks both write to the same file, they are sequential. Pick one to do the file changes, or refactor so they touch different files.
- Tests are usually parallel-safe (each test file is independent).

### Estimation Honesty

- Use the largest of the three: thinking time, coding time, review/fix time.
- If a task is "easy to code but hard to verify", size it by the verification cost.
- Discount estimation: when you estimate 2 days, the task takes 3. Plan for the discount.

## Anti-Patterns

- **Tasks that span "design + impl + test"** — split into 3 tasks. They have different owners and different risks.
- **"Integrate everything"** tasks at the end — they always blow up. Integrate continuously, not at the end.
- **Vague tasks** like "polish the UI" or "clean up" — make them specific or drop them.
- **Dependencies on "after the meeting"** — meetings are not tasks. The decision is the task.
- **Huge critical paths** — if the critical path is 8 tasks, the project will take 8 task-durations minimum. Parallelize harder.

## Integration With Other Skills/Agents

- **`intent-driven-development`** — produces the acceptance criteria. Use those criteria to define task verification.
- **`planner`** agent — consumes the DAG and turns it into an executable plan with risks.
- **`code-architect`** — produces the architecture; the DAG follows from that architecture.
- **`prd-agent`** — the PRD's "fuera de alcance" section maps directly to "do NOT include these as tasks".

## Quick Example

PRD: "Add user profile editing with avatar upload"

```yaml
goal: User can edit their profile (name, bio, avatar) and see the change reflected.
critical_path: [T1, T3, T5]
total_effort: M

parallel_groups:
  - [T1, T2]                       # schema + storage setup
  - [T3, T4]                       # API + UI form
  - [T5]                           # integration test

tasks:
  - id: T1
    title: Add profile fields to users table
    size: S
    depends_on: []
    owner: database-reviewer
    verify: migration applies, columns exist, typecheck passes
    files_hint: [migrations/, src/db/schema.ts]

  - id: T2
    title: Configure S3 (or equivalent) for avatar uploads
    size: S
    depends_on: []
    owner: backend-patterns skill
    verify: upload a test file, retrieve its URL
    files_hint: [src/services/storage.ts, .env.example]

  - id: T3
    title: Implement PATCH /users/:id profile endpoint
    size: M
    depends_on: [T1]
    owner: backend-patterns skill
    verify: curl test updates fields, validation errors return 400
    files_hint: [src/routes/users.ts, src/services/user.ts]

  - id: T4
    title: Build profile edit form component
    size: M
    depends_on: [T1]
    owner: frontend-patterns skill
    verify: form renders, submits, shows error states
    files_hint: [src/components/ProfileForm.tsx]

  - id: T5
    title: E2E test: edit profile, see updated value
    size: S
    depends_on: [T2, T3, T4]
    owner: e2e-runner
    verify: e2e test passes in headless browser
    files_hint: [e2e/profile.spec.ts]
```
