#!/usr/bin/env node
const { Command } = require('commander');
const path = require('node:path');

const giles = require('../dist/giles');
const { version } = require('../package.json');

const program = new Command()
  .usage('[directory] [options]')
  .argument('[directories...]')
  .option('-i, --ignore <dir-list>', 'A comma delimited list of directories to ignore')
  .option('-e, --environment <dev|prod>', 'Template environment. Prefer the NODE_ENV variable.')
  .option('-s, --server', 'Serve and compile assets on demand. The default port is 2255.')
  .option('-c, --clean', 'Clean up the generated files')
  .version(version, '-v, --versionOut', 'Output the version number')
  .option('-p, --port <port>', 'Port for the development server')
  .option('-q, --quiet', 'No output mode')
  .parse();

const options = program.opts();
if (options.quiet) giles.quiet();
if (options.ignore) giles.ignore(options.ignore.split(',').map(pattern => new RegExp(pattern)));

const environment = process.env.NODE_ENV || options.environment;
if (environment) {
  giles.locals.environment = environment;
  giles.locals[environment] = true;
}

const directories = program.args.length ? program.args : [process.cwd()];
for (const directory of directories) {
  const dir = path.resolve(directory);
  const settings = { port: options.port };
  giles.locals.cwd = dir;

  if (options.server) {
    giles.server(dir, settings);
  } else if (options.clean) {
    giles.clean(dir, settings);
  } else {
    giles.build(dir, settings);
  }
}
