#!/usr/bin/env node
/**
 * instinct.js - opencode-native instinct management CLI
 *
 * Storage: ~/.config/opencode/instincts/ (global) + .opencode/instincts/ (project)
 * Format: JSON shape with instincts[] and metadata
 *
 * Usage:
 *   node instinct.js status [--scope project|global|all] [--domain coding]
 *   node instinct.js projects
 *   node instinct.js promote <id>
 *   node instinct.js evolve [--generate] [--domain coding]
 *   node instinct.js export --output ./instincts.json [--min-confidence 0.8] [--category coding]
 *   node instinct.js import ./instincts.json
 *   node instinct.js add --trigger "..." --action "..." --confidence 0.7 --category coding
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const HOME = os.homedir();
const GLOBAL_DIR = path.join(HOME, '.config', 'opencode', 'instincts');
const PROJECT_DIR = path.join(process.cwd(), '.opencode', 'instincts');
const INSTINCTS_FILE = 'instincts.json';
const REGISTRY_FILE = 'projects.json';

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function readJson(file, fallback) {
  if (!fs.existsSync(file)) return fallback;
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    return fallback;
  }
}

function writeJson(file, data) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
}

function loadInstincts(scope) {
  const files = [];
  if (scope === 'all' || scope === 'project') {
    files.push({ path: path.join(PROJECT_DIR, INSTINCTS_FILE), scope: 'project' });
  }
  if (scope === 'all' || scope === 'global') {
    files.push({ path: path.join(GLOBAL_DIR, INSTINCTS_FILE), scope: 'global' });
  }
  const merged = [];
  for (const f of files) {
    const data = readJson(f.path, { instincts: [] });
    for (const i of data.instincts || []) {
      merged.push({ ...i, _scope: f.scope });
    }
  }
  return merged;
}

function saveInstincts(scope, instincts) {
  const dir = scope === 'project' ? PROJECT_DIR : GLOBAL_DIR;
  writeJson(path.join(dir, INSTINCTS_FILE), { instincts });
}

function loadRegistry() {
  return readJson(path.join(GLOBAL_DIR, REGISTRY_FILE), { projects: [] });
}

function saveRegistry(reg) {
  writeJson(path.join(GLOBAL_DIR, REGISTRY_FILE), reg);
}

function projectId() {
  return path.basename(process.cwd());
}

function ensureProjectRegistered() {
  const id = projectId();
  const reg = loadRegistry();
  if (!reg.projects.find(p => p.id === id)) {
    reg.projects.push({
      id,
      path: process.cwd(),
      registered: new Date().toISOString(),
      lastSeen: new Date().toISOString(),
    });
    saveRegistry(reg);
  } else {
    const p = reg.projects.find(p => p.id === id);
    p.lastSeen = new Date().toISOString();
    saveRegistry(reg);
  }
}

function confidenceBar(c) {
  const filled = Math.round(c * 10);
  return '█'.repeat(filled) + '░'.repeat(10 - filled);
}

function cmdStatus(args) {
  const scope = (args.find(a => a === '--scope') ? args[args.indexOf('--scope') + 1] : 'all') || 'all';
  const domain = args.find(a => a.startsWith('--domain')) ? args[args.indexOf('--domain') + 1] : null;
  const minConf = parseFloat((args.find(a => a === '--min-confidence') ? args[args.indexOf('--min-confidence') + 1] : '0') || '0');

  const all = loadInstincts(scope);
  const filtered = all.filter(i =>
    (!domain || i.category === domain) && (i.confidence || 0) >= minConf
  );

  if (filtered.length === 0) {
    console.log(`No instincts found (scope=${scope}, domain=${domain || 'any'})`);
    console.log(`\nStorage:`);
    console.log(`  global: ${GLOBAL_DIR}`);
    console.log(`  project: ${PROJECT_DIR}`);
    return;
  }

  const byDomain = {};
  for (const i of filtered) {
    if (!byDomain[i.category || 'uncategorized']) byDomain[i.category || 'uncategorized'] = [];
    byDomain[i.category || 'uncategorized'].push(i);
  }

  console.log(`Instinct Status (${filtered.length} total, scope=${scope})\n`);
  for (const [dom, items] of Object.entries(byDomain).sort()) {
    console.log(`## ${dom} (${items.length})`);
    items.sort((a, b) => (b.confidence || 0) - (a.confidence || 0));
    for (const i of items) {
      const c = i.confidence || 0;
      const apps = i.applications || 0;
      const succ = i.successes || 0;
      const rate = apps > 0 ? Math.round((succ / apps) * 100) : 0;
      const scopeTag = i._scope ? `[${i._scope[0]}]` : '[?]';
      console.log(`  ${scopeTag} ${confidenceBar(c)} ${c.toFixed(2)}  ${i.trigger || i.id}`);
      if (i.action) console.log(`     → ${i.action.substring(0, 80)}${i.action.length > 80 ? '...' : ''}`);
      console.log(`     ${apps} apps, ${succ} succ (${rate}%)`);
    }
    console.log('');
  }
}

function cmdProjects() {
  ensureProjectRegistered();
  const reg = loadRegistry();
  const all = loadInstincts('all');
  console.log(`Registered Projects (${reg.projects.length})\n`);
  for (const p of reg.projects) {
    const projInstincts = all.filter(i => i._scope === 'project').length;
    const globalInstincts = all.filter(i => i._scope === 'global').length;
    console.log(`  ${p.id}`);
    console.log(`    path: ${p.path}`);
    console.log(`    registered: ${p.registered}`);
    console.log(`    last seen: ${p.lastSeen}`);
    console.log('');
  }
  console.log(`Total instincts: ${all.length} (project: ${all.filter(i => i._scope === 'project').length}, global: ${all.filter(i => i._scope === 'global').length})`);
}

function cmdPromote(args) {
  const id = args[0];
  if (!id) { console.error('Usage: promote <instinct-id>'); process.exit(1); }
  const proj = readJson(path.join(PROJECT_DIR, INSTINCTS_FILE), { instincts: [] });
  const idx = (proj.instincts || []).findIndex(i => i.id === id);
  if (idx === -1) { console.error(`Instinct not found in project: ${id}`); process.exit(1); }
  const [instinct] = proj.instincts.splice(idx, 1);
  writeJson(path.join(PROJECT_DIR, INSTINCTS_FILE), proj);
  const glob = readJson(path.join(GLOBAL_DIR, INSTINCTS_FILE), { instincts: [] });
  if (!glob.instincts) glob.instincts = [];
  const existing = glob.instincts.findIndex(i => i.id === id);
  if (existing >= 0) {
    glob.instincts[existing] = { ...glob.instincts[existing], ...instinct, promoted: new Date().toISOString() };
  } else {
    glob.instincts.push({ ...instinct, promoted: new Date().toISOString() });
  }
  writeJson(path.join(GLOBAL_DIR, INSTINCTS_FILE), glob);
  console.log(`Promoted ${id} (project → global)`);
}

function cmdEvolve(args) {
  const generate = args.includes('--generate');
  const domain = args.find(a => a === '--domain') ? args[args.indexOf('--domain') + 1] : null;
  ensureProjectRegistered();
  const all = loadInstincts('all');
  const filtered = domain ? all.filter(i => i.category === domain) : all;
  console.log(`Evolve Analysis (${filtered.length} instincts${domain ? `, domain=${domain}` : ''})\n`);

  const byTrigger = {};
  for (const i of filtered) {
    const key = (i.trigger || '').toLowerCase().split(' ').slice(0, 3).join(' ');
    if (!key) continue;
    if (!byTrigger[key]) byTrigger[key] = [];
    byTrigger[key].push(i);
  }

  console.log('## Skill candidates (clustered triggers)');
  const skillCandidates = Object.entries(byTrigger).filter(([_, items]) => items.length >= 2);
  if (skillCandidates.length === 0) {
    console.log('  (none — need 2+ instincts with similar triggers)');
  } else {
    for (const [trigger, items] of skillCandidates) {
      console.log(`  "${trigger}..." (${items.length} instincts)`);
      const avgConf = items.reduce((s, i) => s + (i.confidence || 0), 0) / items.length;
      console.log(`    avg confidence: ${avgConf.toFixed(2)}`);
    }
  }

  console.log('\n## Command candidates (high-confidence + frequent)');
  const cmdCandidates = filtered.filter(i => (i.confidence || 0) >= 0.8 && (i.applications || 0) >= 3);
  if (cmdCandidates.length === 0) {
    console.log('  (none — need confidence >= 0.8 and applications >= 3)');
  } else {
    for (const i of cmdCandidates.slice(0, 10)) {
      console.log(`  ${i.trigger} (conf=${i.confidence}, apps=${i.applications})`);
    }
  }

  console.log('\n## Promotion candidates (project scope)');
  const projInstincts = filtered.filter(i => i._scope === 'project' && (i.confidence || 0) >= 0.85 && (i.applications || 0) >= 5);
  if (projInstincts.length === 0) {
    console.log('  (none — need project instincts with conf >= 0.85 and apps >= 5)');
  } else {
    for (const i of projInstincts) {
      console.log(`  ${i.id} (conf=${i.confidence}, apps=${i.applications})`);
    }
  }

  if (generate) {
    const outDir = path.join(PROJECT_DIR, '..', 'evolved');
    ensureDir(outDir);
    const timestamp = new Date().toISOString();
    writeJson(path.join(outDir, 'candidates.json'), {
      generated: timestamp,
      skills: skillCandidates.map(([trigger, items]) => ({ trigger, count: items.length, avg_conf: items.reduce((s, i) => s + (i.confidence || 0), 0) / items.length })),
      commands: cmdCandidates.map(i => ({ id: i.id, trigger: i.trigger, action: i.action, confidence: i.confidence })),
      promotions: projInstincts.map(i => i.id),
    });
    console.log(`\nWrote candidates → ${outDir}/candidates.json`);
  }
}

function cmdExport(args) {
  const outIdx = args.indexOf('--output');
  const outFile = outIdx >= 0 ? args[outIdx + 1] : './instincts-export.json';
  const minConf = parseFloat((args.find(a => a === '--min-confidence') ? args[args.indexOf('--min-confidence') + 1] : '0') || '0');
  const category = args.find(a => a === '--category') ? args[args.indexOf('--category') + 1] : null;
  const scope = (args.find(a => a === '--scope') ? args[args.indexOf('--scope') + 1] : 'all') || 'all';

  const all = loadInstincts(scope);
  const filtered = all.filter(i =>
    (!category || i.category === category) && (i.confidence || 0) >= minConf
  );

  const exportData = {
    instincts: filtered.map(({ _scope, ...rest }) => rest),
    metadata: {
      version: '1.0',
      exported: new Date().toISOString(),
      author: os.userInfo().username,
      total: filtered.length,
      filter: { min_confidence: minConf, category, scope },
    },
  };

  writeJson(outFile, exportData);
  console.log(`Exported ${filtered.length} instincts → ${outFile}`);

  const byCat = {};
  for (const i of filtered) byCat[i.category || 'uncategorized'] = (byCat[i.category || 'uncategorized'] || 0) + 1;
  console.log('\nCategories:');
  for (const [c, n] of Object.entries(byCat).sort()) console.log(`  ${c}: ${n}`);
}

function cmdImport(args) {
  const src = args[0];
  if (!src) { console.error('Usage: import <file|url>'); process.exit(1); }
  let data;
  if (src.startsWith('http://') || src.startsWith('https://')) {
    console.error('URL import requires fetch — use local file path for now');
    process.exit(1);
  }
  if (!fs.existsSync(src)) { console.error(`File not found: ${src}`); process.exit(1); }
  data = readJson(src, null);
  if (!data || !data.instincts) { console.error('Invalid format: missing instincts[]'); process.exit(1); }

  const scope = (args.find(a => a === '--scope') ? args[args.indexOf('--scope') + 1] : 'global') || 'global';
  const existing = loadInstincts('all');
  const existingIds = new Set(existing.map(i => i.id).filter(Boolean));
  let imported = 0, skipped = 0, errors = 0;
  const target = readJson(path.join(scope === 'project' ? PROJECT_DIR : GLOBAL_DIR, INSTINCTS_FILE), { instincts: [] });
  if (!target.instincts) target.instincts = [];

  for (const i of data.instincts) {
    try {
      if (!i.trigger || !i.action) { errors++; continue; }
      const id = i.id || `instinct-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      if (existingIds.has(id)) { skipped++; continue; }
      const adjusted = { ...i, id, confidence: (i.confidence || 0.5) * 0.8, source: 'imported', importedAt: new Date().toISOString() };
      target.instincts.push(adjusted);
      imported++;
    } catch (e) { errors++; }
  }
  saveInstincts(scope, target.instincts);
  console.log(`Import Summary`);
  console.log(`  Source: ${src}`);
  console.log(`  Imported: ${imported}`);
  console.log(`  Skipped (duplicates): ${skipped}`);
  console.log(`  Errors: ${errors}`);
  console.log(`  Scope: ${scope}`);
}

function cmdAdd(args) {
  const get = (flag) => {
    const i = args.indexOf(flag);
    return i >= 0 ? args[i + 1] : null;
  };
  const trigger = get('--trigger');
  const action = get('--action');
  const confidence = parseFloat(get('--confidence') || '0.5');
  const category = get('--category') || 'uncategorized';
  const scope = get('--scope') || 'project';
  if (!trigger || !action) { console.error('Usage: add --trigger "..." --action "..." [--confidence 0.7] [--category coding] [--scope project]'); process.exit(1); }
  const id = `instinct-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const data = readJson(path.join(scope === 'project' ? PROJECT_DIR : GLOBAL_DIR, INSTINCTS_FILE), { instincts: [] });
  if (!data.instincts) data.instincts = [];
  data.instincts.push({ id, trigger, action, confidence, category, applications: 0, successes: 0, source: 'manual', created: new Date().toISOString() });
  saveInstincts(scope, data.instincts);
  console.log(`Added ${id} (${scope})`);
}

function help() {
  console.log(`instinct.js - opencode-native instinct management

Usage:
  status [--scope project|global|all] [--domain X] [--min-confidence 0.5]
  projects
  promote <id>
  evolve [--generate] [--domain X]
  export --output FILE [--min-confidence 0.5] [--category X] [--scope X]
  import FILE [--scope project|global]
  add --trigger "..." --action "..." [--confidence 0.5] [--category X] [--scope X]

Storage:
  global:  ${GLOBAL_DIR}
  project: ${PROJECT_DIR}`);
}

const [, , cmd, ...rest] = process.argv;
switch (cmd) {
  case 'status': cmdStatus(rest); break;
  case 'projects': cmdProjects(rest); break;
  case 'promote': cmdPromote(rest); break;
  case 'evolve': cmdEvolve(rest); break;
  case 'export': cmdExport(rest); break;
  case 'import': cmdImport(rest); break;
  case 'add': cmdAdd(rest); break;
  case 'help':
  case '--help':
  case '-h':
  case undefined: help(); break;
  default: console.error(`Unknown command: ${cmd}`); help(); process.exit(1);
}
