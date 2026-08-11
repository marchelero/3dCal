# Reporte: Endurecimiento pre-producción + features (2026-08-11)

## Contexto

Solicitud: "Consulta que puedo mejorar o agregar al proyecto antes de subirlo a prod".
Análisis previo (read-only, code-explorer + security-reviewer) entregó bloqueantes P0/P1 y 6 features recomendadas.
El usuario aprobó: "dale todo lo que recomiendas".

## Estado final verificado

- `flutter analyze`: **No issues found!**
- `flutter test`: **399/399 PASS** (baseline inicial: 373 ejecutados / 2 fallos)
- `flutter build web --release`: **✓** (235s, tree-shaking OK)
- Migraciones de base: schema v5 → v6 → v7 encadenadas (v4 migra directo a v7)

## Fases ejecutadas

### Fase A — Suite verde
- Corregidos 2 tests fallidos en `test/widget/settings_page_test.dart`:
  - `Privacidad:` → `find.textContaining('Privacidad')` (la UI renderiza 'Privacidad y datos').
  - Finder ambiguo de FilledButton → `find.widgetWithText(FilledButton, 'Restaurar compras')` + ensureVisible + pumpAndSettle (botón a y≈1858, fuera del viewport de test).

### Fase B — Backup/restore endurecido (hallazgo HIGH de security audit)
- `backup_models.dart`: validación exhaustiva (límites de tamaño 50MB, conteos por colección, tipos por campo, strings ≤ 2048, IDs duplicados, integridad referencial calculationMaterials→calculations, errores agregados con cap de 5).
- `backup_service.dart`: guards de tamaño antes de cargar en memoria, errores amigables + debugPrint, rechazo de backups de schema futuro, transacción atómica.
- `settings_page.dart` `_handleImport`: try/catch completo del pipeline read→decode→validate.
- **8 tests nuevos** en `test/unit/backup_validation_test.dart`.

### Fase C — Errores amigables (hallazgo MEDIUM)
- Eliminadas todas las interpolaciones crudas `$e` en snackbars de: settings export, filament/printer forms, calculator save, result_sheet (imagen/PDF/share/save), initial-config.
- RevenueCat logs: stack traces solo con `kDebugMode`; en prod solo `e.runtimeType`.
- Patrón: `debugPrint('...failed: $e')` + mensaje l10n estático.

### Fase D — Duplicar cotización (feature #1)
- `CalculationRepository.duplicate(int id, {pieceNameSuffix})` — transacción, copia los 26 campos snapshot + materiales, resetea isSold y createdAt.
- UI: botón en detail page (AppBar) + acción en el menú del listado. Sufijo ' (copia)'.
- 3 tests nuevos (repo) + 4 keys l10n × 5 locales.

### Fase E — PDF de cotización profesional (feature #3) — **migración schema v6**
- Columnas `notes` y `conditions` en calculations (guardables desde el diálogo de guardado).
- PDF: número de cotización (Nº 0123), fecha formateada dd/MM/yyyy, vencimiento (+15 días, `kQuoteValidDays`), cliente, secciones Notas y Condiciones, header reordenado con branding.
- Backup compatible con esquemas viejos (notas/conditions null).
- 8 tests nuevos (3 migración v5→v6 + 3 repo + 2 pdf-export).

### Fase F — Onboarding al primer cálculo (feature #4)
- La última slide del onboarding ahora tiene botón "Crear mi primera cotización" que salta directo a `/calculator` (marca onboarding done).
- 2 snackbars crudos residuales en initial-config limpiados.

### Fase G — Ayuda de calibración de costos (feature #6)
- `cost_help_dialog.dart`: diálogo con 7 conceptos (energía, mano de obra, post-procesado, tasa de falla, desperdicio, cargo mínimo, margen) con fórmulas 1:1 del motor.
- Botón help en el AppBar de la calculadora (gratis, no gated).
- 15 keys l10n × 5 locales.

### Fase H — Plantillas de trabajo frecuente (feature #2) — **migración schema v7**
- Columna `is_template` en calculations (default false). Plantillas excluidas de historial/dashboard/counts/cap free/analytics SQL.
- Guardar como plantilla desde el diálogo de guardado; aplicar (reusa `loadFromCalculation`); borrar desde el bottom sheet.
- 5 tests nuevos (repo) + 9 keys l10n × 5 locales.

## Resumen de cambios por archivo

| Archivo | Fases |
|---|---|
| lib/core/backup/backup_models.dart, backup_service.dart | B |
| lib/features/settings/presentation/pages/settings_page.dart | B, C |
| lib/features/catalog/*/presentation/pages/*_form_page.dart | C |
| lib/features/calculation/presentation/pages/calculator_page.dart | C, E, G, H |
| lib/features/calculation/presentation/widgets/result_sheet.dart | C |
| lib/features/entitlement/data/payment_service_revenuecat.dart | C |
| lib/features/calculation/data/tables/calculations_table.dart | E, H |
| lib/core/database/app_database.dart | E, H |
| lib/features/calculation/data/calculation_repository.dart | D, E, H |
| lib/features/calculation/presentation/state/calculator_notifier.dart | D, E, H |
| lib/features/calculation/presentation/pages/calculation_detail_page.dart | D, E |
| lib/features/calculation/presentation/pages/calculations_list_page.dart | D |
| lib/core/export/pdf_export.dart | E |
| lib/features/calculation/presentation/widgets/cost_help_dialog.dart | G (nuevo) |
| lib/features/onboarding/.../onboarding_page.dart | F |
| lib/features/onboarding/.../initial_config_page.dart | F, C |
| lib/l10n/* (app_strings, es_bo, en_us, pt_br, de_de, fr_fr) | D-H |

## Bugfix post-reporte: ciclo sin salida onboarding → calculador

**Reportado por el usuario**: al crear la primera cotización desde el onboarding, al volver atrás desde el calculador regresaba al onboarding (ciclo sin salida al menú).

**Causa raíz**: `_startQuoting()` (Fase F) hacía `context.push('/calculator')` sin terminar la ruta `/onboarding`; el onboarding (y `/initial-config`) quedaban vivos en el stack del router.

**Fix** (`onboarding_page.dart`):
1. `_startQuoting()` ahora captura el `GoRouter`, hace `router.go('/')` (stack limpio → Home/menú) y recién después `router.push('/calculator')`. Back desde el calculador → Home, nunca onboarding.
2. La última slide ya no oculta el botón superior: muestra "Ir al menú" (key l10n nueva `onboardingGoHome` × 5 locales) que cierra el onboarding directo al menú — antes no había forma de cerrar la última slide sin crear una cotización.

**Tests**: `test/widget/onboarding_flow_test.dart` (3 tests) — CTA final → Home+calculador y back → Home (nunca OnboardingPage); "Ir al menú" → Home; "Saltar" → Home. Suite: **402/402** (previo 399), analyze 0 issues.

## Checklist para el usuario (acciones NO-code, no ejecutables desde el repo)

1. **Privacy Policy + Terms públicas**: publicar en HTTPS `https://u3dcal.bo/privacy` y `/terms` (constantes en `app_constants.dart:146-150`). Deben mencionar RevenueCat, Google Play Billing, identificadores anónimos, compartición de PDF/PNG/backups y nombres de clientes.
2. **Prueba de compra real**: producto configurado en RevenueCat, sandbox, purchase/restore/reinstalación desde Play Internal Testing (`docs/notes/store-compliance.md`).
3. **Release Android**: definir Application ID real (`android/app/build.gradle.kts` TODO), versionCode + alinear `pubspec.yaml` 0.1.0+1 vs README 1.0.0, keystore de release, AAB firmado + R8.
4. **Data Safety / audiencia**: completar Play Console (declarar tráfico de red para pagos), edad mínima y revisar Families.
5. **AndroidManifest**: definir `allowBackup`/`dataExtractionRules` (excluir base local del backup del sistema); revisar `requestLegacyExternalStorage`.
6. **Docs contradictorias**: PROJECT.md/README dicen "100% local/sin internet" pero RevenueCat/Google Play comunican — aclarar.
7. **Dependencias**: 44 paquetes con versiones más nuevas (`flutter pub outdated`) — revisar controladamente antes de release.
8. **Entitlement client-side**: los gates Pro son evadibles localmente (web fuerza isPro=true). Documentar explícitamente.

## Fuera de alcance (decisión consciente)

Sync en la nube, cuentas de usuario, CRM completo, facturación fiscal, firma electrónica.

## Actualización posterior (mismo día) — bugfix + 3 mejoras UX

### Bugfix: ciclo sin salida onboarding→calculador
`_startQuoting()` pusheaba `/calculator` sin cerrar `/onboarding` (+`/initial-config`) → el back volvía al onboarding. Ahora `router.go('/')` (stack limpio) y luego push. Última slide: botón "Ir al menú" siempre visible. 3 tests nuevos en `test/widget/onboarding_flow_test.dart`.

### UX: botón cerrar en calculadora
AppBar `leading` explícito (X, "Cerrar y volver al menú"). `sprint0_smoke_test` actualizado a `find.byIcon(Icons.close_rounded)`.

### T1 — Acción "Ver" en el snackbar post-guardado
`AppSnackBar.success(EsBO.calcSavedWithId(id), actionLabel: calcSavedViewAction, onAction: () => context.push('/history/$id'))` — abre el detalle de la cotización recién guardada. Key l10n ×5.

### T2 — Política de backup Android explícita
- `AndroidManifest.xml`: `allowBackup="false"`, `fullBackupContent="false"`, `dataExtractionRules="@xml/data_extraction_rules"`.
- Nuevo `res/xml/data_extraction_rules.xml`: cloud-backup y device-transfer deshabilitados (la base local con datos de clientes nunca sale del dispositivo salvo export JSON manual).
- XML validado well-formed (python). **PENDIENTE**: validar `flutter build apk` en máquina con Android SDK (esta máquina no tiene ANDROID_HOME).

### T3 — Clientes recientes en el diálogo de guardar
- Repo: `recentClientNames({limit = 8})` — clientes distintos por `GROUP BY client_name`, orden `MAX(created_at) DESC, MAX(id) DESC` (tie-break determinista ante timestamps del mismo ms), excluye plantillas y vacíos.
- `_SaveDialog`: chips `ActionChip` (quick-pick) que completan el campo cliente; label l10n `calcDialogRecentClients`.
- 3 tests nuevos en `database_repositories_test.dart` (distintos+orden, excluye plantillas/vacíos, límite).

### Estado final tras actualización
`flutter analyze` No issues · `flutter test` **405/405** · XML manifest válido · APK pendiente de validar (sin SDK local). Nada commiteado.

## Corrección posterior — importación de backups (2026-08-11)

### Bug: "createdAt inválido" al importar backup
**Causa raíz**: desacuerdo de formato/unidad. Drift serializa `DateTime` como **milisegundos Unix** (ej. `1786475972000`) en `toJson()`; `BackupData.validate()` solo aceptaba strings ISO-8601. Además `_parseDateTime` tenía un fallback silencioso a `DateTime.now()` y las fechas de impresoras/settings no se validaban (se restauraban con fecha falsa).

**Corrección**:
- `backup_models.dart`: `_checkDateTime` acepta ISO-8601 **o** entero Unix ms finito ≥0; valida también `printers[].createdAt` y `settings[].updatedAt`.
- `backup_service.dart`: `_rowToMap` exporta fechas canónicas ISO-8601; `_parseDateTime` acepta DateTime/ISO/ms y **ya no cae a `DateTime.now()`** (lanza error → transacción revierte).
- +3 tests de regresión (Unix ms aceptado, timestamp no-entero rechazado, fechas de impresoras/settings validadas). Backups viejos (formato ms) importan sin editar.

### Bug: tras restaurar, el menú no mostraba las cotizaciones
**Causa raíz**: providers fetch-once (no watch) — el restore nunca invalidaba las listas cacheadas → UI vieja (vacía) hasta algún refresh manual.

**Corrección**: en `_handleImport` (path de éxito) se invalidan 5 providers: `calculationsNotifierProvider`, `dashboardStatsProvider`, `filamentsNotifierProvider`, `printersNotifierProvider`, `settingsNotifierProvider` (derivados se refrescan en cascada).

### Q&A: tamaño del backup
JSON plano ≈ 250KB/100 cotizaciones, ~2,5MB/1000, ~25MB/10000; límite de importación 50MB (≈20.000 cotizaciones). Free capado a 10 → peor caso ~25KB. Mitigación futura posible: gzip (5-10x) si hay Pro con >2.000 cotizaciones.

### Feature: backup ahora es función Pro
Exportar **e** importar backups quedan gated (petición del usuario). Free → SnackBar gate ("Hacer copias de seguridad es una función Pro.") + acción "Ir a Pro" → `/paywall`; botones atenuados (`kLockedOpacity`). Sin ProBadge extra (evita romper tests de counts de badges). 1 test widget nuevo (tap Exportar en free → gate → Go Pro → paywall stub). Nueva key l10n `settingsBackupLockedBody` ×5.

### Estado final acumulado
`flutter analyze` No issues · `flutter test` **409/409** · Nada commiteado.

## Corrección posterior — importación de backups (2026-08-11)

### Causa

Drift serializaba algunas fechas (`createdAt`/`updatedAt`) como milisegundos Unix
(`1786475972000`), pero `BackupData.validate()` solo aceptaba strings ISO-8601.
Por eso el importador mostraba errores como `Cotizacion #1: createdAt invalido`.

### Corrección

- El validador acepta ISO-8601 y timestamps Unix enteros en milisegundos.
- La exportación normaliza fechas a ISO-8601.
- Las fechas inválidas ya no se reemplazan silenciosamente por `DateTime.now()`;
  se rechazan para evitar restaurar datos con fechas falsas.
- También se validan las fechas de impresoras y settings, que antes no estaban
  cubiertas.

### Verificación

- `flutter analyze`: **No issues found!**
- `flutter test`: **408/408 PASS**
- Regresiones nuevas: timestamps numéricos aceptados, fechas inválidas
  rechazadas, y validación de impresoras/settings.
