const assert = require('node:assert/strict');
const { once } = require('node:events');
const { mkdir, mkdtemp, rm, writeFile, readFile } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const giles = require('..');

giles.quiet();

async function fixture(t, files) {
  const root = await mkdtemp(path.join(tmpdir(), 'giles-test-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  for (const [name, contents] of Object.entries(files)) {
    const file = path.join(root, name);
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, contents);
  }
  return root;
}

function compile(file, locals = {}) {
  return new Promise(resolve => giles.compileFile(file, locals, {}, resolve));
}

test('parses extensions', () => {
  assert.deepEqual(giles.parseFileName('file.min.css'), ['file.min', '.css']);
  assert.deepEqual(giles.parseFileName('.config'), ['.config', '']);
  assert.deepEqual(giles.parseFileName('file'), ['file', '']);
});

test('custom compilers retain callbacks and write output', async t => {
  const dir = await fixture(t, { 'source.sample': 'testing', 'source.legacy': 'legacy' });
  giles.addCompiler('.sample', '.rendered', (contents, filename, locals, done) => {
    assert.equal(path.basename(filename), 'source.sample');
    done(contents.slice(0, locals.limit));
  });
  const input = path.join(dir, 'source.sample');
  const locals = { limit: 5 };
  const result = await compile(input, locals);
  assert.equal(result.content, 'testi');
  assert.equal(result.originalContent, 'testing');
  assert.equal(result.inputFile, input);
  assert.equal(result.outputFile, path.join(dir, 'source.rendered'));
  giles.compile(input, locals);
  assert.equal(await readFile(result.outputFile, 'utf8'), 'testi');
  assert.equal((await compile(input, locals)).exists, true);

  giles.addCompiler('.legacy', '.rendered', (contents, filename, done) => done(contents));
  assert.equal((await compile(path.join(dir, 'source.legacy'))).content, 'legacy');
});

test('native compilers render CoffeeScript, IcedCoffeeScript, Markdown, Jade, Pug and Stylus', { timeout: 5000 }, async t => {
  const src = await fixture(t, {
    'value.coffee': 'coffeeMessage = "Coffee OK"\n',
    'iced.iced': 'icedMessage = "Iced OK"\n',
    'doc.md': '# Markdown OK\n',
    'index.jade': '!!!\ninclude _message\n',
    '_message.jade': 'p= title\n',
    'modern.pug': 'h2 Modern Pug\n',
    'site.styl': '@import "rules/*"\n',
    'rules/base.styl': 'body\n  color: #123456\n',
  });
  const output = async (file, locals) => (await compile(path.join(src, file), locals)).content;
  assert.match(await output('value.coffee'), /coffeeMessage = "Coffee OK"/);
  assert.match(await output('iced.iced'), /icedMessage = ['"]Iced OK['"]/);
  assert.match(await output('doc.md'), /<h1>Markdown OK<\/h1>/);
  const html = await output('index.jade', { title: 'Jade OK' });
  assert.match(html, /<!DOCTYPE html>/i);
  assert.match(html, /<p>Jade OK<\/p>/);
  assert.match(await output('modern.pug'), /<h2>Modern Pug<\/h2>/);
  assert.match(await output('site.styl'), /color: #123456/);
});

test('development server compiles with MIME types and serves existing static files', { timeout: 5000 }, async t => {
  const root = await fixture(t, {
    'index.jade': 'p= title\n',
    'app.coffee': 'available = true\n',
    'base.styl': 'body\n  color: red\n',
    'note.txt': 'Static asset',
  });
  giles.get('/custom.html', path.join(root, 'index.jade'), { title: 'Custom route' });
  const server = giles.server(root, { port: 0 });
  t.after(() => new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve())));
  await once(server, 'listening');
  const url = `http://127.0.0.1:${server.address().port}`;
  for (const [route, mime, content] of [
    ['/custom.html?test=1', 'text/html', 'Custom route'],
    ['/app.js', 'application/javascript', 'available = true'],
    ['/base.css', 'text/css', 'color: #f00'],
    ['/note.txt', 'text/plain', 'Static asset'],
  ]) {
    const response = await fetch(url + route);
    assert.equal(response.status, 200, route);
    assert.ok(response.headers.get('Content-Type').startsWith(mime), route);
    assert.ok((await response.text()).includes(content), route);
  }
  assert.equal((await fetch(url + '/absent.html')).status, 404);
});
