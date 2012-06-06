#!/usr/bin/env node
var commander = require('commander');
var giles = require('../giles');
var log = require('../log')
var pathfs = require('path');

commander.
  usage('[directory] [options]').
//  option('-o, --output-dir <dir>', 'The output directory').
  option('-i, --ignore <dir-list>', 'A comma delimited list of directories to ignore').
//  option('-j, --json <json-config-file>','The json file which defines local variables for templates').
  option('-w, --watch', 'Watches the existing and new files for changes.  For development mode.').
  option('-e, --environment <dev|prod>', 'Sets the environment variable "development" or "production" to use in generated files.');

commander.parse(process.argv);

var args = commander.args;

var cwd = process.cwd();
if(args.length === 0) {
  if(commander.watch)
    log.log("No arguments(see --help), watching: "+cwd)
  else
    log.log("No arguments(see --help), building(-w to watch): "+cwd)
  args = [cwd];
}

args.forEach(function(dir) {
  dir = pathfs.resolve(cwd, dir);
  var opts = {};
  if(commander.ignore) {
    var args = commander.ignore.split(',');
    var map = [], i=0, len=args.length;
    for(i=0;i<len;++i) {
      map.push(new RegExp(args[i]));
    }
    log.log('ignoring ' + map);
    giles.ignore(map);
  }
  if(commander.environment) {
    if(commander.environment == 'dev' || commander.environment == 'development') {
      giles.locals['environment']='development';
      giles.locals['development']=true;
    } else if(commander.environment == 'prod' || commander.environment == 'production') {
      giles.locals['environment']='production';
      giles.locals['production']=true;
    }
  } else {
    log.log("Defaulting to 'development' environment.  Use -e prod for production.");
    giles.locals['environment']='development';
    giles.locals['development']=true;
  }
  giles.locals.cwd = dir;
  if(commander.watch) {
    giles.watch(dir, opts);
  } else {
    giles.build(dir, opts);
  }
});

