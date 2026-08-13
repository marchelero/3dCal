# Auditoría de Seguridad — Production Readiness — 3dCalc

Fecha: 2026-08-13 · Agente: security-reviewer · Estado: SECURE WITH FIXES

## Top 5 riesgos (prioridad)

1. **[ALTO] Credenciales de firma en claro dentro del árbol del repo** — `android/key.properties:1-4` (storePassword/keyPassword en texto plano, storeFile con ruta absoluta) + `android/upload-keystore.jks` co-ubicados. Gitignored (sin leak hoy), pero un accidente (`git add -f`, zip, sync) compromete la clave de firma de Play. Mismo password para store y key. **Fix**: mover a `~/tresdcal-secrets/`, rutas relativas, env vars en CI, rotar passwords, verificar `git ls-files`.
2. **[MEDIO] Cache entitlement local tamperable (ventana 7 días)** — `is_pro`/`entitlement_source`/`entitlement_validated_at` en SharedPreferences + fila DB = Pro gratis vía root. **Fix**: `getCustomerInfo()` asíncrono en cada boot como autoridad; cache solo como fallback offline. (`entitlement_cache.dart:53-62`, `entitlement_notifier.dart:82-91`)
3. **[MEDIO] Sin listener de RevenueCat** — `purchaseStream` no escuchado, sin `addCustomerInfoUpdateListener` → refunds no detectados en tiempo real. (`payment_service_revenuecat.dart:187`)
4. **[MEDIO] Dependencia EOL `sqlite3_flutter_libs 0.6.0+eol`** — deprecada, redundante (drift 2.34 + sqlite3 3.5.1 bundlean SQLite); puede causar `dlopen libsqlite3.so` en toolchains nuevas. **Fix**: eliminar de `pubspec.yaml:32`.
5. **[BAJO] URLs legales placeholder `u3dcal.bo`** — requisito de Play Console para IAP; publicar con placeholder = riesgo de rechazo. (`app_constants.dart:146-150`)

## Otros hallazgos
- [BAJO] Logo empresa 512px sin tope de bytes ni imageQuality → base64 sin límite en settings + memoria en PDF. (`settings_page.dart:925-932`)
- [BAJO] `requestLegacyExternalStorage="true"` legacy (solo API≤29), eliminable. (`AndroidManifest.xml:15`)
- [BAJO] `int.parse(state.pathParameters['id']!)` sin catch de FormatException → crash ante deep link malformado. (`app_router.dart:139-143`)
- [BAJO] Draft de formulario en SharedPreferences sin cifrar (aceptable, no sensible).

## Verificado OK
- Sin secretos commiteados (git ls-files + git log --all; key.properties/jks/local.properties nunca trackeados)
- RevenueCat key vía --dart-define, no hardcodeada; `diagnosticsEnabled = kDebugMode`
- Entitlement check post-compra correcto (`entitlements.all['pro'].isActive`); restore maneja canceled/empty/error
- SQL: cero inyección (5 customSelect parametrizados o literales)
- Backup import: tope 5 MB, validación estructural, restore transaccional con rollback
- Image picker: re-encode 1024px/85, tope 5 MB
- url_launcher: solo 2 URLs HTTPS hardcodeadas, sin URLs de usuario
- Android: MainActivity única sin deep links, cleartext bloqueado, permisos mínimos
- Web: estático puro, sin CORS/servidor/keys; CI GitHub Pages sin REVENUECAT key (correcto)
- Dependencias: purchases_flutter 10.4.2 sin CVEs; pdf/printing/share_plus/file_picker/url_launcher/go_router/drift sin CVEs

## Veredicto
Sin vulnerabilidad explotable de forma remota (app 100% local). Acción bloqueante antes de release: **rotar + reubicar credenciales de firma** (punto 1). Puntos 2-4 hardening recomendado. Punto 5 requisito de Play Console.
