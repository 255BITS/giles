#!/usr/bin/env node
var commander = require('commander')
var giles = require('../giles')

commander.
  usage('[directory] [options]').
  option('-o, --output-dir <dir>', 'The output directory').
  option('-i, --ignore <dir-list>', 'A comma delimited list of directories to ignore').
//  option('-j, --json <json-config-file>','The json file which defines local variables for templates').
  option('-w, --watch', 'Watches the existing and new files for changes.  For development mode.');

commander.parse(process.argv);

console.log(commander);
commander.args.forEach(function(dir) {
  var opts = {};
  if(commander.watch) {
    giles.watch(dir, opts);
  } else {
    giles.build(dir, opts);
  }
});
