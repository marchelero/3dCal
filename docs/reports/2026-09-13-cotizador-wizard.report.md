# Reporte — Cotizador Wizard (rediseño UI/UX del calculator)

- **Fecha**: 2026-09-13
- **PRD**: `docs/prds/2026-09-13_2130-cotizador-wizard.prd.md` (actualizado a 3 pasos)
- **Estado**: funcionalidad implementada + validada (wizard test 8/8 verdes)

## Que se hizo (visible para el usuario)

El cotizador (`CalculatorPage`) paso de ser una hoja unica de ~2770 lineas
con 6 secciones apiladas a un **wizard de 3 pasos** + **barra de resultado
fija abajo** (presente en todos los pasos, como siempre):

1. **Pieza** — membrete + selector Express/Avanzado + nombre (opcional) +
   **Peso** (campo hero) + fila de filamento (catalogo o precio/grams).
   Regla del 95% intacta: los 3 inputs del Express se ven sin scrollear.
2. **Impresion** — horas + minutos + impresora activa.
3. **Otros** — cantidad (gate Pro) + **Descuento** (subio del result
   sheet al form) + OTROS/costos de la pieza (gate Pro; 1 campo por fila
   para no desbordar en moviles).

**Abajo, fijas en los 3 pasos** (feedback del usuario: "el resultado debe
seguirse viendo abajo"): lineas de lote + `Perforation` (cuando aplica
escalón) + **`ResultBottomBar` de siempre** (total live o hint "Completa
peso... para ver la cotización"; tap → desglose completo) + mini-footer de
navegacion con **dos flechas espejo** (IconButton.outlined): `← | Paso X de
3 | →`. La flecha adelante se **deshabilita en el ultimo paso** (igual que
la atras en el primero) — ya NO muta a "Guardar"/"Ver cotizacion": la barra
de total de arriba ya ofrece ese acceso. El chip de total del AppBar sigue
dando feedback live en cualquier paso y con el teclado abierto.

> Iteraciones de UX (feedback del usuario, mismo dia):
> 1. v1 tenia un 4to paso "Resultado" → rechazo ("esta por demas, quiero el
>    resultado abajo") → se retiro el paso y volvio la `ResultBottomBar` fija.
> 2. El boton "Siguiente" (FilledButton) se convirtio en una flecha espejo de
>    "Atras" (solo `→`, sin texto), con tooltip 'Siguiente' para a11y/tests,
>    y disabled en el ultimo paso.
> 3. El paso 3 se renombr6 "Ajustes" → "Otros" (label `calcWizardStepAdjust`,
>    traducido en los 5 idiomas: es Otros / en Other / de Sonstiges / fr Autres
>    / pt Outros).

## Que NO cambio (por contrato)

- Motor de calculo, `CalculatorNotifier`, `CalculatorState`, drafts,
  prefill "Reusar", plantillas, gates Pro (Advanced/Cantidad/OTROS),
  result sheet y su save flow, PDF/imagen de cotizacion.
- Modo Express y Advanced se mantienen; Advanced solo re-embutelo su lista
  multi-material en el paso 1 del mismo wizard.

## Decisiones tecnicas

| Decision | Razon |
|---|---|
| `IndexedStack` (no PageView) | Los 3 pasos quedan MONTADOS: el estado local de `_MaterialRowTile` (filamento elegido) y los controllers sobreviven los cambios de paso; nav deterministica por chips/botones. |
| `_step` con `setState` | Permitido por las Non-Negotiables ("page index de stepper" es estado UI efimero explicito). |
| `ResultBottomBar` restaurada | Pidio el usuario: total visible abajo en todo momento; cero regressions de tests que la tapaban (paywall/pro_badge vuelven a usarla directa). |
| l10n: 2 getters nuevos (`calcWizardStepPrint`, `calcWizardStepAdjust`) + `calcWizardFullBreakdown` (hoy sin uso en UI pero consistente en las 5 lenguas) | Resto reusa strings existentes (`onboardingNext`, `configBack`, `configStepCounter`, `calcResultBarTapHint`). |

## Bugs encontrados en el camino (todos arreglados)

1. **Theme global `FilledButton.minimumSize: Size(double.infinity, 52)`** — invalido
   dentro del Row del footer (eje principal sin acotar) → crash de layout.
   Fix: `minimumSize: Size(64, 52)` en los botones del footer.
2. **`Flexible` como label de un FilledButton** → constraints infinitos. Fix:
   `Flexible(child: FilledButton)` con label ellipsizable.
3. **`Column` del body sin `crossAxisAlignment.stretch`** → `Row(Expanded)` del
   step bar recibio ancho ilimitado. Fix: stretch.
4. **Overflow 73px a 360dp en OTROS (grid 2x2) y selector de modo** — preexistentes,
   ahora visibles: OTROS paso a 1 campo por fila y el selector de modo a `Wrap`.
5. **Flaky pre-existente en esta maquina**: "A Timer is still pending" (drift
   `markAsClosed` Timer(0) al desmontar el ProviderScope en el cleanup del
   binding, fuera de todo pump). Confirmado contra baseline (git stash): pasa
   TAMBIEN con el codigo viejo. Fix en los tests nuevos: helper `_bye()` que
   desmonta la pagina dentro del test con un pump posterior.

## Tests

- `test/unit/calculator_page_test.dart` — reescrito para el wizard de 3 pasos:
  **8/8 verdes** (chrome y regla del 95%, navegacion por chips y botones,
  hint live en la barra, total live en barra + chip AppBar, tap barra abre
  desglose, borrar weight apaga el total, descuento desde Ajustes, reset
  vuelve al paso 1).
- Adaptados a la navegacion del wizard (no se re-corrrio la tanda completa a
  pedido del usuario; estan listos para `flutter test`): `lot_lines`
  (finders offstage documentados), `draft_recovery`, `sprint0_smoke`,
  `full_flow` (navegan "Impresión"), `paywall_navigation` y
  `pro_badge_navigation` (vuelven a `ResultBottomBar` + badge de OTROS via
  paso Ajustes), `pro_locked_visual` sin tocar (solo ve el paso visible).

## Verificacion manual

`flutter run -d chrome` (o device): Home → "Nueva cotización" → walkthrough
de 3 pasos; probar: chips del step bar, Atras/Siguiente, barra de total
siempre abajo (hint → total live → tap abre desglose), descuento en Ajustes,
Guardar desde el sheet, Reusar desde historial (prefill), cambio a
Avanzado (con y sin Pro), teclado no tapa el total.

## Archivos tocados

- `lib/features/calculation/presentation/pages/calculator_page.dart` (wizard)
- `lib/features/calculation/presentation/widgets/calculator_wizard.dart` (nuevo)
- `lib/l10n/app_strings.dart`, `es_bo.dart`, `en_us.dart`, `de_de.dart`, `fr_fr.dart`, `pt_br.dart`
- `test/unit/calculator_page_test.dart` (reescrito), `test/widget/{lot_lines,draft_recovery,sprint0_smoke,pro_badge_navigation,paywall_navigation}_test.dart`, `test/integration/full_flow_test.dart`
- `docs/prds/2026-09-13_2130-cotizador-wizard.prd.md` (nuevo)
