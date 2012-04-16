fs = require 'fs'
pathfs = require 'path'
class Giles 
  constructor : () ->
    @compilerMap = {}
    @ignored = []

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
          fs.stat path, handlePath(path)

  watch : (dir, opts) ->
    onFile = (name) =>
      @compile(name) unless @isIgnored(name)

    onDirectory = (dir) =>
      return if @isIgnored(dir)
      fs.watch dir, {persistent:true}, (event, file) =>
        path = dir+'/'+file
        #console.log 'event: ' + event + ' ' + file
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
    compiler = 
      callback : callback,
      extension: target
    
    if typeof extensions is 'object'
      @compilerMap[ext] = compiler for ext in extensions
    else
      @compilerMap[extensions] = compiler

  build : (dir, opts) ->
    onFile = (name) =>
      @compile(name) unless @isIgnored(name)

    onDirectory = () ->

    @crawl dir, onDirectory, onFile
    
  ignore : (types) ->
    @ignored = types


  compile : (file) ->
    result = @compileFile file, (result) ->
      return unless result
      fs.writeFileSync result.outputFile, result.content, 'utf8'

  compileFile : (file, cb) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    return unless pathfs.existsSync(file)
    console.log('compiling ' +file+ ' to ' + prefix+compiler.extension);
    content = fs.readFileSync(file, 'utf8')
    compiler.callback content, file, (output) ->
      cb( 
        outputFile : prefix+compiler.extension,
        content : output,
        inputFile : file,
        originalContent : content
      )

    return 
  parseFileName : (file) ->
    index = file.lastIndexOf '.'
    if index == -1
      [file, '']
    else
      [file.substr(0,index), file.substr(index)]

  isIgnored : (name) ->
    for ignore in @ignored
      return true if ignore.test(name)
    return false


stylus = false
coffee = false
jade = false

giles = new Giles()
giles.locals = {}
giles.addCompiler [".styl", ".stylus"], '.css', (contents, filename, output) ->
  stylus = require 'stylus' unless stylus
  stylus.render contents, {filename: filename}, (err, css) ->
    if err
      console.error "Could not render stylus file: "+filename
      console.error err
    else
      output(css)

giles.addCompiler ['.coffee', '.cs'], '.js', (contents, filename, output) ->
  coffee = require 'coffee-script' unless coffee
  output(coffee.compile(contents, {}))

giles.addCompiler '.jade', '.html',  (contents, filename, output) ->
  jade = require 'jade' unless jade
  output(jade.compile(contents, giles.locals)(giles.locals))

giles.ignore [/node_modules/, /.git/]

module.exports = giles
