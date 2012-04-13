fs = require 'fs'
String.prototype.endsWith = (suffix) -> this.indexOf(suffix, this.length - suffix.length) != -1
class Giles 
  constructor : () ->
    @compilerMap = {}

  watch : (dir, opts) ->
    console.log("Watching "+ dir)
    fs.watch dir, {persistent:true}, (event, file) ->
      console.log event
      console.log file
    #XXX TODO
    
  addCompiler : (extensions, target, callback) ->
    compiler = {
      callback : callback,
      extension: target
    }
    if typeof extensions is Array
      @compilerMap[ext] = compiler for ext in extensions
    else
      @compilerMap[extensions] = compiler

  build : (dir, opts) ->
    console.log("building " + dir)
    #XXX TODO 
    
  ignore : (types) ->
    console.log("types to ignore " + types)


  compileFile : (file) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    content = fs.readFileSync(file, 'utf8')
    output = @compilerMap[ext].callback(content)

    return { 
      outputFile : prefix+compiler.extension,
      content : output,
      inputFile : file,
      originalContent : content
    }

  parseFileName : (file) ->
    index = file.lastIndexOf '.'
    if index == -1
      [file, '']
    else
      [file.substr(0,index), file.substr(index)]

stylus = false
coffee = false
jade = false

giles = new Giles()
giles.locals = {}
giles.addCompiler [".styl", ".stylus"], '.css', (contents) ->
  stylus = require 'stylus' unless stylus
  stylus.render contents, {filename: file}, (err, css) ->
    if err
      console.error "Could not render stylus file: "+file
      console.error err

giles.addCompiler ['.coffee', '.cs'], '.js', (contents) ->
  coffee = require 'coffee-script' unless coffee
  coffee.compile contents, {}

giles.addCompiler '.jade', '.html',  (contents) ->
  jade = require 'jade' unless jade
  jade.compile(contents, giles.locals)(giles.locals)

giles.ignore [/node_modules/, /.git/]

module.exports = giles
