# RevenueCat + Google Play setup (T7/T8)

Guia paso a paso para configurar pagos in-app de **tresdcal Pro**
($4.99 USD, one-time unlock). El codigo de la app (T9) consume la config
que generes aca.

**Package name**: `bo.u3dcal.tresdcal` (definido en
`android/app/build.gradle.kts:8,19`).

**Product ID**: `tresdcal_pro_lifetime` (non-consumable).

**Entitlement ID**: `pro`.

**Offering ID**: `default`.

---

## 1. RevenueCat (cloud dashboard)

### 1.1 Crear cuenta / proyecto

1. Ir a https://app.revenuecat.com/signup → signup con Google (recomendado,
   mismo email que Play Console).
2. Click **Create new project** → nombre `tresdcal` → confirm.
3. Quedas en Project Settings.

### 1.2 Conectar Google Play service

En Project Settings → **Apps** → **Add app** → **Google Play Store**:

- **Package name**: `bo.u3dcal.tresdcal`
- **Service account JSON**: (subir archivo del paso 2.4)

### 1.3 Obtener public SDK key

Project Settings → **API keys** → seccion **Public app-specific API keys**:

- Copiar la key que empieza con `goog_` (es la unica que se hardcodea en
  el cliente Android).
- Guardar localmente — la va a usar T9.

### 1.4 Crear entitlement

Left menu → **Entitlements** → **+ New**:

- **Identifier**: `pro` (sin espacios, lowercase)
- **Description**: "tresdcal Pro features"

### 1.5 Crear product

Left menu → **Products** → **+ New**:

- **App**: Google Play (la unica que tenemos)
- **Product identifier**: `tresdcal_pro_lifetime` (mismo ID que en Play
  Console, paso 2.1)
- **Entitlement**: attach → `pro`

### 1.6 Crear offering

Left menu → **Offerings** → **+ New**:

- **Identifier**: `default` (RC usa "default" automaticamente como
  offering principal, pero confirmar)
- **Package**: **+ Add package** → identifier `lifetime` → duration
  `Non-Consumable` → attach product `tresdcal_pro_lifetime` del paso 1.5.

---

## 2. Google Play Console

### 2.1 Crear IAP product

1. Play Console → app **tresdcal** (crear app primero si no existe —
   wizard de "Create app", tipo Application, gratis).
2. **Monetize** → **Products** → **In-app products** → **Create product**.
3. Llenar:
   - **Product ID**: `tresdcal_pro_lifetime`
   - **Name**: "tresdcal Pro"
   - **Description**: "Unlocks all Pro features: custom branding, advanced
     calculator, unlimited history, CSV export, dashboard charts."
   - **Price**: **Set price** → USD → $4.99
4. **Activate** (toggle arriba a derecha). Sin activar, el SDK tira
   "Item not found".

### 2.2 License testers (sandbox)

1. Play Console → **Setup** → **License testing**.
2. **Add testers** → agregar el email Google del user (el que va a usar
   para hacer compras de prueba).
3. **Save changes**. **No tomar efecto hasta 5-15 min** (cache de Google).

### 2.3 Internal testing track (para instalar APK de test)

1. Play Console → **Testing** → **Internal testing** → **Create new
   release**.
2. Subir APK signed (debug keystore sirve para internal testing).
3. **Testers** tab → **Create email list** → agregar mismo email de
   license tester → opt-in URL.
4. Abrir opt-in URL en el device → instalar → loguear con la tester
   account cuando Play pida.

### 2.4 Service account JSON (para RevenueCat)

1. Play Console → **Setup** → **API access**.
2. Si nunca configuraste: **Create new service account** → te lleva a
   Google Cloud Console.
3. En GCP: **Create service account** → nombre `revenuecat-tresdcal` →
   role **Service Account User** → **Done**.
4. **Keys** tab → **Add key** → **Create new key** → JSON → download
   archivo `.json` (guardar seguro).
5. Volver a Play Console → **API access** → **Grant access** al service
   account nuevo → permisos:
   - View app information
   - Manage in-app products
   - View financial data
6. Subir el `.json` a RevenueCat → paso 1.2.

---

## 3. En la app (codigo, contexto para T9)

- `lib/core/constants/revenuecat_keys.dart` (nuevo, T9 lo crea):
  ```dart
  class RevenueCatKeys {
    static const android = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  }
  ```
- `lib/main.dart` (T9 modifica), despues de `ensureInitialized`:
  ```dart
  await Purchases.configure(
    PurchasesConfiguration(RevenueCatKeys.android),
  );
  ```
- Build: `flutter build apk --debug --dart-define=REVENUECAT_GOOGLE_KEY=goog_XXX`
  o pasar via `--dart-define-from-file=secrets.json` (NO commitear el
  secrets.json).

---

## 4. Verificacion T21

### Compra sandbox

1. Build con la SDK key real (paso 1.3).
2. Install en device con internal testing (paso 2.3).
3. Loguear con la license tester account (paso 2.2).
4. Abrir app → tap paywall → tap **Comprar**.
5. Play muestra el sheet de pago, tarjeta de prueba `4242 4242 4242 4242`,
   fecha futura, CVC cualquiera.
6. Compra exitosa → paywall cierra → features Pro se desbloquean (no
   mas cap 10, CSV enabled, charts visibles).

### Verificar en RevenueCat

Dashboard → **Customers** → aparece la tester account con entitlement
`pro` activo. **Charts** tab → evento de purchase registrado.

### Verificar en Play Console

**Sales reports** → esperar 1-2h (batch) → aparece la unidad.

---

## 5. Troubleshooting

### "Item not found" / `BillingResponse.itemUnavailable`

- Producto no activado en Play Console (paso 2.1 → toggle Activate).
- O app no esta firmada con la keystore correcta (Play valida
  package + signature match).
- O app no esta uploaded al internal testing track (paso 2.3).

### "Authentication required" / user no puede comprar

- Email no esta en License testers (paso 2.2).
- Tester no espera 5-15 min despues de agregar el email (cache de
  Google).
- User esta logueado en Play Store con la account INCORRECTA (la que
  figura arriba a derecha en Play Store app).

### SDK key invalida / "Invalid API key"

- Falta prefijo `goog_` (es especifico de Google Play, no generic).
- Project ID equivocado en RevenueCat (chequear que coincida con el
  project del paso 1.1).
- SDK key del project equivocado (cada project tiene las suyas).

### Build no encuentra el package `purchases_flutter`

- `flutter pub get` no se corrio despues de agregar el dep.
- Cache stale: `flutter clean && flutter pub get`.

### Service account 403

- Falta **Grant access** en Play Console (paso 2.4 #5).
- JSON subido en RevenueCat esta corrupto (re-download).

---

## Checklist T8 (user)

- [ ] Cuenta RevenueCat creada
- [ ] Project `tresdcal` + Google Play service con `bo.u3dcal.tresdcal`
- [ ] Service account JSON subido a RC
- [ ] Public SDK key Android (`goog_...`) copiada y guardada
- [ ] Entitlement `pro` creado
- [ ] Product `tresdcal_pro_lifetime` creado en Play Console y **activado**
- [ ] Product attacheado al entitlement en RC
- [ ] Offering `default` con package `lifetime` apuntando al product
- [ ] License tester email agregado
- [ ] Internal testing release con el email del user
- [ ] User confirma en chat: "T8 listo, SDK key guardada en
      `~/tresdcal-secrets/revenuecat.txt`"
