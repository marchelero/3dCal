---
prd: docs/prds/2026-07-22_0943-free-pro-monetization.prd.md
plan: docs/plans/2026-07-22_1100-free-pro-monetization.plan.md
task: T3
status: PASSED
created: 2026-07-22_1200
owner: tdd-guide
---

# T3 Report — `EntitlementRepository` (Drift read/write)

## Summary

T3 del plan free/pro monetization implementado en TDD estricto.
- Repository contract (`abstract class EntitlementRepository`) + impl Drift
  (`DriftEntitlementRepository`) en `lib/features/entitlement/data/entitlement_repository.dart`.
- 19 unit tests verde en `test/unit/entitlement_repository_test.dart`.
- 100% line coverage en el archivo del repository.
- 0 issues nuevos de `flutter analyze`.
- Full suite 171/171 sin regresiones.

## RED → GREEN → verify

### RED
Archivo test creado sin impl → `flutter test` falla con compile errors
(`EntitlementRepository` type not found, `DriftEntitlementRepository` not
found). 1 test loader failure.

### GREEN
Impl escrita con la API del spec del user:
- `save(EntitlementsCompanion)` — upsert atomico en transaction.
- `getActive()` — Future<Entitlement?>.
- `clear()` — soft delete (isActive=false, no borra filas).
- `watchActive()` — Stream<Entitlement?> reactivo.

Primer run: 18/19 verde. 1 fallo en `watchActive emite null cuando clear()
desactiva la activa` → Drift's `watchSingleOrNull` con `limit(1)` cierra el
stream cuando la row trackeada deja de matchear. Fix: usar
`.watch().map((rows) => rows.isEmpty ? null : rows.first)` — stream nunca
cierra.

Tambien hubo un test bug: `await expectLater(...)` antes de `repo.clear()`
causaba deadlock. Fix: pattern `final future = expectLater(...); await
repo.clear(); await future;`. Documente el gotcha en el test para que
no se repita.

### VERIFY
- `flutter test test/unit/entitlement_repository_test.dart` → 19/19 PASS
- `flutter analyze lib/features/entitlement test/unit/entitlement_repository_test.dart`
  → 0 issues
- `flutter analyze` (full project) → 606 issues, todos pre-existentes
- `flutter test` (full suite) → 171/171 PASS, 0 regresiones
- `flutter test --coverage` → LF:23, LH:23 → 100% line coverage en
  `entitlement_repository.dart`

## Decisiones de diseno

| Decision | Rationale |
|---|---|
| `abstract class` + concrete `DriftEntitlementRepository` | Spec del user lo pide asi. Permite mockear en T4 (`EntitlementService` con Riverpod) sin acoplar a Drift. |
| `const` constructor + `final AppDatabase _db` | Matchea el resto del proyecto (`PrinterRepository`, `FilamentRepository`, `SettingsRepository`, `CalculationRepository`). |
| Queries inline en repo, sin `@DriftAccessor` | Proyecto no usa DAOs. Mantener consistencia. |
| `save()` envuelto en `_db.transaction` | "deactivate + insert" debe ser atomico: si el insert falla, la activa previa se mantiene. Drift lo garantiza via rollback. |
| `save()` semantics: `isActive` absent/true → deactivate + insert activo. `isActive=Value(false)` → insert historico sin tocar | Spec del user: "si ya hay una activa, la marca isActive=false y crea nueva". El caller controla con el companion. |
| `clear()` ≠ `delete()`: marca `isActive=false`, no borra filas | Spec: "NO borra — mantiene historial para auditoria". Restore que dice "no hay" debe preservar el entitlement previo en la DB. |
| `watchActive()` con `.watch().map()` en vez de `watchSingleOrNull()` + `limit(1)` | Drift cierra el stream cuando la row trackeada (por PK) deja de matchear el WHERE. Con `map()` el stream nunca cierra — necesario para emitir `null` post-`clear()`. |
| Helper privado `_deactivateAll()` reusable por `save()` y `clear()` | Misma SQL, dos razones de uso. DRY. |

## Disonancias / notas

1. **Disonancia menor con el spec del user**: la spec dice "logica: si ya
   hay una activa, la marca isActive=false y crea nueva" — interprete que
   el caller controla el flag `isActive` del companion. Si quiere activo
   (default), reemplaza; si quiere historico (`Value(false)`), no toca.
   El spec del user menciono "save() con isActive=true debe primero
   desactivar" — implemente asi. Si la intencion era "save() SIEMPRE
   reemplaza la activa independientemente del isActive del companion",
   avisar y reviso.

2. **Tabla T1 ya estaba creada con `isActive` default `true`**. La
   invariante "1 fila activa" se enforce en el repo, no en DB (decision
   documentada en `entitlements_table.dart`). Esto matchea la migration
   comment en `app_database.dart:75-82` ("enforcement en repository (T3),
   no en DB").

3. **Coverage**: line coverage 100% en el repo (23/23). Branch coverage
   no trackeado por `flutter test --coverage` (limitación del runner,
   no del codigo). Los branches relevantes (`_wantsActive` true/false)
   estan cubiertos por tests dedicados.

4. **No commit, no push** per user instruction. Work untracked en
   `lib/features/entitlement/` + `test/unit/entitlement_repository_test.dart`
   (T1 + T2 + T3 todos untracked todavia — el user maneja el commit batch).

## Files

- **Creado**: `lib/features/entitlement/data/entitlement_repository.dart` (113 lines)
- **Creado**: `test/unit/entitlement_repository_test.dart` (318 lines, 19 tests)
- **Modificado**: ninguno (T3 no toca otros archivos)

## Next step (T4)

`EntitlementService` (Riverpod) + cache SP + `isProProvider`. Depende de
T3 (repo) + T2 (constants). Tests T3 ya proveen mock seam
(`DriftEntitlementRepository` es `const`-constructible con un
`AppDatabase.forTesting()`).
