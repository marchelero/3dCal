# PRD: UI Visual Enhancement — 3dCalc

> **Fecha**: 2026-07-18
> **Estado**: Aprobado
> **Version**: 1.0
> **Audiencia**: Implementacion fase por fase

---

## 1. Resumen Ejecutivo

Mejorar la UI/UX de 3dCalc (Flutter, calculadora de precios 3D) de un estado actual **7/10** a **9/10**. El proyecto tiene base solida (M3 theme, tokens semanticos, shared widgets) pero adolece de micro-interacciones pobres, calculator sobrecargado, skeletons sub-utilizados, catalogos planos, y falta de animaciones profesionales.

**Plan**: 5 fases, ~18.5h estimadas.

---

## 2. Estado Actual

| Area | Puntaje | Problema principal |
|------|---------|-------------------|
| Theme system | 9/10 | M3 completo, OK |
| Shared widgets | 8/10 | LoadingView usa spinner, debria usar skeletons existentes |
| Home Page | 7/10 | Error state inconsistente, sin entrada animada |
| Calculator | 5/10 | 13 controllers, sin feedback de calculo, OTROS sin SectionHeader |
| History | 8/10 | Loading usa spinner (no skeleton), filter state local |
| Dashboard | 8/10 | Legendas hardcodeadas, "Bs." fijo, sin pull-to-refresh |
| Settings | 8/10 | CurrencyPicker sin search, loading/error states pobres |
| Catalogos | 6/10 | Sin skeletons, ListTile plano, sin busqueda |
| Onboarding | 7/10 | Solo iconos, sin imagenes, fondo plano |
| Splash | 6/10 | Sin errorBuilder, fondo solido #0D0D0D |
| Navigation shell | 9/10 | Responsive, cross-fade, gradiente |
| Micro-interacciones | 4/10 | Solo staggered list + cross-fade tabs |

**Hallazgos clave del audit**:
- `LoadingView` se usa en 5 paginas donde ya existe `ListPageSkeleton`
- Calculator tiene 13 TextEditingControllers + collapsable OTROS sin icono
- Chart Y-axis hardcodea "Bs." en vez de `currency.symbol`
- 0 hero transitions, 0 shared element transitions
- `Semantics` ausente en HomePage, CalculatorPage, Splash

---

## 3. Roadmap: 5 Fases

### Fase 1: Quick Wins (~1h)
Fixes inmediatos de consistencia visual.

| ID | Tarea | Archivos | Esfuerzo |
|----|-------|----------|----------|
| 1.1 | Reemplazar LoadingView por ListPageSkeleton en History | `calculations_list_page.dart` | 15min |
| 1.2 | Reemplazar LoadingView por skeleton en Catalog | `filaments_page.dart`, `printers_page.dart` | 15min |
| 1.3 | Home error state → usar ErrorView | `home_page.dart` | 5min |
| 1.4 | Settings loading/error → usar LoadingView/ErrorView | `settings_page.dart` | 10min |
| 1.5 | Fix icono share Android | `calculation_detail_page.dart`, `result_sheet.dart` | 5min |
| 1.6 | Fix "Bs." hardcode en chart Y-axis | `profit_bar_chart.dart` | 5min |
| 1.7 | Chart legends → EsBO strings | dashboard chart files | 10min |
| 1.8 | errorBuilder en splash logo | `splash_screen.dart` | 5min |
| 1.9 | Bottom padding Detail page dinámico | `calculation_detail_page.dart` | 5min |

**Criterio de exito**: Todas las paginas usan skeletons (no spinners) para loading. Error states consistentes. Sin hardcode de moneda ni strings.

---

### Fase 2: Calculator UX (~3h)
El corazon de la app. Subir de 5/10 a 7/10.

| ID | Tarea | Archivos | Esfuerzo |
|----|-------|----------|----------|
| 2.1 | AnimatedSwitcher en ResultBottomBar al cambiar total | `result_sheet.dart` | 30min |
| 2.2 | OTROS collapsable: SectionHeader con icono `tune_rounded` | `calculator_page.dart` | 20min |
| 2.3 | Validacion visual: icono check verde en campos completos | `numeric_input_field.dart` | 45min |
| 2.4 | Keyboard avoidance: resizeToAvoidBottomInset + viewInsets | `calculator_page.dart` | 20min |
| 2.5 | Compactar hint de bottom bar (badge "Falta: peso") | `result_sheet.dart` | 30min |
| 2.6 | MaterialRowTile responsive (Wrap/LayoutBuilder) | `calculator_page.dart` | 30min |
| 2.7 | Mode selector unico fuera del scroll | `calculator_page.dart` | 15min |

**Criterio de exito**: El total se anima al cambiar. El form es scrolleable sin perderse. Los campos validos muestran check. Layout no se rompe en <360dp.

---

### Fase 3: Animaciones y Micro-interacciones (~4h)
Subir de 4/10 a 7/10.

| ID | Tarea | Archivos | Esfuerzo |
|----|-------|----------|----------|
| 3.1 | Staggered entrance en Home stats y quick actions | `home_page.dart` | 45min |
| 3.2 | Staggered entrance + chart animateFromZero en Dashboard | `dashboard_page.dart` | 45min |
| 3.3 | Hero transition History→Detail | `calculations_list_page.dart`, `calculation_detail_page.dart` | 1h |
| 3.4 | Pull-to-refresh en Dashboard | `dashboard_page.dart` | 20min |
| 3.5 | Hover states en web (NavigationRail, botones) | `app_scaffold.dart`, theme | 30min |
| 3.6 | Transicion splash→app con fade | `splash_screen.dart`, router | 30min |

**Criterio de exito**: Las paginas tienen entrada animada. History→Detail tiene hero transition. Dashboard tiene pull-to-refresh. Web tiene hover states.

---

### Fase 4: Catalogos y Forms (~4.5h)
Subir catalogos de 6/10 a 8/10.

| ID | Tarea | Archivos | Esfuerzo |
|----|-------|----------|----------|
| 4.1 | Search + filter chips en Filamentos | `filaments_page.dart` | 45min |
| 4.2 | Search + filter chips en Impresoras | `printers_page.dart` | 45min |
| 4.3 | Card design en listas de catalogo (vs ListTile) | `filaments_page.dart`, `printers_page.dart` | 1h |
| 4.4 | CurrencyPicker con search dialog + flags | `settings_page.dart`, `initial_config_page.dart` | 1.5h |
| 4.5 | Delete con Undo SnackBar (4s timer) | `confirm_dialog.dart`, callers | 45min |

**Criterio de exito**: Catalogos tienen busqueda y filtros. CurrencyPicker tiene search. Delete tiene undo.

---

### Fase 5: Polish y Accesibilidad (~6h)
Subir a 9/10.

| ID | Tarea | Archivos | Esfuerzo |
|----|-------|----------|----------|
| 5.1 | Agregar Semantics en HomePage, CalculatorPage, Splash | multiples | 1.5h |
| 5.2 | Splash con gradiente (vs fondo solido) | `splash_screen.dart` | 30min |
| 5.3 | Onboarding con ilustraciones/imagenes | `onboarding_page.dart` | 2h |
| 5.4 | Refactor duplicacion SummaryCard/QuoteImageTemplate | `summary_card.dart`, `quote_image_template.dart` | 1h |
| 5.5 | textScaleFactor testing + fixes | multiples | 1h |

**Criterio de exito**: Screen readers navegan toda la app. Splash y onboarding tienen branding visual. Sin codigo duplicado en widgets de cotizacion.

---

## 4. Principios de Diseno

### Paleta existente (mantener)
- **Seed**: `#1B4D7A` (azul tecnico)
- **Accent (secondary)**: `#E67E22` (naranja PLA)
- **Tertiary**: `#1A8A7A` (verde teal)
- **Success**: `#2ECC71`
- **Error**: `#E74C3C`
- **Tipografia**: Inter (texto) + JetBrains Mono (cifras)

### Tokens existentes (mantener)
- `AppSpacing` (2-32dp, grid 4dp)
- `AppRadii` (4-20px + pill 999)
- M3 tonal surface containers

### Nuevos patrones a introducir
- **Skeleton en todas las listas** (ya existe `SkeletonWidget`)
- **Staggered entrance** en todas las paginas principales
- **Hero transitions** entre listas y detalles
- **Undo SnackBar** en operaciones destructivas
- **Search + filter** en catalogos

---

## 5. Arquitectura

### No breaking changes
- Ninguna tarea cambia providers, DAOs, o logica de negocio
- Solo tocan archivos de `presentation/` y `shared/widgets/`
- Los cambios son aditivos o sustitutivos (reemplazar spinner por skeleton)

### Shared widgets a crear/modificar
- `LoadingView` → que use skeleton si hay uno disponible
- `SectionCard` → permitir collapsable mode (para Fase 2.2)
- `NumericInputField` → agregar `showSuccessIcon` (Fase 2.3)

### Testing
- Verificar visualmente cada cambio (sin tests automatizados de UI por ahora)
- `flutter analyze` debe pasar sin nuevos warnings
- `flutter test` debe pasar sin cambios en tests existentes

---

## 6. Riesgos

| Riesgo | Probabilidad | Mitigacion |
|--------|-------------|------------|
| Calculator refactor (2.6) rompe inputs | Baja | Cambios son solo layout responsive, no logica |
| Hero transition rompe navegacion | Baja | Probar en mobile + web antes de commit |
| CurrencyPicker search dialog muy grande | Media | Paginar resultados, search con debounce 300ms |

---

## 7. Aprobacion

Plan aprobado. Ejecucion fase por fase, cada fase con su propio checkpoint de revision.
