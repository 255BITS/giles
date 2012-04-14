fs = require 'fs'
pathfs = require 'path'
class Giles 
  constructor : () ->
    @compilerMap = {}

  crawl : (dir, onDirectory, onFile) ->
    handlePath = (path) =>
      (err, stats) =>
        if err
          console.error(err)
        else if stats.isFile()
          onFile(path)
        else if stats.isDirectory()
          @crawl(path, onDirectory, onFile)
        else
          #wtf are we dealing with.  A device?!
          console.error("Could not determine file "+filename)
          console.error(stats)

    fs.readdir dir, (err, files) =>
      if err
        console.error("cannot read dir")
        console.error(err)
      else
        onDirectory(dir)
        for file in files
          path=dir+'/'+file
          console.log("path is "+path)
          fs.stat path, handlePath(path)

  watch : (dir, opts) ->
    onFile = (name) =>
      console.log('compiling ' +name)
      @compile(name)

    onDirectory = (dir) =>
      console.log("watch: " + dir)
      fs.watch dir, {persistent:true}, (event, file) =>
        path = dir+'/'+file
        console.log 'event: ' + event + ' ' + file
        fs.stat path, (err, stats) ->
          if err
            console.error(err)
          else if stats.isDirectory()
            onDirectory(path)
          else if stats.isFile()
            onFile(path)
          else
            #wtf are we dealing with.  A device?!
            console.error("Could not determine file "+filename)
            console.error(stats)

    @crawl dir, onDirectory, onFile
    #XXX TODO
    
  addCompiler : (extensions, target, callback) ->
    compiler = {
      callback : callback,
      extension: target
    }
    if typeof extensions is 'object'
      @compilerMap[ext] = compiler for ext in extensions
    else
      @compilerMap[extensions] = compiler

  build : (dir, opts) ->
    #XXX TODO 
    
  ignore : (types) ->


  compile : (file) ->
    result = @compileFile(file)
    return unless result
    fs.writeFileSync result.outputFile, result.content, 'utf8'

  compileFile : (file) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    return unless pathfs.existsSync(file)
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
