# Play Sandbox — Checklist reproducible (tresdcal Pro)

Verificación manual en **sandbox** de Google Play + RevenueCat para `tresdcal_pro_lifetime`.
Reproduce los 4 flujos que el código implementa: **compra**, **restore**, **cancelación** y
**revocación/refund** (detección en boot).

> **Requisito explícito**: este checklist NO es automático ni reproducible sin acceso a
> **cuentas externas**: Play Console (licencias de prueba + track de prueba interna),
> RevenueCat dashboard y una cuenta de Google **licensed tester** distinta de la
> administradora. Sin esos accesos, el checklist es una guía, no una validación.

## Precondiciones (una sola vez)

- [ ] App configurada: `--dart-define=REVENUECAT_GOOGLE_KEY=...` presente en el build (Android, no debug por `flutter install`).
- [ ] Producto `tresdcal_pro_lifetime` **activado** en Play Console (`Monetiza con Play` → `Productos` → `Productos únicos`).
- [ ] RevenueCat: proyecto `tresdcal`, entitlement `pro`, offering `default`, package `lifetime` vinculado al producto de Google Play.
- [ ] Play Console → `Configuración` → `Licencias de prueba`: **licensed testers** agregados (cuenta de prueba, no la admin).
- [ ] Play Console → `Prueba` → `Prueba interna`: build AAB subido y aprobado; enlace de opt-in copiado.
- [ ] Dispositivo: instalación **desde Play Store** usando el enlace de opt-in con la cuenta **licensed tester** (NO `flutter install`).
- [ ] Recordar pago de prueba: Google NO cobra con licencias de prueba, pero puede exigir método de pago registrado.

## Flujo 1 — Compra sandbox

1. Abrir la app → ir a la feature Pro (paywall o gate).
2. Confirmar en el paywall: precio `$4.99`, botón **Restore**, enlaces Privacy/Terms.
3. Pulsar comprar → completar el diálogo de Google Play (sin cargo real).
4. Esperar a que el gate se desbloquee (`isPro == true`; en tests o logs: entitlement `pro` activo).
5. **Verificación externa**: RevenueCat → `Clientes` → cuenta tester muestra entitlement `pro` activo, fecha de compra y `tresdcal_pro_lifetime`.

## Flujo 2 — Restore

1. Borrar datos de la app (o reinstalar desde Play Store) para limpiar `EntitlementCache`.
2. Abrir la app → paywall → **Restore**.
3. Resultado esperado: snackbar de éxito y Pro desbloqueado **sin segundo cargo** (la compra es non-consumable vinculada a la cuenta de Play).
4. Si aparece "no purchases to restore": el tester/usuario no tiene la compra en esa cuenta de Google — verificar cuenta en Play Store.

## Flujo 3 — Cancelación

1. En Play Console: revocar la licencia de prueba del tester (o cancelar el pedido).
2. **Sin reiniciar la app**: el entitlement sigue activo en cache (comportamiento esperado: la app no consulta en vivo).
3. Reabrir la app (o reiniciar) → la app detecta el estado en boot o en la siguiente restauración → Pro queda bloqueado para esa cuenta.

## Flujo 4 — Revocación / Refund

1. Play Console → gestor de pedidos → **reembolsar** el pedido del tester.
2. Reabrir la app → **detección de refund/revocación en boot**:
   - `EntitlementCache` se invalida;
   - el estado vuelve a free (gates activos).
3. Verificar que una **compra real** (fuera de sandbox) NO se ve afectada por reembolsos de prueba.

## Reglas de oro

- [ ] Probar SIEMPRE con licensed tester; una compra con cuenta admin puede quedar "fantasma" para RevenueCat.
- [ ] Cerrar sesión de evaluación de Google Play (Play Store → `Configuración` → `Cuenta de evaluación`) al terminar.
- [ ] Registrar resultados con fecha y versión (ej. `v0.6.0+13`) en `docs/reports/`.

---

Relacionado: `docs/notes/store-compliance.md` (cumplimiento), `docs/notes/revenuecat-setup.md` (setup T7/T8),
`docs/GUIA_PUBLICACION_PLAYSTORE.md` (runbook completo de publicación Android).