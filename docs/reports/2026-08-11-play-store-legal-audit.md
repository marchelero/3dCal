# Auditoría preliminar: documentos legales y Google Play

## Veredicto

Los documentos actuales no deben considerarse listos para publicar. La app es mayormente local, pero Android usa Google Play Billing/RevenueCat y permite exportar o compartir datos comerciales fuera de la app.

## Hallazgos prioritarios

1. Las rutas internas `/legal/privacy` y `/legal/terms` no sustituyen una política de privacidad publicada en una URL pública y accesible para Play Console. Las URLs configuradas actualmente siguen marcadas como pendientes.
2. La política debe identificar al responsable, correo de privacidad, jurisdicción, categorías de datos, finalidad, terceros (Google Play y RevenueCat), transferencias, retención, derechos y procedimiento de eliminación.
3. Debe describir cotizaciones, nombres de clientes, empresa, logo, imágenes, catálogos, borradores, backups, PDF/PNG y los datos que el usuario entrega al destino de compartir.
4. Debe evitar afirmaciones absolutas como “100% local” o “sin telemetría”: no hay backend/analytics propio, pero sí existen comunicaciones de compras/restauración y un identificador anónimo del proveedor de compras.
5. Los términos deben identificar al proveedor, explicar que Pro es una compra única si esa condición está confirmada en Play Console, y remitir compras, restauraciones y reembolsos a las condiciones de Google Play.

## Ajuste aplicado

Se retiraron de la interfaz y de los documentos las afirmaciones de que la aplicación es “100% local”, “sin telemetría” o que funciona “sin internet”.

## Datos recibidos del responsable

- Responsable: Juan Marcelo Albis Ortiz.
- Contacto: marcheloalbis@gmail.com.
- País: Bolivia.
- RevenueCat: activo en producción.
- Edad mínima declarada: 10 años.
- Dominio público: todavía no disponible.

## Información pendiente antes de una versión publicable

- Dominio público donde se alojarán Privacy Policy y Terms.

La ausencia de una URL pública HTTPS sigue bloqueando la publicación como política enlazable en Play Console. El texto interno ya fue actualizado, pero no debe considerarse sustituto de esa URL. Una edad mínima de 10 años incluye potencialmente a menores: la audiencia, la sección Families y las declaraciones de datos de Play Console deben configurarse de forma coherente. La aplicación actualmente no implementa una verificación automática de edad.

Este documento es una revisión técnica de cumplimiento, no asesoría legal.
