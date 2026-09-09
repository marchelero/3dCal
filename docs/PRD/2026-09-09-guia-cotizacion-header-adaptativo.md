# PRD: Guía paso a paso de la cotización + AppBar adaptativo

**Fecha**: 2026-09-09
**Estado**: Aprobado (usuario validó formato y solución en Q&A)
**Scope**: UI (Flutter), i18n 6 idiomas, tests widget

## Problema

1. No existe una guía que explique al usuario cómo funciona una cotización
   (flujo completo: modo → materiales → impresora → tiempo → extras →
   descuento → resultado → guardar/compartir/historial).
2. El AppBar de la pantalla Cotización (`calculator_page.dart`) carga hasta 6
   elementos: `[X cerrar] [título] [chip total] [ayuda] [plantillas] [reset]
   [ajustes]`. En pantallas angostas (teléfono) desborda; agregar un nuevo
   icono de guía lo empeoraría.

## Decisiones (validadas por el usuario)

- **Guía**: modal de pasos deslizables (estilo onboarding existente:
  PageView + dots + botón Siguiente). Nada de coach marks.
- **Header**: patrón adaptativo con menú `⋮` — iconos directos si hay ancho;
  colapsa los secundarios a un menú overflow en pantallas chicas. Se aplica a
  toda la app (todas las pantallas con AppBar), no solo cotización.

## Entregables

### 1. Guía paso a paso de la cotización
- Nuevo widget reutilizable tipo modal (dialog/bottom sheet): "Cómo funciona
  la cotización".
- Pasos (5-6 páginas), texto i18n en los 6 locales:
  1. Elegí modo Express (rápido, 3 campos) o Avanzado (control total).
  2. Material: elegí filamento del catálogo o ingresá precio/gramos.
  3. Impresora activa (velocidad/costos de la impresora).
  4. Tiempo de impresión (horas/minutos).
  5. Extras opcionales: mano de obra, post-procesado, fallas, mínimo, markup.
  6. Resultado: total en vivo, descuento, guardar cotización, compartir/PDF,
     historial + dashboard.
- Punto de entrada: ítem en el menú `⋮` de la pantalla Cotización (y visible
  como icono directo `help` si hay ancho).

### 2. AppBar adaptativo (`SmartAppBarActions`)
- Nuevo widget shared: `lib/shared/widgets/smart_app_bar_actions.dart`.
- API sugerida: recibe `actions` (widgets siempre visibles / de alta
  prioridad) + `overflowItems` (PopupMenuItem) + `leading?`; usa
  `LayoutBuilder` + `MediaQuery` para decidir colapso.
- Comportamiento:
  - Ancho suficiente (≥ umbral, ej. ~400-500dp): muestra todo directo.
  - Angosto: muestra solo prioridad alta; el resto en `PopupMenuButton`
    (`Icons.more_vert`).
  - Sin overflow nunca (RenderFlex overflow eliminado).
- Aplicar en: `calculator_page.dart` (reemplazar los 4 iconos + chip total
  con el patrón; chip total siempre visible), `calculations_list_page.dart`,
  `filaments_page.dart`, `printers_page.dart`, `settings_page.dart`,
  `dashboard_page.dart`, `calculation_detail_page.dart` (revisar cuáles
  aplican; no tocar AppBars triviales de 1 acción si no hay riesgo).

### 3. i18n
- Agregar strings nuevos a `lib/l10n/app_strings.dart` (interfaz) y a los 6
  locales: `es_bo.dart`, `en_us.dart`, `pt_br.dart`, `fr_fr.dart`,
  `de_de.dart`.
- Prefijo sugerido: `quoteGuide*` (título, subtítulo, pasos 1-6, botones
  Siguiente/Cerrar, ítem de menú "Guía" / tooltip).

### 4. Tests
- Widget test del modal de guía (abre, pagina, cierra, textos i18n).
- Widget test del `SmartAppBarActions` (ancho angosto → menú; ancho amplio →
  iconos directos; sin overflow en 320dp).
- Ajustar tests existentes si el AppBar de calculator cambia.

## Criterios de aceptación

1. Desde Cotización se puede abrir la guía y recorrer todos los pasos.
2. En 320dp de ancho no hay overflow en ningún AppBar con el patrón aplicado.
3. En web/tablet (≥ umbral) los iconos se ven directos (sin menú).
4. Los 6 idiomas compilan (dart analyze limpio).
5. `flutter test` verde (incluidos los nuevos tests).

## No-goals

- No coach marks / spotlight overlay.
- No cambios de lógica de cálculo.
- No tocar onboarding existente (reusar su patrón visual, no su ruta).