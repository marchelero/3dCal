# Selección de superficies de capacidad

> Cuándo una capacidad debería ser una **regla**, una **skill**, un **servidor MCP** o un simple **CLI/flujo de API**.

El pack expone cuatro superficies para las capacidades. Elegir la correcta es una decisión de ruteo: afecta al coste de tokens, al lugar donde vive el prompt y a quién puede invocar qué.

## Árbol de decisión rápida

```
¿Es una regla dura que SIEMPRE aplica (seguridad, consentimiento git, no destrucción)?
  └─ SÍ → REGLA (INSTRUCTIONS.md o AGENTS.md, capa 1)
  └─ NO ↓

¿Es conocimiento/contexto que el agente debe APLICAR cuando es relevante
(convenciones REST, patrones de error, disciplina TDD)?
  └─ SÍ → SKILL (.opencode/skills/<nombre>/SKILL.md, capa 3 bajo demanda)
  └─ NO ↓

¿Es una acción discreta que el agente LLAMA y que puede tener efectos
(buscar docs, correr una herramienta, recuperar datos externos)?
  └─ SÍ → servidor MCP (capacidades que el modelo invoca como tools)
  └─ NO ↓

¿Es un flujo o pipeline independiente que el usuario EJECUTA
(init, auditoría, migración, sincronización)?
  └─ SÍ → CLI en .opencode/bin/ (cero-deps) O slash command en .opencode/commands/
  └─ NO ↓

¿Es trabajo profundo que debe correr en un contexto aislado con su propio
system prompt y permisos (revisión de código, auditoría de seguridad, planning)?
  └─ SÍ → SUB-AGENTE (.opencode/agents/<nombre>.md)
```

## Las superficies en detalle

### 1. Regla (capa 1, siempre cargada)

**Dónde**: `INSTRUCTIONS.md`, `AGENTS.md`, `.agents/PROJECT.md`

**Coste de tokens**: se paga cada turno. Mantener corto (~2K tokens total).

**Úsala para**:
- Comportamiento de seguridad obligatorio
- Política de acciones destructivas en git
- Estilo de output (caveman)
- No negociables específicos del proyecto

**Anti-patrón**: poner convenciones de API, tips de frameworks o conocimiento de flujo aquí. Inflan cada turno.

### 2. Skill (capa 3, bajo demanda)

**Dónde**: `.opencode/skills/<nombre>/SKILL.md` (o instaladas por el usuario en `.agents/skills/`)

**Coste de tokens**: cero hasta que el agente decide cargarla (vía catálogo `<available_skills>` + tool `skill`).

**Úsala para**:
- Conocimiento de dominio que el agente aplica cuando el contexto encaja (diseño REST, TDD, manejo de errores, revisión de seguridad)
- Patrones de referencia que el agente lee una vez y reutiliza muchas veces
- Convenciones demasiado extensas para `INSTRUCTIONS.md` pero que no justifican un agente

**Reglas de frontmatter** (las aplica `validate-frontmatter.js`):
- `name` (requerido, kebab-case)
- `description` (requerido, 1-1024 caracteres, tercera persona, "Use when...")
- `origin` (opcional, p. ej. "starter-pack")

### 3. Servidor MCP (capa 3, superficie de tools)

**Dónde**: `opencode.json > mcp.<nombre>`

**Coste de tokens**: el esquema se pre-carga (~pocos cientos de tokens); cada invocación devuelve datos.

**Úsalo para**:
- Llamar a servicios externos (Context7 docs, navegador Playwright, GitHub, Postgres)
- Cualquier cosa que el modelo necesite hacer, no solo saber
- Capacidades con input/output estructurado que valen la pena validar con Zod

**Anti-patrón**: un servidor MCP cuyo único propósito sea imprimir texto. Usa una skill o un slash command.

**Ejemplos en este pack**:
- `context7` — resuelve library ID, recupera documentación actualizada (reemplaza los datos de entrenamiento)
- `playwright` — automatización de navegador para tests E2E y debugging en vivo

### 4. CLI / slash command (invocado por el usuario, sin prompt de agente)

**Dónde**: `.opencode/bin/<nombre>.js` (CLI) o `.opencode/commands/<nombre>.md` (slash)

**Coste de tokens**: cero hasta que se invoca.

**Úsalo para**:
- Flujos puntuales que el usuario ejecuta a propósito (`smoke-test`, `refresh-project`, `instinct status`)
- Prompts prearmados que siempre necesitan el mismo preámbulo (`/prd`, `/verify`, `/code-review`)
- Cualquier cosa que necesite I/O de archivos determinista sin interpretación del modelo

**Slash command vs CLI**:
- CLI: cuando el output son datos que el usuario lee (`instinct status`, `context --recommend`)
- Slash command: cuando el output es un prompt que el agente luego ejecuta (`/prd` → prd-agent corre)

### 5. Sub-agente (capa 3, contexto aislado)

**Dónde**: `.opencode/agents/<nombre>.md`

**Coste de tokens**: arranca un sub-proceso nuevo con su propio system prompt e historial de conversación.

**Úsalo para**:
- Trabajo especializado que no debe contaminar el contexto del primary
- Trabajo paralelizable (varios agentes en un mismo mensaje)
- Auditorías read-only (code-reviewer, security-reviewer, pr-test-analyzer) donde el aislamiento previene ediciones accidentales
- Expertos específicos de stack (python-reviewer, flutter-reviewer, go-reviewer) — solo se cargan cuando son relevantes

**Reglas de frontmatter** (las aplica `validate-frontmatter.js`):
- `description` (requerido, tercera persona, qué + cuándo)
- `mode: subagent` (requerido)
- `permission:` (recomendado)

## Ejemplos de ruteo

| Necesidad | Elige | Por qué |
|-----------|-------|---------|
| "Siempre requerir consentimiento explícito para `git push`" | Regla (INSTRUCTIONS.md) | Aplica cada turno, sin opt-out |
| "Al diseñar una API REST, seguir estos patrones" | Skill (`api-design`) | Condicional al contexto, contenido extenso |
| "Recuperar docs actualizadas de la librería X" | Servidor MCP (context7) | Datos externos, petición estructurada |
| "Listar todos los instintos aprendidos" | CLI (`instinct.js status`) | Escaneo determinista de archivos, el usuario lee el output |
| "Generar un PRD para la próxima tarea" | Slash command (`/prd`) | Prompt prearmado para el prd-agent |
| "Auditar un PR de Python por temas idiomáticos" | Sub-agente (`python-reviewer`) | Especialista + contexto aislado + read-only |
| "Hook pre-commit que corra smoke-test" | Workflow de CI (`.github/workflows/`) | Corre en push, no en el loop del agente |

## Anti-patrones

- **Skill en `instructions`**: doble carga de contenido; desperdicia ~30K tokens/turno. Confía en `<available_skills>`.
- **CLI para trabajo del LLM**: si el output es "pídele al modelo que haga X", usa un slash command.
- **Sub-agente para un one-liner**: un sub-agente cuesta un system prompt + historial completos. Usa una skill para conocimiento pequeño de especialista.
- **Servidor MCP para texto estático**: si no tiene efectos secundarios y no tiene input estructurado, es una skill.
- **Regla para "al diseñar API..."**: las reglas no pueden ser condicionales. Usa una skill con una descripción "Use when...".
