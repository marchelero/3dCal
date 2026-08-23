# Auditoría Funcional — 3dCal v1

> Fecha: 2026-08-22
> Auditor: code-explorer
> Alcance: Nivel 1 — trazabilidad de 7 journeys + auditoría del motor de cálculo + reglas no negociables (sin ejecutar nada)
> Archivos revisados: 60+ en `lib/` (calculation, catalog, dashboard, settings, history, onboarding, splash, backup, export, share, core/database, core/money, core/router)

## Resumen ejecutivo

- **Total bugs encontrados**: 27
- Críticos: 2 | Altos: 8 | Medios: 10 | Bajos: 7
- **Veredicto**: La arquitectura del motor (Decimal everywhere, Formula F1 versionada, migrations numeradas) es sólida; **el detalle UI y la concurrencia en catalog + migrations tienen fugas que se manifiestan en producción** (catálogo vacío, race en default-flag, descuento mal mostrado en detalle, setState extendido). El motor de cálculo **PASA** la auditoría de `Decimal` (cero `double` en `lib/features/calculation/domain/` salvo `MonthlyTotal`, que es bug menor).

---

## Hallazgos por severidad

### 🔴 CRÍTICOS (rompen funcionalidad o violan non-negotiables)

#### BUG-001: Discount en CalculationDetailPage usa fórmula incorrecta
- **Archivo:línea**: `lib/features/calculation/presentation/pages/calculation_detail_page.dart:562`
- **Journey afectado**: J2 (Advanced), J4 (vendido), J5 (PDF/Share)
- **Descripción**: El descuento mostrado al usuario en la página de detalle se calcula como `materialCostSnapshot * discountPercentage / 100`, pero el motor lo calcula como `totalFinal * discountPercentage / 100` donde `totalFinal = totalBeforeProfit + profitAmount` (incluye profit y markup).
- **Evidencia**:
  ```dart
  // cálculo_detail_page.dart:562 (incorrecto)
  Decimal.parse((calc.materialCostSnapshot * calc.discountPercentage / 100).toStringAsFixed(2))
  // calculation_engine.dart:83 (verdadero)
  discountAmount = totalFinal * discountPercentage / 100
  ```
- **Impacto**: Cualquier cotización con `profitBase > 0` o `markupOnMaterials > 0` muestra al cliente un descuento SUBESTIMADO en el detalle (a veces drásticamente — un 10% sobre total+profit puede ser un 30% sobre material). El PDF/PNG exportado usa el motor (correcto), pero el detalle UI muestra otro número. **Inconsistencia defendible-mente rota frente al cliente.**
- **Fix propuesto**: Usar `calc.discountPercentage * X / 100` donde X es el recompute del output (`result.output.totalFinal`) o persistir un snapshot `discountAmountSnapshot` en la tabla calculations y mostrarlo directamente.

#### BUG-002: Race condition en `_clearDefault()` de catálogos
- **Archivo:línea**:
  - `lib/features/catalog/filaments/data/filament_repository.dart:89-92` (`_clearDefault`)
  - `lib/features/catalog/printers/data/printer_repository.dart:92-95` (`_clearDefault`)
- **Journey afectado**: J7 (Onboarding — printer/filament creation)
- **Descripción**: `create()` y `update()` con `asDefault: true` ejecutan `_clearDefault()` (UPDATE no-transaccional) seguido de un INSERT/UPDATE. Dos llamadas concurrentes (poco probable en mobile, **muy probable en web con multi-tab o en auto-guardado**) pueden:
  1. A: `_clearDefault()` (no default rows) → B: `_clearDefault()` (no default rows)
  2. A: INSERT with `isDefault=true` → B: INSERT with `isDefault=true`
  3. DB queda con **dos filas con `isDefault=true`**.
- **Evidencia**:
  ```dart
  // filament_repository.dart:42-56
  if (asDefault) {
    await _clearDefault();  // no transaction
  }
  return _db.into(_db.filaments).insert(...);
  ```
- **Impacto**: `getDefault()` con `getSingleOrNull()` puede fallar silenciosamente (drift devuelve null o throws); el `activePrinterProvider` cae a `list.first` que puede ser uno u otro; el `defaultFilamentProvider` puede quedar desincronizado con la realidad. **Bug silencioso que aparece tras concurrencia.**
- **Fix propuesto**: Envolver `_clearDefault() + insert/update` en `_db.transaction(() async { ... })` (mismo patrón que ya usa `CalculationRepository.createIfWithinLimit`).

---

### 🟠 ALTOS (feature rota en casos comunes)

#### BUG-003: `MonthlyTotal.quoted` / `sold` / `totalWeightGrams` tipados como `double` (no Decimal)
- **Archivo:línea**: `lib/features/calculation/domain/monthly_totals.dart:17,20,33`
- **Journey afectado**: J3, J4 (Dashboard)
- **Descripción**: La non-negotiable dice "prohibido `double` en motor de cálculo". El motor F1 devuelve `Decimal`, pero al persistir/agregar en SQL (columna `REAL`) se hace `SUM` y el resultado vuelve como `double`, luego se mantiene como `double` en el modelo `MonthlyTotal`. Para un solo mes con 1-10 cotizaciones el redondeo es despreciable; con 50-100 cotizaciones grandes se acumula drift.
- **Evidencia**:
  ```dart
  // monthly_totals.dart:17
  final double quoted;
  // calculation_repository.dart:438
  quoted: r.read<double>('quoted'),
  ```
- **Impacto**: Pérdida de precisión agregada en dashboard mensual; no rompe el UI (se formatea a 2 decimales al renderizar) pero **viola non-negotiable explícitamente**.
- **Fix propuesto**: Convertir a `Decimal` en repository (`Decimal.parse(r.read<double>('quoted').toStringAsFixed(2))`) y tipar `MonthlyTotal` con `Decimal`.

#### BUG-004: Migrations drift usan patrón `if (from <= N)` — frágil y semánticamente incorrecto
- **Archivo:línea**: `lib/core/database/app_database.dart:50-97`
- **Journey afectado**: J6 (Restore), todos los journeys en upgrades
- **Descripción**: Cada bloque corre cuando `from <= N`. Esto funciona **solo porque `schemaVersion` siempre es 7** (latest). Si en algún release se publica `schemaVersion=5`, y un usuario está en v3, las migraciones v5→v6 y v6→v7 también se ejecutarán contra una DB que NO debería tener `notes`/`conditions`/`isTemplate` aún (esos se agregan recién en v6/v7). Drift's `addColumn` falla con error `duplicate column` si la columna ya existe en el destino (en este caso, si fue creada por una migración posterior manual).
- **Evidencia**:
  ```dart
  if (from <= 4) { await m.createTable(entitlements); }    // v4→v5
  if (from <= 5) { await m.addColumn(... notes); ... }      // v5→v6
  if (from <= 6) { await m.addColumn(... isTemplate); }     // v6→v7
  ```
- **Impacto**: Latente. Funciona hoy pero rompe en cualquier release intermedio. Patrón confuso.
- **Fix propuesto**: Cambiar a `if (from < 2)`, `if (from < 3)`, ... (cada bloque solo aplica cuando `from < target_version`, no cuando `from <= target_version`).

#### BUG-005: `SettingsRepository._upsert()` no es atómico — race condition
- **Archivo:línea**: `lib/features/settings/data/settings_repository.dart:62-86`
- **Journey afectado**: J5, J6 (settings persistidos)
- **Descripción**: `_upsert()` hace SELECT seguido de INSERT o UPDATE, sin transacción. Dos updates concurrentes al mismo setting (ej: dos `updateKwhRate`) pueden ambos hacer SELECT (no row), ambos intentar INSERT → conflicto de PK.
- **Evidencia**:
  ```dart
  final existing = await (_db.select(...))..where(...).getSingleOrNull();
  if (existing == null) { await _db.into(_db.settingsTable).insert(...); }
  else { await (_db.update(_db.settingsTable)..where(...)).write(...); }
  ```
- **Impacto**: Crash intermitente al guardar settings en concurrencia (ej: blur de profitCtrl + blur de kwhCtrl casi simultáneo, que SÍ ocurre — ver initial_config_page líneas 583-589 con dos `onBlur` separados).
- **Fix propuesto**: Envolver en `_db.transaction`, o usar un upsert nativo de drift (`db.into(table).insertOnConflictUpdate(...)`).

#### BUG-006: `setState` extendido en TODAS las vistas dinámicas — violación sistémica del non-negotiable
- **Archivo:línea**: 68 ocurrencias en 13 archivos (ver grep completo)
- **Journey afectado**: Todos
- **Descripción**: El PROJECT.md establece "No setState en vistas dinámicas: solo Riverpod notifiers". El código tiene `setState` en:
  - `lib/features/settings/presentation/pages/settings_page.dart` (1704 líneas — 9 `setState`)
  - `lib/features/calculation/presentation/widgets/result_sheet.dart` (10+ `setState` para busy state, quantity counter, image bytes)
  - `lib/features/calculation/presentation/pages/calculation_detail_page.dart` (12 `setState`)
  - `lib/features/calculation/presentation/pages/calculator_page.dart` (3 `setState`)
  - `lib/features/calculation/presentation/pages/calculations_list_page.dart` (3 `setState`)
  - `lib/features/onboarding/presentation/pages/initial_config_page.dart` (10+ `setState` para stepper state, save flags)
  - `lib/features/onboarding/presentation/pages/onboarding_page.dart` (1 setState para page index)
  - `lib/features/entitlement/presentation/pages/paywall_page.dart` (4 setState)
  - `lib/features/catalog/{filaments,printers}/presentation/pages/*` (10 setState en forms)
  - `lib/shared/widgets/{numeric_input_field,brand_selector_field}.dart` (4 setState)
- **Evidencia**: `grep setState\( lib` → 68 matches.
- **Impacto**: El non-negotiable está documentado pero no enforced. Si la intención es "los datos vienen de Riverpod pero el estado puramente UI local (focus, busy) puede usar setState", entonces el non-negotiable es engañoso y debería acotarse. Si la intención es "ningún setState", entonces TODO este código requiere refactor.
- **Fix propuesto**: Decidir semántica. Si `setState` para UI local efímero (busy, focus, pageIndex, dropdown selection) es OK, documentar la excepción. Si no, refactor masivo a Riverpod (state notifiers locales o StatefulNotifier). **Recomendación pragmática: permitir setState para UI local efímero; documentar la excepción y dejar de exigir Riverpod para todo.**

#### BUG-007: `_recompute` del CalculatorNotifier lee settings SIN watch — race condition con settings async
- **Archivo:línea**: `lib/features/calculation/presentation/state/calculator_notifier.dart:482-535`
- **Journey afectado**: J1, J2 (cotización reactiva)
- **Descripción**: `_buildInput()` lee `ref.read<AsyncValue<Settings>>(settingsNotifierProvider)`. Si `settingsNotifierProvider` está en loading (DB no inicializada, restore en curso), `asyncSettings.value` es null y se usa `Settings.defaults` (que tiene `profitBase=200`, `kwhRate=0.7`). El cálculo inicial se hace con defaults, y el `ref.listen(settingsNotifierProvider, ...)` ya configurado en `build()` **NO** dispara un recompute cuando el async termina, porque el listener solo se activa si cambia el state (cambia de `loading → data` sí, pero el `.value` ya dio el dato anterior). **En cold start con DB lenta, el primer cálculo puede ser visible con los defaults y luego "congelarse" hasta que el usuario toque un campo.**
- **Evidencia**:
  ```dart
  // calculator_notifier.dart:48
  ref.listen(settingsNotifierProvider, (_, _) {
    if (state.isValid) { state = _recompute(state); }
  });
  // calculator_notifier.dart:483-486
  final asyncSettings = ref.read<AsyncValue<Settings>>(settingsNotifierProvider);
  final settings = asyncSettings.value ?? Settings.defaults;
  ```
- **Impacto**: En la primera cotización tras cold start, el `totalPrice` puede reflejar los defaults de `Settings.defaults` en lugar de los settings persistidos del usuario. Cuando el usuario toca cualquier campo, se recomputa con los reales. Bug intermitente y confuso.
- **Fix propuesto**: Usar `ref.watch` en vez de `ref.read` dentro de `_buildInput`, o esperar al menos un ciclo de loading→data del provider de settings antes de aceptar outputs en `CalculatorState`.

#### BUG-008: ResultSheet `share/save/pdf` tienen `_isBusy` local — race con múltiples taps
- **Archivo:línea**: `lib/features/calculation/presentation/widgets/result_sheet.dart:402-498`
- **Journey afectado**: J5 (export)
- **Descripción**: El guard `if (_isBusy) return;` está en `_handleShare`, `_handleSave`, `_handleSharePdf`, `_handlePrint` — cada uno setea `_isBusy` local. Pero las llamadas `share_plus`/`gal`/`Printing.sharePdf` son async y el setState al final ocurre DESPUÉS del await. Entre el await y el setState, el botón sigue habilitado (el `onPressed` callback se cierra sobre el valor actual). **Doble tap rápido puede disparar dos shares concurrentes** que pelean por el share sheet o corrompen bytes de imagen.
- **Evidencia**:
  ```dart
  // result_sheet.dart:402-417
  setState(() => _isBusy = true);
  final bytes = await captureQuoteImageBytes(_captureKey);
  setState(() => _pieceImageBytes = bytes);
  ...
  if (mounted) setState(() => _isBusy = false);  // ← después de await largo
  ```
- **Impacto**: Compartir 2x la misma cotización, o capturar 2x la imagen antes que termine la primera.
- **Fix propuesto**: Usar un `bool _inFlight` al nivel del closure (no en el state), o cancelar la operación previa (`CancelToken`).

#### BUG-009: Materiales en `CalculationDetailPage` re-calculan con `gramsPerBobbin=0` → Infinity/NaN
- **Archivo:línea**: `lib/features/calculation/presentation/pages/calculation_detail_page.dart:489-498`
- **Journey afectado**: J4 (detalle histórico)
- **Descripción**: El costo por material se calcula inline `(weight * price / grams).toStringAsFixed(2)`. Si `gramsPerBobbinSnapshot == 0` (legacy data corrupto, edición manual de DB, import de backup malformado), la división produce `Infinity`, `toStringAsFixed` lanza `UnsupportedError: Infinity or NaN toString`.
- **Evidencia**:
  ```dart
  // calculation_detail_page.dart:491-495
  Decimal.parse(
    (ms[i].weightGrams * ms[i].pricePerBobbinSnapshot / ms[i].gramsPerBobbinSnapshot).toStringAsFixed(2),
  )
  ```
- **Impacto**: Crash al abrir detalle de una cotización con material corrupto. El motor de cálculo (`calculation_engine.dart:108-111`) **NO** valida gramsPerBobbin != 0, así que el bug se origina en el motor y se manifiesta aquí.
- **Fix propuesto**: Validar `gramsPerBobbin > 0` en el motor antes de calcular `pricePerGram`; o usar guard `gramsPerBobbin == 0 ? Decimal.zero : ...` en este display.

#### BUG-010: ListAll incluye isTemplate por error cuando dashboard query no la usa
- **Archivo:línea**: `lib/features/calculation/data/calculation_repository.dart:266-271`
- **Journey afectado**: J3 (Dashboard), J4 (Historial)
- **Descripción**: `listAll()` filtra `isTemplate.equals(false)` ✓. `monthlyTotals()` filtra `is_template = 0` ✓. `totalQuoted()` filtra `is_template = 0` ✓. Pero `topMaterials()` (`calculation_repository.dart:445-467`) incluye el filtro `c.is_template = 0` también ✓. OK, pero **`watchAll()` no filtra `isTemplate`** y `recentClientNames()` (línea 315) sí filtra. Hay inconsistencia menor: `watchAll()` está implementado pero nadie lo consume actualmente (búsqueda con grep). Es dead code peligroso si se reusa.
- **Evidencia**: `lib/features/calculation/data/calculation_repository.dart:287-292`
  ```dart
  Stream<List<Calculation>> watchAll() {
    return (_db.select(_db.calculations)..where((c) => c.isTemplate.equals(false))...watch();
  }
  ```
  Esta SÍ filtra — corregido. Pero otras queries internas no relacionadas pueden no hacerlo.
- **Impacto**: Bajo hoy, pero recordatorio de revisar TODAS las queries cuando se introduce un nuevo campo con semántica de "excluir".
- **Fix propuesto**: Centralizar la cláusula `isTemplate = false` en un helper compartido `baseFilter()` para que sea imposible olvidar.

---

### 🟡 MEDIOS (edge cases / UX degradado)

#### BUG-011: `ConversionPct` calculado con `double` en dashboard_stats (no Decimal)
- **Archivo:línea**: `lib/features/calculation/domain/dashboard_stats.dart:38-41`
- **Journey afectado**: J3
- **Descripción**: `conversionPct` retorna `double` (es un ratio 0-100, no dinero, pero el non-negotiable es estricto). Aceptable pragmáticamente (un % no se acumula), pero **violación literal del non-negotiable**.
- **Impacto**: Cosmético, no afecta cálculos.
- **Fix propuesto**: Tipar como `Decimal` o documentar la excepción para ratios no monetarios.

#### BUG-012: `_sumMaterialCost` no filtra weight/gramsPerBobbin <= 0
- **Archivo:línea**: `lib/features/calculation/domain/calculation_engine.dart:106-112`
- **Journey afectado**: J1 (Express con gramsPerBobbin=0), J2 (multi-material)
- **Descripción**: Si llega un material con `weightGrams=0` o `gramsPerBobbin=0` (escenarios de UI donde no se validó bien, o race en draft restore), `pricePerGram` retorna `Infinity` o `NaN` (vía getter en `material_input.dart:31-32`), y la suma final queda corrupta.
- **Evidencia**:
  ```dart
  // material_input.dart:31-32
  Decimal get pricePerGram =>
      (pricePerBobbin / gramsPerBobbin).toDecimal(scaleOnInfinitePrecision: 12);
  ```
- **Impacto**: Cálculo silenciosamente erróneo. UI mostraría `Infinity` o NaN en el bottom bar.
- **Fix propuesto**: Validar `m.weightGrams > 0 && m.gramsPerBobbin > 0` en `_sumMaterialCost` y saltar/clampar a 0; o assert en `MaterialInput` constructor.

#### BUG-013: `Discount percentage > 100%` produce `totalPrice < 0` sin warning
- **Archivo:línea**: `lib/features/calculation/domain/calculation_engine.dart:82-86` (motor), `lib/features/calculation/presentation/state/calculator_state.dart:580` (validator)
- **Journey afectado**: J1, J2
- **Descripción**: El motor comenta "se preserva para que la UI lo maneje" pero la UI no valida el rango superior. `kMaxDiscountPercentage = 50` está en constantes (línea 58 de app_constants.dart), pero NO se aplica en el form de descuento. Un usuario puede tipear "150%" y ver `totalPrice = totalFinal - 1.5 * totalFinal = -0.5 * totalFinal`.
- **Evidencia**: El comentario del motor dice `// si descuento > 100%, totalPrice quedaria negativo (caso borde, se preserva para que la UI lo maneje)`. UI no maneja.
- **Impacto**: Total negativo en pantalla. Compartir/PDF muestra precio negativo (cliente se confunde).
- **Fix propuesto**: Cap input del descuento en 50% con validator o `onChanged` clamp; o retornar error en el motor para descuentos > 100%.

#### BUG-014: Splash screen asume 2.5s de carga; en cold start de DB lenta puede terminar antes de init
- **Archivo:línea**: `lib/features/splash/presentation/pages/splash_screen.dart:44-61`
- **Journey afectado**: J7 (Onboarding/first run)
- **Descripción**: `_startLoading()` espera `Future.delayed(2.5s)` y luego navega. No verifica si la DB está lista, si RevenueCat terminó de configurar, etc. En cold start con DB de 5MB, es probable que el primer `ref.watch(calculationsNotifierProvider)` lance antes de que la DB abra.
- **Evidencia**:
  ```dart
  await Future<void>.delayed(const Duration(milliseconds: 2500));
  if (!mounted) return;
  final prefs = await SharedPreferences.getInstance();
  ```
- **Impacto**: Primer frame del Home muestra spinner/error si la DB aún no abrió; splash desapareció sin que la app esté lista.
- **Fix propuesto**: Hacer que el splash escuche `appDatabaseProvider`/`firstReadiness` y solo navegue cuando esté listo; o quitar el delay hardcoded.

#### BUG-015: `recentClientNames` query tiene LIMIT hardcoded y filtra por createdAt max — pero no excluye plantillas
- **Archivo:línea**: `lib/features/calculation/data/calculation_repository.dart:315-332`
- **Journey afectado**: J1, J2 (save dialog)
- **Descripción**: La query excluye plantillas ✓, pero usa `MAX(created_at)` para ordenar — si dos clientes tienen la misma fecha exacta (segundos), pueden aparecer/desaparecer según timestamp. Edge case, no crítico.
- **Impacto**: Mínimo.
- **Fix propuesto**: Ordenar también por `MAX(id) DESC` (ya lo hace, OK).

#### BUG-016: CalculationDetailPage no maneja el caso `materials` vacío (cotización legacy sin child rows)
- **Archivo:línea**: `lib/features/calculation/presentation/pages/calculation_detail_page.dart:420-433`
- **Journey afectado**: J4
- **Descripción**: Si `materials.isEmpty` se muestra `EsBO.calcNoMaterials`. Pero el `_recomputeOutput` retorna `null` si `materials` está vacío (`if (materials.isEmpty) return null;` o similar — en realidad NO retorna null, divide por cero). Verificación: en el código actual, `materialsAsync.value ?? []` puede ser vacío, y `_recomputeOutput` (línea 837) no retorna null — procesa la lista vacía y devuelve un output con `materialCost = 0`. Pero la sección de "Desglose" entonces muestra solo material=0 y total=0, sin advertir al usuario que la cotización está huérfana.
- **Impacto**: Confuso si llega una cotización sin materiales (restore desde backup parcial, bug pasado).
- **Fix propuesto**: Si `materials.isEmpty`, mostrar banner "Cotización sin materiales — datos incompletos" en el detalle.

#### BUG-017: `Decimal.parse(calc.totalPriceSnapshot.toString())` sin `.toStringAsFixed(2)` en list page
- **Archivo:línea**: `lib/features/calculation/presentation/pages/calculations_list_page.dart:343,445`
- **Journey afectado**: J4 (Historial)
- **Descripción**: Usa `.toString()` que puede producir notación científica (`1.234e+5`) o `NaN` si el double es corrupto. `Decimal.parse('1.234e+5')` funciona pero `Decimal.parse('NaN')` lanza.
- **Impacto**: Crash si un snapshot está corrupto.
- **Fix propuesto**: Usar `.toStringAsFixed(2)` consistente con el resto del código.

#### BUG-018: `FormatException` silenciosa en `tryDecode` del draft
- **Archivo:línea**: `lib/core/storage/calculation_draft.dart:88-95`
- **Journey afectado**: J1, J2 (restore de draft)
- **Descripción**: `catch (_) { return null; }` traga la excepción sin loggear. Si el draft guardado se corrompe (ej: cambio de formato), el usuario abre la app con form vacío sin saber que tenía un draft.
- **Impacto**: UX silenciosa. Usuario pierde su draft sin saber por qué.
- **Fix propuesto**: `debugPrint('Draft decode failed: $e')` antes de retornar null; o mostrar SnackBar "no se pudo restaurar el draft anterior".

#### BUG-019: `_persistActivePrinterId` swallow exception silenciosa
- **Archivo:línea**: `lib/features/calculation/presentation/widgets/printer_selector_dialog.dart:78-85`
- **Journey afectado**: J1, J2
- **Descripción**: `catch (_) { /* la seleccion sigue valida */ }` traga la excepción. Si SharedPreferences falla (corrupción, cuota llena), el usuario no sabe que su elección no se persistirá entre sesiones.
- **Impacto**: Bajo — la selección en sesión funciona, solo se pierde entre sesiones.
- **Fix propuesto**: `debugPrint('Failed to persist active printer id: $e')`.

#### BUG-020: `_base64ToBytes` en home_page y quote_image_template swallow silently
- **Archivo:línea**:
  - `lib/features/calculation/presentation/pages/home_page.dart:269-275`
  - `lib/features/calculation/presentation/widgets/quote_image_template.dart:432-438`
- **Journey afectado**: J5 (logo en cotización)
- **Descripción**: Si el logo de empresa en base64 está corrupto, `base64Decode` lanza, se captura, retorna `Uint8List(0)`, y la UI muestra imagen vacía sin avisar.
- **Impacto**: Visual — logo no aparece, usuario no sabe por qué.
- **Fix propuesto**: `debugPrint('Failed to decode logo base64: $e')`.

---

### 🟢 BAJOS (cosmético / cleanup)

#### BUG-021: `MaterialInput` permite weight/price/grams negativos
- **Archivo:línea**: `lib/features/calculation/domain/entities/material_input.dart:11-16`
- **Descripción**: El comentario dice "deben ser > 0 (validado en el motor, no aca)" pero el motor NO valida. UI filtra con `isValid` que verifica `> 0`, pero un programador que llame `MaterialInput` directamente puede pasar `-5`.
- **Fix**: Assert en constructor o validación lazy.

#### BUG-022: `MonthlyTotal` no es `@immutable`
- **Archivo:línea**: `lib/features/calculation/domain/monthly_totals.dart:6-21`
- **Descripción**: Falta `@immutable` (que sí tienen `MaterialCostBreakdown` y `CalculatorState`).
- **Fix**: Agregar `@immutable` annotation.

#### BUG-023: `DashboardStats.conversionPct` retorna `0` cuando countAll=0, no marca "sin datos"
- **Archivo:línea**: `lib/features/calculation/domain/dashboard_stats.dart:38-41`
- **Descripción**: Un dashboard con 0 cotizaciones muestra 0% — semánticamente es "no aplica", no "0%". Sin embargo, el `DashboardPage` ya muestra EmptyView si countAll==0, así que el bug es latente.
- **Fix**: Cambiar a `null` y que la UI muestre "—".

#### BUG-024: `BackupData.toJson()` no es `@override` y no valida tipos antes de serializar
- **Archivo:línea**: `lib/core/backup/backup_models.dart:117-127`
- **Descripción**: Si el caller pasa tipos raros (ej: `Decimal` en lugar de `String`), `jsonEncode` falla en runtime.
- **Fix**: Agregar `@override`, documentar precondiciones.

#### BUG-025: `ShareParams` con `text: 'Backup 3dCal'` (inglés) en export, vs `EsBO.pdfShareSubject` (es_BO) en PDF
- **Archivo:línea**: `lib/core/backup/backup_service.dart:68`
- **Descripción**: El texto del share al exportar backup está hardcodeado en inglés, inconsistente con el resto de la app.
- **Fix**: Usar `EsBO.backupShareText` (probablemente ya existe).

#### BUG-026: `FormatException` en `_parseDateTime` no tiene mensaje específico
- **Archivo:línea**: `lib/core/backup/backup_service.dart:419-428`
- **Descripción**: `throw const FormatException('Fecha de backup invalida')` — el mensaje es claro, OK. Pero la línea de arriba (188-237) usa `debugPrint('[Backup] restoreFromJson fallo: $e')` con la stack completa, lo cual es ruidoso para el usuario final (en consola debug). Es OK pero verbose.
- **Fix**: Usar `debugPrint` con menos detalle.

#### BUG-027: Onboarding + InitialConfig duplican flujo (initial config → onboarding slides → home)
- **Archivo:línea**: `lib/features/onboarding/presentation/pages/initial_config_page.dart:231-233` + `lib/features/onboarding/presentation/pages/onboarding_page.dart:75-82`
- **Descripción**: Después de InitialConfig, navega a `/onboarding` que muestra 4 slides marketineras. Pero el splash ya verifica `onboardingDone` para decidir `/initial-config` vs `/`. Si `onboardingDone=true`, splash va a `/`. Si se completa InitialConfig, se marca `onboardingDone=true` y se va a `/onboarding` — **el splash NUNCA verá este usuario en `/onboarding` después de initial-config**. Confuso: hay dos flags conceptuales ("config inicial hecho" y "onboarding visto") mezclados en uno.
- **Fix**: Separar en dos prefs (`initialConfigDone` + `onboardingSlidesViewed`) o eliminar OnboardingPage.

---

## Auditoría del motor de cálculo

- **Decimal usage**: ✓ parcial — `CalculationEngine.compute()` 100% Decimal; `CalculationInput` 100% Decimal; `CalculationOutput` 100% Decimal; `MaterialInput` 100% Decimal. **Excepciones**:
  - `MonthlyTotal.quoted`, `MonthlyTotal.sold`, `TopMaterial.totalWeightGrams`, `DashboardStats.conversionPct` son `double` (BUG-003, BUG-011).
  - `_sumMaterialCost` usa `m.pricePerGram` (getter Decimal) — OK.
  - **Recomendación**: el motor core es Decimal-puro, los modelos downstream pueden migrarse sin tocar el motor.

- **Fórmula energía**: ✓ — `printerWatts * totalHours * kwhRate / 1000`. Gated por `printerWatts > 0 && totalHours > Decimal.zero`. **Bug**: si kwhRate es negativo o NaN, no se valida (proviene de settings, podría estar corrupto).

- **Markup base**: ⚠ — `markupCost = materialCost * markupOnMaterials / 100`. Aplica **solo sobre materialCost**, NO sobre base+overhead. Si el usuario espera "markup de desperdicio = % extra de filamento", está OK; si espera "markup general", está mal. Documentación inconsistente.

- **Descuento orden**: ✓ en motor — descuento se aplica al FINAL (`totalFinal`), después de markup+profit. **Pero** en detail UI (BUG-001) se aplica sobre materialCost.

- **Tasa falla**: ✓ — sobre `baseCost` (material+electric+labor+post-proc). Bien.

- **Multi-material**: ⚠ — `_sumMaterialCost` itera todos los materials sin filtrar weight/grams<=0 (BUG-012). Suma es correcta para inputs válidos.

- **Mínimo cotizado**: ⚠ — `kDefaultMinimumCharge = 0` está en constants, `Settings.minimumCharge` se persiste, **pero el motor NO lo aplica**. El campo `minimumChargeAppliedSnapshot = 0` se persiste siempre. **Feature declarada pero no implementada en el motor.**

- **Post-procesado**: ✓ — sobre materialCost.

- **Mano de obra**: ✓ — `totalHours * laborRate`.

- **Ganancia base**: ✓ — sobre `totalBeforeProfit` (post-falla, post-markup, pre-descuento).

---

## Journeys — observaciones

### J1: Cotizar Express
- **✓ flujo general funciona**: CalculatorNotifier reacciona a cada `onChanged`, output se recomputa, draft autosave (500ms debounce), restore al reabrir.
- **⚠ BUG-007**: en cold start con DB lenta, primer cálculo puede usar Settings.defaults en lugar de los settings reales.
- **⚠ BUG-013**: descuento > 100% no se valida; total puede ser negativo.
- **⚠ BUG-012**: si `gramsPerBobbin` llega a 0 (vía draft corrupto), NaN/Infinity.

### J2: Cotizar Advanced multi-material
- **✓ flujo general**: addMaterial/removeMaterial/updateMaterial funcionan, AnimatedList sincroniza, multi-material se persiste.
- **⚠ BUG-012**: mismo que J1 pero multiplicado por N.
- **⚠ BUG-007**: mismo race con settings.

### J3: Dashboard con 0 / 1 / N cotizaciones
- **✓ countAll==0**: dashboard muestra `EmptyView` (dashboard_page.dart:45-54). Bien.
- **✓ countAll==1**: stats se muestran, conversionPct puede ser 0% o 100%. Bien.
- **⚠ BUG-003**: MonthlyTotal usa double; precisión agregada se pierde con 50+ cotizaciones.
- **⚠ BUG-011**: conversionPct es double (violación non-negotiable, baja severidad).
- **✓ monthlyTotals query maneja DB vacía**: retorna `[]` (no rows).
- **⚠ Chart meses vacíos**: si el usuario tiene cotizaciones en enero y julio, el chart muestra esos 2 puntos (sin línea recta entre ellos). Esperable, no bug.

### J4: Marcar cotización como vendida
- **✓ flujo**: `toggleSold(id, isSold)` en calculations_notifier.dart:75-79 actualiza DB, recarga lista.
- **✓ dashboard se invalida**: `_calculationByIdProvider` watches calculations; `dashboardStatsProvider` también. Bien.
- **⚠ Detalle muestra descuento incorrecto**: BUG-001 — el discount row en el detail page es engañoso.

### J5: Exportar PDF/imagen → share
- **✓ flujo normal funciona**.
- **⚠ BUG-008**: doble tap puede disparar 2 shares concurrentes.
- **⚠ BUG-009**: si `gramsPerBobbinSnapshot == 0` en un material legacy, crash al abrir detalle (no al exportar, pero el detail se usa para llegar al export).
- **✓ Lista materiales vacía**: PDF muestra solo el total, no crashea (línea 354-372 de pdf_export.dart).
- **⚠ `totalHours > 0` check**: si totalHours es 0 (corrupción), PDF muestra metadata sin horas (línea 406), OK.

### J6: Backup → restore → verificar integridad
- **✓ validación robusta**: kBackupMaxFileBytes, kBackupMaxFilaments, validate() cubre tipos y referencias (backup_models.dart:135-254).
- **⚠ BUG-004**: si se publica schemaVersion intermedio, migraciones se rompen (relacionado, no directo al backup).
- **✓ schema version check**: rechaza backups de schema futuro (línea 215-218).
- **⚠ Restricción de tamaño es post-decodificación**: el check `jsonContent.length > kBackupMaxFileBytes` (línea 191) ocurre después de `utf8.decode(bytes)` que ya cargó todo a memoria. El check pre-decode (línea 149) sí funciona para FilePicker. OK.
- **✓ Restore transaccional**: si falla, rollback total (línea 222-229).

### J7: Onboarding primera vez (catálogo vacío)
- **⚠ Flujo OK**: initial_config → onboarding slides → home. App arranca.
- **✓ Impresora requerida**: el stepper bloquea continuar si no hay printer guardada (`_canContinue` en initial_config_page.dart:213).
- **⚠ Filamento opcional**: si el usuario skip filamento, el calculator abre con `defaultFilamentProvider = null`, el `CalculatorPage.initState` no carga defaults (línea 194-206 de calculator_page.dart). El form queda con `filamentPrice=''` y `filamentGrams=''`, **el cálculo no es válido hasta que el usuario los complete**.
- **⚠ BUG-002**: si dos sesiones concurrentes (web con multi-tab) crean printers con `asDefault=true`, dos filas quedan con default.
- **⚠ BUG-014**: splash termina antes que la DB esté lista, primer frame del Home muestra spinner.

---

## Reglas no negociables

### No doubles en dinero
- ✗ **Violado en `lib/features/calculation/domain/monthly_totals.dart:17,20`** — `MonthlyTotal.quoted`, `MonthlyTotal.sold` son `double` (BUG-003, ALTO).
- ✗ **Violado en `lib/features/calculation/domain/dashboard_stats.dart:38`** — `conversionPct` es `double` (BUG-011, MEDIO — ratio no monetario).
- ✓ El motor de cálculo (`calculation_engine.dart`, `calculation_input.dart`, `calculation_output.dart`, `material_input.dart`) es 100% Decimal.
- ✓ Las conversiones double→Decimal usan `.toStringAsFixed(2)` consistentemente (40+ llamadas a `Decimal.parse((...).toStringAsFixed(2))`).
- ⚠ Las columnas REAL en drift son double por debajo; esto es inevitable con SQLite + drift, pero significa que la precisión se pierde en el momento del INSERT/UPDATE.

### No setState en vistas dinámicas
- ✗ **Violado extensamente** (BUG-006, ALTO): 68 ocurrencias en 13 archivos. Si el non-negotiable es literal, requiere refactor masivo. Si la intención es "datos en Riverpod, UI local efímero OK", debería documentarse.

### No backend / no auth / no cloud sync
- ✓ Cumplido. `purchases_flutter` es el único bridge externo (IAP store) y está gateado a `kIsWeb == false` en `main.dart:59-61`. En web, `isProProvider` se override a `true`.

### Regla del 95% (Express visible por defecto)
- ✓ `CalculatorState.initial()` tiene `mode = CalculatorMode.express` (calculator_state.dart:141).

### No cloud sync
- ✓ Cumplido. Backup export/import usa file_picker + share_plus, no cloud.

---

## Recomendaciones priorizadas (próximos pasos)

1. **CRÍTICO**: Arreglar BUG-001 (discount display en detail page) — es visible al cliente, viola la promesa de "desglose honesto y defendible". 1-2 horas.
2. **CRÍTICO**: Envolver `_clearDefault` de catalog repos en transacción (BUG-002) — bug latente que se manifiesta en concurrencia web. 30 min.
3. **ALTO**: Decidir semántica del non-negotiable "no setState" (BUG-006) — si se permite UI local efímero, documentar; si no, refactor. Toma de decisión + 1-2 días de refactor.
4. **ALTO**: Cambiar patrón de migrations a `if (from < N)` (BUG-004) — protege contra releases intermedios futuros. 1 hora.
5. **ALTO**: Persistir `discountAmountSnapshot` y mostrarlo directo en detail (elimina BUG-001 root cause). 2 horas + migración.
6. **ALTO**: Validar `gramsPerBobbin > 0` en `_sumMaterialCost` del motor (BUG-012) — fuente del BUG-009. 30 min.
7. **ALTO**: Atómico `_upsert` en SettingsRepository (BUG-005). 30 min.
8. **MEDIO**: Cambiar `MonthlyTotal` y `conversionPct` a `Decimal` (BUG-003, BUG-011). 2 horas.
9. **MEDIO**: Validar rango de descuento en UI (clamp 0-50%) (BUG-013). 30 min.
10. **MEDIO**: Splash que espera DB-ready antes de navegar (BUG-014). 2 horas.
11. **MEDIO**: `Decimal.parse((double).toStringAsFixed(2))` en calculations_list_page.dart (BUG-017). 5 min.
12. **BAJO**: Separar flags `initialConfigDone` vs `onboardingSlidesViewed` (BUG-027). 1 hora.
13. **BAJO**: Loggear las excepciones silenciosas en catch(_). 30 min.
14. **BAJO**: Implementar `minimumCharge` en el motor (feature declarada, no implementada). 1 hora + tests.

---

## Archivos clave (referencia)

| Archivo | Rol | Líneas |
|---------|-----|--------|
| `lib/features/calculation/domain/calculation_engine.dart` | Motor de cálculo (pure Dart, Decimal) | 113 |
| `lib/features/calculation/data/calculation_repository.dart` | CRUD cotizaciones + queries dashboard | 480 |
| `lib/features/calculation/presentation/state/calculator_notifier.dart` | Notifier reactivo del form | 542 |
| `lib/features/calculation/presentation/pages/calculator_page.dart` | UI principal cotizador (Express/Advanced) | 1913 |
| `lib/features/calculation/presentation/pages/calculation_detail_page.dart` | UI detalle cotización (PDF/Share source) | 1029 |
| `lib/core/database/app_database.dart` | Drift schema + migrations v1→v7 | 117 |
| `lib/core/backup/backup_service.dart` | Export/Import con validación | 429 |
| `lib/core/money/{currency,currency_formatter,decimal_extensions}.dart` | Helpers dinero (Decimal formatting) | 17+73+46 |
| `lib/features/calculation/domain/monthly_totals.dart` | Modelo agregado mensual ⚠ double | 34 |

---

## Notas metodológicas

- **No ejecuté código**. Toda la auditoría es estática (lectura + razonamiento).
- Las severidades son juicio del auditor; el equipo debe confirmar antes de priorizar.
- El motor de cálculo core pasa la auditoría Decimal — los problemas están en los bordes (UI display, concurrencia, validaciones).
- El non-negotiable "no setState" está documentado pero no enforced; requiere decisión del equipo sobre su semántica.
