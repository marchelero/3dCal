# Guía de opencode

> Punto de entrada al pack portable de opencode. Cópialo a cualquier proyecto, reinicia opencode y empieza a trabajar.

## ¿Qué incluye?

- **69 sub-agentes** en `.opencode/agents/` (revisores, planners, resolvers, especialistas por stack)
- **14 skills portables** en `.opencode/skills/` (patrones de API, TDD, seguridad, error handling, etc.)
- **65 slash commands** en `.opencode/commands/` (atajos recurrentes)
- **0 servidores MCP** configurados por default (soporte via `opencode.json`; los comunes son `context7` y `playwright`)
- **5 plugins**: `opencode-vibeguard`, `opencode-pty`, `@tarquinen/opencode-dcp`, `@zenobius/opencode-skillful`, `@opencode-ai/plugin`
- **9 CLIs nativos** en `.opencode/bin/` (cero dependencias, solo Node stdlib)

## Instalación

```bash
# copia las partes portables a tu proyecto
cp -r .opencode opencode.json AGENTS.md instructions/ /ruta/a/tu/proyecto/

# abre opencode en ese proyecto
cd /ruta/a/tu/proyecto && opencode .
```

> Windows PowerShell: `Copy-Item -Path ".opencode","opencode.json","AGENTS.md","instructions" -Destination "C:\ruta\a\tu\proyecto" -Recurse -Force`

> Si tu proyecto ya tiene un `README.md`, no se toca. Si quieres fusionar `AGENTS.md` con reglas propias, hazlo a mano.

## 5 comportamientos obligatorios (siempre activos)

1. **Caveman mode** — respuestas tersas, ~75% menos tokens. Solo se sale en advertencias de seguridad, acciones irreversibles, secuencias multi-paso o cuando dices "habla normal".
2. **PRD-first** — "construir X" / "crear Y" / "agregar Z" → `@prd-agent` o `/prd` PRIMERO. Nunca se propone una solución sin antes clarificar la intención y escribir el PRD. Solo se omite en preguntas y respuestas, arreglos de una línea, reportes de bug con reproducción o cuando dices "skip PRD" de forma explícita.
3. **Memoria de sesión** — "listo" / "bye" / "hasta mañana" → snapshot automático en `.agents/sessions/`. No hace falta ejecutar `/session-end` manualmente.
4. **Nada destructivo sin consentimiento** — `git commit` / `push` / `rm -rf` / `DROP TABLE` requieren verbo explícito. "vale" / "ok" solos NO son consentimiento.
5. **El consentimiento no se hereda entre turnos** — el permiso de un turno previo NO se aplica al actual. Cada `commit`/`push` necesita su propio "commitea"/"push" en el turno actual.

## 8 comandos principales

| Comando | Función |
|---------|---------|
| `/prd` | Clarifica intención y escribe el PRD |
| `/plan` | Plan de implementación a partir de un PRD |
| `/orchestrate` | Flujo multi-agente (Phase 0 = prd-agent automático) |
| `/verify` | Valida cambios (revisión de código + seguridad + revisor del lenguaje) |
| `/code-review` | Revisión de código puntual |
| `/security` | Auditoría de seguridad puntual |
| `/session-start` / `/session-end` | Memoria entre sessions (automática al cerrar) |
| `/context` | Audita el presupuesto de contexto (skills, agentes, sessions) |

Lista completa: `node .opencode/bin/context.js` o explora `.opencode/commands/`.

## 9 CLIs nativos (cero dependencias, solo Node stdlib)

```bash
node .opencode/bin/smoke-test.js         # 24 comprobaciones estructurales
node .opencode/bin/context.js            # informe de presupuesto de contexto
node .opencode/bin/instinct.js           # add/status/projects/promote/evolve/export/import
node .opencode/bin/validate-frontmatter.js  # valida frontmatter de agentes/skills/comandos
node .opencode/bin/refresh-project.js    # regenera .agents/PROJECT.md desde el proyecto
```

## 4 capas de memoria

| Capa | Qué contiene | Cuándo se carga | Tamaño |
|------|--------------|-----------------|--------|
| 1 | `AGENTS.md` + `INSTRUCTIONS.md` + `.agents/PROJECT.md` | siempre | ~2K tokens |
| 2 | `.agents/sessions/LATEST.md` | al iniciar sesión | ~1-3K tokens |
| 3 | Skills bajo demanda, archivos, sub-agentes | cuando se piden | variable |
| 4 | Historial git, PRDs, planes, instintos | nunca | disco |

## Primeros 5 minutos (post-instalación)

```bash
# 1. Verifica que todo funciona
node .opencode/bin/smoke-test.js         # esperado: PASSED 24+, FAILED 0

# 2. Genera el contexto del proyecto (si el proyecto es nuevo)
#    Rellena .agents/PROJECT.md a mano, o ejecuta:
node .opencode/bin/refresh-project.js

# 3. Arranca una tarea real
/prd "descripción de tu primera feature"
```

## Documentación adicional

- **[ROUTE.md](./ROUTE.md)** — elige el sub-agente correcto según la intención
- **[COMMANDS.md](./COMMANDS.md)** — los 65 slash commands agrupados por intención
- **[EXAMPLES.md](./EXAMPLES.md)** — 5 flujos completos de proyectos reales
- **[ARCH.md](./ARCH.md)** — 4 capas, flujo PRD, ciclo de instintos, estructura de archivos
- **[SURFACES.md](./SURFACES.md)** — cuándo usar regla vs skill vs MCP vs agente vs CLI

## Reinicio tras cambios

opencode lee la configuración una sola vez al arrancar. Tras cualquier cambio:

```
Ctrl+C          # salir
opencode .      # volver a entrar
```

## Referencia

- Esquema del config: <https://opencode.ai/config.json>
- Agentes: <https://opencode.ai/docs/agents/>
- Skills: <https://opencode.ai/docs/skills/>
- Comandos: <https://opencode.ai/docs/commands/>
- Plugins: <https://opencode.ai/docs/plugins/>
