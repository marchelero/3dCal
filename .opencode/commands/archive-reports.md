---
description: "Archiva reports viejos a .opencode/reports/_archive/. NO borra, solo mueve. Use when .opencode/reports/ tenga >20 archivos o antes de un commit grande para mantener el directorio limpio."
agent: build
---

# Archive Reports Command

Mover reports viejos a archivo: $ARGUMENTS

## Tu Task

### Sin argumentos (modo default)

Archivar reports con >30 dias de antiguedad Y status `COMPLETADO`.

```
for each .opencode/reports/*.md:
  if status == "COMPLETADO" and mtime < (now - 30d):
    move to .opencode/reports/_archive/{YYYY}/  (por año del archivo)
    log: "[archivo] movido a _archive/YYYY/{name}.report.md"
```

NO archivar:
- Reports con status `EN PROGRESO` o `BLOQUEADO`.
- Reports con veredicto `FAIL` en seccion Auditoria (aun requieren atencion).
- Reports con `## Auditoria` modificado en los ultimos 14 dias (trabajo reciente).

### Con argumento `--older-than {Nd}`

Archivar reports mas viejos que N dias (cualquier status excepto FAIL).

Ejemplo: `/archive-reports --older-than 60d` mueve todo >60 dias.

### Con argumento `--all-completed`

Archivar TODOS los reports con status COMPLETADO sin importar antiguedad.

### Con argumento `--dry-run`

Solo listar lo que se moveria. NO mover nada.

## Comportamiento

1. Crear `.opencode/reports/_archive/{YYYY}/` si no existe.
2. Para cada candidato a archivar:
   - Verificar que NO esta abierto (no se esta editando).
   - Mover con `mv` (preservar mtime con `mv -p` si la version lo soporta).
3. Actualizar `.opencode/reports/INDEX.md` (quitar los movidos, agregar linea "Archivados: N en YYYY/").
4. Reportar al usuario:
   ```
   Archivados: N reports
   Destino: .opencode/reports/_archive/{YYYY}/
   
   Lista:
   - {name}.report.md ({dias}d, status: COMPLETADO)
   - ...
   
   rollback? (s/n) — los archivos siguen aca, faciles de restaurar
   ```

5. Si el user dice `s` rollback: `mv _archive/YYYY/*.report.md .opencode/reports/`. Solo si estan en la misma sesion.

## Garantias

- **NUNCA** se borra un archivo. Solo se mueve.
- **NUNCA** se mueve un archivo abierto o modificado en los ultimos 14 dias.
- **NUNCA** se mueven reports con veredicto FAIL.
- El INDEX siempre se regenera despues del archive.

## Cuando correr

- Cada 1-2 meses cuando `.opencode/reports/` tenga >20 archivos.
- Antes de un commit grande (limpiar el directorio).
- Cuando el user dice "limpia reports" / "archiva lo viejo" / "los reports estan muchos".
