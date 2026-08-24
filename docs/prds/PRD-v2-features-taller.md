# PRD v2 — Features de taller para vendedores de impresión 3D

> Generado por prd-agent el 2026-08-24 desde el pedido:
> "Escribe un PRD COMPLETO en español para la app 3dCal… cubre 12 features nuevas
> priorizadas para usuarios que imprimen 3D y venden piezas."
> Fuentes de contexto verificadas: `docs/PROJECT.md`, `PRODUCT.md` (raíz del repo).

## Estado

DRAFT — pendiente de aprobación del dueño de producto y handoff a `/plan`.

---

## 1. Resumen ejecutivo

### 1.1 Contexto

3dCal es una calculadora reactiva de precios para impresión 3D, 100% offline
(Flutter + Riverpod 2.x codegen + drift + `decimal`, i18n es_BO, mundo visual M3).
Hoy ya cotiza en modo Express/Advanced, mantiene catálogos de filamentos e
impresoras, historial con toggle vendido/no vendido, dashboard de ganancias,
export PDF/imagen y paywall Pro.

El usuario objetivo — dueño de taller o maker que vende piezas — cotiza **frente
al cliente**, en ferias o en el local, con una mano y poco tiempo. La v1 resuelve
"dar un precio defendible en segundos". La v2 ataca el ciclo completo del taller:
**estimar la pieza sin pesarla (STL), vender en cantidad, gestionar el pipeline de
cotizaciones, controlar insumos y costos reales, y proteger los datos** — todo sin
romper la promesa offline y sin agregar fricción al flujo Express de 3 inputs.

### 1.2 Objetivo

Convertir 3dCal de "calculadora de precio" a "herrmina de venta diaria del taller":
que el usuario pueda estimar una pieza desde su archivo STL, cotizar lotes con
descuento, seguir el estado de cada cotización hasta la venta, descontar stock real
y respaldar sus datos, todo offline.

### 1.3 Objetivos medibles (KPIs)

Sin claims inventados: primero se mide línea base (fase 1, contadores locales),
luego se fijan metas. Los valores de mejora son **hipótesis a validar**, no promesas.

| KPI | Definición | Línea base | Meta (hipótesis) |
|---|---|---|---|
| Ticket promedio | Promedio del total de cotizaciones `vendida` del mes | Se mide al cerrar fase 1 | Subir tras habilitar lotes (hipótesis: +15% a 60 días; el dueño fija la meta al ver la base) |
| Tiempo de cotización | Mediana entre creación del draft y primer export/compartido | Se mide al cerrar fase 1 | Bajar con STL + plantillas (hipótesis: −20%) |
| Conversión a venta | % de cotizaciones `enviada`+`aceptada` que terminan `vendida` | Se mide con estados (fase 1) | Referencia mensual; sin meta fija en v2 |
| Retención (proxy) | Días con ≥1 cotización creada en los últimos 7/30 | Se mide con contadores locales | ≥4 días/semana en usuarios frecuentes (definición a validar) |
| Adopción STL | % de cotizaciones nuevas originadas desde import STL | 0 (feature nueva) | Medir adopción real; sin meta prefijada |

### 1.4 Usuarios

- **Primario**: dueño de taller / maker-freelance que vende piezas impresas,
  cotiza en punto de venta (feria, local, taller), a una mano, con o sin sol
  directo, y envía la cotización por WhatsApp/PDF.
- **Secundario**: mismo usuario en modo "gestión": revisa historial, stock y
  dashboard fuera del punto de venta.
- **No es para**: compradores finales, equipos multi-usuario, empresas con ERP
  (no hay auth ni multiusuario por diseño).

### 1.5 Restricciones no negociables (aplican a las 12 features)

1. **Sin backend, sin auth, sin cloud sync. Cero red.** Toda feature funciona
   100% offline (el deep link `wa.me` es salida opcional iniciada por el usuario,
   no dependencia de la app).
2. **Dinero SIEMPRE con `decimal`** (o int centavos). `double` solo en formateo
   final. Cantidades físicas (gramos, cm³, horas, watts) pueden ser numéricas no
   monetarias, pero el motor de cálculo de precios opera con `decimal`.
3. **Estado de negocio solo por Riverpod notifiers (codegen).** `setState`
   permitido únicamente para UI efímera no persistente (focus, índices de
   stepper, estado de slider en simulación, busy flags).
4. **Regla del 95%**: el modo Express (3 inputs) sigue siendo el camino por
   defecto. Ninguna feature puede agregar taps obligatorios al flujo Express
   con N=1 y sin STL.
5. **UI en español (es_BO); código en inglés.**
6. **Un solo mundo visual M3**: sin temas paralelos salvo la variante de alto
   contraste (feature 10).

### 1.6 Supuestos globales

- Los IDs de todas las tablas son texto tipo UUID (necesario para backup sin
  colisiones). Validar en implementación.
- La tabla `settings`/parámetros globales permite agregar claves nuevas sin
  recrear esquema (si es fila única, migración aditiva de columnas).
- El usuario acepta que "vencida" sea un estado calculado al abrir/leer la app
  (sin notificaciones push, coherente con cero red).
- Densidades y velocidades por defecto son editables; ninguna se presenta como
  dato técnico oficial del fabricante.

---

## 2. Alcance: 12 features en 3 fases

Criterio de orden:
- **Fase 1 — Diferenciadores**: lo que ningún competidor offline ofrece y lo que
  cambia la venta diaria (STL, lotes, pipeline de estados).
- **Fase 2 — Operación**: costos reales y protección de datos (inventario,
  amortización, costo/g real, backup).
- **Fase 3 — Retención/UX**: comodidad y cierre del WIP multi-moneda.

Cada fase es **enviable por sí sola** (gate de release al final de cada una).

---

### FASE 1 — Diferenciación

#### F1. Importar STL y estimar peso/volumen localmente — Esfuerzo: L

**Problema.** Para cotizar, el usuario necesita el peso de la pieza. Si no la ha
impreso antes, lo estima a ojo: cotiza mal o debe imprimir/ pesar primero. El
cliente espera.

**Solución.** Parseo de STL (binario y ASCII) 100% local: volumen de la malla
mediante suma de tetraedros firmados (sin reparación de malla) × densidad del
material → gramos sugeridos + estimación de tiempo. El resultado prellena la
cotización.

**UX resumida.**
1. En el cotizador (Express y Advanced), botón "Importar STL" junto al input de
   peso (no reemplaza el flujo manual: con N=1 sin STL nada cambia).
2. File picker del sistema → pantalla de análisis con indicador de progreso.
3. Resultado: volumen (cm³), material seleccionado (default: último filamento
   usado), densidad aplicada (editable), factor de ajuste opcional (default 100%,
   para relleno/ahuecado), gramos sugeridos, tiempo estimado.
4. CTA "Usar en cotización" → prellena peso (y tiempo en Express); **todos los
   valores quedan editables**. Sin CTA no se toca el draft.

**Reglas de negocio.**
- Unidades: se asume que el STL está en **mm** (convención de facto); volumen
  mm³ → cm³ (÷1000). Sanity check: si el volumen resulta 0, negativo, o fuera de
  rango plausible (p. ej. >10 000 cm³), advertir y ofrecer entrada manual.
- Mallas inválidas/no-manifold: estrategia simple — suma de tetraedros firmados;
  si el volumen resultante no es positivo y finito, mostrar error claro
  ("No se pudo estimar el volumen; ingresá el peso manualmente") y fallback
  manual. **Sin reparación de malla.**
- Densidades por defecto (editables por filamento): PLA 1.24, PETG 1.27,
  ABS 1.04 g/cm³.
- Tiempo estimado: heurística `gramos / velocidad_gph` con velocidad
  configurable (default 10 g/h). Se etiqueta siempre como "estimación".
- Límites de archivo: **25 MB / ~1 M de triángulos en mobile; 15 MB en web**
  (valores iniciales, ajustables). Sobre el límite: error claro antes de parsear.

**Criterios de aceptación.**
- Given un STL binario válido de una pieza cerrada, When lo importo con PLA
  seleccionado, Then veo volumen cm³ ≈ real (±1% vs herramienta de referencia) y
  gramos = volumen × 1.24 con densidad editable.
- Given un STL ASCII válido, When lo importo, Then el resultado es equivalente al
  caso binario para la misma malla.
- Given un archivo >límite de tamaño, When intento importar, Then veo error sin
  crash y sin consumo de memoria descontrolado.
- Given una malla no-manifold con volumen firmado ≤0, When termina el análisis,
  Then veo advertencia y el flujo manual sigue disponible (fallback).
- Given un análisis exitoso, When toco "Usar cotización", Then el campo peso de
  Express queda prellenado y editable; When NO toco el CTA, Then el draft no
  cambia.
- Given la regla del 95%, When abro el cotizador sin usar STL, Then el flujo
  Express sigue teniendo exactamente 3 inputs visibles.

**Impacto en arquitectura.**
- Feature nueva `lib/features/stl/`: parser en Dart puro (domain, sin dependencias
  de Flutter ni drift) para testeabilidad; presentación con su propio notifier
  (estado de análisis efímero + resultado).
- Integración con `calculation/` vía prefill (contrato de datos: gramos, tiempo,
  fuente `stl`). Ninguna dependencia inversa.
- Densidad por filamento: columna nueva en tabla `filaments` (ver §4).
- Parámetro global nuevo: velocidad de impresión (g/h).

**Riesgos.** Performance de parseo en web (JS sin isolates trivialmente):
mitigar con límites de archivo, parseo incremental con progreso y prueba con
archivos reales grandes. Ambigüedad de unidades del STL: mitigar con sanity
check de volumen. Precisión en mallas rotas: mitigar con etiqueta "sugerido" +
edición siempre disponible.

---

#### F2. Cotización por cantidad (lotes) — Esfuerzo: M

**Problema.** "¿Y por 10 unidades?" es la segunda pregunta más común en ferias.
Hoy el usuario multiplica mentalmente y pierde el desglose defendible.

**Solución.** Cantidad N (default 1) por cotización + descuento escalonado
configurable (p. ej. 10% desde 10 u, 15% desde 25 u). El desglose y el export
muestran unitario × N.

**UX resumida.**
- En Express/Advanced, control de cantidad **colapsado por defecto**
  ("¿Varias unidades?"). Con N=1 no se muestra nada nuevo: cero fricción.
- Al subir N>1: el total pasa a `unitario × N − descuento de lote`; el desglose
  agrega filas "Subtotal unitario", "Cantidad ×N", "Descuento por cantidad (X%)".
- Configuración de escalones en Parámetros globales: lista de
  (cantidad mínima, % descuento), ordenada, editable, con validación.

**Reglas de negocio.**
- Se aplica el escalón de mayor cantidad mínima que N cumpla; N por debajo del
  primer escalón → 0% de lote.
- Composición con el descuento global existente: **asumido (ver Pregunta
  abierta #1)** — el descuento global se aplica al unitario y el descuento de
  lote al subtotal del lote; ambos visibles como filas separadas del desglose.
- Todo el cálculo en `decimal`; el % del escalón se persiste como snapshot en la
  cotización (cambios de configuración futuros no alteran cotizaciones pasadas).
- Aplica igual en Express y Advanced (en Advanced, unitario = total
  multi-material).

**Criterios de aceptación.**
- Given escalones [10 u → 10%, 25 u → 15%], When cotizo N=10, Then se aplica
  10%; When N=25, Then 15%; When N=9, Then 0%; When N=30, Then 15% (mayor
  cumplido).
- Given N=1, When cotizo en Express, Then no veo controles de lote y el flujo es
  idéntico al actual.
- Given una cotización con lote, When exporto PDF/imagen, Then se muestran:
  precio unitario, cantidad, % descuento de lote, monto de descuento y total.
- Given que edito la configuración de escalones mañana, When reabro una
  cotización pasada con lote, Then conserva el % snapshot original.
- Given Advanced con 2 materiales y N=5, When calculo, Then unitario = suma
  multi-material y total = unitario × 5 (− descuento si aplica).

**Impacto en arquitectura.**
- Tabla `quotes`: columnas `quantity`, `batch_discount_percent` (snapshot),
  `batch_discount_amount`.
- Tabla nueva `discount_tiers` (ver §4).
- Motor de cálculo: entrada `quantity` + escalones; salida con líneas de lote.
- Export PDF/imagen: layout con bloque de lote.

**Riesgos.** Ambigüedad de composición con descuento global (resolver con dueño;
default documentado arriba). Layout del PDF con muchas filas: probar con
unitarios chicos y N grandes.

---

#### F3. Estados de cotización + vencimiento — Esfuerzo: M

**Problema.** El toggle binario vendido/no vendido no representa la realidad de
venta: no distingue enviada, aceptada, rechazada ni vencida. El dashboard no
puede reflejar el pipeline y las cotizaciones viejas quedan "colgadas" sin
validez.

**Solución.** Estados: `borrador`, `enviada`, `aceptada`, `rechazada`,
`vencida`, `vendida` + validez configurable (default 7 días) con vencimiento
automático calculado localmente.

**UX resumida.**
- Historial: chip de estado por cotización + filtro por estado (multi-selección).
- Detalle de cotización: selector de estado con transiciones válidas; al pasar a
  `enviada` se estampa `valid_until = ahora + validez_días` (si no tenía).
- Cálculo de vencimiento: al abrir la app y al leer la lista, toda cotización
  `enviada` con `now > valid_until` pasa a `vencida` (persistido en la misma
  lectura). `aceptada` NO vence (compromiso del cliente); `vendida`, `rechazada`
  y `vencida` son terminales salvo paso explícito a `vendida`/`aceptada`
  (reapertura permitida: `vencida → aceptada/vendida`).
- Dashboard: "real" = `vendida`; "cotizado" = `enviada` + `aceptada` +
  `vendida` del período (excluye borrador/rechazada/vencida). Leyenda actualizada
  para explicar la semántica nueva.

**Reglas de negocio.**
- Validez en días configurable en Parámetros (default 7, rango 1–90).
- Migración de datos existentes (**asumido, ver Pregunta abierta #2**):
  `is_sold = true → vendida`; `is_sold = false → enviada`. La columna `is_sold`
  se elimina tras el backfill.
- El límite free de 10 cotizaciones y Pro ilimitado no cambian.

**Criterios de aceptación.**
- Given una cotización con toggle "vendida" hoy, When se ejecuta la migración,
  Then queda en estado `vendida` con el mismo total.
- Given una cotización no vendida, When migra, Then queda `enviada` (default) y
  puedo cambiarla a cualquier estado válido.
- Given validez 7 días y una cotización `enviada` hace 8 días, When abro la app,
  Then aparece como `vencida` sin intervención manual.
- Given una cotización `aceptada` hace 30 días, When abro la app, Then NO está
  vencida.
- Given el historial, When filtro por `rechazada`, Then solo veo rechazadas.
- Given el dashboard del mes, When hay 1 enviada (Bs X), 1 aceptada (Bs Y) y 1
  vendida (Bs Z), Then cotizado = X+Y+Z y real = Z.
- Given una cotización `vendida` que vuelve a `enviada` (reapertura), When se
  vende de nuevo, Then el dashboard refleja el cambio (idempotencia).

**Impacto en arquitectura.**
- Tabla `quotes`: columna `status` (texto/enum), `valid_until`; backfill desde
  `is_sold`; drop de `is_sold` (ver §4, migración M1).
- `history/`: UI de estados y filtros; `dashboard/`: consulta agregada nueva.
- Notifier de estados con transiciones válidas centralizadas (domain).

**Riesgos.** Migración en producción local sin rollback de servidor: mitigar con
migración aditiva + backfill testeado (drift migration tests). Cambio de
semántica del dashboard puede confundir: mitigar con leyenda. Cálculo de
vencimiento en lectura debe ser barato y sin loops de escritura repetida
(idempotente).

---

### FASE 2 — Operación

#### F4. Inventario de bobinas — Esfuerzo: M

**Problema.** El usuario no sabe cuánto filamento le queda; vende piezas y
descubre tarde que no tiene bobina. Hoy el stock vive en su cabeza.

**Solución.** Gramos restantes por filamento del catálogo, descuento automático
al marcar una cotización como `vendida`, y alerta de stock bajo configurable.

**UX resumida.**
- CRUD de filamento: campo "Stock (g)" (opcional; vacío = no controlar stock) y
  ajuste manual directo.
- Catálogo: badge de stock bajo cuando `stock < umbral`.
- Al pasar una cotización a `vendida`: descuento automático
  `gramos_por_material × quantity` de cada filamento usado; snackbar con lo
  descontado y opción "Deshacer" (revierte el estado y el stock).
- Stock insuficiente: advertencia ("Quedan 80 g y la venta descuenta 150 g"),
  **no bloquea** la venta; el stock se limita a 0 (ver Pregunta abierta #7).
- Parámetro global: umbral de alerta default (p. ej. 100 g); override opcional
  por filamento.

**Criterios de aceptación.**
- Given filamento con 1000 g y cotización Express de 150 g × N=2, When la marco
  `vendida`, Then el stock queda en 700 g y veo snackbar con el detalle.
- Given Advanced con 2 materiales, When vendo, Then descuenta de ambos
  filamentos según sus gramos.
- Given stock 80 g y venta de 150 g, When vendo, Then veo advertencia, la venta
  se registra y el stock queda en 0 (nunca negativo).
- Given stock bajo el umbral, When abro el catálogo, Then el filamento muestra
  badge de alerta.
- Given una venta deshecha (estado vuelve a `enviada`), When revierto, Then el
  stock se restaura exactamente.
- Given un filamento sin stock cargado, When vendo una cotización que lo usa,
  Then no se descuenta nada ni hay error.

**Impacto en arquitectura.**
- `filaments`: columnas `stock_g`, `low_stock_g` (override) — ver §4.
- `settings`: umbral default.
- Lógica de descuento en notifier de estados de cotización (transacción: cambio
  de estado + descuento de stock atómicos).

**Riesgos.** Consistencia estado↔stock si la transacción falla: mitigar con
transacción drift única. Reapertura/edición de cotización vendida cambia gramos:
definir en implementación (recalcular diferencia) — mantener simple: solo
"Deshacer" inmediato revierte; ediciones posteriores requieren ajuste manual.

---

#### F5. Amortización de impresora por hora — Esfuerzo: S

**Problema.** El costo de la impresora no aparece en el precio: el usuario
cobra energía y filamento, pero la máquina se deprecia en silencio.

**Solución.** Costo de la impresora ÷ vida útil estimada (horas) = costo fijo
por hora, agregado al desglose como línea propia.

**UX resumida.**
- CRUD de impresora: campos opcionales "Costo (Bs)" y "Vida útil (horas)".
  Ambos vacíos → la línea no aparece (cero fricción).
- Desglose: línea "Amortización máquina" = `costo_hora × horas`, entre energía
  y mano de obra. Tooltip/explicación corta en el CRUD.

**Reglas de negocio.**
- `costo_hora = costo / vida_util` en `decimal` con escala interna 6; se muestra
  redondeado a 2 decimales. Vida útil ≤0 o vacía → línea ausente.
- No confundir con el costo de energía existente (watts): son líneas separadas
  (energía = variable; amortización = fijo).

**Criterios de aceptación.**
- Given impresora Bs 3500 y 4000 h de vida útil, When la selecciono en una
  cotización de 2 h, Then el desglose incluye amortización Bs 1.75 y el total la
  incluye.
- Given impresora sin costo cargado, When cotizo con ella, Then no existe la
  línea de amortización y el total es idéntico al actual.
- Given vida útil 0, When cotizo, Then no hay división por cero ni línea.

**Impacto en arquitectura.**
- `printers`: columnas `purchase_cost` (texto decimal), `useful_life_hours`.
- Motor de cálculo: entrada opcional `amortization_per_hour`; línea nueva en el
  resultado y en el export.

**Riesgos.** Confusión del usuario entre energía y amortización: mitigar con
copy claro. Impacto en totals existentes al cargar datos por primera vez:
esperado y deseado; UI debe mostrar el cambio con transparencia.

---

#### F6. Costo real por gramo desde precio de bobina — Esfuerzo: S

**Problema.** El usuario compra bobinas con envío y estima el precio/g a mano;
suele subestimar el costo real.

**Solución.** Mini-calculadora en el CRUD de filamento: precio de bobina + costo
de envío + peso de bobina → precio/g calculado y aplicable.

**UX resumida.**
- En edición de filamento, botón "Calcular desde bobina" → hoja con 3 inputs
  (precio bobina, envío, gramos bobina; default 1000 g) → resultado precio/g en
  vivo → "Aplicar" escribe `price_per_g` del filamento.
- Los inputs de la hoja son efímeros (no se persisten en v1).

**Reglas de negocio.**
- `precio_g = (precio_bobina + envio) / gramos_bobina` en `decimal` (escala
  interna 4). Peso ≤0 → error de validación.

**Criterios de aceptación.**
- Given bobina Bs 160 + envío Bs 40 + 1000 g, When aplico, Then el filamento
  queda con precio/g Bs 0.20.
- Given gramos 0 o vacíos, When calculo, Then veo error y no se escribe nada.
- Given "Aplicar", When guardo el filamento, Then el catálogo muestra el nuevo
  precio/g.

**Impacto en arquitectura.**
- Solo presentación de `catalog/filaments/` (hoja efímera) + uso del helper de
  dinero existente. Sin cambios de esquema.

**Riesgos.** Mínimos. Posible evolución futura: persistir historial de compras
por bobina — explícitamente fuera de v2.

---

#### F7. Backup y restore por archivo — Esfuerzo: M

**Problema.** Sin backend ni cuenta, cambiar de teléfono o reinstalar pierde
todo el historial del taller. La promesa offline exige una salida de datos
igualmente offline.

**Solución.** Exportar la base completa (todas las tablas drift) como archivo
JSON versionado, compartible por WhatsApp/archivos del sistema; importarlo con
validación estricta y reemplazo total transaccional.

**UX resumida.**
- Parámetros → "Datos": botones "Exportar respaldo" y "Restaurar respaldo".
- Export: genera el archivo y abre el share sheet del sistema (WhatsApp, Files,
  etc.). Nombre sugerido: `3dcal-backup-AAAA-MM-DD.json`.
- Import: file picker → validación → pantalla de confirmación con resumen
  (cantidades por tabla, fecha del respaldo) → **aviso fuerte de reemplazo
  total** + botón "Exportar mi datos actuales primero" (recomendado, un tap) →
  confirmar.

**Reglas de negocio.**
- Formato (esquema conceptual):
  ```
  {
    "app": "3dcal",
    "schema_version": <int>,
    "app_version": "<semver>",
    "exported_at": "<ISO8601>",
    "tables": { "<tabla>": [ <filas> ] }
  }
  ```
- **Estrategia de import v1: reemplazo total** (wipe + carga), dentro de una
  única transacción drift. Merge/upsert queda fuera de v2 (Pregunta abierta #3).
- Validación obligatoria antes de tocar la DB: JSON parseable, `app == "3dcal"`,
  `schema_version` soportada, columnas requeridas presentes y tipos correctos.
  Cualquier fallo → rechazo total con mensaje claro, sin escrituras parciales.
- `schema_version` menor a la actual: se aplican defaults de columnas nuevas
  (compatibilidad hacia adelante acotada). Mayor → rechazo
  ("Actualizá la app para restaurar este respaldo").
- Corrupción: el archivo no se modifica nunca; si la transacción falla, rollback
  completo y la DB queda como estaba.

**Criterios de aceptación.**
- Given una DB con datos en todas las tablas, When exporto, Then el archivo
  contiene todas las tablas con sus filas y metadatos de versión.
- Given el archivo exportado, When lo restauro (tras confirmar), Then la app
  queda con exactamente los mismos datos (IDs incluidos).
- Given un JSON corrupto/trunco, When restauro, Then veo error claro y la DB
  actual permanece intacta.
- Given un respaldo con `schema_version` mayor, When restauro, Then se rechaza
  con mensaje de actualización.
- Given un respaldo de versión menor, When restauro, Then las columnas nuevas se
  llenan con sus defaults sin error.
- Given cero red, When exporto e importo (p. ej. vía archivo local), Then todo el
  flujo funciona offline.

**Impacto en arquitectura.**
- Feature nueva (p. ej. `lib/features/backup/`): serializador de esquema
  completo (una función por tabla, generable desde los DAOs), validador de
  import, notifier de progreso/resultado.
- Constante de `schema_version` ligada a la versión de esquema drift.

**Riesgos.** Deriva entre serializador y esquema real: mitigar con tests que
comparan columnas declaradas vs serializadas. DBs grandes en web (IndexedDB):
export puede ser lento → progreso + límite práctico documentado. Olvido del
usuario de exportar antes de restaurar: mitigar con el botón de auto-backup en
la confirmación.

---

### FASE 3 — Retención y UX

#### F8. Clientes ligeros — Esfuerzo: M

**Problema.** Las cotizaciones no tienen dueño: el usuario no sabe a quién le
cotizó qué, y reenviar una cotización implica buscar el PDF y reescribir el
número.

**Solución.** Entidad cliente mínima (nombre, teléfono, nota) vinculada a
cotizaciones + botón "Reenviar por WhatsApp" con deep link `wa.me`.

**UX resumida.**
- CRUD mínimo de clientes (lista con búsqueda por nombre/teléfono; crear/editar/
  eliminar). Entrada desde el cotizador y desde el historial.
- En el cotizador: selector opcional de cliente (chip colapsado "Cliente" — no
  interfiere con los 3 inputs). En el detalle/historial: nombre del cliente
  visible y filtro por cliente.
- Detalle de cotización con cliente: botón "WhatsApp" → abre
  `https://wa.me/<teléfono>?text=<resumen>` (total, ítems principales, validez).
  El adjunto del PDF sigue siendo manual vía share existente (limitación de
  `wa.me`, comunicada con copy honesto: el botón de PDF queda al lado).

**Reglas de negocio.**
- Teléfono: texto libre. Normalización al construir el deep link
  (**asumido, ver Pregunta abierta #6**): 8 dígitos empezando en 6/7 → anteponer
  `+591`; si ya tiene `+`, se usa tal cual.
- Cotización sin cliente sigue siendo válida (vínculo opcional).
- Eliminar cliente con cotizaciones vinculadas: las cotizaciones conservan el
  nombre snapshot (o quedan sin cliente — decidir en implementación; default:
  conservar nombre snapshot).

**Criterios de aceptación.**
- Given un cliente con teléfono 7XXXXXXX, When toco "WhatsApp" en su cotización,
  Then se abre el deep link con `+5917XXXXXXX` y texto de resumen codificado.
- Given una cotización sin cliente, When la guardo, Then no hay error ni
  obligación de crear cliente.
- Given el historial, When filtro por cliente "Ana", Then veo solo sus
  cotizaciones.
- Given cero red dentro de la app, When creo/edito clientes, Then todo funciona
  offline (la apertura de WhatsApp es acción externa del usuario).

**Impacto en arquitectura.**
- Tabla nueva `customers`; `quotes.customer_id` FK nullable (ver §4).
- Feature nueva `lib/features/customers/` (o dentro de `history/` — decidir en
  planificación; se recomienda feature propia).

**Riesgos.** No es un CRM: evitar scope creep (sin seguimientos, sin recordatorios
— fuera de alcance). Formatos de teléfono raros: mitigar con validación laxa
(solo dígitos/+/espacios) y deep link tolerante.

---

#### F9. Simulador "qué pasa si" — Esfuerzo: M (Pro)

**Problema.** El usuario quiere explorar "¿qué margen me queda si bajo el
markup?" sin tocar (y arriesgar) sus parámetros reales.

**Solución.** Vista de sensibilidad con sliders sobre markup, tasa de falla,
descuento y precio/g, mostrando total y margen resultantes en vivo. **No
persiste nada.** Gateada a Pro.

**UX resumida.**
- Entrada desde el cotizador ("Simular") con el draft actual como caso base.
- 4 sliders con valor actual y rango (markup 0–100%, falla 0–30%, descuento
  0–50%, precio/g ±50% del base). Panel en vivo: total simulado, margen
  (`(total − costo) / total`), diferencia vs caso base.
- Botón "Restablecer" vuelve al caso base. Sin botón "guardar" en v1
  (Pregunta abierta #8).

**Reglas de negocio.**
- El motor de cálculo se reutiliza con parámetros sobrescritos en memoria; la DB
  no se toca. Estado de simulación en Riverpod (cálculo de negocio), posiciones
  de slider como UI efímera.
- Free: la entrada muestra el paywall existente.

**Criterios de aceptación.**
- Given un draft con total Bs 100, When abro el simulador, Then el caso base
  muestra Bs 100 y margen coherente con el desglose.
- When muevo el slider de markup, Then el total y margen se actualizan en vivo
  (<100 ms por tick en dispositivo objetivo).
- When cierro el simulador, Then ningún parámetro global ni draft cambió.
- Given usuario free, When toca "Simular", Then ve el paywall.

**Impacto en arquitectura.**
- Vista nueva en `calculation/presentation/`; notifier de simulación que recibe
  el caso base y parámetros sobrescritos. Sin esquema nuevo.

**Riesgos.** Recálculo por tick debe ser barato (el motor es puro: OK). Riesgo de
producto: el usuario espera "aplicar" el resultado — decidir con dueño antes de
prometerlo en UI.

---

#### F10. Modo alto contraste / sol directo — Esfuerzo: S

**Problema.** En ferias con sol directo, la legibilidad del mundo M3 estándar
baja: el usuario no puede mostrar el total con claridad justo cuando más lo
necesita.

**Solución.** Toggle de tema de alto contraste dentro del mismo mundo visual M3,
persistido en Parámetros.

**UX resumida.**
- Parámetros → "Apariencia": switch "Alto contraste (sol directo)". Aplica a
  toda la app al instante, sin reinicio.
- Implementación como variante de tokens del theme existente (contraste elevado
  en textos, bordes y superficies; el total sigue siendo el héroe visual).

**Criterios de aceptación.**
- Given el toggle activo, When navego cualquier pantalla (cotizador, historial,
  dashboard, catálogos, export preview), Then los textos cumplen contraste alto
  y no hay elementos ilegibles.
- Given el toggle, When lo cambio, Then el cambio es inmediato y persiste al
  reiniciar.
- Given el toggle activo, When desactivo, Then vuelvo exactamente al tema M3
  anterior.

**Impacto en arquitectura.**
- `core/theme/`: variante de alto contraste; `settings`: clave persistida. Sin
  esquema drift nuevo si settings lo soporta.

**Riesgos.** Auditoría visual de todas las pantallas (incluido el PDF/imagen de
cotización, que NO cambia: el export mantiene el diseño actual).

---

#### F11. Plantillas de cotización — Esfuerzo: S

**Problema.** El taller cotiza variantes de la misma pieza una y otra vez
(mismo diseño, distinto material/color): reconstruir desde cero cada vez es
ceremonia evitable.

**Solución.** Guardar una cotización como plantilla y duplicarla en 2 taps.

**UX resumida.**
- Desde el detalle de cotización/draft: "Guardar como plantilla" (pide nombre).
- Pantalla "Plantillas" (acceso desde el cotizador): lista con nombre, fecha y
  resumen. Tap → confirmación "Crear cotización" → se abre un draft nuevo
  prellenado (materiales, parámetros, cantidad) con material editable.
- Nota visible: "Valores guardados el <fecha>" (los precios son snapshot; el
  usuario ajusta si cambiaron).

**Reglas de negocio.**
- La plantilla guarda snapshot completo de inputs (no referencias vivas):
  cambiar el catálogo después no altera plantillas existentes.
- Editar/eliminar plantillas: gestión mínima (renombrar, borrar).

**Criterios de aceptación.**
- Given una cotización Express guardada como plantilla "Llavero logo", When la
  duplico, Then en ≤2 taps tengo un draft nuevo con los mismos valores y puedo
  cambiar el material.
- Given una plantilla guardada hace un mes, When la duplico tras cambiar precios
  del catálogo, Then conserva los valores snapshot (y muestra la fecha).
- Given el flujo Express normal, When no uso plantillas, Then no hay ningún paso
  adicional.

**Impacto en arquitectura.**
- Tabla nueva `quote_templates` con payload JSON serializado (ver §4).
- Reutiliza el mecanismo de draft/autosave existente para materializar la copia.

**Riesgos.** Deriva del formato del snapshot entre versiones de la app: mitigar
con campo `schema_version` dentro del payload y defaults tolerantes.

---

#### F12. Multi-moneda — Esfuerzo: M

**Problema.** El WIP de multi-moneda está abierto: parte del mercado piensa o
cobra en USD, y BOB hardcoded limita la adopción.

**Solución.** Selector de moneda de trabajo + tipo de cambio manual (sin red) +
formateo por locale. BOB sigue siendo la moneda base/canónica.

**UX resumida.**
- Parámetros → "Moneda": moneda de trabajo (default BOB; iniciales: BOB, USD) y
  tipo de cambio manual editable (Bs por unidad de la moneda elegida).
- Cotizador: la cotización nueva hereda la moneda de trabajo; el total y el
  desglose se muestran en esa moneda. Selector por cotización para casos
  puntuales.
- Export PDF/imagen y share en la moneda de la cotización.

**Reglas de negocio.**
- **BOB es canónico**: catálogo (precio/g de filamentos, costo de impresoras) y
  dashboard se mantienen en BOB. El motor calcula en BOB y convierte solo para
  mostrar/guardar el total en la moneda de la cotización.
- Cada cotización guarda snapshot `currency` + `exchange_rate` al crearse: el
  historial no cambia si el usuario edita el tipo de cambio después.
- Conversión con `decimal` (escala definida); redondeo de presentación por
  locale (es_BO para BOB; formato USD estándar).
- Cambiar el tipo de cambio global NO reescribe cotizaciones existentes.

**Criterios de aceptación.**
- Given moneda de trabajo USD con cambio manual Bs 6.9/USD, When creo una
  cotización cuyo total interno es Bs 69, Then veo USD 10.00 y el snapshot queda
  guardado.
- Given una cotización en USD creada ayer, When hoy cambio el tipo de cambio
  global, Then la cotización conserva su total y su rate snapshot.
- Given el dashboard, When lo abro, Then los montos están en BOB
  independientemente de la moneda de trabajo.
- Given BOB default, When no toco nada, Then la experiencia es idéntica a la v1.

**Impacto en arquitectura.**
- `quotes`: columnas `currency`, `exchange_rate` (ver §4). `settings`: moneda de
  trabajo + rate manual.
- `core/money/`: formateadores por moneda/locale y helper de conversión
  (solo capa de presentación). Motor de cálculo intacto (siempre BOB interno).

**Riesgos.** Confusión BOB-canónico vs display: mitigar con copy claro en
Parámetros. Redondeos de conversión en el desglose (la suma de líneas convertidas
puede no clavar el total convertido): regla de presentación — el total se
convierte directo, las líneas son aproximadas y se indica. Alcance de monedas:
empezar con 2 para no inflar QA.

---

## 3. Fuera de alcance explícito

| Ítem | Motivo |
|---|---|
| Reparación de mallas STL (no-manifold, huecos) | Complejidad de librería nativa incompatible con el alcance offline/web; estrategia de volumen firmado + fallback manual cubre el 95% |
| Sincronización cloud, cuentas, auth, multi-dispositivo | Viola la promesa central offline/privacidad; backup por archivo es la respuesta v2 |
| CRM completo (seguimientos, recordatorios, embudos, tareas) | Solo cliente ligero vinculado a cotizaciones; lo demás es otro producto |
| Precios de mercado / benchmarking / scraping de competidores | Requiere red; fuera de la promesa offline |
| Historial de compras de bobinas (lotes de compra) | F6 resuelve el costo/g puntual; la trazabilidad de compras es v3+ |
| Merge/upsert al importar backup | v2 solo reemplazo total (Pregunta abierta #3) |
| Notificaciones de vencimiento / recordatorios push | Cero red y cero background confiable; vencimiento calculado en lectura |
| Multi-usuario / modo equipo | Un solo dueño de taller por instalación |
| STL en formatos distintos de STL (3MF, OBJ, STEP) | Evaluar en v3 si la adopción de STL lo justifica |
| Aplicar resultados del simulador a la cotización real | Decisión de producto pendiente (Pregunta abierta #8) |
| Rediseño del PDF/imagen de cotización | Solo agrega bloques nuevos (lote, moneda); el diseño base no cambia |

---

## 4. Modelo de datos (drift, nivel conceptual)

> Detalle de tipos exactos y migraciones lo define `/plan`. Aquí: esquema
> conceptual. Dinero SIEMPRE como texto `decimal`; cantidades físicas como
> numérico no monetario.

### Tablas modificadas

**`filaments`** (F1, F4, F6)
- `+ density_g_cm3` REAL — densidad editable (default por tipo: PLA 1.24,
  PETG 1.27, ABS 1.04).
- `+ stock_g` REAL NULL — NULL = stock no controlado.
- `+ low_stock_g` REAL NULL — override del umbral global.
- (`price_per_g` existente: recibe el resultado de F6; sin cambio de esquema.)

**`printers`** (F5)
- `+ purchase_cost` TEXT NULL — costo de la impresora (`decimal`).
- `+ useful_life_hours` REAL NULL — vida útil estimada.

**`quotes`** (F2, F3, F8, F12)
- `+ quantity` INTEGER NOT NULL DEFAULT 1.
- `+ batch_discount_percent` TEXT NULL — snapshot `decimal`.
- `+ batch_discount_amount` TEXT NULL — snapshot `decimal`.
- `+ status` TEXT NOT NULL DEFAULT 'draft' — enum: draft/sent/accepted/
  rejected/expired/sold. Reemplaza `is_sold` (backfill: true→sold,
  false→sent; luego drop).
- `+ valid_until` TEXT NULL — ISO8601.
- `+ customer_id` TEXT NULL — FK a `customers` (nullable).
- `+ currency` TEXT NOT NULL DEFAULT 'BOB'.
- `+ exchange_rate` TEXT NULL — snapshot `decimal` (Bs por unidad).
- `+ exported_at` TEXT NULL — timestamp del primer export (para KPI de tiempo).

**`settings` / parámetros globales** (todas las fases)
- `+ quote_validity_days` (default 7), `+ low_stock_default_g`,
  `+ stl_print_speed_gph` (default 10), `+ high_contrast_enabled`,
  `+ working_currency` (default BOB), `+ manual_exchange_rate`.

### Tablas nuevas

**`customers`** (F8)
- `id` TEXT PK, `name` TEXT NOT NULL, `phone` TEXT NULL, `note` TEXT NULL,
  `created_at` TEXT.

**`discount_tiers`** (F2)
- `id` TEXT PK, `min_qty` INTEGER NOT NULL, `percent` TEXT NOT NULL (`decimal`),
  `sort_order` INTEGER.

**`quote_templates`** (F11)
- `id` TEXT PK, `name` TEXT NOT NULL, `payload_json` TEXT NOT NULL
  (snapshot de inputs + `schema_version` interno), `created_at` TEXT.

**`usage_counters`** (métricas offline, §5)
- `event_key` TEXT, `day` TEXT (AAAA-MM-DD), `count` INTEGER — PK compuesta.

### Migraciones (una por fase, aditivas)

- **M1 (fase 1)**: `quotes` + quantity/lote/status/valid_until/exported_at;
  backfill de `status` desde `is_sold`; drop de `is_sold`; crear
  `discount_tiers`. Claves de settings nuevas.
- **M2 (fase 2)**: `filaments` + density/stock/low_stock; `printers` +
  purchase_cost/useful_life_hours; settings de stock/velocidad.
- **M3 (fase 3)**: crear `customers`, `quote_templates`, `usage_counters`;
  `quotes` + customer_id/currency/exchange_rate; settings de moneda/contraste.

Principios de migración: siempre aditivas salvo el drop de `is_sold` (post
backfill verificado); defaults explícitos; tests de migración drift
obligatorios; idempotencia (una lectura no debe re-escribir dos veces).

---

## 5. Métricas de éxito y medición offline

Sin analytics de red (promesa central). Medición con `usage_counters`
(contadores locales agregados por día) + datos propios de las tablas.

**Eventos contados (mínimo):** `quote_created`, `quote_exported` (pdf/imagen),
`stl_imported`, `stl_used_in_quote`, `batch_used` (N>1), `status_changed_<x>`,
`quote_sold`, `backup_exported`, `backup_imported`, `template_used`,
`simulator_opened`, `customer_created`, `high_contrast_toggled`.

**Panel "Uso" en el dashboard** (agregados, sin red):
- Ticket promedio del período (desde `quotes` vendidas).
- Tiempo de cotización: mediana de `exported_at − created_at`.
- Conversión: vendidas / (enviadas+aceptadas+vendidas).
- Días activos (7/30) y top features usadas (desde `usage_counters`).
- Opción de reiniciar contadores en Parámetros.

**Criterio de éxito del release v2 completo:** al cierre de fase 3, el dueño
puede responder con datos locales: ¿subió el ticket con lotes?, ¿bajó el tiempo
con STL/plantillas?, ¿qué % de cotizaciones se vende? — y decidir v3 con esa
evidencia.

---

## 6. Riesgos globales y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Parseo STL lento/bloqueante en web (JS, archivos grandes) | Alta | Alto | Límites 15 MB web / 25 MB mobile, tope de triángulos, progreso incremental, tests con archivos reales; worker web como optimización futura |
| Mallas inválidas → volumen erróneo → precio erróneo | Media | Alto | Sanity checks de volumen, etiqueta "sugerido", valores siempre editables, fallback manual, nunca autoguardar sin CTA |
| Crecimiento de DB en IndexedDB (web) con historial Pro ilimitado | Media | Medio | Backup/restore como vía de alivio; monitorear tamaño en el panel de datos; considerar límites por plataforma en v3 |
| Migraciones drift en producción local sin rollback de servidor | Media | Alto | Migraciones aditivas, backfill con defaults, migration tests, reemplazo de backup transaccional, release por fases |
| Errores de precisión monetaria al sumar features al motor | Baja | Alto | `decimal` obligatorio, divisiones con escala explícita, tests unitarios del motor por cada feature, revisión con checklist |
| Scope creep: 12 features = ciclo largo | Alta | Medio | Gates por fase, cada fase enviable sola, cut-line tras fase 2, fuera de alcance explícito (§3) |
| Cambio de semántica del dashboard (estados) confunde al usuario | Media | Medio | Leyenda explicativa, migración que conserva totales, estados visibles en el detalle |
| Ambigüedad STL (unidades mm, factor de relleno) | Media | Medio | Suposición mm documentada + sanity check; factor de ajuste opcional; preguntas abiertas #4/#5 |
| Deep links `wa.me` cambian de formato | Baja | Bajo | Construcción del link aislada en un helper testeable |

---

## 7. Preguntas abiertas para el dueño de producto

> Las P1–P3 tienen default propuesto y bloquean planificación de sus features si
> no se confirman. El resto puede resolverse durante implementación.

1. **Lotes (F2):** ¿el descuento por cantidad se **suma** al descuento global
   existente (default propuesto: se suman, ambos visibles en el desglose) o lo
   **reemplaza** cuando hay lote?
2. **Estados (F3):** en la migración, las cotizaciones hoy "no vendidas" ¿van a
   `enviada` (default propuesto) o a `borrador`?
3. **Backup (F7):** ¿confirmás v1 con **solo reemplazo total** + auto-backup
   sugerido antes de importar (default propuesto), o exigís merge/upsert desde
   el inicio?
4. **STL (F1):** ¿la estimación de tiempo por heurística g/h (default 10 g/h,
   configurable) es aceptable, o preferís que el tiempo lo ingrese siempre el
   usuario?
5. **STL (F1):** ¿incluimos el factor de ajuste de relleno (multiplicador
   opcional, default 100%) en v2 o lo dejamos para v3?
6. **Clientes (F8):** ¿anteponemos `+591` automáticamente a números de 8
   dígitos (default propuesto) o pedimos el número completo siempre?
7. **Inventario (F4):** con stock insuficiente, ¿solo advertimos (default
   propuesto, stock piso en 0) o bloqueamos la venta?
8. **Simulador (F9):** ¿el simulador necesita botón "aplicar a la cotización"
   en v2 o alcanza con ver (default propuesto: solo ver)?
9. **Multi-moneda (F12):** ¿monedas iniciales solo BOB+USD? ¿confirmás BOB como
   base canónica (catálogo y dashboard siempre en BOB)?
10. **Densidades (F1):** ¿densidad editable **por filamento** con default por
    tipo (default propuesto) o un único valor global por tipo de material?

---

## 8. Hitos de entrega

| # | Hito | Resultado visible para el usuario | Estado | Plan |
|---|---|---|---|---|
| 1 | Fase 1 — Diferenciación | Cotiza desde STL, vende lotes con descuento y gestiona pipeline con estados/vencimiento | pending | — |
| 2 | Fase 2 — Operación | Controla stock real, costos completos (amortización + costo/g real) y respalda sus datos | pending | — |
| 3 | Fase 3 — Retención/UX | Reenvía a clientes por WhatsApp, simula escenarios, alto contraste, plantillas y multi-moneda | pending | — |

---

*Status: DRAFT — solo requerimientos. Planificación de implementación pendiente
vía `/plan` (un plan por hito).*
