# PRD — Costos de la pieza: lotes, insumos y servicios (diseño/pintado)

> Fecha: 2026-09-13 · Estado: DRAFT — pendiente de aprobación y handoff a `/plan`.
> Idioma del documento y de la UI: **español neutro (es_BO)** — sin voseo, sin regionalismos.
> Fuentes de contexto: `docs/PROJECT.md`, `PRODUCT.md`, `docs/prds/PRD-v2-features-taller.md` (F2 y F11), código actual de `calculation/` y `settings/`.

---

## 1. Resumen ejecutivo

### 1.1 Contexto

3dCal cotiza hoy con cantidad N (multiplicación unitario × N) y descuento manual (%).
La sección colapsable "Otros" (Pro) expone 4 overrides por impresión: mano de obra,
post-procesado, tasa de falla y markup. Los parámetros globales viven en Ajustes
(energía, mano de obra, post-procesado %, falla %, cargo mínimo, markup, ganancia base).

El dueño de taller cotiza piezas repetidas (llaveros, logotipos), recibe la pregunta
"¿y por 10 unidades?" y agrega costos que hoy no existen en el cálculo: **insumos
físicos** (aro de llavero, caja, bolsa, envío) y **servicios diferenciados** (diseño,
pintado) con precios distintos entre sí. Estos costos son variables por impresión:
cambian según la pieza, el lote y el proveedor.

### 1.2 Problema

1. El descuento por cantidad se hace a mano (o mental) y no queda registrado ni
   defendible frente al cliente.
2. Los insumos (aro del llavero, packaging, envío) no existen en el cálculo: el
   precio no cubre el costo real de la pieza terminada.
3. Diseño y pintado se mezclan con la mano de obra general: no hay forma de cobrar
   tarifas distintas ni de mostrarlas como líneas propias.
4. La sección "Otros" mezcla tarifas (configurables) con lo que debería ser un
   espacio de costos variables; y no se distingue qué es configuración global de
   qué es costo de esa impresión.

### 1.3 Objetivo

Que el dueño de taller pueda:
- Configurar una vez el descuento por cantidad (escalones mayoristas) y que se
  aplique automáticamente al ingresar la cantidad, visible como línea propia.
- Agregar insumos por pieza (aro, caja, bolsa, envío) con precio, reutilizables
  desde un catálogo (Pro, opcional) o como línea libre.
- Cobrar diseño y pintado con tarifas propias, cada uno como precio fijo a mano o
  como porcentaje del costo base (1–100 %).
- Ver todos estos costos como líneas separadas en el desglose, en el resumen de la
  cotización y en el export (imagen/PDF).

Todo sin romper: la regla del 95 % (Express con N=1 sin cambios), la promesa
offline (cero red), el dinero siempre en `decimal`, y el estado de negocio solo
por Riverpod notifiers.

### 1.4 Restricciones no negociables (heredadas)

1. Sin backend, sin auth, sin cloud sync. Cero red.
2. Dinero SIEMPRE con `decimal` (o int centavos); `double` solo en formateo final.
3. Estado de negocio solo por Riverpod notifiers (codegen); `setState` solo para UI
   efímera y no persistente.
4. Regla del 95 %: Express con N=1 y sin extras debe ser idéntico al flujo actual.
5. UI en español neutro (es_BO); identificadores y comentarios técnicos en inglés.
   Nueva UI en los tres idiomas (es_bo, en_us, pt_br).
6. Un solo mundo visual M3.

### 1.5 Supuestos globales

- La tabla `settings` permite agregar claves sin recrear esquema (migración aditiva).
- El motor de cálculo actual (unitario, sin conocer cantidad) no cambia su contrato
  base; cantidad y escalamiento viven en la capa de presentación/repositorio como hoy.
- "Plantillas" en este PRD = **plantillas de export de la cotización** (imagen/PDF
  existentes). Si en el futuro se implementan plantillas de producto (PRD v2 F11),
  estas heredarán los snapshots sin cambios de esquema nuevos.

---

## 2. Alcance: 4 features

### A. Descuentos por cantidad (mayorista configurable)

**Problema.** "¿Y por 10 unidades?" se responde a mano; el descuento no queda
registrado, no es consistente y no es defendible.

**Solución.** Configuración de escalones en Ajustes; aplicación automática según la
cantidad N ya ingresada en el cotizador; línea propia en el desglose y en el export.

**UX resumida.**
1. **Ajustes → "Descuentos por cantidad"**: lista editable y ordenada de escalones
   `(cantidad mínima → % de descuento)`. Agregar/quitar/editar; validación
   (cantidad ≥ 2, % en 0–100, orden creciente o auto-ordenado).
2. **Cotizador**: sin controles nuevos. El usuario solo ingresa la cantidad N
   (ya existe). Si N cumple un escalón, el descuento **aparece solo**.
3. **Resultado/desglose**: fila separada **"Descuento por cantidad (X %)"** junto a la
   fila existente "Descuento (Y %)". Ambas siempre diferenciadas, incluso si una es 0
   (se muestra solo la que aplica).
4. **Export (imagen/PDF)**: ambas líneas de descuento visibles y diferenciadas, en
   el bloque de cantidad (`N u. × unitario`).

**Reglas de negocio.**
- Se aplica el escalón con la mayor cantidad mínima que N cumpla. N por debajo del
  primer escalón → 0 % de lote (sin línea en desglose).
- El descuento por cantidad se calcula sobre el **subtotal de impresión del lote**
  (`(costo_base + falla + markup) × N`), NO sobre insumos ni servicios (decisión
  P3, sección 5). El descuento manual actual sí escala sobre el subtotal total
  (que ya incluye insumos y servicios).
- Ambos descuentos se **suman** (no se reemplazan) y se muestran como líneas
  separadas. Composición oficial: subtotal (impresión + insumos + servicios) →
  descuento por cantidad (sobre impresión) → descuento manual (sobre el total) →
  total (con piso de cargo mínimo).
- El % del escalón aplicado se persiste como **snapshot** en la cotización:
  editar escalones después no altera cotizaciones guardadas.
- Aplica igual en Express y Advanced (en Advanced, unitario = total multi-material).
- El descuento por cantidad NO toca los insumos ni los servicios: se calcula solo
  sobre el subtotal de impresión (decisión P3; ver sección 3). Solo el descuento
  manual final los reduce de forma global, como hoy.

**Criterios de aceptación.**
- Given escalones [10 u → 10 %, 25 u → 15 %], When cotizo N=10, Then se aplica 10 %;
  When N=25, Then 15 %; When N=30, Then 15 %; When N=9, Then no hay descuento de
  cantidad ni línea en el desglose.
- Given N=1, When cotizo en Express, Then no veo ningún control ni línea nueva: el
  flujo es idéntico al actual.
- Given una cotización con cantidad y descuento manual, When exporto imagen/PDF,
  Then se ven `N u. × unitario`, "Descuento por cantidad (X %)" y "Descuento (Y %)"
  como líneas separadas, con montos correctos.
- Given que edito los escalones mañana, When reabro una cotización con lote, Then
  conserva el % snapshot original.
- Given la configuración vacía (sin escalones), When cotizo con cualquier N, Then
  no hay descuento por cantidad (comportamiento actual intacto).

---

### B. Insumos por pieza (aros, packaging, envío)

**Problema.** El aro del llavero, la caja, la bolsa y el envío cuestan y no están en
el precio. Además el mismo insumo tiene precios distintos según el lote o proveedor.

**Solución.** Lista de insumos por cotización dentro de "Costos de la pieza": cada
insumo tiene nombre y precio, escala con la cantidad (por unidad) o es único por
trabajo (ej. envío). Guardar al catálogo reutilizable es **opcional y Pro**.

**UX resumida.**
1. **Cotizador → "Costos de la pieza" → "Insumos"**: botón "Agregar insumo"
   (disponible para **todos** los usuarios — la sección deja de ser 100 % Pro,
   ver decisión P1 en la sección 5).
2. Al agregar: el usuario crea la línea libre (nombre + precio) y elige si es
   **por unidad** o **único**. Si es **Pro**, además puede elegir del catálogo
   (precio precargado y editable) y guardar la línea como insumo reutilizable.
   El precio siempre es editable en la cotización (el catálogo da el default).
3. Cada insumo indica si es **por unidad** (se multiplica × cantidad, ej. aro,
   caja) o **único por trabajo** (no escala, ej. envío). Toggle visual por insumo.
4. Botón opcional **"Guardar como insumo"** (Pro): persiste nombre + precio al
   catálogo para reutilizarlo. El usuario puede no guardarlo: la línea vive solo
   en esa cotización.
5. Desglose: líneas propias por insumo (`Aro llavero — Bs 2,50 ×10 = Bs 25,00`;
   `Envío — Bs 5,00 (único)`). Export imagen/PDF las incluye.
6. **Ajustes → "Insumos comunes" (Pro)**: CRUD simple (nombre, precio default).

**Reglas de negocio.**
- Insumo por unidad: `costo = precio × cantidad`. Insumo único: `costo = precio`.
- Verificación de módulo: el subtotal de insumos NO recibe falla ni markup
  (es costo directo); ver reglas de cálculo en la sección 4.
- El catálogo guarda snapshot del precio al momento de elegir el insumo en la
  cotización (editar el catálogo no altera cotizaciones existentes).
- Free: líneas libres disponibles dentro de "Costos de la pieza"; el botón
  "Guardar como insumo" y el catálogo están gateados a Pro (paywall con badge
  Pro por ítem, no por sección completa).
- Durabilidad: los insumos se persisten como filas hijas de la cotización con su
  snapshot (label, precio, es_por_unidad).

**Criterios de aceptación.**
- Given una cotización Express de N=10 con insumo "Aro llavero Bs 2,50 por unidad",
  When calculo, Then el desglose muestra `Aro llavero — Bs 2,50 ×10 = Bs 25,00` y el
  total lo incluye.
- Given el mismo insumo marcado "único", When calculo, Then el costo es Bs 2,50 sin
  importar la cantidad.
- Given usuario Pro, When agrego insumo desde el catálogo, Then el precio viene
  precargado y editable, y guardar es opcional.
- Given usuario free, When abre "Costos de la pieza" y toca "Agregar insumo",
  Then crea línea libre (sin acceso al catálogo) y el botón "Guardar como
  insumo" muestra el paywall.
- Given que edito el catálogo (precio) después de guardar una cotización, When la
  reabro, Then conserva el precio snapshot original.
- Given una cotización sin insumos, When calculo, Then no aparece ninguna línea de
  insumos y el total es idéntico al actual.

---

### C. Servicios diferenciados: Diseño y Pintado

**Problema.** Diseñar, post-procesar y pintar son servicios distintos con tarifas
distintas. Hoy solo existe mano de obra general y post-procesado en porcentaje; no
hay forma de cobrar "diseño" ni "pintado" como líneas propias.

**Solución.** Dos servicios nuevos, cada uno con un **switch** de modo de cobro:
- **OFF → precio a mano** (Bs): monto fijo que ingresa el usuario.
- **ON → porcentaje del costo base**: slider de 1 a 100 %, aplicado sobre el costo
  base de la pieza (material + energía + amortización + mano de obra +
  post-procesado; sin falla ni markup).

Regla de escalamiento: **pintado es por pieza** (escala con la cantidad);
**diseño es único por trabajo** (no escala).

**UX resumida.**
1. **Ajustes → "Costos de impresión"**: entradas nuevas "Diseño" y "Pintado", cada
   una con el mismo switch (precio a mano / % del costo base) + valor por defecto.
   Son los defaults globales; el cotizador permite override por pieza.
2. **Cotizador → "Costos de la pieza" → "Servicios"**: entradas de override para
   Diseño y Pintado (precargadas con el default global; si el usuario no las toca,
   se usa el default). **Modo "precio a mano"**: disponible para todos.
   **Modo "% del costo base" (slider)**: Pro (badge por ítem → paywall al
   activarlo).
3. Desglose: línea **"Diseño"** (único por trabajo) y línea **"Pintado"**
   (`Bs 5,00 ×10 = Bs 50,00`) como líneas separadas entre post-procesado y
   descuentos. Export imagen/PDF las incluye.

**Reglas de negocio.**
- `costo_diseño` = valor manual (Bs) o `costo_base × % / 100`. Siempre único:
  se suma 1 vez por cotización (carece de ×cantidad).
- `costo_pintado` = valor manual o % del costo base, **por pieza**: se multiplica
  por la cantidad.
- El % de diseño/pintado NO compone sobre sí mismo: ambos se calculan sobre el
  mismo costo base (sin falla, sin markup, sin insumos, sin el otro servicio).
- Override por pieza en la cotización: si el usuario lo modifica, se persiste el
  snapshot del valor elegido (y su modo); si no lo toca, se persiste el default
  global al guardar.
- **Gate free/Pro** (decisión P1): modo "manual" es free; modo "percent" (slider
  % del costo base) es Pro con badge por ítem.
- Aplican igual en Express y Advanced.

**Criterios de aceptación.**
- Given diseño a mano Bs 30 y N=10, When calculo, Then el desglose muestra
  "Diseño — Bs 30,00 (único)" y el unitario sube Bs 3,00 (30 ÷ 10).
- Given pintado a mano Bs 5 y N=10, When calculo, Then el desglose muestra
  "Pintado — Bs 5,00 ×10 = Bs 50,00".
- Given pintado al 20 % del costo base (costo base Bs 100), When calculo, Then
  pintado = Bs 20 por pieza (×N si N > 1).
- Given el slider ON (Pro), When muevo de 1 a 100, Then el valor se recalcula en
  vivo y se ve el monto resultante.
- Given defaults de Ajustes, When el usuario no toca los servicios en una
  cotización, Then se usa el default global y el desglose lo muestra.
- Given usuario free, When abre "Servicios" y usa el modo precio a mano, Then
  puede cargar diseño/pintado sin paywall; When activa el modo "% del costo
  base", Then ve el paywall (decisión P1).
- Given N=1 y servicios en 0/desactivados, When calculo, Then no aparece ninguna
  línea de servicios y el total es idéntico al actual.

---

### D. Reorganización: "Otros" → "Costos de la pieza" + Ajustes

**Problema.** "Otros" mezcla tarifas con costos variables, y Ajustes no tiene lugar
para escalones ni insumos.

**Solución.** Renombrar y agrupar; Ajustes gana dos secciones.

**Cotizador** — sección colapsable "Otros" pasa a llamarse **"Costos de la pieza"**,
con tres subgrupos (colapsados por defecto). **Acceso libre para todos los
usuarios**; los ítems Pro llevan badge por subgrupo (decisión P1):

```
Costos de la pieza (acceso libre; ítems Pro con badge)
├── Insumos          ← nuevo (feature B): línea libre free; catálogo Pro
├── Servicios        ← nuevo (feature C): modo manual free; % del costo base Pro
└── Tarifas          ← Pro (los 4 campos actuales, gate sin cambios)
```

**Ajustes** — orden y secciones nuevas:

```
Ajustes/
├── Empresa                      (actual)
├── Energía                      (actual: Bs/kWh)
├── Costos de impresión          (actual + Diseño y Pintado con switch modo/valor)
├── Descuentos por cantidad      ← NUEVO (feature A): lista de escalones
└── Insumos comunes (Pro)        ← NUEVO (feature B): catálogo
```

**Reglas de negocio.**
- Ninguna migración de comportamiento: los 4 campos de "Tarifas" mantienen su
  semántica actual (override por cotización de los defaults globales).
- El orden visual de las secciones de Ajustes es el indicado; los títulos se
  traducen a los tres idiomas.
- Glyph/ícono de la sección: se actualiza con el nuevo nombre en todos los
  idiomas (i18n); no se reutiliza `calcSectionOthers` para la nueva sección
  (queda deprecado).

**Criterios de aceptación.**
- Given una instalación existente con la sección "Otros", When abre la app tras la
  migración, Then la sección se llama "Costos de la pieza" y contiene los 4 campos
  de tarifas con los valores guardados.
- Given usuario free, When expande "Costos de la pieza", Then puede usar Insumos
  (línea libre) y Servicios (modo manual), y ve badges Pro en el catálogo de
  insumos, en el modo "% del costo base" y en "Tarifas"; tap en un ítem Pro →
  paywall (decisión P1).
- Given Ajustes, When navego, Then veo las secciones en el orden indicado y las
  nuevas ("Descuentos por cantidad", "Insumos comunes") presentes.
- Given el flujo Express con N=1 sin extras, When cotizo, Then no veo nada nuevo
  (regla del 95 % intacta).
- Given los tres idiomas, When navego Ajustes y la sección nueva, Then no hay
  strings sin traducir ni voseo ni regionalismos en es_bo.

---

## 3. Reglas de cálculo (orden del motor)

Sin cambios sobre el contrato del motor unitario; los nuevos conceptos se suman
en la capa de cálculo con este orden:

1. `costo_base` = material + energía + amortización + mano de obra + post-procesado
   (definición actual, sin cambios).
2. `falla` = `costo_base × tasa_falla` (sin cambios; no cubre insumos/servicios).
3. `markup` = `materiales × markup` (sin cambios; no cubre insumos/servicios).
4. `insumos` = Σ(insumos por unidad) × N + Σ(insumos únicos). Costo directo.
5. `pintado` = (valor manual o % de costo_base) × N. Costo directo por pieza.
6. `diseño` = valor manual o % de costo_base. Costo directo único.
7. `subtotal_impresion` = (`costo_base` + `falla` + `markup`) × N
   (solo la parte de impresión: sin insumos ni servicios).
8. `subtotal` = `subtotal_impresion` + `insumos` + `pintado` + `diseño`
   (equivale a `unitario × N`, con `unitario` = subtotal ÷ N para el desglose).
9. `desc_cantidad` = escalón aplicado sobre **`subtotal_impresion`** (feature A;
   decisión P3: NO toca insumos ni servicios).
10. `desc_manual` = % manual sobre `subtotal` total (comportamiento actual
    escalado: sí reduce insumos y servicios de forma global).
11. `total` = máx(`subtotal − desc_cantidad − desc_manual`, `cargo_minimo`).

Ejemplo de verificación (N=10, costo_base 20, falla 10 %, markup 5 % sobre
materiales 8, insumo aro 2,50 por unidad, envío 5 único, diseño 30 único, pintado
3 por unidad, escalón 10 u → 10 %, descuento manual 0):
- falla = 2,00 · markup = 0,40
- insumos = 2,50×10 + 5,00 = 30,00 · pintado = 3,00×10 = 30,00 · diseño = 30,00
- subtotal_impresion = (20 + 2,00 + 0,40) × 10 = 224,00
- subtotal = 224,00 + 30,00 + 30,00 + 30,00 = 314,00 (unitario 31,40)
- desc_cantidad = 10 % × 224,00 = 22,40 · desc_manual = 0
- total = 314,00 − 22,40 = 291,60

Desglose esperado: costo base 20,00 · falla 2,00 · markup 0,40 · insumos
`2,50×10=25,00` · envío 5,00 único · pintado `3,00×10=30,00` · diseño 30,00 único ·
**subtotal 314,00** · descuento por cantidad −22,40 (sobre impresión) · descuento
manual −0,00 · **total 291,60 Bs**.

---

## 4. Modelo de datos (drift, nivel conceptual)

> Dinero siempre como texto `decimal`; cantidades físicas como numérico no monetario.
> Migraciones aditivas; IDs texto tipo UUID (consistente con PRD v2).

### Tablas nuevas

**`discount_tiers`** (feature A)
- `id` TEXT PK · `min_qty` INTEGER NOT NULL · `percent` TEXT NOT NULL (`decimal`) · `sort_order` INTEGER NOT NULL.

**`calculation_extras`** (feature B, hijos de `calculations`)
- `id` TEXT PK · `calculation_id` TEXT NOT NULL FK → `calculations.id`
- `label` TEXT NOT NULL · `unit_price` TEXT NOT NULL (`decimal`, snapshot)
- `is_per_unit` INTEGER NOT NULL (1 = escala con cantidad, 0 = único)
- `created_at` TEXT NOT NULL.
- Índice sobre `calculation_id`.

**`insumo_catalog`** (feature B, Pro)
- `id` TEXT PK · `name` TEXT NOT NULL · `default_price` TEXT NOT NULL (`decimal`) · `created_at` TEXT NOT NULL.

### Tablas modificadas

**`calculations`** (features C y D)
- `+ design_mode` TEXT NOT NULL DEFAULT 'manual' ('manual' | 'percent')
- `+ design_value` TEXT NOT NULL DEFAULT '0' (`decimal`)
- `+ paint_mode` TEXT NOT NULL DEFAULT 'manual' ('manual' | 'percent')
- `+ paint_value` TEXT NOT NULL DEFAULT '0' (`decimal`)
- `+ batch_discount_percent` TEXT NULL (snapshot del escalón aplicado, feature A)
- `+ batch_discount_amount` TEXT NULL (snapshot, feature A)

**`settings`** (features A, B, C)
- `+ design_default_mode`, `+ design_default_value`
- `+ paint_default_mode`, `+ paint_default_value`
- Claves de escalones: la lista `discount_tiers` es tabla propia (no settings).
- Sin cambios para insumos comunes (tabla propia).

### Migración

- M1 (única): crear `discount_tiers`, `calculation_extras`, `insumo_catalog`;
  columnas nuevas en `calculations` (con defaults que preservan el comportamiento:
  mode 'manual', value '0', batch NULL); columnas nuevas en `settings` con
  defaults. Tests de migración drift obligatorios; idempotente.

---

## 5. Preguntas abiertas para el dueño de producto

- **P1 (gate free/Pro)** — **DECIDIDO (2026-09-13): híbrido.** La sección
  "Costos de la pieza" es accesible para todos. Free: línea libre de insumos y
  servicios (diseño/pintado) en modo precio a mano. Pro: catálogo de insumos +
  "Guardar como insumo", modo "% del costo base" para servicios, y los overrides
  de Tarifas (sin cambios). Mecánica de paywall **por ítem** (badge Pro dentro de
  la sección), no de sección completa. Racional: el costo real debe ser cobrable
  siempre (precio honesto); la velocidad (catálogo) y la optimización (% del
  costo base) son el gancho de conversión Pro.
- **P2 (falla/markup sobre insumos)**: ¿confirmás que insumos y servicios NO
  reciben falla ni markup (default propuesto, sección 3) o deben componerse?
- **P3 (descuento por cantidad sobre insumos/servicios)** — **DECIDIDO
  (2026-09-13):** el descuento por cantidad se calcula solo sobre
  `subtotal_impresion` (no toca insumos ni servicios). El descuento manual final
  sí reduce el subtotal total (incluye insumos y servicios), como hoy. Racional:
  el % mayorista premia el volumen de impresión (setup, filamento, energía), no
  los insumos tercerizados; y el desglose queda limpio y defendible.
- **P4 (snapshot de servicios)**: si el usuario no toca los servicios en la
  cotización, ¿se persiste el default global en ese momento (default propuesto:
  sí, para que el historial no cambie si edita Ajustes después)?
- **P5 (máximo de escalones/insumos)**: ¿límite práctico de escalones (default 10)
  e insumos por cotización (default 20)? Fuera del límite: validación visual.

---

## 6. Fuera de alcance (explícito)

| Ítem | Motivo |
|---|---|
| Plantillas de producto reutilizables (PRD v2 F11) | Requiere su propio ciclo; aquí solo los snapshots quedan listos para heredarlas |
| Descuento por cantidad en términos de %/monto absoluto | Solo % por escalón en v1 |
| Historial de compras de insumos | Los insumos del catálogo son CRUD simple sin trazabilidad |
| IVA/impuestos, comisiones de marketplace, tarifa de tarjeta | Features futuras (F13+), fuera de este PRD |
| Envío calculado por reglas (peso/zonas) | Solo línea "único" a mano en v1 |
| Multi-moneda | PRD v2 F12, sin cambios aquí (moneda BOB en ejemplos) |
| Reparación/edición masiva de lotes guardados | Recalcular lotes pasados queda fuera |

---

## 7. Hitos de entrega

| # | Hito | Resultado visible |
|---|---|---|
| 1 | A + D (escalones + reorganización) | Descuento mayorista automático con líneas diferenciadas; Ajustes ordenado |
| 2 | B (insumos) | Aros, packaging y envío en el cálculo, con catálogo Pro opcional |
| 3 | C (servicios diseño/pintado) | Líneas propias de diseño y pintado, modo manual o % del costo base |

Cada hito es enviable por sí solo (gate de release al cierre de cada uno).

*Status: DRAFT — planificación de implementación pendiente vía `/plan` (un plan por hito).*