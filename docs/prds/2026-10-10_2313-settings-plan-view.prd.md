# PRD — Vista comparativa de plan (Gratis / Pro) en Settings

**Fecha:** 2026-10-10 · **Estado:** DRAFT (rev v2 — implementado, pendiente cierre)
**Base:** `main` @ `f5fb310` · Flutter mobile/web · local/offline · Drift schema 17 · cinco locales.
**Origen:** pedido del dueño — "cuando vas a Configuración y ves lo de Pro siento que falta algo; me gustaría que esté más claro qué da Gratis y qué da Pro, en todos los idiomas".

## Revisión v2 (feedback del dueño)

La **v1** implementó un **card comparativo** embebido en Settings (Grupo "Plan"
arriba de Empresa). Feedback: *"quedó muy largo, ocupa toda la pantalla y tapa
el resto… me gustaría que sea una opción clickeable que diga Plan y al tocarla
se vea el detalle"*.

**v2 (este documento):** la sección "Plan" es una **fila compacta** (una sola
línea) que abre un **bottom sheet** con el comparador completo. Decisión
confirmada con el dueño:
- Formato: **fila compacta → bottom sheet** (NO un `switch`/segmented; el plan
  lo determina la compra, no un toggle).
- Detalle (dentro del sheet): **ambas listas** (Gratis + Pro) visibles juntas.

## Contexto

Hoy la información Pro/Free en Settings estaba dispersa y no se explicaba por
sí sola (`ProActiveBadge`, `ProBadge` sobre Empresa, botón Restaurar). No había
un lugar único que mostrara, en contraste, **qué incluye Gratis** y **qué
incluye Pro**. El objetivo se mantiene; cambia el **formato** para no ocupar la
pantalla.

## Objetivo

Mostrar el estado actual (Gratis o Pro) y las dos listas de features (Gratis y
Pro) en un **bottom sheet** abierto desde una **fila compacta "Plan"** al inicio
de Settings, localizado, **sin cambiar** la lógica de entitlement ni los gates.

## Decisión de diseño (v2)

1. **Fila** (`ListTile`) en un `SettingsCard`, arriba de Empresa:
   `IconBadge` + título `settingsPlanSectionTitle` ("Plan") + subtítulo con el
   estado actual (`settingsPlanStatusFree`/`settingsPlanStatusPro`) si el
   entitlement ya resolvió + chevron. Al tocar → bottom sheet.
2. **Bottom sheet** (patrón `showProSheet`: `isScrollControlled`, `useSafeArea`,
   `showDragHandle`): cabecera con icono + estado + **badge**; si free, CTA
   "→ /paywall"; si Pro, mensaje "Ya tienes PRO". Luego lista **Gratis** y
   subsección **Pro** ("Todo lo de Gratis, y además:").
3. Durante `loading` no se muestra estado (ni en la fila ni en el sheet).
4. Copy en es / en / pt-br / fr / de (paridad forzada por
   `test/unit/l10n_parity_test.dart`).

## Matriz real Free vs Pro (verificada en código)

| Feature | Gratis | Pro |
|---|---|---|
| Calculadora single-material (modo express) | ✓ | ✓ |
| Parámetros F1 (mano de obra, post-proceso, falla, markup, mínimo) | ✓ | ✓ |
| Catálogo de filamentos | hasta 5 | ilimitado |
| Catálogo de impresoras | hasta 2 | ilimitado |
| Historial de cotizaciones | hasta 10 | ilimitado |
| Export PDF | ✓ (con marca "3dCalc") | ✓ (sin marca) |
| Branding custom (nombre + logo de empresa) | — | ✓ |
| Cotizaciones multi-material (modo avanzado) | — | ✓ |
| Costos adicionales (panel) | — | ✓ |
| Export CSV | — | ✓ |
| Backups (exportar/importar) | — | ✓ |
| Dashboard | básico (totales) | avanzado (charts, top materiales) |
| Cambio de moneda | ✓ | ✓ |
| Tema claro/oscuro | ✓ | ✓ |

Constantes de referencia: `kFreeHistoryCap = 10` (`lib/core/constants/app_constants.dart:130`), `_kFreeFilamentLimit = 5` (`filaments_page.dart:24`), `_kFreePrinterLimit = 2` (`printers_page.dart:22`).

## Success Criteria

- [ ] **SC1**: Existe una **fila "Plan"** visible en Settings (cuando el entitlement resolvió, muestra su estado).
- [ ] **SC2**: El estado mostrado (fila y sheet) es correcto según `isProProvider`.
- [ ] **SC3**: El sheet muestra el CTA "→ /paywall" solo si el usuario es free.
- [ ] **SC4**: Las listas Gratis y Pro del sheet reflejan la matriz verificada, sin features inventadas.
- [ ] **SC5**: El copy está en los 5 idiomas con paridad (test de paridad verde).
- [ ] **SC6**: No hay regresión en los gates existentes (suite completa verde).
- [ ] **SC7**: Durante `loading` no se muestra un estado incorrecto (no falso "Gratis" en cold start).
- [ ] **SC8**: La fila compacta ocupa **una sola línea** (no tapa el resto de Settings).

## Criterios de aceptación

- **AC-001 (P1):** Settings renderiza una **fila compacta** "Plan" (`ListTile`) ubicada antes de la sección Empresa; su subtítulo refleja el plan actual cuando el entitlement resolvió. (v1 pedía un card con `GroupLabel`; v2 lo reemplaza.)
- **AC-002 (P1):** El estado refleja `isProProvider` (`settingsPlanStatusPro` si `true`, `settingsPlanStatusFree` si `false`) tanto en la fila como en el badge del sheet; sin estado mientras `entitlementNotifierProvider.isLoading`.
- **AC-003 (P1):** Al tocar la fila se abre un bottom sheet con el comparador. Con usuario free el sheet muestra un CTA "→ /paywall"; con Pro no se muestra y aparece "Ya tienes PRO".
- **AC-004 (P1):** El sheet lista las features Gratis y, en la subsección Pro, el encabezado "Todo lo de Gratis, y además:" seguido de las features Pro-only, coherentes con la matriz.
- **AC-005 (P1):** Todas las cadenas nuevas existen en `app_strings.dart` (abstract), `es_bo.dart` (`EsImpl` + facade), `en_us.dart`, `pt_br.dart`, `fr_fr.dart`, `de_de.dart`, con paridad; `test/unit/l10n_parity_test.dart` pasa.
- **AC-006 (P1):** Regresión: la suite completa sigue verde; `flutter analyze` sin issues.
- **AC-007 (P2):** El estado `loading` no muestra estado ni badge ni CTA (evita falso "Gratis" en cold start).
- **AC-008 (P3):** Accesibilidad: el badge expone semántica legible; las listas usan `Icon` + `Text`.

## Fuera de alcance

- Cambiar gates, límites o lógica de entitlement.
- Rediseñar el paywall (`/paywall`) o la hoja de beneficios (`ProSheetBody`).
- Nuevos idiomas más allá de los 5 existentes.
- Precios, tiers nuevos, suscripciones.

## Supuestos

- A1: Los límites free (5 filamentos / 2 impresoras / 10 historial) siguen vigentes.
- A2: El CTA reutiliza la navegación existente a `/paywall` (mismo patrón que `settingsGoProAction`).
- A3: No se requiere una fuente de datos nueva; el estado sale de `isProProvider` y `entitlementNotifierProvider`.

## Verificación requerida

- Widget test nuevo `test/widget/settings_plan_test.dart` cubriendo: fila presente + orden antes de Empresa, estado free vs pro, apertura del sheet, CTA solo en free, navegación a `/paywall`, y estado loading.
- Test de paridad l10n para las claves nuevas.
- `flutter analyze`, `flutter test`, `flutter build web`.
- Revisión especializada antes de cerrar; actualizar `docs/reports/` y `docs/audits/`.
