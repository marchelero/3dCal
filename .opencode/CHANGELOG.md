# Changelog

All notable changes to this starter pack are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- **Docs sync (Tiers A-D)**: 14 archivos actualizados para reflejar el estado real del pack. Números canónicos fijados (69 agents, 14 skills, 65 commands, 5 plugins, 9 CLIs, 0 MCPs). Paths corregidos (`agentes/`→`agents/`, `comandos/`→`commands/`, `instincts/` ahora existe con `.gitkeep`). 13 commands faltantes agregados a `COMMANDS.md` en 4 secciones nuevas. `@intent-driven-development` corregido en EXAMPLES.md (es skill, no agent).
- **EXAMPLES.md**: nuevo "Ejemplo 6" mostrando `/quick-prd` + `/flow-bugfix` workflow. Tabla "Patrones comunes" extendida con 4 patrones nuevos (`/quick-prd`, `/flow-*`, `/audit-report`, `/pack-doctor`). Header actualizado a "6 ejemplos".

## [1.0.0] — 2026-06-29

**MILESTONE**: El pack deja de ser "starter" y se considera completo. Incluye todos los flujos de trabajo, auditoría post-ejecución, archivado automático, validación de salud y convenciones de naming estandarizadas.

### Changed (breaking)
- **Estructura del pack consolidada en `.opencode/`**: todos los archivos del pack viven en `.opencode/`. Cero conflicto con archivos del proyecto del user (su `README.md`, `CHANGELOG.md`, `AGENTS.md` ya no chocan con los del pack). Cambio de paths en `opencode.json > instructions`:
  - Antes: `["AGENTS.md", ".opencode/instructions/INSTRUCTIONS.md"]`
  - Ahora: `[".opencode/AGENTS.md", ".opencode/instructions/INSTRUCTIONS.md"]`
- **Naming convention formalizada**: `YYYY-MM-DD_HHMM-{slug}.{ext}` con guion bajo entre fecha y hora. Documentado en `.opencode/CONVENTIONS.md`. Anteriormente el patron era `YYYY-MM-DD-HHMM-` con guion (mas dificil de tipear y parsear).

### Added
- **Reportes y auditoria post-ejecucion (paquete completo)**:
  - `report-auditor` agent: auditor lightweight (no exhaustivo). Cruza report contra PRD origen y skills cargadas, emite veredicto PASS / PASS-WITH-NITS / FAIL. ~30-60 lineas de output, sin tablas decorativas.
  - `/audit-report` command: invoca el auditor. Soporta `--separate` (auditoria en archivo aparte), `index` / `--index` (regenera INDEX global), `quick {name}` (solo veredicto), `compare {a} {b}` (diff de veredictos).
  - `/archive-reports` command: mueve reports viejos a `.opencode/reports/_archive/{YYYY}/`. NUNCA borra. Default: COMPLETADO >30d. Flags: `--older-than Nd`, `--all-completed`, `--dry-run`.
  - `/quick-prd` command: mini-PRD de 10 lineas para bugs/fixes/one-liners. Auto-regenera a PRD completo si crece en scope.
- **Auto-report al cerrar flujos**:
  - `/orchestrate` ahora tiene Phase 4 OBLIGATORIA: genera `.opencode/reports/{YYYY-MM-DD-HHMM}-{name}.report.md` con agentes usados, decisiones, criterios PRD, desvios, skills, archivos.
  - `/verify` exitoso auto-genera report (cuando hay cambios + PRD activo). Ofrece auditar al final.
  - `/code-review`, `/security`, `/plan`, `/tdd` ofrecen guardar el output como report y auditar contra el PRD origen.
- **Cross-link plans↔PRDs**: frontmatter obligatorio al inicio de cada plan con `prd:`, `status:`, `created:`. El auditor usa este link cuando el report no nombra el PRD directamente.
- **INDEX global** (`.opencode/reports/INDEX.md`): tabla de todos los reports con status, criterios, veredicto, skill gaps. Se regenera en cada `/audit-report` (silent). Seccion "Skill gaps recurrentes" con flag para refactor si >3 ocurrencias.
- **Skills feedback loop**: el auditor emite NIT "skill gap" cuando una skill se cargo pero se ignoro, o cuando deberia haberse cargado y no se cargo. Esto mantiene las skills vivas.
- **Regla de idioma en PRDs**: espanol por default. Ingles solo para identificadores de codigo, terminos tecnicos sin traduccion natural, siglas. Sin espanglish tipo "el button de push". Documentado en `prd-agent.md` con ejemplos good A/B.
- **`/pack-doctor` command**: valida la salud del pack completo. Detecta frontmatter invalido, agents duplicados, commands huerfanos (que apuntan a agents inexistentes), skills sin descripcion, permalinks rotos, archivos >800 lineas.
- **4 workflows pre-hechos** (`/flow-*`): bajan el costo cognitivo. Cada workflow es un slash command que encadena los commands existentes.
  - `/flow-bugfix`: `/quick-prd` → fix → `/verify` → report → audit
  - `/flow-feature`: `/orchestrate` → implement → `/verify` → report → audit
  - `/flow-refactor`: `/plan` → refactor → `/verify` → report → audit
  - `/flow-security`: `/security` → fix → `/verify` → report → audit
- **Plantillas de report por stack** en `.opencode/reports/templates/`: `default.md`, `angular.md`, `python.md`, `rust.md`. El orquestador auto-elige segun `.agents/PROJECT.md`.
- **Recovery state**: cada command escribe `.opencode/state/{command}.state.json` con el progreso. Al reabrir, `/session-start` detecta estados interrumpidos y ofrece resumir.
- **Stats del pack** en `/pack-doctor`: cuenta agents/skills/commands/PRDs/reports/audits. Utilidad baja en tokens, valor alto de orientacion.

### Changed
- **`prd-agent.md`**: seccion "Idioma del PRD" agregada. Default espanol, ingles solo para terminos tecnicos. Reglas explicitas con ejemplos bad/good.
- **`orchestrate.md`**: Phase 4 obligatoria con template completo de report. Coordinacion rule #7 ("Report always") agregada.
- **5 commands existentes** (`/code-review`, `/security`, `/verify`, `/plan`, `/tdd`): bloque "Post-X: Audit" agregado al final. Indica cuando aplica y cuando no. `/verify` es el unico con auto-snapshot, el resto solo ofrece.
- **`audit-report.md`**: INDEX con columna "Skill gaps" + seccion recurrente.
- **AGENTS.md**: pendiente actualizar con la nueva seccion "Comportamientos obligatorios" que cubra auto-report y audit.

### Removed
- Nada. Todo es aditivo.

---

## [0.8.0] — 2026-06-29

### Added
- **`validate-frontmatter.js`**: nuevo CLI cero-deps que valida el frontmatter de los 65 agentes, 10 skills y 52 comandos (descripción requerida, modo `subagent`, `name` igual al directorio, descripción de skill entre 1-1024 caracteres, descripción con prefijo "Use when..."). Reporta PASS/WARN/FAIL con códigos de salida. Integrado en `smoke-test.js` y en CI.

### Changed
- **`opencode.json > instructions`**: se eliminaron las 10 skills de la lista de instrucciones siempre cargadas. El catálogo `<available_skills>` ya las expone, así que cargarlas duplicaba contenido y desperdiciaba ~30K tokens por turno. Solo quedan `INSTRUCTIONS.md` y `AGENTS.md` como capa 1.
- **`autoupdate`**: cambiado de `"notify"` a `false` para skippear el HTTP check al startup de opencode. La verificación de updates online estaba causando lentitud al abrir el TUI.
- **PRD filename format**: la convención de nombres pasó de `{YYYY-MM-DD}-{name}.prd.md` a `{YYYY-MM-DD-HHMM}-{name}.prd.md` (incluye hora en formato 24h). Evita colisiones cuando se crean varios PRDs el mismo día. Actualizado en `prd-agent.md`, `commands/prd.md`, `commands/orchestrate.md`, `AGENTS.md`, `docs/ARCH.md`, `docs/EXAMPLES.md`.
- **PRD confirmation vocabulary**: el `prd-agent` ahora acepta un set más amplio de confirmaciones, no solo "confirmo" u "OK" mayúscula. Acepta también `dale`, `ok`, `sí`, `aprobado`, `hazlo`, `perfecto`, `procede`, `va`, `adelante` (y equivalentes en inglés). Esto resuelve el caso donde el prd-agent generaba el Intention Map pero no escribía el archivo porque la confirmación no era reconocida.
- **`.agents/PROJECT.md`**: se rellenó con el contenido real del pack (stack, convenciones, no negociables, arquitectura de 4 capas). Antes era un template con placeholders, lo que dejaba al prd-agent sin contexto en Fase 0.
- **`STARTER.md` movido a `.opencode/docs/README.md`**: el archivo se renombró y se movió dentro de `.opencode/` para que viaje con el pack al copiarlo a otros proyectos. Toda la documentación del pack ahora vive en `.opencode/docs/` (en español neutro, sin voseo). El `README.md` raíz queda solo como landing de GitHub.
- **`smoke-test.js`**: 24 comprobaciones (antes 23). Añadido check `validate-frontmatter.js runs`. Actualizado para apuntar a `.opencode/docs/README.md` en vez del antiguo `STARTER.md`.
- **README.md**: updated to use `cp` instead of setup scripts. Quick start is now a single copy command.
- **smoke-test.js**: removed `setup.ps1`/`setup.sh` checks; added `CHANGELOG.md` check.
- **STARTER.md**: updated stats (65 agents, 10 skills, 52 commands, 4 CLIs).

### Removed
- **`setup.sh`** and **`setup.ps1`**: deleted. Install is now manual via `cp`. Reason: scripts duplicated logic, added complexity, and required maintenance. `cp -r` of the portable files is atomic and works on all platforms.

## [0.7.0] — 2026-06-23

### Added
- **`/refresh-project` slash command** + `refresh-project.js` CLI: regenerate `.agents/PROJECT.md` from current project state. Detects stack from `package.json` / `pubspec.yaml` / `pyproject.toml` / `Cargo.toml` / `go.mod` / etc. Preserves manual sections (Non-Negotiables, Architecture Notes, Open Questions). Backups to `.bak.{timestamp}` before overwrite. Auto-runs in `/session-end` Step 6.
- **`/prd` slash command**: explicit invocation of prd-agent. Same as `@prd-agent` but discoverable via slash menu.
- **Step 6 in `/session-end`**: refresh `.agents/PROJECT.md` if stale. Reports lines added/removed.
- **PRD timestamp convention**: filenames now use `{YYYY-MM-DD}-{name}.prd.md` for chronological sorting and disambiguation. Conflicts auto-suffix with `-2`, `-3`, etc.
- **Per-turn consent rule** documented in INSTRUCTIONS.md: permission to commit/push from a previous turn does NOT carry over.

### Changed
- **PRD agent description** rewritten as "MANDATORY FIRST STEP for any non-trivial task" to enforce auto-trigger.
- **AGENTS.md** restructured around 4 mandatory behaviors (caveman, PRD-first, session memory, no-destructive) plus the no-git-push rule.
- **prd-agent** filename convention updated: `.opencode/prds/{kebab-case-name}.prd.md` → `.opencode/prds/{YYYY-MM-DD}-{kebab-case-name}.prd.md`.

## [0.6.0] — 2026-06-23

### Added
- **`/context` slash command** + `context.js` CLI: shows context budget report (skills inventory, agents count, commands count, sessions, project size, recommendations). Supports `--skills`, `--recommend`, and full report.
- **Tool result truncation rules** in INSTRUCTIONS.md: cap `grep -m 50`, `head -n 100`, prefer Read tool over `cat`, sub-agent discipline (pass paths not contents).
- **Smoke test** (`smoke-test.js`): self-verifies the starter pack is healthy. Checks structure, counts, junctions, bin scripts, frontmatter, broken paths. Reports 23 checks. Exits non-zero on failure.

### Changed
- **Skill frontmatter** (`intent-driven-development`): added `origin: ECC` for consistency with other skills.
- **Agents** (5): cleaned broken ECC references. `chief-of-staff.md` (`.claude/rules/` → `instructions/`), `harmonyos-app-resolver.md` (`rules/arkts/` → opencode-native), `react-build-resolver.md` and `react-reviewer.md` (rules/react/* + skills/react-* → coding-standards + security-review), `learn.md` (`rules/[category].md` → `instructions/INSTRUCTIONS.md`).
- **INSTRUCTIONS.md** expanded with ECC consolidated rules: Research & Reuse step 0, Pre-Review Checks, Code Review Standards (with severity CRITICAL/HIGH/MEDIUM/LOW), Security Review Triggers, Parallel Task Execution, Multi-Perspective Analysis, Skeleton Projects pattern.

## [0.5.0] — 2026-06-22

### Added
- **Session memory system** (4-layer hierarchy):
  - Capa 1: always loaded — `AGENTS.md` + `INSTRUCTIONS.md` + `.agents/PROJECT.md` (~2K tokens)
  - Capa 2: loaded on session start — `.agents/sessions/LATEST.md` (~1-3K tokens)
  - Capa 3: on-demand — skills, files, sub-agents (variable)
  - Capa 4: never loaded — git history, PRDs, plans, instincts (disk only)
- **`/session-start` slash command**: reads Capa 1+2, reports compact 1-2 line summary, waits for user direction.
- **`/session-end` slash command**: writes session snapshot to `.agents/sessions/{DATE}-{SLUG}.md`, updates `LATEST.md`, includes "Decisions made", "Files touched", "Open questions", "Next steps", "Commits this session".
- **`.agents/sessions/` folder** with README.md explaining the lifecycle.
- **prd-agent** (`.opencode/agents/prd-agent.md`, 12 KB, mode: all): the MANDATORY FIRST STEP for any non-trivial task. Runs a 4-phase Understanding Protocol: Phase 0 (verify/create `.agents/PROJECT.md`), Phase 1 (active listening), Phase 2 (build Intention Map), Phase 3 (resolve ambiguities, max 3 at a time), Phase 4 (confirm Intention Map with explicit user OK). Output: `.opencode/prds/{name}.prd.md` with full template.
- **`.agents/PROJECT.md` template** (1.6 KB): project's source of truth for stack, conventions, non-negotiables. prd-agent reads at Phase 0; auto-generates from existing project files if missing.

### Changed
- **`/orchestrate` command** rewritten with Phase 0 (MANDATORY): dispatch to prd-agent FIRST before any planning, then existing 1-5 phases.
- **AGENTS.md** structured around 4 mandatory behaviors (caveman, PRD-first, session memory, no-destructive) + 5th rule (no-git-push).
- **prd-agent description** aggressive: "MANDATORY FIRST STEP for any non-trivial task. The primary agent MUST delegate to this agent before any planning."

## [0.4.0] — 2026-06-22

### Added
- **`instinct.js` CLI** (14 KB, zero deps): replaces ECC's continuous-learning-v2 Python plugin. Commands: `status`, `projects`, `promote`, `evolve`, `export`, `import`, `add`. Storage: `~/.config/opencode/instincts/` (global) + `.opencode/instincts/` (project). Format: ECC-compatible JSON (instincts[], metadata).
- **`.opencode/instincts/`** directory: project-scope instinct storage.
- **`.opencode/prds/`** directory: PRD artifacts.

### Changed
- **6 commands migrated** to use `node .opencode/bin/instinct.js`:
  - `instinct-status.md` (was python3 plugin)
  - `evolve.md` (was python3 plugin)
  - `projects.md` (was python3 plugin)
  - `promote.md` (was python3 plugin)
  - `instinct-export.md` (was python3 plugin)
  - `instinct-import.md` (was python3 plugin)
- **`security-scan.md`**: removed broken `skills/security-scan/` reference; uses `npx ecc-agentshield` standalone.

## [0.3.0] — 2026-06-22

### Added
- **No destructive actions without explicit consent rule** in AGENTS.md and INSTRUCTIONS.md: agent NEVER does `git commit` / `push` / `rm -rf` / `DROP TABLE` without explicit verb from user. "dale" / "ok" alone are NOT consent.
- **"Acciones destructivas requieren consentimiento explicito"** section in AGENTS.md with full list of protected actions.

## [0.2.0] — 2026-06-22

### Added
- **5 mandatory behaviors** consolidated in AGENTS.md:
  1. Caveman mode (terse responses, ~75% token reduction)
  2. PRD-first (any non-trivial task → prd-agent)
  3. Session memory (auto-snapshot on close signals)
  4. No destructive actions without consent
  5. No git push/commit without explicit per-turn consent
- **STARTER.md** rewritten with new "Flutter quiz" example (9 steps from command to commit), summary tables, "Lo que NO tuviste que pedir" section explaining auto-invoked specialists.
- **Tool truncation table** in INSTRUCTIONS.md.
- **Token optimization analysis** documented: 4-layer hierarchy, on-disk vs in-context mental model.

## [0.1.0] — 2026-06-22

### Added
- **Initial starter pack** (forked from ECC, restructured for opencode-native).
- **64 agents** migrated from ECC, normalized to `mode: all` + `permission:` block.
- **11 skills** with consistent frontmatter (name, description, origin).
- **47 commands** extracted from opencode.json into `.opencode/commands/*.md`.
- **Setup scripts** (`setup.ps1`, `setup.sh`) with robocopy/rsync node_modules exclusion.
- **Junctions** (`.opencode/agent` → `agents/`, `.opencode/skill` → `skills/`) for opencode 1.17.x backwards compat.
- **MCP servers**: `context7` (docs search), `playwright` (browser automation).
- **Plugins**: `dynamic-context-pruning`, `skillful`, `vibeguard`, `pty`.
- **Permission**: `skill: "allow"` global.
- **2 hidden junctions** + `.opencode/.gitignore` to exclude node_modules.
- **AGENTS.md** with caveman rules, structure, conventions.
- **INSTRUCTIONS.md** with security, coding style, testing, git workflow, agent orchestration, common patterns.
- **README.md** (409 B): GitHub landing pointing to STARTER.md.
- **STARTER.md** (22 KB): complete documentation including 47-command table, real example (Node.js API endpoint), command/skill/agent comparison.
- **`opencode.json`** (1.3 KB): minimal config — mcp, plugin, instructions. NO `model`/`small_model` (each user configures their own).

### Fixed
- `singular` vs `plural` folder names: renamed `.opencode/agent/` and `.opencode/skill/` to `.opencode/agents/` and `.opencode/skills/` per opencode 1.17.x standards.
- `opencode.json` bloat: 63 KB (with inline commands) → 1.3 KB (commands in .md files).
- **node_modules** bloat: pack was 53.85 MB → 1.38 MB (97% reduction) by deleting `node_modules` and excluding in setup scripts. Regenerated by `bun install` on first `opencode .` (~30s).
- **Junction untracking**: removed `.opencode/agent/*` and `.opencode/skill/*` from git tracking (75 files were duplicates via junction).

---

## Summary by numbers

| Metric | 0.1.0 (init) | 0.8.0 | 1.0.0 (current) | Delta total |
|--------|-------------|-------|------------------|-------------|
| Source pack size | 53.85 MB | 1.38 MB | ~1.5 MB | -97% |
| `opencode.json` size | 63 KB | 1.3 KB | 1.3 KB | -98% |
| Files in repo root (pack) | 7 | 3 | **1** (opencode.json) | -86% |
| Agents | 64 | 65 | 66 | +2 |
| Skills | 11 | 10 | 10 | -1 |
| Commands | 47 | 52 | 60 | +13 |
| Bin CLIs | 0 | 4 | 4 | +4 |
| Mandatory behaviors | 0 | 5 | 6 | +6 |
| Report templates | 0 | 0 | 4 (default/angular/python/rust) | +4 |
| Recovery state | 0 | 0 | 1 (documented) | +1 |
| Naming convention | ad-hoc | informal | formal (`CONVENTIONS.md`) | formal |
| Token reduction (typical) | baseline | ~80% | ~85% | -85% |
| Auto-destructive actions blocked | no | yes | yes | safety+ |

## Commands added across versions

| Version | Command | Purpose |
|---------|---------|---------|
| 0.4.0 | (migrated) instinct-status | Show learned instincts with confidence |
| 0.4.0 | (migrated) evolve | Analyze and suggest evolved structures |
| 0.4.0 | (migrated) projects | List registered projects and instinct counts |
| 0.4.0 | (migrated) promote | Promote project instincts to global scope |
| 0.4.0 | (migrated) instinct-export | Export instincts for sharing |
| 0.4.0 | (migrated) instinct-import | Import instincts from external sources |
| 0.5.0 | /session-start | Load minimal context (Capa 1+2) |
| 0.5.0 | /session-end | Write session snapshot |
| 0.6.0 | /context | Show context budget report |
| 0.7.0 | /refresh-project | Regenerate .agents/PROJECT.md from current state |
| 0.7.0 | /prd | Quick invocation of prd-agent |

## Architecture (current — v1.0.0)

```
D:\dev\2026\open\
├── opencode.json       (root, ONLY this. 1.3 KB: mcp + plugin + instructions)
├── .agents/            (user-installed skills + project context)
│   ├── PROJECT.md      (auto-refreshable)
│   ├── sessions/       (1 .md per session + LATEST.md)
│   └── skills/caveman/ (user-installed)
└── .opencode/          (TODO el pack vive aca — zero conflict con archivos del user)
    ├── AGENTS.md       (reglas del pack, referenciado en opencode.json)
    ├── README.md       (doc del pack)
    ├── CHANGELOG.md    (version history)
    ├── CONVENTIONS.md  (naming + estados + frontmatter schemas)
    ├── agents/         (66 .md, mode: all|primary|subagent)
    ├── skills/         (10 .md, on-demand)
    ├── commands/       (60 .md, slash commands)
    ├── instructions/   (INSTRUCTIONS.md, 8 KB, capa 1)
    ├── reports/        (reports + templates + INDEX)
    ├── audits/         (auditorias separadas)
    ├── prds/           (PRD artifacts, YYYY-MM-DD_HHMM-{slug}.prd.md)
    ├── plans/          (planes, YYYY-MM-DD_HHMM-{slug}.plan.md)
    ├── state/          (recovery state por sesion)
    ├── bin/            (4 CLIs, zero deps)
    ├── instincts/      (JSON store)
    ├── docs/           (ROUTE, COMMANDS, EXAMPLES, ARCH, SURFACES)
    ├── node_modules/   (regenerable con bun install)
    ├── package.json    (deps de plugins/MCPs)
    ├── agent           (junction → agents/)
    └── skill           (junction → skills/)
```

## Token efficiency (cumulative)

| Layer | Mechanism | Savings |
|-------|-----------|---------|
| Output | caveman mode | ~75% |
| Chat history | dynamic-context-pruning plugin | 30-50% |
| Resume | session memory 4-layer | ~80% |
| Sub-agents | task tool isolated contexts | 70-90% in parallel |
| Skills | on-demand via `<available_skills>` | ~95% on unused |
| Tool results | truncation rules in INSTRUCTIONS.md | 20-40% |
| PROJECT.md | auto-refresh keeps it accurate | avoids re-derivation |
| Instincts | persistent learnings in JSON | avoids re-explanation |
| **Total** | | **~85% reduction vs unoptimized starter** |
