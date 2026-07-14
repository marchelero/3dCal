# Recovery State

Cada command de flujo largo (orchestrate, plan, flow-*, verify) escribe su progreso en `.opencode/state/{command}-{timestamp}.json`. Esto permite resumir flujos interrumpidos.

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
  "prd": ".opencode/prds/2026-06-29-1830-foo.prd.md",
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
ls .opencode/state/*.json 2>/dev/null | head -n 5
```

Si hay archivos:
- Parsear el JSON.
- Mostrar al user: "Detecte un {command} interrumpido en fase {N}. Resumir? (s/n)"
- Si dice s → continuar desde `currentPhase`.
- Si dice n → archivar el state (no borrar, mover a `.opencode/state/_archive/`).

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

## Garantias

- State solo se escribe. **Nunca se borra automaticamente** salvo al completar exitosamente.
- State viejo (>7 dias) lo mueve `/session-start` a `_archive/` con aviso.
- State NO contiene codigo, secrets, ni archivos. Solo metadata.
