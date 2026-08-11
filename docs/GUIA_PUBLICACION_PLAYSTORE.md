# Guía de publicación de `tresdcal` en Google Play

**Última actualización:** 2026-08-11  
**Estado documentado:** preparación Android, integración RevenueCat y publicación en **Prueba interna**.  
**Aplicación:** `tresdcal`  
**Application ID / package:** `bo.u3dcal.tresdcal`  
**Versión del repositorio:** `0.1.0+1`

Esta guía resume el procedimiento realizado y sirve como runbook para repetirlo sin
guardar credenciales en el repositorio. Los nombres de menús corresponden a la interfaz
en español de Play Console/Google Cloud/RevenueCat; Google puede cambiar su traducción o
la ubicación de una opción.

## 1. Alcance y reglas de seguridad

- La compra es un desbloqueo único **no consumible** de **USD 4.99**.
- Producto en Google Play y RevenueCat: `tresdcal_pro_lifetime`.
- Entitlement de RevenueCat: `pro`.
- Offering: `default`.
- Package del offering: `lifetime`.
- No pegar en tickets, commits ni documentación: contraseña del keystore, alias secreto,
  JSON de service account, clave privada, API key privada, tokens ni archivos `.env`.
- La clave pública de RevenueCat se entrega al build mediante `--dart-define`; aun así,
  no debe registrarse aquí. Las credenciales de servidor de RevenueCat/Google nunca van
  dentro de la aplicación.

## 2. Estado técnico de la aplicación

Rutas relevantes:

| Elemento | Ruta/valor |
|---|---|
| Código Flutter | `lib/` |
| Dependencias y versión | `pubspec.yaml` |
| ID Android | `android/app/build.gradle.kts` |
| Firma Gradle | `android/app/build.gradle.kts` |
| Propiedades locales de firma | `android/key.properties` (no publicar) |
| Keystore de subida | `android/<UPLOAD_KEYSTORE>.jks` (no publicar) |
| AAB generado | `build/app/outputs/bundle/release/app-release.aab` |
| SDK RevenueCat | `purchases_flutter` en `pubspec.yaml` |
| Variable de build | `REVENUECAT_GOOGLE_KEY` |

La configuración release ya carga `key.properties`, usa el signing config `release`,
mantiene minificación/recursos reducidos y genera el AAB con la upload key. La firma de
la distribución final la gestiona **Play App Signing**; la clave local es únicamente la
clave de subida.

## 3. Preparación Flutter y Android

Desde la raíz `D:\dev\2026\3dCal`:

```powershell
flutter doctor
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Comprobación previa de Android:

```powershell
flutter devices
flutter build apk --debug
flutter build apk --release
```

La app usa `bo.u3dcal.tresdcal` en `namespace` y `applicationId`. La versión se toma de
`pubspec.yaml`; aumentar `versionCode` en cada subida aceptada por Play.

### 3.1 Release signing y upload keystore

Crear la upload key una sola vez, fuera de una carpeta pública y usando placeholders en
esta guía:

```powershell
keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\<RUTA_SEGURA>\<UPLOAD_KEYSTORE>.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
  -alias <UPLOAD_KEY_ALIAS>
```

Guardar el archivo en un lugar respaldado y restringido. No regenerarlo: perder la upload
key complica las subidas posteriores. Configurar `android/key.properties` con valores
locales, sin copiar el contenido real aquí:

```properties
storePassword=<UPLOAD_STORE_PASSWORD>
keyPassword=<UPLOAD_KEY_PASSWORD>
keyAlias=<UPLOAD_KEY_ALIAS>
storeFile=<RUTA_ABSOLUTA_AL_UPLOAD_KEYSTORE>
```

Verificar que `android/app/build.gradle.kts` lea ese archivo antes de `android {}` y que
`buildTypes.release.signingConfig` apunte a `signingConfigs.release`. Confirmar también
que `key.properties` y el `.jks` estén ignorados por Git:

```powershell
git check-ignore android/key.properties android/<UPLOAD_KEYSTORE>.jks
```

Si se habilita Play App Signing durante la primera publicación, aceptar que Google genere
o aloje la **app signing key** y conservar solo el respaldo indicado por Play. Subir el
AAB firmado con la upload key, nunca con el keystore debug.

### 3.2 Build AAB con RevenueCat sin revelar la clave

La clave pública de Google Play de RevenueCat debe estar disponible solo en la máquina o
en el sistema CI. Ejemplo seguro con archivo local ignorado:

`tool/secrets/revenuecat.dart-define.json` (no versionar):

```json
{
  "REVENUECAT_GOOGLE_KEY": "<REVENUECAT_PUBLIC_GOOGLE_KEY>"
}
```

Build reproducible:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release `
  --dart-define-from-file=tool/secrets/revenuecat.dart-define.json
```

Alternativa, sin crear el archivo:

```powershell
flutter build appbundle --release `
  --dart-define=REVENUECAT_GOOGLE_KEY=<REVENUECAT_PUBLIC_GOOGLE_KEY>
```

Resultado esperado: `build/app/outputs/bundle/release/app-release.aab`. Antes de subirlo,
comprobar que sea release, que tenga `bo.u3dcal.tresdcal` y que no se esté usando el
keystore debug. No imprimir el comando completo en logs compartidos.

## 4. Configuración de Google Cloud y permisos

### 4.1 Proyecto y service account

1. Abrir Google Cloud Console y crear el proyecto **`tresdcal-revenuecat`**.
2. Seleccionar ese proyecto → **IAM y administración** → **Cuentas de servicio** →
   **Crear cuenta de servicio**.
3. Crear la cuenta **`revenuecat-tresdcal`** con una descripción identificable.
4. Conceder solo los roles necesarios para la integración con Play Console. Si el flujo
   de creación solicita el rol de identidad, usar **Usuario de cuenta de servicio**.
5. En la cuenta → **Claves** → **Agregar clave** → **Crear clave nueva** → **JSON**.
6. Descargar el JSON una sola vez, guardarlo en un almacén seguro y no abrirlo en un
   editor compartido ni subirlo a Git. Esta guía no contiene su nombre ni contenido.

### 4.2 Vincular la cuenta en Play Console

1. En Play Console, abrir **Usuarios y permisos**.
2. Pulsar **Invitar usuario nuevo** y pegar el correo `client_email` del JSON de
   `revenuecat-tresdcal`.
3. En **Permisos de la app**, agregar `tresdcal` (`bo.u3dcal.tresdcal`).
4. Conceder como mínimo:
   - **Ver los datos financieros**.
   - **Administrar los pedidos y las suscripciones**.
5. Guardar y esperar la propagación. Si RevenueCat devuelve 403, revisar que la cuenta
   tenga acceso a la aplicación correcta, no solo al proyecto de Cloud.

## 5. RevenueCat

En el panel de RevenueCat:

1. Crear/seleccionar el proyecto **`tresdcal`**.
2. **Configuración del proyecto** → **Aplicaciones** → **Añadir aplicación** →
   **Google Play Store**.
3. Introducir package `bo.u3dcal.tresdcal` y cargar el JSON de
   `revenuecat-tresdcal`. No guardar ese JSON dentro del repositorio.
4. En **Claves de API**, copiar la **clave pública específica de la aplicación** de
   Google Play. Usarla únicamente como `<REVENUECAT_PUBLIC_GOOGLE_KEY>` en el build.

### 5.1 Entitlement, producto y offering

1. **Entitlements** → **Nuevo entitlement** → identificador `pro`.
2. **Productos** → **Nuevo producto**:
   - aplicación: Google Play;
   - identificador: `tresdcal_pro_lifetime`;
   - tipo: no consumible;
   - asociar al entitlement `pro`.
3. **Offerings** → crear/seleccionar `default` y marcarlo como offering actual/default.
4. **Añadir paquete** → identificador `lifetime` → duración/tipo **No consumible** →
   asociar `tresdcal_pro_lifetime`.

La cadena debe coincidir exactamente en los tres lugares: Play Console, RevenueCat y
código. RevenueCat usa la clave pública en el cliente; la validación de la compra se hace
contra la tienda mediante la integración configurada.

## 6. Google Play Console

### 6.1 Aplicación y producto único

1. **Todas las aplicaciones** → **Crear aplicación** (si aún no existe): tipo
   **Aplicación**, gratuita inicialmente, nombre `tresdcal` y package correcto.
2. **Monetiza con Play** → **Productos** → **Productos únicos** → **Crear un producto
   único**.
3. Configurar:
   - ID del producto: `tresdcal_pro_lifetime`;
   - nombre: `tresdcal Pro`;
   - descripción: desbloqueo de funciones Pro;
   - tipo: producto único **no consumible**;
   - precio base: **USD 4.99**.
4. Guardar y **Activar** el producto. Un producto en borrador/inactivo produce errores
   de artículo no disponible aunque RevenueCat esté bien configurado.

### 6.2 Merchant account

1. Play Console → **Configuración** → **Cuenta de desarrollador** → **Perfil de pagos**
   (la etiqueta puede aparecer como **Cuenta de comerciante**).
2. Crear o vincular el perfil de pagos/merchant account con los datos legales y bancarios
   solicitados por Google.
3. Completar verificaciones y aceptar los acuerdos de productos pagados. Sin merchant
   account activo, el producto o el cobro pueden quedar bloqueados aunque el precio esté
   definido.

### 6.3 Licencias y lista de verificadores

1. **Configuración** → **Pruebas de licencia**.
2. **Añadir verificadores** y agregar las cuentas Google que harán la compra de prueba:
   `<TESTER_EMAIL_1>`, `<TESTER_EMAIL_2>`.
3. Guardar. Esperar normalmente entre 5 y 15 minutos y usar esas mismas cuentas en Play
   Store del dispositivo.

### 6.4 Prueba interna y enlace

1. **Pruebas** → **Prueba interna** → **Crear nueva versión**.
2. Subir `app-release.aab`, revisar advertencias y publicar la versión para pruebas.
3. Pestaña **Verificadores** → **Crear lista de correo** (o seleccionar una existente).
4. Añadir la lista de correos de prueba, guardar y abrir **Enlace de participación**.
5. Registrar aquí solo el enlace operativo cuando exista:
   `https://play.google.com/apps/internaltest/<INTERNAL_TEST_ID>`
6. Cada verificador debe abrir el enlace con la cuenta correcta, aceptar participar y
   luego instalar/actualizar desde Play Store. La compra de prueba debe usar esa cuenta,
   no necesariamente la cuenta administradora de Play Console.

## 7. Verificación de extremo a extremo

- [ ] AAB release subido y disponible en **Prueba interna**.
- [ ] Verificador incluido en la lista de prueba y en **Pruebas de licencia**.
- [ ] Enlace de participación abre con la cuenta Google correcta.
- [ ] App instalada desde Play Store, no desde `flutter install` ni APK debug.
- [ ] Producto `tresdcal_pro_lifetime` activo y visible en Play Console.
- [ ] RevenueCat muestra producto, entitlement `pro`, offering `default` y package
      `lifetime` conectados.
- [ ] Paywall muestra USD 4.99 y compra única.
- [ ] Compra sandbox desbloquea Pro.
- [ ] **Restaurar compras** recupera `pro` sin iniciar sesión propia de la app.
- [ ] RevenueCat → **Clientes** muestra el entitlement `pro` activo para el verificador.
- [ ] No hay claves, JSON, contraseñas o logs sensibles en Git.

## 8. Troubleshooting

### “El AAB está firmado en debug”

**Causa habitual:** se subió `app-debug.aab`/APK, `key.properties` no se cargó, o el
build release no apuntó al signing config.

**Corrección:**

1. Confirmar que el archivo sea `build/app/outputs/bundle/release/app-release.aab`.
2. Confirmar que `android/key.properties` exista localmente y que `storeFile` apunte al
   upload keystore correcto.
3. Confirmar `signingConfig = signingConfigs.getByName("release")` en `build.gradle.kts`.
4. Ejecutar `flutter clean` y repetir `flutter build appbundle --release` con el
   `dart-define` seguro.
5. Subir el AAB nuevo. Play App Signing no convierte un AAB debug en un release válido.

### RevenueCat: “Could not check”

Revisar en este orden:

1. **Configuración del proyecto** → **Aplicaciones**: package exacto
   `bo.u3dcal.tresdcal`.
2. Google Cloud: proyecto `tresdcal-revenuecat`, cuenta
   `revenuecat-tresdcal`, JSON vigente y sin corrupción.
3. Play Console → **Usuarios y permisos**: abrir la cuenta de servicio y confirmar que
   la app `tresdcal` está asignada y que están activos **Ver los datos financieros** y
   **Administrar los pedidos y las suscripciones**.
4. Esperar propagación de permisos y volver a guardar la app en RevenueCat.
5. Confirmar que Play Console tenga creada la aplicación y que el producto exista y esté
   activo.
6. No confundir la clave pública `goog_...` del SDK con el JSON/credencial de servidor.

### Enlace del tester: “No se encontró el elemento”

1. La versión puede estar guardada pero no publicada en la pista **Prueba interna**.
   Completar **Revisar versión** → **Iniciar implementación**.
2. Abrir el enlace con la cuenta Google que figura en la lista de verificadores; salir de
   otras cuentas del navegador o usar una ventana de perfil correcto.
3. Confirmar que el enlace es el de **Enlace de participación** de la app correcta, no
   un enlace antiguo/regional.
4. Esperar a que Play propague la versión y volver a copiar el enlace desde la pestaña
   **Verificadores**.
5. Si el verificador ya participó en otra versión, abrir primero la ficha de prueba,
   aceptar la participación y después instalar desde Play Store.

### Producto no encontrado o compra no disponible

- Producto inactivo: pulsar **Activar** en el producto único.
- App instalada fuera de Play: instalar desde el enlace de prueba interna.
- Package o firma distintos: comprobar `bo.u3dcal.tresdcal` y usar upload key.
- Cuenta incorrecta o licencia aún no propagada: revisar **Pruebas de licencia** y
  esperar 5–15 minutos.
- Offering sin package: asociar `lifetime` al producto exacto en RevenueCat.

## 9. Referencias internas

- [`docs/notes/revenuecat-setup.md`](notes/revenuecat-setup.md): configuración inicial.
- [`docs/notes/store-compliance.md`](notes/store-compliance.md): cumplimiento de tienda.
- [`docs/reports/2026-08-09_0240-free-pro-playstore-prep.report.md`](reports/2026-08-09_0240-free-pro-playstore-prep.report.md): resultados de preparación.
- [`android/app/build.gradle.kts`](../android/app/build.gradle.kts): firma release.
- [`pubspec.yaml`](../pubspec.yaml): versión y `purchases_flutter`.
