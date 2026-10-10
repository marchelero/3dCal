# PRD — Corrección de brechas detectadas en revisión de 3dCal

**Fecha:** 2026-10-10 · **Estado:** aprobado para implementación por solicitud “corrígelo todo”
**Base:** `main` @ `57f218c` · Flutter mobile/web · local/offline · Drift schema 17 · cinco locales.

## Objetivo

Cerrar defectos verificables y brechas de UX/operación señaladas por la revisión estática, sin cambiar silenciosamente decisiones legales/comerciales ni inventar configuración externa.

## Supuestos seguros para esta ronda

- Mantener Android como la plataforma de compra Pro; actualizar documentación para no prometer compras iOS.
- Mantener `WEB_UNLOCK_ALL=true` por defecto; no existe checkout web.
- Mantener las URLs legales actuales temporalmente: el dueño aún debe publicar Términos separados; no inventar texto legal ni URL.
- Mejorar aviso y recuperación de backups, sin añadir cifrado/password ni tocar el formato existente en esta ronda.
- Mantener la app offline: no implementar conversión de moneda con tasas externas. Aclarar que la moneda cambia presentación, no valor/tasa.
- Eliminar datos locales de usuario debe preservar una compra Pro verificable/recuperable desde la tienda, pero borrar cotizaciones, borradores, catálogos y ajustes locales; no borra archivos `.3dcal` exportados fuera de la app.
- Alcance concreto de borrado: una transacción borra `calculations` (incluye drafts/templates; materiales por cascade), `printers`, `filaments`, `settings` y `discount_tiers`; borrar `form_draft` y `active_printer_id`; resetear `onboarding_done` para que el usuario vuelva a configurar catálogos. Preservar locale, tema, entitlement DB/cache, HMAC install key e identidad RevenueCat. No usar `SharedPreferences.clear()`.
- El repositorio usa GitHub (`origin`); CI se limita a analyze, tests y build web. No incluir firma ni publicación.

## Criterios de aceptación

### Función y datos
- **AC-001 (P1):** La cantidad nunca supera `1..kMaxQuantity` (9999), incluso con botón `+`, entrada directa o llamada al notifier. En el máximo, `+` queda deshabilitado o no altera el valor.
- **AC-002 (P1):** Precio/gramos de filamento se validan antes de `Decimal.parse`; gramos vacío, decimal o no positivo no se guardan. Toda excepción restablece loading y da feedback localizado.
- **AC-003 (P1):** Reabrir un formulario recuperado no duplica parcial. Al guardar, el parcial original se convierte o se reemplaza transaccionalmente y queda una sola cotización definitiva. Debe existir regresión widget+Drift antes del fix.
- **AC-004 (P2):** Settings permite borrar datos de trabajo locales tras confirmación explícita y localizada. La operación elimina cotizaciones (incluyendo drafts/templates), catálogos, ajustes de cálculo y draft de sesión; elimina la impresora activa y reinicia onboarding para reconfigurar catálogos. Preserva locale/tema, entitlement y cache Pro, y claves de firma HMAC. No pretende borrar exportaciones externas.
- **AC-005 (P2):** Los cinco idiomas describen coherentemente filamento/gramos como requeridos durante onboarding.

### Privacidad y experiencia
- **AC-006 (P2):** La app explica que el backup es manual, no se sincroniza automáticamente y el `.3dcal` exportado no está cifrado; HMAC se describe como verificación de integridad, no cifrado. La política de backups Android se mantiene sin cambios.
- **AC-007 (P2):** El copy de privacidad se corresponde con el flujo local de borrado y no implica borrar archivos exportados.
- **AC-008 (P3):** El manifest PWA deja de incluir descripción/color de Flutter template y usa identidad de 3dCal.
- **AC-009 (P3):** La ayuda de monedas deja claro que seleccionar moneda no convierte importes ni usa tasas de cambio.

### Release/soporte
- **AC-010 (P2):** GitHub Actions en pull requests ejecuta Flutter analyze, suite de tests y web build; workflow no usa secretos ni firma artefactos.
- **AC-011 (P2):** Tests de migración crean bases v1/v2/v3 representativas y las migran a schema 17, verificando datos y defaults relevantes.
- **AC-012 (P2):** Añadir checklist reproducible para sandbox Play/RevenueCat: compra, restore, cancelación y revocación/refund; declarar explícitamente que requiere track/cuentas externas.
- **AC-013 (P2):** README/docs describen correctamente Android como plataforma de pagos soportada; no afirmar que iOS ofrece Pro hasta implementar StoreKit.
- **AC-014:** Mantener intactas las URLs temporales de Privacy/ToS y el comportamiento web Pro; registrar como acción externa pendiente publicar términos separados y pegarlos en Play Console.

## Fuera de alcance

Crear contenido/hosting legal, integrar pagos Apple o checkout web, añadir cifrado al formato backup, sincronización cloud, conversión FX, publicar/desplegar, configurar Play Console/RevenueCat, gestionar credenciales/copias de keystore, licencia comercial. Requieren decisiones o acceso del dueño.

## Verificación requerida

- Tests unit/widget/integration nuevos para AC-001 a AC-005 y AC-011.
- `flutter analyze`, `flutter test`, `flutter build web`; CI valida los mismos gates.
- Revisión manual/externa para sandbox store, URLs legales y hosting; marcar UNKNOWN si no hay credenciales.
- Revisión de código especializada antes de cerrar; actualizar `docs/reports/` y `docs/audits/`.
