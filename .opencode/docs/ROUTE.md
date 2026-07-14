# Ruteo de agentes

> 69 sub-agentes, agrupados por intención. Elige por lo que quieres hacer, no por el nombre del agente.
> Descripciones completas en `.opencode/agents/<nombre>.md`.

## "Quiero clarificar la intención antes de construir"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `prd-agent` | Protocolo de entendimiento → archivo PRD | **PRIMER PASO OBLIGATORIO** en cualquier tarea no trivial. Dispara con: "construir X", "crear Y", "agregar Z". |

## "Quiero planear / diseñar"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `planner` | Plan por fases con riesgos, dependencias y validación | Features complejos, refactors, cambios arquitectónicos |
| `architect` | Diseño de sistema, decisiones tecnológicas, escalabilidad | Decisiones arquitectónicas, "¿usamos X o Y?" |
| `code-architect` | Plano de archivos, interfaces, flujo de datos y orden de construcción | Antes de implementar una feature en un repo existente |
| `gan-planner` | Expande un prompt de una línea en un spec GAN completo | Flujo GAN (plan→genera→evalúa en bucle) |

## "Quiero revisar código"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `code-reviewer` | Calidad, seguridad, mantenibilidad | **OBLIGATORIO** en cada cambio de código |
| `security-reviewer` | OWASP Top 10, secretos, SSRF, inyección, criptografía insegura | Tras tocar auth, pagos, datos de usuario o secretos |
| `a11y-architect` | WCAG 2.2, diseño inclusivo | Componentes de UI, design systems |
| `comment-analyzer` | Comentarios obsoletos, doc desactualizada | Codebases maduros, antes de un PR |
| `silent-failure-hunter` | Errores silenciados, fallbacks peligrosos | Tras fusionar un fix crítico, auditorías de robustez |
| `type-design-analyzer` | Encapsulación, invariantes, uniones discriminadas | Refactors de modelo de dominio, diseño de APIs internas |
| `pr-test-analyzer` | Calidad de cobertura de tests, cobertura conductual | Antes de aprobar un PR |
| `performance-optimizer` | Perfilado, fugas de memoria, rendimiento de render, bundle | Quejas de latencia, pre-release, frame drops |

### Revisores por stack (OBLIGATORIOS cuando el stack coincide)

| Stack | Agente | Se dispara con |
|-------|--------|----------------|
| TypeScript/JS | `typescript-reviewer` | cambios en `.ts`/`.tsx`/`.js` |
| React | `react-reviewer` | cambios en `.tsx`/`.jsx`, hooks, boundaries de Next.js |
| Python | `python-reviewer` | cambios en `.py` |
| Django | `django-reviewer` | apps Django (ORM, DRF, migraciones) |
| FastAPI | `fastapi-reviewer` | apps FastAPI (async, Pydantic, DI) |
| Go | `go-reviewer` | cambios en `.go` |
| Rust | `rust-reviewer` | cambios en `.rs`, borrow checker, `unsafe` |
| Java | `java-reviewer` | Java + Spring Boot o Quarkus |
| Kotlin | `kotlin-reviewer` | Kotlin / Android / Compose |
| Swift | `swift-reviewer` | Swift / iOS / SwiftUI |
| C# | `csharp-reviewer` | cambios en .NET |
| C++ | `cpp-reviewer` | cambios en C++, templates, RAII |
| F# | `fsharp-reviewer` | cambios en F# |
| PHP | `php-reviewer` | PHP, Laravel/Symfony |
| Flutter | `flutter-reviewer` | widgets Dart/Flutter, gestión de estado |
| Base de datos | `database-reviewer` | SQL, migraciones, diseño de schema |
| Salud | `healthcare-reviewer` | apps EMR/EHR/clínicas (HIPAA) |
| ML/MLOps | `mle-reviewer` | entrenamiento, inferencia, feature store |

## "Quiero arreglar un error de build / tipos"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `build-error-resolver` | Errores genéricos de TS/build, diff mínimo | `tsc` o `npm run build` falla |
| `cpp-build-resolver` | C++ / CMake / linker | build de C++ falla |
| `dart-build-resolver` | `dart analyze`, pub, build_runner | build de Flutter falla |
| `django-build-resolver` | pip, migraciones, `manage.py` | Django no arranca |
| `go-build-resolver` | `go build`, `go vet` | build de Go falla |
| `java-build-resolver` | Maven/Gradle, Spring/Quarkus | build de Java falla |
| `kotlin-build-resolver` | Kotlin/Gradle, KSP, KAPT | build de Kotlin falla |
| `pytorch-build-resolver` | Formas de tensor, device, grad, DataLoader | entrenamiento/inferencia de PyTorch crashea |
| `react-build-resolver` | Vite/webpack/Next.js/JSX/hidratación | build de React falla |
| `rust-build-resolver` | `cargo build`, borrow checker | build de Rust falla |
| `swift-build-resolver` | Xcode, SPM, code signing | build de Xcode falla |

## "Quiero testear"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `tdd-guide` | ROJO→VERDE→REFACTOR, cobertura 80%+ | **PROACTIVAMENTE** en features nuevas, fix de bugs o refactors |
| `e2e-runner` | Playwright/Vercel Agent Browser E2E | Flujos críticos de usuario, pre-release |

## "Quiero entender el codebase"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `code-explorer` | Traza paths de ejecución, mapea capas, documenta dependencias | Onboarding en un repo nuevo, antes de un cambio grande |
| `docs-lookup` | Recupera docs actualizadas de librerías vía Context7 | Cuando necesitas referencia actual de la API, no datos de entrenamiento |

## "Quiero mantener / limpiar"

| Agente | Qué hace | Cuándo usarlo |
|--------|----------|---------------|
| `refactor-cleaner` | Código muerto, duplicados (knip/depcheck/ts-prune) | Mantenimiento periódico, pre-release |
| `doc-updater` | Codemaps, `/update-codemaps`, `/update-docs` | Tras cambios estructurales |
| `code-simplifier` | Claridad, consistencia, sin cambio de comportamiento | Tras un PR pero antes del merge |
| `harness-optimizer` | Ajusta la configuración local del harness de agentes | Cuando el ruteo o los permisos se sienten mal |
| `loop-operator` | Monitorea bucles autónomos de agentes, abort seguro | Cuando corres agentes de noche |

## "Quiero abrir el código de un proyecto"

Pipeline de 3 etapas. Ejecuta en orden:

1. `opensource-forker` — copia y elimina secretos
2. `opensource-sanitizer` — verifica la limpieza (PASS/FAIL)
3. `opensource-packager` — genera CLAUDE.md, LICENSE, README, plantillas de GitHub

## "Quiero usar el bucle GAN"

3 agentes en bucle:

1. `gan-planner` — prompt de una línea → spec
2. `gan-generator` — implementa según el spec
3. `gan-evaluator` — testea con Playwright, puntúa, feedback → bucle

## "Quiero trabajo de red / homelab"

| Agente | Uso |
|--------|-----|
| `network-architect` | Diseño enterprise/multi-sitio |
| `network-config-reviewer` | Auditoría de config de router/switch (pre-prod) |
| `network-troubleshooter` | Diagnóstico read-only por capas OSI |
| `homelab-architect` | Planes de red para home-lab o laboratorio pequeño |

## "Quiero ayuda especializada"

| Agente | Uso |
|--------|-----|
| `marketing-agent` | Estrategia de campaña, copy, calendario de contenido |
| `chief-of-staff` | Triaje de email/Slack/Messenger (4 niveles) |
| `harmonyos-app-resolver` | HarmonyOS / OpenHarmony (ArkTS/ArkUI) |
| `conversation-analyzer` | `/hookify` — encuentra comportamientos que vale la pena prevenir con hooks |
