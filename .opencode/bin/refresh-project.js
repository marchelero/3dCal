#!/usr/bin/env node
/**
 * refresh-project.js - regenerate .agents/PROJECT.md from current project state
 *
 * Scans:
 *   - package.json (Node/JS/TS)
 *   - pubspec.yaml (Flutter/Dart)
 *   - pyproject.toml / requirements.txt / setup.py (Python)
 *   - Cargo.toml (Rust)
 *   - go.mod (Go)
 *   - *.csproj / *.sln (.NET)
 *   - pom.xml / build.gradle* (Java/Kotlin)
 *   - index.html (Web)
 *   - README.*.md
 *
 * Generates a fresh .agents/PROJECT.md and (in --dry-run) shows the diff
 * without writing. In normal mode, writes a backup then overwrites.
 *
 * Usage:
 *   node .opencode/bin/refresh-project.js          # scan + write
 *   node .opencode/bin/refresh-project.js --dry-run  # scan + show diff, no write
 *   node .opencode/bin/refresh-project.js --check    # exit 0 if up to date, 1 if stale
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const CWD = process.cwd();
const ARGS = process.argv.slice(2);
const DRY_RUN = ARGS.includes('--dry-run');
const CHECK_ONLY = ARGS.includes('--check');

if (ARGS.includes('--help') || ARGS.includes('-h')) {
  console.log(`Usage:
  node .opencode/bin/refresh-project.js              # scan + write
  node .opencode/bin/refresh-project.js --dry-run    # scan + show diff, no write
  node .opencode/bin/refresh-project.js --check      # exit 0 if up to date, 1 if stale
  node .opencode/bin/refresh-project.js --help       # this help

Scans: package.json, pubspec.yaml, pyproject.toml, requirements.txt, setup.py,
       Cargo.toml, go.mod, *.csproj, *.sln, pom.xml, build.gradle*, index.html, README.*.md
Writes: .agents/PROJECT.md (backup at .agents/PROJECT.md.bak.<ts>)`);
  process.exit(0);
}

const HOME = os.homedir();
const PROJECT_MD = path.join(CWD, '.agents', 'PROJECT.md');
const BACKUP_MD = path.join(CWD, '.agents', `PROJECT.md.bak.${Date.now()}`);

function exists(p) { return fs.existsSync(p); }
function read(p) { try { return fs.readFileSync(p, 'utf8'); } catch { return ''; } }
function readJSON(p) { try { return JSON.parse(read(p)); } catch { return null; } }
function readYAML(p) {
  // Lightweight YAML parser for pubspec.yaml / pyproject.toml
  const txt = read(p);
  if (!txt) return null;
  const out = {};
  for (const line of txt.split('\n')) {
    const m = line.match(/^([\w-]+):\s*(.+)$/);
    if (m) out[m[1]] = m[2].trim().replace(/^["']|["']$/g, '');
  }
  return out;
}

function detectType() {
  if (exists('pubspec.yaml')) return 'flutter-app';
  if (exists('package.json')) {
    const pkg = readJSON('package.json');
    if (pkg && pkg.dependencies && pkg.dependencies['next']) return 'web-app';
    if (pkg && pkg.dependencies && pkg.dependencies['express']) return 'api-service';
    if (pkg && pkg.bin) return 'cli';
    return 'node-app';
  }
  if (exists('pyproject.toml') || exists('setup.py')) return 'python-app';
  if (exists('Cargo.toml')) return 'rust-app';
  if (exists('go.mod')) return 'go-app';
  if (exists('pom.xml') || exists('build.gradle')) return 'java-app';
  if (exists('index.html')) return 'web-app';
  return 'unknown';
}

function detectName() {
  if (exists('package.json')) {
    const pkg = readJSON('package.json');
    if (pkg && pkg.name) return pkg.name;
  }
  if (exists('pubspec.yaml')) {
    const pub = readYAML('pubspec.yaml');
    if (pub && pub.name) return pub.name;
  }
  if (exists('pyproject.toml')) {
    const py = readYAML('pyproject.toml');
    if (py && py.name) return py.name;
  }
  if (exists('Cargo.toml')) {
    const cargo = readYAML('Cargo.toml');
    if (cargo && cargo.name) return cargo.name;
  }
  if (exists('go.mod')) {
    const go = read('go.mod');
    const m = go.match(/^module\s+(\S+)/m);
    if (m) return m[1].split('/').pop();
  }
  return path.basename(CWD);
}

function detectDescription() {
  if (exists('README.md')) {
    const m = read('README.md').match(/^#\s+.+?\n+(.+?)(\n\n|\n#)/);
    if (m) return m[1].trim();
  }
  if (exists('package.json')) {
    const pkg = readJSON('package.json');
    if (pkg && pkg.description) return pkg.description;
  }
  if (exists('pubspec.yaml')) {
    const pub = readYAML('pubspec.yaml');
    if (pub && pub.description) return pub.description;
  }
  return '(no description)';
}

function detectStack(type) {
  const stack = { language: '?', framework: '?', runtime: '?', package_manager: '?' };
  if (exists('package.json')) {
    const pkg = readJSON('package.json') || {};
    stack.language = 'JavaScript/TypeScript';
    stack.framework = pkg.dependencies && pkg.dependencies['next'] ? `Next.js ${pkg.dependencies['next']}` :
                     pkg.dependencies && pkg.dependencies['express'] ? `Express ${pkg.dependencies['express']}` :
                     pkg.dependencies && pkg.dependencies['react'] ? `React ${pkg.dependencies['react']}` : '(none)';
    stack.package_manager = exists('pnpm-lock.yaml') ? 'pnpm' : exists('yarn.lock') ? 'yarn' : exists('bun.lockb') ? 'bun' : 'npm';
  } else if (exists('pubspec.yaml')) {
    const pub = readYAML('pubspec.yaml') || {};
    stack.language = 'Dart';
    stack.framework = 'Flutter';
    stack.runtime = 'Dart SDK';
    stack.package_manager = 'pub';
  } else if (exists('pyproject.toml')) {
    stack.language = 'Python';
    stack.package_manager = exists('poetry.lock') ? 'poetry' : exists('uv.lock') ? 'uv' : 'pip';
  } else if (exists('Cargo.toml')) {
    stack.language = 'Rust';
    stack.package_manager = 'cargo';
  } else if (exists('go.mod')) {
    stack.language = 'Go';
    stack.package_manager = 'go mod';
  } else if (exists('pom.xml')) {
    stack.language = 'Java';
    stack.package_manager = 'maven';
  } else if (exists('build.gradle')) {
    stack.language = 'Kotlin/Java';
    stack.package_manager = 'gradle';
  }
  return stack;
}

function detectConventions() {
  const conv = [];
  if (exists('.eslintrc') || exists('.eslintrc.json') || exists('eslint.config.js')) conv.push('eslint');
  if (exists('.prettierrc') || exists('prettier.config.js')) conv.push('prettier');
  if (exists('tsconfig.json')) conv.push('TypeScript strict');
  if (exists('jest.config.js') || exists('jest.config.ts')) conv.push('jest');
  if (exists('vitest.config.ts') || exists('vitest.config.js')) conv.push('vitest');
  if (exists('pytest.ini') || exists('pyproject.toml')) {
    const py = readYAML('pyproject.toml');
    if (py && (py.tool && (py.tool.pytest || py['pytest-runner']))) conv.push('pytest');
  }
  if (exists('.github/workflows')) conv.push('GitHub Actions CI');
  return conv.length ? conv.join(', ') : 'free-form';
}

function listKeyDirs() {
  const dirs = ['src', 'lib', 'app', 'pkg', 'cmd', 'internal', 'modules', 'components', 'pages', 'test', 'tests'];
  return dirs.filter(d => exists(d));
}

function detectLicense() {
  for (const f of ['LICENSE', 'LICENSE.md', 'LICENSE.txt']) {
    if (exists(f)) {
      const c = read(f).toLowerCase();
      if (c.includes('mit license')) return 'MIT';
      if (c.includes('apache license')) return 'Apache-2.0';
      if (c.includes('bsd')) return 'BSD';
      if (c.includes('gpl')) return 'GPL';
      return 'custom (see LICENSE)';
    }
  }
  return 'unspecified';
}

function generate() {
  const type = detectType();
  const name = detectName();
  const desc = detectDescription();
  const stack = detectStack(type);
  const conv = detectConventions();
  const dirs = listKeyDirs();
  const license = detectLicense();
  const date = new Date().toISOString().slice(0, 10);

  return `# Project Context

> Auto-refreshed by refresh-project.js on ${date}.
> Source of truth: actual project files (package.json, pubspec.yaml, etc.)
> Edit \`Conventions\` / \`Non-Negotiables\` / \`Architecture Notes\` sections manually — they are preserved across refreshes.

## Identity
- **Name**: ${name}
- **Type**: ${type}
- **Description**: ${desc}

## Stack
- **Language**: ${stack.language}
- **Framework**: ${stack.framework}
- **Runtime / Build**: ${stack.runtime || '?'}
- **Package manager**: ${stack.package_manager}
- **Database**: (not detected)
- **Deployment**: (not detected)

## Conventions
${conv}

## Directory Layout
${dirs.length ? dirs.map(d => `- \`${d}/\``).join('\n') : '(no standard layout detected)'}

## License
${license}

## Non-Negotiables
- (manually edited — preserve across refreshes)

## Architecture Notes
- (manually edited — preserve across refreshes)

## Open Questions
- (manually edited — preserve across refreshes)
`;
}

function simpleDiff(oldText, newText) {
  const oldLines = oldText.split('\n');
  const newLines = newText.split('\n');
  const max = Math.max(oldLines.length, newLines.length);
  const diff = [];
  for (let i = 0; i < max; i++) {
    if (oldLines[i] !== newLines[i]) {
      if (oldLines[i] !== undefined) diff.push(`- L${i + 1}: ${oldLines[i]}`);
      if (newLines[i] !== undefined) diff.push(`+ L${i + 1}: ${newLines[i]}`);
    }
  }
  return diff.length ? diff.join('\n') : '(no changes)';
}

function preserveManualSections(oldContent, newContent) {
  // Preserve "Non-Negotiables", "Architecture Notes", "Open Questions"
  // sections from old content if they exist.
  if (!oldContent) return newContent;
  const sections = ['Non-Negotiables', 'Architecture Notes', 'Open Questions'];
  let result = newContent;
  for (const section of sections) {
    const re = new RegExp(`(## ${section}\\s*\\n)([\\s\\S]*?)(?=\\n## |$)`, 'm');
    const oldMatch = oldContent.match(re);
    if (oldMatch) {
      result = result.replace(re, `$1${oldMatch[2].trim()}\n\n`);
    }
  }
  return result;
}

const newContentRaw = generate();
const oldContent = read(PROJECT_MD);
const newContent = preserveManualSections(oldContent, newContentRaw);

if (CHECK_ONLY) {
  if (oldContent === newContent) {
    console.log('OK: PROJECT.md is up to date');
    process.exit(0);
  } else {
    console.log('STALE: PROJECT.md needs refresh (run refresh-project.js)');
    process.exit(1);
  }
}

if (DRY_RUN) {
  console.log('--- DRY RUN: would write to .agents/PROJECT.md ---');
  console.log('');
  if (oldContent === newContent) {
    console.log('(no changes — already up to date)');
  } else {
    console.log('--- DIFF ---');
    console.log(simpleDiff(oldContent, newContent));
  }
  process.exit(0);
}

if (oldContent === newContent) {
  console.log('PROJECT.md is already up to date. Nothing to do.');
  process.exit(0);
}

if (oldContent) {
  fs.copyFileSync(PROJECT_MD, BACKUP_MD);
  console.log(`Backup: ${path.relative(CWD, BACKUP_MD)}`);
}
fs.writeFileSync(PROJECT_MD, newContent);
console.log(`Updated: ${path.relative(CWD, PROJECT_MD)}`);
console.log('');
console.log('--- REPORT ---');
const diff = simpleDiff(oldContent, newContent);
const added = (diff.match(/^\+/gm) || []).length;
const removed = (diff.match(/^-/gm) || []).length;
console.log(`Lines added: ${added}`);
console.log(`Lines removed: ${removed}`);
console.log('');
console.log('Sections regenerated: Identity, Stack, Conventions, Directory Layout, License');
console.log('Sections preserved: Non-Negotiables, Architecture Notes, Open Questions (manual edits kept)');
