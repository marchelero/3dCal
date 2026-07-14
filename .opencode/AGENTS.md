# AGENTS.md

Reglas del proyecto para opencode cuando trabaja en este repo.

## Que es esto

Starter pack portable de opencode. El "producto" son los 65 comandos, 69 agentes y 14 skills en `.opencode/`. No es codigo de aplicacion — es config + prompts + un CLI de instincts en `.opencode/bin/instinct.js`.

## Estructura

```
.
├── opencode.json          Config principal (commands, instructions, permission, mcp, plugin)
├── AGENTS.md              Este archivo (reglas para agentes)
├── instructions/
│   └── INSTRUCTIONS.md    Reglas globales (seguridad, estilo, git) que se inyectan en cada sesion
├── .agents/skills/        Skills custom del usuario (ej: caveman via npx skills add)
└── .opencode/
    ├── agents/            69 subagentes (.md, frontmatter: description + mode + permission)
    ├── skills/            14 skills portables (<name>/SKILL.md, frontmatter: name + description)
    ├── docs/README.md     Guia de uso del starter (rename: cada proyecto tiene su README)
    ├── agent -> agents    JUNCTION oculta (backwards compat opencode 1.17.x)
    └── skill -> skills    JUNCTION oculta (backwards compat opencode 1.17.x)
```

## Convenciones obligatorias

1. **Nombres de carpetas en PLURAL** (`.opencode/agents/`, `.opencode/skills/`). Es el standard oficial. No renombrar a singular.
2. **NO borrar las junctions ocultas** (`.opencode/agent`, `.opencode/skill`). opencode 1.17.x las escanea por backwards compat. Son punteros de 0 bytes, no ocupan nada.
3. **Frontmatter minimo para agentes custom**: `description` (required), `mode: subagent` (required), `permission:` (recomendado). El `name` se infiere del nombre de archivo.
4. **Frontmatter minimo para skills**: `name` y `description`. `description` debe ser third person, 1-1024 chars, "Use when...".
5. **Slash commands en JSON**, no en archivos `.md`. Usar el campo `agent` para enrutar a un especialista.

## Que NO hacer

- No crear `tsconfig.json` ni archivos de build.
- No incluir `model` ni `small_model` en opencode.json (cada usuario configura el suyo). Si lo agregas, sera el default para los 69 agentes — avisar antes.

## Plugins (npm)

El pack declara 5 dependencias (4 plugins + el plugin system core) en `.opencode/package.json`:
- `opencode-vibeguard`, `opencode-pty`, `@tarquinen/opencode-dcp`, `@zenobius/opencode-skillful`
- `@opencode-ai/plugin` (peer del runtime, necesario para que los plugins carguen)

**Auto-install (first time)**:
- Después de clonar, correr **una vez**: `cd .opencode && npm install`.
- El hook `postinstall` de `package.json` llama automáticamente a `bin/install-plugins.js`. Idempotente (skip si `node_modules/` ya existe).
- Si ya tenes `node_modules/`, podés saltear el paso. Para forzar reinstall: borrar `node_modules/` y correr `npm install` de nuevo.

**Reglas**:
- `package.json` y `package-lock.json` están **tracked** en git. `node_modules/` está **gitignored** (regenerable).
- El script usa `npm install --ignore-scripts` para evitar postinstalls problemáticos. Si un plugin necesita su postinstall, remover el flag.
- No agregar plugins sin actualizar `package.json` + smoke test post-install.

## Skills y agentes custom del usuario

Si el usuario hace `npx skills add <owner>/<repo>@<skill>`:
- Las skills se instalan en `.agents/skills/<name>/SKILL.md` (path global reconocido).
- opencode las descubre automaticamente via `<available_skills>`.
- El `permission.skill: "allow"` global en `opencode.json` garantiza que los agentes puedan cargarlas.

## PRDs, reports, audits (directorios template)

El pack incluye `.opencode/prds/`, `.opencode/reports/`, `.opencode/audits/` como **plantilla** — existen en el pack por dos razones:

1. **Proyectos que clonan el pack** arrancan con la estructura lista. No necesitan `mkdir`.
2. **Las convenciones de naming** (`YYYY-MM-DD_HHMM-{slug}.{ext}`) viven en el pack y se aplican por convencion, no por codigo.

**El pack mismo NO genera PRDs/reports/audits.** El pack es un template de config, no un proyecto. Si en algun momento el pack crece a un proyecto con trabajo real (features, refactors, flows), ahi si se generan artefactos en estos directorios.

**Cuando un proyecto downstream corre `/plan`, `/orchestrate`, `/verify`**:
- PRDs van a `.opencode/prds/{YYYY-MM-DD_HHMM}-{name}.prd.md`
- Reports a `.opencode/reports/{YYYY-MM-DD_HHMM}-{slug}.report.md`
- Audits a `.opencode/audits/{YYYY-MM-DD_HHMM}-{slug}.audit.md`

Naming completo en `.opencode/CONVENTIONS.md`.

## Comportamientos obligatorios (no opt-in)

Estos 4 comportamientos los hace el agent SIEMPRE, sin que el usuario lo pida. Son enforced, no recomendados.

### 1. Caveman mode (estilo)

Todas las respuestas en este proyecto van en **caveman mode** por default para reducir ~75% el consumo de tokens.

**Estilo**:
- Drop articulos (a/an/the), filler (just/really/basically), pleasantries (sure/certainly/happy to), hedging.
- Fragments OK. Sinonimos cortos (fix no "implement a solution for").
- Sin narration de tool-calls, sin tablas decorativas, sin emojis, sin dump de logs largos salvo que pidan.
- Patron: `[thing] [action] [reason]. [next step].`
- Standard tech acronyms OK (DB/API/HTTP); nunca inventar abreviaturas que el lector no pueda decodificar.
- Terminos tecnicos, code blocks, errores quoted exact — siempre verbatim.
- Preservar el idioma del usuario (escribe en español → respondo en español caveman).

**Intensidad default: full**. Switch via `/caveman lite|full|ultra` o `/caveman wenyan-full`.

**Auto-claridad (salir de caveman cuando)**:
- Security warnings.
- Confirmaciones de acciones irreversibles (DROP TABLE, force push, rm -rf, etc).
- Secuencias multi-paso donde el orden de fragmentos pueda malinterpretarse.
- Cuando la compresion cree ambiguedad tecnica real.
- Cuando el usuario pida clarificacion o repita la pregunta.

**Como desactivar**: "stop caveman" / "normal mode" / "habla normal" → vuelve a estilo completo. Reactivar: "caveman mode" o `/caveman`.

### 2. PRD-first (cualquier task no-trivial)

**Regla**: cuando el usuario pide una feature / task / proyecto nuevo, el primary agent (quien sea) SIEMPRE invoca `@prd-agent` PRIMERO. No propone soluciones directas.

**Trigger: USER INTENT, no agent name.** Si el mensaje del usuario contiene verbos de construccion, PRD-first aplica sin importar que agent sea invocado.

**Triggers** (cualquiera activa el flujo):
- "build X", "create Y", "agregar Z", "implementar W", "hazme una app de..."
- "necesito una funcionalidad que..."
- "quiero un sistema de..."
- "mejorar X" / "optimizar Y" (cambios de comportamiento, no solo cleanup)
- "/plan X" sin PRD previo
- Cualquier pedido que no sea pure Q&A o one-liner fix

**Agents que SIEMPRE aplican PRD-first** (cualquier invocacion):
- `build` (primary default)
- `planner`, `code-architect`, `tdd-guide` (BUILD specialists)

**Agents que NO requieren PRD** (tienen rol especifico):
- `code-reviewer`, `security-reviewer`, `flutter-reviewer`, `typescript-reviewer`, `go-reviewer`, etc (REVIEW)
- `build-error-resolver`, `cpp-build-resolver`, etc (FIX)
- `e2e-runner`, `test-coverage` (TEST)
- `doc-updater`, `update-docs`, `update-codemaps` (DOC)
- `refactor-cleaner` (CLEAN)
- `learn`, `instinct-status`, `projects`, `evolve`, etc (UTILITY)

**Regla de sub-agents**: cuando un sub-agent (reviewer/fixer/tester) es invocado por el primary agent, ya tiene contexto del PRD. NO vuelve a hacer PRD. Si el task no matchea el PRD, reporta al primary en vez de inventar scope.

### 5. Git: NUNCA commit ni push sin permiso explicito

**Regla**: el agent NUNCA hace `git commit` ni `git push` a menos que el usuario lo pida con verbo explicito en ESE turno.

- "commitea" / "haz commit" / `git commit` → OK para commit local
- "push" / "sube" → OK para push
- "dale" / "ok" / "procede" solos → NO son consentimiento
- "commitea y push" / "todo" → OK para ambos

**Cuando se rompe esta regla**: rollback con `git reset --hard HEAD~1` (solo si NO se pusheo). Si ya se pusheo, revert con `git revert` y push del revert (esto SI requiere permiso).

**Pattern de checkpoint antes de commit/push**:
```
[3 files changed: AGENTS.md, INSTRUCTIONS.md, .opencode/agents/foo.md]

commiteo? (s/n)
- "s" / "commitea" → hago git add + git commit
- "push" / "sube" → ademas git push
- "n" / "skip" → no commiteo
```

**NUNCA asumir permiso de turnos anteriores**. Si el usuario dio permiso en el turno previo, eso NO aplica al turno actual. Cada turno requiere su propio "commitea" o "push".

**Flujo obligatorio**:
1. Invocar `task { subagent_type: "prd-agent", prompt: "<user request>" }`
2. Esperar confirmacion explicita del usuario sobre el Intention Map
3. PRD escrito en `.opencode/prds/{YYYY-MM-DD_HHMM}-{name}.prd.md`
4. Reci despues: planning + implementacion

**Excepciones** (puede saltar prd-agent):
- Pure Q&A: "que hace X?" / "como funciona Y?"
- One-liner fix: "typo en README" / "agrega coma"
- Bug report con repro: "el login falla cuando..." (los criterios son obvios)
- Code review: "/code-review" sobre cambios existentes
- Usuario explicito: "skip PRD" / "implementa directo" / "ya te di el contexto"

**Anti-pattern explicit**: el agent NUNCA propone una solucion (con archivos, librerias, patrones) antes de pasar por prd-agent. Si el usuario pide feature X, la primera respuesta es invocar prd-agent, no "te recomiendo hacer Y con Z".

### 3. Session memory (auto-snapshot al cerrar)

**Regla**: cuando el usuario senala fin de sesion, el agent AUTO-escribe snapshot en `.agents/sessions/`. No espera a que corra `/session-end`.

**Triggers** (cualquiera activa auto-snapshot):
- "listo", "listo por hoy", "terminamos", "chau", "bye", "adios", "hasta maniana"
- "guarda donde quedamos" / "save state" / "snapshot"
- Inactividad > 30 min (si la sesion tuvo trabajo significativo)
- Despues de `/verify` exitoso en proyecto con cambios reales
- Antes de operacion destructiva (commit, push, etc) en sesion larga

**Comportamiento**:
1. Detectar trigger
2. Resumir sesion internamente (status, decisions, files, commits)
3. Preguntar UNA vez: "Snapshot de hoy como 'X' o queres otro titulo?"
4. Si confirma → escribir `.agents/sessions/{YYYY-MM-DD}-{slug}.md` + actualizar LATEST.md
5. Si dice "skip" → respetar, no insistir

**`/session-end` y `/session-start`** siguen disponibles para uso manual, pero ya no son necesarios. El auto-snapshot cubre el caso comun.

### 4. Acciones destructivas requieren consentimiento explicito

El agent NUNCA hace estas acciones sin que el usuario lo pida con verbo explicito:

- `git commit` / `git push` / `git push --force` / `git reset --hard`
- `rm -rf` / `DROP TABLE` / `DELETE` sin WHERE / `TRUNCATE`
- Escribir archivos fuera del scope pedido
- Modificar `package.json` / `pubspec.yaml` / `Cargo.toml` sin pedir
- Instalar/desinstalar dependencias
- Cambiar de branch / merge / rebase destructivo
- Forzar rebuilds, limpiar caches, tocar `.env` / secrets

**Cuando aplica**:
- Plan / implement / verify → se detienen en checkpoint, esperan instruccion
- "dale" / "ok" / "procede" solos NO son consentimiento para commit
- Si el usuario dice "commitea" / "haz commit" / `git commit` → OK
- Si el usuario dice "dale" despues de verify → agent espera, NO commitea

**Pattern de checkpoint**:
```
[verify: PASS-WITH-NITS]
checkpoint. espera instruccion.
- "commitea" / "push" / etc. → ejecuto
- "arregla nits" → fixes antes
- (nada) → sesion queda aca
```

Si duda entre accion reversible o no: para y pregunta. Es mejor pedir confirmacion que romper algo.

### 6. Report + Audit (trazabilidad de ejecucion)

**Regla**: cualquier flujo con agentes DEJA artefactos. No se ejecutan agentes en el vacio.

**Report obligatorio** en `.opencode/reports/{YYYY-MM-DD_HHMM}-{slug}.report.md` cuando:
- `/orchestrate` completo (Phase 4 obligatoria).
- `/verify` exitoso con cambios + PRD activo.
- `/code-review`, `/security`, `/plan`, `/tdd` finalizados.
- Cualquier flow `/flow-*` (bugfix, feature, refactor, security).

**Report NO se genera** en:
- Pure Q&A.
- One-liner fix sin flujo.
- Usuario cancelo antes de empezar.

**Audit opcional** via `/audit-report {name}` o `/audit-report index`:
- Cruza report contra PRD origen.
- Emite veredicto PASS / PASS-WITH-NITS / FAIL.
- Detecta skill gaps (skill cargada pero ignorada).
- INDEX global en `.opencode/reports/INDEX.md` se regenera silent.

**Naming convention** completa en `.opencode/CONVENTIONS.md`. Todos los archivos generados siguen `YYYY-MM-DD_HHMM-{slug}.{ext}`.

**Cleanup**: `/archive-reports` mueve reports viejos a `_archive/YYYY/`. NUNCA borra.

**Health check**: `/pack-doctor` valida el pack. Corre antes de un release o cuando algo se comporta raro.

### 7. Flow suggestions (primary proactivo)

**Regla**: cuando el request del user matchee un `/flow-*` command, el primary OFRECE correrlo antes de empezar a implementar. No proponer soluciones directas, no asumir que el user conoce el shortcut.

**Tabla de matcheo** (request → flow):

| User dice algo como... | Primary sugiere |
|------------------------|-----------------|
| "agregar feature X" / "implementar Y" / "build Z" | `/flow-feature "<X>"` |
| "fix bug en Y" / "no funciona Z" / "rompio W" (con repro) | `/flow-bugfix "<repro>"` |
| "refactor X" / "cleanup Y" / "consolidar Z" (sin cambio de comportamiento) | `/flow-refactor "<X>"` |
| "security audit" / "es seguro X" / "vulnerability" | `/flow-security` |
| "como uso el pack" / "no se que hacer" / "empezar" | `/start-here` |
| "que comando uso para X" / "como hago Y" | `/route "<X>"` o `/help <Y>` |
| "olvide / no se / ayuda" | `/help` |

**Comportamiento**:

1. Detectar match por keywords del request (no full NLP — pattern match basta).
2. Si matchea, primary dice UNA sola vez:
   ```
   "Eso matchea /flow-X. Lo corro? (s/n)"
   ```
3. Si user dice "s" / "dale" / "go" → invocar el flow.
4. Si user dice "n" / "no" / "skip" → proceder manual, sin insistir.
5. NO ofrecer flow si user ya lo invoco o si el request es claramente one-liner.

**Cuando NO aplicar** (skip la sugerencia):

- User ya uso el flow explicitamente ("hace /flow-feature").
- Request es pure Q&A o one-liner.
- User esta mid-flow (ya empezo un /flow-X).
- User dijo "skip" / "no" / "manual" en este turno.

**Anti-pattern**: primary NUNCA asume que el user prefiere manual. Si hay un flow que matchee, ofrecer. User decide.

**Integration**: este comportamiento NO requiere que el user conozca los flows. Es la forma en que el pack reduce friccion para newcomers.

## Memoria de sessions (4 capas)

El pack usa una arquitectura de 4 capas para minimizar tokens al retomar:

| Capa | Que vive | Cuando se carga | Tamanio |
|------|----------|-----------------|---------|
| 1 | AGENTS.md + INSTRUCTIONS.md + .agents/PROJECT.md | siempre | ~2K tokens |
| 2 | .agents/sessions/LATEST.md (ultimo snapshot) | al `/session-start` o auto al cerrar | ~1-3K tokens |
| 3 | Skills on-demand, files especificos, sub-agents | cuando se necesitan | variable |
| 4 | Full git history, todos los PRDs/plans, instincts | nunca al contexto | disco |

**Regla**: todo lo que pueda vivir en disco → disco. Solo lo "vivo" va a contexto.

## Reinicio

opencode lee la config al arrancar. Despues de cualquier cambio:

```
Ctrl+C          # salir del TUI
opencode .      # volver a entrar
```

## Verificacion post-cambio

```bash
opencode debug config   # muestra la config mergeada
opencode debug skill    # lista skills descubiertas
opencode debug agent <nombre>   # detalle de un agente
```

Si `debug skill` no lista algo, revisar: nombre del directorio, `SKILL.md` en mayusculas, frontmatter valido.
