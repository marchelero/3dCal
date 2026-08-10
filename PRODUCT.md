# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

Flutter cross-platform: la misma app corre en iOS y web (build estático) con el mismo mundo Material 3. La escena primaria es un dispositivo móvil en mano, en el punto de venta.

## Users

Dueño de taller de impresión 3D (o maker/freelance que vende piezas) que cotiza **frente al cliente**, en el local, en una feria o en el taller. Job: calcular un precio justo y desglosado en segundos, mostrarlo y cerrar la venta ahí mismo. Modo empresa disponible (logo + nombre propios del usuario en la cotización).

## Product Purpose

Calculadora reactiva de precios para impresión 3D: entrada de pieza/materiales/tiempo → precio total al instante, con desglose honesto y defendible. Incluye catálogo local de filamentos e impresoras, historial de cotizaciones (con estado vendido/no vendido) y dashboard de ganancias reales vs cotizadas. 100% offline, sin auth, sin backend, privacidad absoluta.

## Positioning

Precio exacto, desglosado y defendible **al instante, sin internet**, en el bolsillo del vendedor. Multi-material + costos reales (filamento, energía por watts de impresora, mano de obra, post-procesado, tasa de falla, markup, descuento) en el punto de venta: el vendedor no improvisa precios frente al cliente.

## Operating Context

- Taller / feria / local: ruido, luz variable (incluido sol directo), pieza en mano, cliente esperando.
- El total es la meta: velocidad de llegada y claridad del número son críticas para cerrar la venta.
- Uso frecuente de pie, con una mano, pantalla táctil.
- La cotización se cierra en pantalla y se envía por WhatsApp/PDF/imagen.
- Autosave de draft local: el usuario puede retomar una cotización a medias.

## Capabilities and Constraints

- Modo Express (3 inputs: peso, precio/gramos de filamento, tiempo) visible por defecto — regla del 95%: la mayoría de cotizaciones son de una pieza simple.
- Modo Advanced multi-material (Pro): N materiales, cada uno con peso/precio/gramos, agregable y removible.
- Catálogos locales CRUD: filamentos e impresoras (marca, watts promedio).
- Historial: 10 cotizaciones free / ilimitado Pro; toggle vendido/no vendido.
- Dashboard: ganancias reales vs cotizadas (bar chart mensual).
- Paywall RevenueCat (Pro).
- Export: PDF + imagen de cotización (quote_image_template), share por plataforma.
- Parámetros: mano de obra, post-procesado, tasa de falla, markup, descuento, mínimos.
- i18n: es_BO default; moneda BOB hardcoded; multi-currency WIP.
- Técnico: Flutter 3.x, Riverpod 2.x codegen (prohibido setState en vistas dinámicas), drift SQLite (web: IndexedDB), `decimal` para dinero (prohibido double en el motor), fl_chart.
- Sin backend, sin auth, sin cloud sync. Cero red.

## Brand Commitments

- Nombre: 3dCal (3D Cal). Meta description: "Cotizaciones 3D precisas, rapidas y sin internet".
- Idioma UI: español (es_BO); comentarios técnicos en español, identificadores en inglés.
- Modo empresa: el usuario puede cargar su propio logo y nombre (identidad del cliente, no de la app).
- Sin assets de marca oficiales binding; favicon/logo actual es placeholder genérico de Flutter starter.

## Evidence on Hand

- Ningún testimonio, cliente, caso, benchmark o claim comercial real — no fabricar.
- Código fuente completo (lib/), motor de cálculo puro testeado (test/unit), i18n es_bo.dart.
- Flujo completo de cotización implementado y funcional (express/advanced, draft, historial, export).

## Product Principles

1. **El total es el héroe.** Toda la pantalla empuja al precio: llegada rápida, número grande y legible, desglose disponible pero no interpuesto.
2. **Desglose honesto y defendible.** Cada componente del precio (filamento, energía, mano de obra, falla, markup, descuento) es visible y explicable frente al cliente.
3. **Velocidad sobre ceremonia.** Menos fricción para el caso 95% (una pieza simple); la potencia multi-material existe pero no estorba.
4. **Offline y privado como promesa central.** Cero red, cero auth: la app nunca depende de conectividad para cerrar una venta.
5. **Un solo mundo visual en toda la app.** El rediseño reemplaza el mundo completo (theme, tokens, componentes, todas las superficies), no solo el cotizador.
