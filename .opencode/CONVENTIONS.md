# Conventions

Reglas formales del pack. Cualquier archivo nuevo DEBE seguir estos patrones.

---

## Naming convention

Todos los archivos generados siguen el patron `YYYY-MM-DD_HHMM-{slug}.{ext}`:

- `YYYY-MM-DD` — fecha local en formato ISO 8601.
- `HHMM` — hora en formato 24h (sin `:`).
- Separador fecha↔hora: guion bajo `_`.
- Separador timestamp↔slug: guion `-`.
- Slug: kebab-case, lowercase, sin acentos, max 50 chars.
- Extension: lowercase, punto antes (`prd.md`, `plan.md`, `report.md`, `audit.md`, `json`).

**Caracteristica comun a TODOS los archivos generados:** llevan timestamp con hora. Esto permite:
- Ordenamiento cronologico estricto (`ls` ordena naturalmente).
- Colisiones improbables (2 archivos el mismo segundo requiere un clock skew).
- Busqueda por fecha simple (`find . -name "2026-06-29_*"`).

### Ejemplos validos

```
2026-06-29_1830-csv-import.prd.md
2026-06-29_1830-csv-import.plan.md
2026-06-29_1830-csv-import.report.md
2026-06-29_1830-csv-import.audit.md
orchestrate-2026-07-14T19-30-27.json
2026-06-29_1830-quick-typo-fix.prd.md
```

### Ejemplos invalidos

```
2026-06-29-csv-import.prd.md          # falta hora
2026-06-29_1830_csv_import.prd.md     # guion bajo en vez de guion
2026-06-29_1830-CSV-Import.prd.md     # mayusculas
2026-06-29_1830-csv-import.PRD.MD     # extension en mayuscula
2026-06-29T18:30:00-csv-import.prd.md # ISO 8601 completo, no usar
```

---

## Patrones por tipo

### PRDs

| Tipo | Patron | Ejemplo |
|------|--------|---------|
| PRD normal | `docs/prds/YYYY-MM-DD_HHMM-{slug}.prd.md` | `2026-06-29_1830-csv-import.prd.md` |
| Quick-PRD | `docs/prds/YYYY-MM-DD_HHMM-quick-{slug}.prd.md` | `2026-06-29_1830-quick-typo-fix.prd.md` |

Slug: max 50 chars, kebab-case, derivado del objetivo.

### Plans

```
docs/plans/YYYY-MM-DD_HHMM-{slug}.plan.md
```

Mismo slug que el PRD origen. Cross-link via frontmatter:

```markdown
---
prd: docs/prds/2026-06-29_1830-csv-import.prd.md
status: DRAFT
created: 2026-06-29_1830
---
```

### Reports

```
docs/reports/YYYY-MM-DD_HHMM-{slug}.report.md
```

Mismo slug que el PRD/plan origen.

### Audits

| Modo | Patron | Ejemplo |
|------|--------|---------|
| Inline (default) | seccion al final del report | (no archivo separado) |
| Separate | `docs/audits/YYYY-MM-DD_HHMM-{slug}.audit.md` | `2026-06-29_1830-csv-import.audit.md` |

Trigger de `--separate`: el user lo pide explicitamente o el auditor detecta que el report es >500 lineas.

### INDEX

```
docs/reports/INDEX.md
```

Unico, sin timestamp. Se regenera en cada `/audit-report` (silent).

### Recovery state

```
docs/state/{command}-{ISO-timestamp}.json
```

Filename = `{command}-{YYYY-MM-DDTHH-MM-SS}.json`. Time part uses hyphens (not colons) for filesystem safety. **Command comes first, timestamp second** — this groups files by command in `ls` output and makes ISO timestamps grep-friendly.

Examples:
```
orchestrate-2026-07-14T19-30-27.json
flow-feature-2026-07-14T19-30-27.json
plan-2026-07-14T19-30-27.json
```

Written by `bin/state.js`. On successful flow completion the file is **removed** (no state = done). On interruption, `/session-start` detects and offers to resume from `currentPhase`.

Schema:

```json
{
  "command": "orchestrate",
  "started": "2026-07-14T19:30:27.000Z",
  "prd": "docs/prds/2026-07-14_1930-csv-import.prd.md",
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

### Sessions

```
docs/sessions/YYYY-MM-DD-{slug}.md
docs/sessions/LATEST.md
```

sessions usan solo fecha (sin hora) porque son humanas, no automatizadas.

### Instincts

```
docs/instincts/YYYY-MM-DD-{slug}.instinct.json
```

Mismo razon: humanos, no automatizados.

### Archive

```
docs/reports/_archive/YYYY/YYYY-MM-DD_HHMM-{slug}.report.md
```

Agrupa por año del archivo (no del movimiento). Preserva el nombre original con timestamp.

---

## Estados consistentes

Todos los archivos con seccion `## Status` usan el mismo enum:

```
DRAFT           — recien creado, no aprobado
IN_PROGRESS     — trabajo en curso
BLOCKED         — esperando algo externo
COMPLETED       — terminado y verificado
ARCHIVED        — fuera de uso activo
```

Usar exactamente estos strings. Variantes como "WIP", "done", "finished" NO se aceptan.

---

## Frontmatter

### Agents

```yaml
---
description: <required>
mode: subagent | primary | all
permission:
  read: allow
  write: allow | ask | deny
  edit: allow | ask | deny
  bash:
    "<comando>": allow | ask | deny
    "*": deny
---
```

### Skills

```yaml
---
name: <kebab-case, requerido>
description: <1-1024 chars, empieza con "Use when...">
---
```

### Commands

```yaml
---
description: <required>
agent: <nombre de agent existente en agents/>
---
```

### Plans (nuevo en 1.0.0)

```yaml
---
prd: docs/prds/{archivo}.prd.md
status: DRAFT | IN_PROGRESS | COMPLETED | BLOCKED
created: YYYY-MM-DD_HHMM
---
```

### Reports (nuevo en 1.0.0)

```yaml
---
prd: docs/prds/{archivo}.prd.md
plan: docs/plans/{archivo}.plan.md
status: DRAFT | IN_PROGRESS | COMPLETED | BLOCKED
created: YYYY-MM-DD_HHMM
audited: YYYY-MM-DD_HHMM  # cuando se audito
verdict: PASS | PASS-WITH-NITS | FAIL | NOT-AUDITED
---
```

---

## Slug rules

- Lowercase siempre.
- Kebab-case (`-` entre palabras, sin espacios ni guion bajo).
- Sin acentos (`cafe` no `café`).
- Sin caracteres especiales (`!@#$%^&*`).
- Verbos primero cuando es accion (`fix-login`, `add-csv-import`, `refactor-parser`).
- Sustantivo cuando es feature (`csv-import`, `auth-jwt`).
- Max 50 caracteres.
- Si el slug crece, cortar las palabras menos importantes. NO abreviar (excepto terminos tecnicos conocidos: `auth`, `db`, `api`, `csv`, `jwt`).

**Bueno:**
- `fix-login-redirect`
- `add-csv-import`
- `refactor-auth-middleware`
- `csv-import-export`

**Malo:**
- `FixLoginRedirect` (PascalCase)
- `fix_login_redirect` (snake_case)
- `fix login redirect` (espacios)
- `fl` (abreviatura extrema)
- `cosa-que-hace-algo-con-csv-y-otras-cosas` (demasiado largo)

---

## Migracion desde versiones < 1.0.0

Los archivos con formato viejo (sin hora, con guion en vez de guion bajo) siguen funcionando. No se renombran automaticamente. Si el user quiere migrar:

```bash
# Renombrar PRDs viejos
for f in docs/prds/*.md; do
  base=$(basename "$f" .prd.md)
  # Si no tiene guion bajo entre fecha y nombre, skip
  echo "$base" | grep -q '_' || echo "Skipping: $f (formato nuevo ya)"
done
```

Esto es opt-in. No hay deadline. Ver `MIGRATION.md` para detalles completos.
