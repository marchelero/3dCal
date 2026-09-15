# PRD: Scroll Continuo con Auto-Step en el Cotizador

**Fecha:** 2026-09-15
**Estado:** Aprobado (usuario solicitó directamente)
**Prioridad:** Alta

## Problema Actual

El wizard de cotización obliga al usuario a hacer clic en "Siguiente" para moverse entre pasos. Esto genera fricción innecesaria cuando el formulario es corto y podría mostrarse todo junto.

## Solución Propuesta

Transformar el wizard de 3 pasos en un **scroll continuo** donde:

1. **Sección única scrolleable**: Los 3 pasos (Pieza, Impresión, Ajustes) se muestran en una sola vista con scroll vertical.
2. **Step bar auto-actualizado**: Al hacer scroll, el step bar refleja automáticamente qué sección está visible.
3. **Secciones colapsables completadas**: Cuando el usuario completa una sección y pasa a la siguiente, la sección anterior se colapsa automáticamente mostrando un check ✓.
4. **Footer simplificado**: Se elimina el footer de navegación (atras/adelante) ya que la navegación es por scroll.

## Criterios de Aceptación

### AC-001: Scroll Continuo
- **Escenario**: Usuario abre el cotizador
- **Acción**: Hace scroll hacia abajo
- **Resultado**: Pasa de la sección "Pieza" a "Impresión" a "Ajustes" sin clics adicionales
- **No debe**: Perder el estado de los campos al hacer scroll

### AC-002: Step Bar Auto-Actualizado
- **Escenario**: Usuario está en la sección "Pieza" (paso 1)
- **Acción**: Hace scroll hasta "Impresión"
- **Resultado**: El step bar marca automáticamente el paso 2 como activo
- **Verificación**: El círculo del paso 2 se resalta con el color primario

### AC-003: Auto-Collapse de Secciones Completadas
- **Escenario**: Usuario completa la sección "Pieza" (peso + filamento llenos)
- **Acción**: Hace scroll hasta "Impresión"
- **Resultado**: La sección "Pieza" se colapsa mostrando solo el título + ✓
- **Verificación**: Al tocar el título colapsado, se expande nuevamente

### AC-004: Navegación por Tap en Step Bar
- **Escenario**: Usuario quiere volver a la sección "Pieza"
- **Acción**: Toca el paso 1 en el step bar
- **Resultado**: Scroll automático a la sección "Pieza"
- **Verificación**: El scroll es suave (smooth scroll)

### AC-005: Compatibilidad con Modo Express/Advanced
- **Escenario**: Usuario cambia de Express a Advanced
- **Acción**: Toca el toggle de modo
- **Resultado**: La sección 1 cambia entre el formulario Express (peso + filamento) y Advanced (materiales múltiples)
- **No debe**: Romper el auto-step o el collapse

### AC-006: Persistencia del Estado
- **Escenario**: Usuario llena peso en paso 1, hace scroll al paso 2
- **Acción**: Vuelve al paso 1 (tap en step bar o scroll up)
- **Resultado**: El peso sigue ahí, no se perdió

## Fuera de Alcance

- Animaciones complejas de transición entre secciones
- Drag-and-drop para reordenar secciones
- Validación por sección (solo validación al final)
- Cambios en la lógica de cálculo

## Technical Notes

- Reemplazar `IndexedStack` por `SingleChildScrollView` con `GlobalKey` por sección
- Usar `ScrollController` + `NotificationListener<ScrollNotification>` para detectar posición
- Mantener `_step` como estado efímero de UI (setState)
- El `CalcWizardStepBar` se mantiene como widget puro (sin cambio de interfaz)
- Se agrega lógica de `isDone` por sección basada en completitud de campos clave
