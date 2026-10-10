# Plan — Corrección de brechas de 3dCal

**PRD:** `docs/prds/2026-10-10_1600-gap-remediation.prd.md`  
**Base:** `main` @ `57f218c` · **Modo:** TDD, sin commits ni pushes sin autorización explícita.

## Contratos de datos

- Recuperación de sesión: persistir `currentPartialId` junto al draft. Drafts antiguos sin id no se asociarán a un parcial por heurística; después de upgrade se mantienen restaurables y cualquier parcial de DB existente se presenta aparte, sin borrado silencioso.
- Borrado local: transacción Drift elimina cálculos (incluye drafts/templates; materiales por cascade), impresoras, filamentos, settings de cálculo y descuentos por cantidad. Después elimina `form_draft`/`active_printer_id`, quita `onboarding_done` y reinicia onboarding. Preserva locale, tema, entitlements/Pro cache, clave/ID HMAC. No toca archivos exportados ni claves SDK de RevenueCat.
- Ningún cambio de formato de backup, schema Drift ni tasa/cálculo monetario salvo lo exigido por tests. No implementar cifrado, FX, checkout web ni iOS StoreKit.

## DAG de trabajo

### Etapa 0 — captura y contratos

1. Confirmar schema 17, tabla/keys afectadas y pruebas actuales de cantidad, onboarding, draft, ajustes, backups y migraciones.
2. Añadir primero las pruebas nuevas; documentar evidencia RED antes del cambio funcional.

### Etapa 1 — defectos independientes

3. **AC-001:** tests límite de notifier + widget; fijar `1..9999` y deshabilitar `+` en el máximo.
4. **AC-002:** tests del validator de gramos y spinner/error; validar entero positivo y cubrir parseo/persistencia en try/finally.
5. Ejecutar targets de esos tests secuencialmente (no ejecutar dos `flutter test` a la vez).

### Etapa 2 — drafts y borrado local

6. **AC-003:** agregar `partialId` nullable y serialización backward-compatible a `CalculationDraft`; persistirlo tras autosave; probar restart → retomar → guardar y que solo queda una fila definitiva. No emparejar drafts legacy por similitud de contenido.
7. **AC-004:** añadir tests de repo/service de borrado transaccional y preferencias conservadas/eliminadas; agregar diálogo confirmado y navegación segura a onboarding. Testear escenario de fallo para no informar éxito falso.
8. Actualizar copy de privacidad/backups y completar paridad en cinco idiomas; ejecutar tests de paridad.

### Etapa 3 — migraciones y release

9. **AC-011:** construir bases SQLite v1/v2/v3 representativas con `user_version`; actualizar hasta 17 sin subir schema; comprobar filas/valores/defaults y materiales.
10. **AC-010:** GitHub Actions para pull requests (`flutter analyze`, `flutter test`, `flutter build web`), sin secrets, signing ni release.
11. **AC-008/009/012/013/014:** identidad PWA, help de monedas, checklist de sandbox Play/RevenueCat, documentación Android-only y nota explícita de Términos/Play Console externos pendientes.

### Etapa 4 — verificación/cierre

12. Formatear solo archivos modificados usando formato vigente del repo (no reflow masivo a 100 columnas), correr analyze, suite completa, build web y `git diff --check`.
13. Revisión Flutter/code-reviewer; resolver findings; actualizar reporte y auditoría con estado por AC, tests y `UNKNOWN` externo.
14. Verificar working tree. No commit/push salvo solicitud explícita.

## Riesgos y mitigaciones

- **Draft legacy ambiguo:** falta ID → no asociar automáticamente un borrador anterior; cubrir compatibilidad y documentar coexistencia.
- **Borrado irreversible:** UI debe enumerar datos que borra/preserva, exigir confirmación explícita y no mostrar éxito si una etapa falla.
- **Dos almacenes sin transacción común:** implementar orden/reintento idempotente y tests de error para que draft viejo no reaparezca tras wipe.
- **Migraciones:** fixtures sintéticos representativos; schema sigue v17 salvo prueba de necesidad real.
- **Servicios externos:** Play, RevenueCat, URLs legales y deploy quedan `UNKNOWN` sin credenciales/URL/contenido del dueño.

## Comandos de validación

```text
flutter test test/unit/calculator_notifier_test.dart
flutter test test/unit/result_sheet_test.dart
flutter test test/widget/initial_config_stepper_test.dart
flutter test test/widget/draft_recovery_test.dart
flutter test test/unit/data_deletion_test.dart
flutter test test/integration/migration_v1_to_v17_test.dart
flutter test
flutter analyze
flutter build web
dart format --output=none --set-exit-if-changed <modified Dart files>
git diff --check
```

Ejecutar tests en serie, no en paralelo.
