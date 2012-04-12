fs = require 'fs'
String.prototype.endsWith = (suffix) -> this.indexOf(suffix, this.length - suffix.length) != -1

class Giles 
  watch : (dir, opts) ->
    console.log("Watching "+ dir)
    fs.watch dir, {persistent:true}, (event, file) ->
      console.log event
      console.log file
    #XXX TODO
    
  compile : (target, extensions, callback) ->
    console.log "added " + extensions
    #XXX TODO

  build : (dir, opts) ->
    console.log("building " + dir)
    #XXX TODO 
    #
stylus = false
coffee = false
jade = false

giles = new Giles()
giles.locals = {}
giles.compile [".styl", ".stylus"], '.css', (file) ->
  stylus = require 'stylus' unless stylus
  contents = fs.readFileSync(file, 'utf8')
  stylus.render contents, {filename: file}, (err, css) ->
    if err
      console.error "Could not render stylus file: "+file
      console.error err

giles.compile ['.coffee', '.cs'], '.js', (file) ->
  coffee = require 'coffee-script' unless coffee
  contents = fs.readFileSync(file, 'utf8')
  coffee.compile contents, {}

giles.compile '.jade', '.html',  (file) ->
  jade = require 'jade' unless jade
  contents = fs.readFileSync(file, 'utf8')
  jade.compile(contents, giles.locals)(giles.locals)

giles.ignore [/node_modules/, /.git/]

if require.main == module
  #called as cli tool
else
  #required as module
  module.exports = giles
