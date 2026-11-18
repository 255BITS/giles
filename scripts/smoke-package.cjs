const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { mkdirSync, mkdtempSync, readFileSync, existsSync, rmSync, writeFileSync } = require('node:fs');
const { createRequire } = require('node:module');
const { tmpdir } = require('node:os');
const path = require('node:path');

const archive = path.resolve(process.argv[2]);
const source = require('../package.json');
const root = mkdtempSync(path.join(tmpdir(), 'giles-package-'));
try {
  execFileSync('npm', ['install', '--ignore-scripts', '--no-audit', '--no-fund', '--prefix', root, archive], {
    stdio: 'inherit',
  });
  const fromConsumer = createRequire(path.join(root, 'package.json'));
  assert.equal(typeof fromConsumer('giles').build, 'function');
  assert.equal(fromConsumer('giles/package.json').version, source.version);

  const cli = path.join(root, 'node_modules', '.bin', 'giles');
  const run = (...args) => execFileSync(cli, args, { cwd: root, encoding: 'utf8' });
  assert.match(run('--help'), /--server/);
  assert.equal(run('--versionOut').trim(), source.version);
  assert.equal(run('-v').trim(), source.version);

  const assets = path.join(root, 'sample assets');
  mkdirSync(assets);
  const input = path.join(assets, 'app.coffee');
  const output = path.join(assets, 'app.js');
  writeFileSync(input, 'result = "installed package"\n');
  run(input, '--quiet');
  assert.match(readFileSync(output, 'utf8'), /result = "installed package"/);
  run(assets, '--clean', '--quiet');
  assert.equal(existsSync(output), false);
} finally {
  rmSync(root, { recursive: true, force: true });
}
