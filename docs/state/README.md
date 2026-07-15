# Recovery State

Cada command de flujo largo (orchestrate, plan, flow-*, verify) escribe su progreso en `docs/state/{command}-{timestamp}.json`. Esto permite resumir flujos interrumpidos.

## Cuando se escribe

- **Inicio del command**: `{command: "orchestrate", started: "...", prd: null, currentPhase: 0, completed: []}`
- **Despues de cada fase**: actualizar `currentPhase` y agregar a `completed`.
- **Fin exitoso**: borrar el archivo (no queda state).
- **Fin con error**: dejar el archivo con `error: "..."`.

## Schema

```json
{
  "command": "orchestrate",
  "started": "2026-06-29T18:30:00Z",
  "prd": "docs/prds/2026-06-29-1830-foo.prd.md",
  "currentPhase": 2,
  "completed": [0, 1],
  "context": {
    "userRequest": "feat: import CSV",
    "agentsInvoked": ["prd-agent", "planner"],
    "filesModified": ["src/app/foo.ts"]
  },
  "error": null
}
```

## Como lo detecta /session-start

```bash
ls docs/state/*.json 2>/dev/null | head -n 5
```

Si hay archivos:
- Parsear el JSON.
- Mostrar al user: "Detecte un {command} interrumpido en fase {N}. Resumir? (s/n)"
- Si dice s → continuar desde `currentPhase`.
- Si dice n → archivar el state (no borrar, mover a `docs/state/_archive/`).

## Comandos que escriben state

| Command | Escribe state | Por que |
|---------|---------------|---------|
| /orchestrate | si | flujo largo multi-fase |
| /plan | si | si el plan es largo |
| /flow-bugfix | si | multi-step |
| /flow-feature | si | multi-step |
| /flow-refactor | si | multi-step |
| /flow-security | si | multi-step |
| /verify | no | corre en segundos |
| /code-review | no | single-pass |
| /security | no | single-pass |
| /quick-prd | no | corre rapido |

## CLI manual

```bash
node .opencode/bin/state.js init <command> <user-request> [<prd-path>] [--dry-run]
node .opencode/bin/state.js update <file-or-basename> <phase> <context-json> [--dry-run]
node .opencode/bin/state.js complete <file-or-basename>
node .opencode/bin/state.js fail <file-or-basename> "<error message>"
node .opencode/bin/state.js list          # muestra todos los activos
node .opencode/bin/state.js archive <file-or-basename>   # mueve a _archive/
```

**Path resolution**: `update`, `complete`, `fail`, `archive` aceptan tanto el full path (de `init` output) como el basename (de `list` output). El script busca primero el path as-is, después prueba `docs/state/{basename}`.

**--dry-run**: para `init` y `update`, preview el cambio sin escribir. Útil para verificar que el state quedaría bien antes de commitear un flow largo.

## Garantias

- State solo se escribe. **Nunca se borra automaticamente** salvo al completar exitosamente.
- State viejo (>7 dias) lo mueve `/session-start` a `_archive/` con aviso.
- State NO contiene codigo, secrets, ni archivos. Solo metadata.
