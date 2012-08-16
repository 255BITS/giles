#!/usr/bin/env node
var commander = require('commander');
var giles = require('../giles');
var log = require('../log')
var pathfs = require('path');
var fs = require('fs');

commander.
  usage('[directory] [options]').
//  option('-o, --output-dir <dir>', 'The output directory').
  option('-i, --ignore <dir-list>', 'A comma delimited list of directories to ignore').
//  option('-j, --json <json-config-file>','The json file which defines local variables for templates').
  option('-e, --environment <dev|prod>', 'Sets the environment variable "development" or "production" to use in generated files.').
  option('-s, --server', 'Start a server to serve your compiled jade/coffeescript/etc files - on port 3999').
  option('-c, --clean', 'Clean up all the generated files').
  option('-v, --versionOut', 'Outputs version number').
  option('-p, --port <port>', 'Port to run with giles -s.').
  option('-q, --quiet', 'No output mode');

commander.parse(process.argv);

var args = commander.args;

var cwd = process.cwd();

if(commander.versionOut) {
  var package = JSON.parse(fs.readFileSync(__dirname+'/../package.json'));
  console.log(package.version);
  return;
}

if(commander.quiet) {
  giles.quiet();
  log.quiet();
}

if(args.length === 0) {
  log.notice("No path specified.  That's quite alright, I'll use the current path: "+cwd);
  args = [cwd];
}

args.forEach(function(dir) {
  dir = pathfs.resolve(cwd, dir);
  var opts = {};
  if(commander.port) {
    opts.port = commander.port;
  }
  if(commander.ignore) {
    var args = commander.ignore.split(',');
    var map = [], i=0, len=args.length;
    for(i=0;i<len;++i) {
      map.push(new RegExp(args[i]));
    }
    log.log('ignoring ' + map);
    giles.ignore(map);
  }

  if(commander.environment == 'dev') {
    commander.environment = "development";
  }
  if(commander.environment == 'prod') {
    commander.environment = "production";
  }
  if(commander.environment == null) {
    commander.environment = "development";
  }
  
  log.info("Environment set to "+commander.environment);
  giles.locals['environment']=commander.environment;
  giles.locals[commander.environment]=true;
  giles.locals.cwd = dir;

  if(commander.server) {
    giles.server(dir, opts);
  } else if(commander.clean) {
    giles.clean(dir, opts);
  } else {
    giles.build(dir, opts);
  }
});

