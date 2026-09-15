# PRD — Cotizador Wizard (rediseño UI/UX del calculator)

- **Fecha**: 2026-09-13
- **Estado**: aprobado por usuario (chat: "rediseño UI/UX, wizard por pasos, mantener Express/Advanced")
- **Revision (mismo dia, post-entrega v1)**: el usuario vio el wizard de 4
  pasos y rechazo el paso "Resultado" ("esta por demas, el resultado debe
  seguir viendose abajo") → **el resultado dejo de ser paso y la
  `ResultBottomBar` fijo volvio al pie de los 3 pasos**. El wizard quedo en
  3 pasos (Pieza | Impresion | Ajustes) + barra de total fija + mini-footer
  de navegacion (Atras | Paso X de 3 | Siguiente / Ver cotizacion).
- **Componente**: `lib/features/calculation/presentation/pages/calculator_page.dart` (monolito actual, 2770 líneas, layout de cards apiladas con scroll largo)

## Problema

El cotizador actual es una sola hoja con 6+ secciones apiladas (Pieza+Material, Tiempo, Impresora, Cantidad, OTROS):
scroll largo, campos clave diluidos, la seccion OTROS escondida detras un collapsable, y el resultado vive solo en una barra inferior. El usuario pide reformularlo "de forma diferente, que se note mejor".

## Decisiones (del usuario)

1. **Alcance**: rediseño UI/UX. La logica de negocio (notifier, engine, drafts, gates Pro) NO cambia.
2. **Formato**: wizard por pasos (stepper).
3. **Modos**: se mantienen Express y Advanced; el wizard se adapta a cada modo.

## Diseño nuevo

Wizard de 4 pasos dentro de `CalculatorPage` (misma ruta, mismo AppBar, mismo draft/prefill/gates):

| Paso | Express | Advanced |
|---|---|---|
| 1 Pieza | membrete + mode selector + nombre pieza + **Peso (g)** (hero) + fila filamento (catalogo o precio/gramos) | membrete + mode selector + nombre pieza + lista multi-material (AnimatedList) + Agregar |
| 2 Impresion | Horas + Minutos + impresora activa (selector) | identico |
| 3 Ajustes | Cantidad (gate Pro) + **Descuento %** (sube desde el result sheet al form) + Costos de la pieza/OTROS (gate Pro) | identico |
| 4 Resultado | total grande (lotTotal), precio unitario si N>1, lineas de lote (batch), hint de campos faltantes con CTA "Completar campos" que salta al paso correspondiente, botones "Guardar cotizacion" y "Ver desglose completo" (result sheet existente) | identico |

Chrome del wizard:
- **Step bar** arriba del body: 4 chips numerados + label; el activo filled; tap = salto libre (nav de testeabilidad y UX).
- **Footer bar** (reemplaza `ResultBottomBar`): `Atras` (outlined, disabled en paso 1) | centro: hint de validacion cuando el form es incompleto ("Completa peso... para ver la cotizacion" — mismo builder existente) o contador "Paso X de Y" | derecha: `Siguiente` (filled) en pasos 1–3, `Guardar cotizacion` en paso 4.
- El chip de total del AppBar (`_TotalChip`) se mantiene: feedback live en todos los pasos (no rompe regla 95%: el paso 1 muestra los 3 inputs hero del Express).
- Transicion entre pasos: `IndexedStack` (todos los pasos montados → sin perder foco/estado local de `_MaterialRowTile` ni re-montar AnimatedList; sin swipe manual: la nav es por botones/chips).

## Fuera de scope

- Cambios al motor de calculo, notifier, estado, drafts, persistencia, PDF/imagen de cotizacion, result sheet (solo se abre desde el paso 4).
- Navegacion fisica con botones del sistema, animaciones de page-slide.
- Eliminar Express/Advanced o fusionarlos.

## Impacto tecnico

- `calculator_page.dart`: `build()` pasa a armar step bar + IndexedStack + footer; los 2 mega-forms se partizan en 8 step-builders privados (mismos controllers/listeners intactos). `_step` es `setState` local (permitido por Non-Negotiables: "page index de stepper").
- Nuevo archivo `widgets/calculator_wizard.dart`: `CalcWizardStepBar` + `CalcWizardFooter` (Stateless/Consumer widgets puros).
- l10n: 6 getters nuevos (`calcWizardStepPrint`, `calcWizardStepAdjust`, `calcWizardStepResult`, `calcWizardFixMissing`, `calcWizardFullBreakdown`, `calcWizardUnitSuffix`) en `AppStrings` + facade `EsBO` + 5 impls.

## Criterios de aceptacion

- [ ] AC-1: Al abrir el cotizador se ve el paso 1 (Pieza) con nombre opcional, Peso y fila de filamento; sin scrollear se puede completar el input hero.
- [ ] AC-2: El step bar muestra 4 pasos con contador "Paso X de Y"; tap en chip salta a ese paso; Atras/Siguiente navegan.
- [ ] AC-3: Con form incompleto, el footer muestra el hint "Completa ... para ver la cotizacion" y el paso 4 lista los faltantes con CTA que salta al paso correcto.
- [ ] AC-4: Con form valido, el total live aparece en el chip del AppBar en cualquier paso; el paso 4 muestra total grande + lineas de lote si hay escalon + precio unitario cuando N>1.
- [ ] AC-5: Guardar (footer paso 4 o result sheet) funciona igual que hoy: _SaveSheet, historial, plantillas, history cap, snackbar "Ver".
- [ ] AC-6: Draft restore, prefill "Reusar", template apply y reset siguen sincronizando todos los controllers (comportamiento actual, sin regresion).
- [ ] AC-7: Gates Pro intactos: Advanced bloqueado en free (SnackBar + Go Pro), Cantidad/OTROS con ProBadge + paywall; memberte/sin cambios de calculo.
- [ ] AC-8: Modo Advanced: paso 1 muestra la lista multi-material con Agregar/Eliminar; el resto de pasos es comun.
- [ ] AC-9: `flutter analyze` sin nuevos warnings; `dart format` limpio; suite de tests verde (se adaptan los tests de layout que asumian una sola pantalla).

## Test plan

- Ajustar `test/unit/calculator_page_test.dart` (hint unico en footer), `test/widget/lot_lines_test.dart` (lineas batch ahora en paso 4 — montadas via IndexedStack, verificar), `test/widget/pro_locked_visual_test.dart` y `quote_save_flow_test.dart` (taps que requieren cambiar de paso con el step bar).
- Nuevos widget tests del wizard: avance/retroceso por botones, salto por chip, CTA "Completar campos" aterriza en el paso del campo faltante.
