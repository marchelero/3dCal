# LATEST.md

**Última sesión: 2026-09-17** — Migración Built-in Kotlin + build sin warnings.

- **Logrado**: `flutter build appbundle --release` → 0 warnings / 0 errores.
  - file_picker 10.3.10 → 13.1.0, share_plus 12.0.2 → 13.3.0 (migración API en `backup_service.dart` y `settings_page.dart`).
  - Warning Java 8 de `printing` suprimido vía `android.javaCompile.suppressSourceTargetDeprecationWarning=true`.
- **Tests**: backup 18/18 OK.
- **Pendiente**: Flutter 3.47+ → habilitar `android.builtInKotlin=true`; `flutter pub outdated` (riverpod/go_router/drift); 3 infos preexistentes de analyze.
- Detalle: `docs/sessions/2026-09-17-built-in-kotlin-warnings.md`.