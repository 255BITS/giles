fs = require 'fs'
class Giles 
  watch : (dir, opts) ->
    console.log("Watching "+ dir)
    #XXX TODO
    
  addFileType : (extension, callback) ->
    console.log " watching " + extension
    #XXX TODO

  build : (dir, opts) ->
    console.log("Building " + dir)
    #XXX TODO 
    #
stylus = false
coffee = false
jade = false

giles = new Giles()
giles.globals = {}
giles.addFileType [".styl", ".stylus"], (file) ->
  stylus = require 'stylus' unless stylus
  contents = fs.readFileSync(file, 'utf8')
  stylus.render contents, {filename: file}, (err, css) ->
    if err
      console.error "Could not render stylus file: "+file
      console.error err

giles.addFileType ['.coffee', '.cs'], (file) ->
  coffee = require 'coffee-script' unless coffee
  contents = fs.readFileSync(file, 'utf8')
  coffee.compile contents, {}

giles.addFileType '.jade', (file) ->
  jade = require 'jade' unless jade
  contents = fs.readFileSync(file, 'utf8')
  jade.compile(contents, giles.globals)(giles.globals)

module.exports = giles
