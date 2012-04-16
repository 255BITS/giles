#!/usr/bin/env node
var commander = require('commander')
var giles = require('../giles')

commander.
  usage('[directory] [options]').
//  option('-o, --output-dir <dir>', 'The output directory').
  option('-i, --ignore <dir-list>', 'A comma delimited list of directories to ignore').
//  option('-j, --json <json-config-file>','The json file which defines local variables for templates').
  option('-w, --watch', 'Watches the existing and new files for changes.  For development mode.');

commander.parse(process.argv);

var args = commander.args;

var cwd = process.cwd();
if(args.length === 0) {
  if(commander.watch)
    console.log("No arguments(see --help), watching: "+cwd)
  else
    console.log("No arguments(see --help), building(-w to watch): "+cwd)
  args = [cwd];
}

args.forEach(function(dir) {
  var opts = {};
  if(commander.ignore) {
    var args = commander.ignore.split(',');
    var map = [], i=0, len=args.length;
    for(i=0;i<len;++i) {
      map.push(new RegExp(args[i]));
    }
    console.log('ignoring ' + map);
    giles.ignore(map);
  }
  if(commander.watch) {
    giles.watch(dir, opts);
  } else {
    giles.build(dir, opts);
  }
});

