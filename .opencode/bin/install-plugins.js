#!/usr/bin/env node
// .opencode/bin/install-plugins.js
// Installs the optional opencode plugins declared in package.json.
// Idempotent: skips if node_modules already exists.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const pkgPath = path.join(root, 'package.json');
const nodeModulesPath = path.join(root, 'node_modules');

if (!fs.existsSync(pkgPath)) {
  console.error('[install-plugins] ERROR: package.json not found at', pkgPath);
  console.error('  This script must be run from the .opencode/ directory.');
  process.exit(1);
}

if (fs.existsSync(nodeModulesPath)) {
  console.log('[install-plugins] node_modules/ already exists. Skipping install.');
  console.log('  To force reinstall, delete node_modules/ and run this script again.');
  process.exit(0);
}

console.log('[install-plugins] Installing plugins from package.json...');
console.log('  This may take 30-60 seconds on first run.');

try {
  // --ignore-scripts: skip postinstall hooks (some plugins require bun, deno, etc.)
  // Remove this flag if a plugin's postinstall is required for it to work.
  execSync('npm install --no-audit --no-fund --ignore-scripts', {
    cwd: root,
    stdio: 'inherit'
  });
  console.log('\n[install-plugins] OK. Restart opencode to load the plugins.');
} catch (err) {
  console.error('\n[install-plugins] FAILED:', err.message);
  console.error('  Check your network connection and try again.');
  process.exit(1);
}
