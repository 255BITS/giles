fs = require 'fs'
pathfs = require 'path'
class Giles 
  constructor : () ->
    @compilerMap = {}
    @ignored = []

  #Crawls a directory recursively
  #calls onDirectory for every directory encountered
  #calls onFile for every file encountered
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

  #Watches a directory recursively
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
    
  #Adds a compiler.  See README.md for usage
  addCompiler : (extensions, target, callback) ->
    compiler = 
      callback : callback,
      extension: target
    
    if typeof extensions is 'object'
      @compilerMap[ext] = compiler for ext in extensions
    else
      @compilerMap[extensions] = compiler

  #Builds a directory.  See README.md for usage
  build : (dir, opts) ->
    onFile = (name) =>
      @compile(name) unless @isIgnored(name)

    onDirectory = () ->

    @crawl dir, onDirectory, onFile
    
  #Ignore an array of various directory names
  ignore : (types) ->
    @ignored = types


  #Compiles a file and writes it out to disk
  compile : (file) ->
    result = @compileFile file, (result) ->
      return unless result
      fs.writeFileSync result.outputFile, result.content, 'utf8'

  #Compiles a file and calls cb() with the result object
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

  # Get the prefix and extension for a filename
  parseFileName : (file) ->
    index = file.lastIndexOf '.'
    if index == -1
      [file, '']
    else
      [file.substr(0,index), file.substr(index)]

  # true if name contains an ignored directory
  isIgnored : (name) ->
    for ignore in @ignored
      return true if ignore.test(name) #this matches really greedy
    return false


stylus = false
coffee = false
jade = false

#create our export singleton to set up default values
giles = new Giles()
giles.locals = {}

#Stylus compiler.  Nothing fancy
giles.addCompiler [".styl", ".stylus"], '.css', (contents, filename, output) ->
  stylus = require 'stylus' unless stylus
  stylus.render contents, {filename: filename}, (err, css) ->
    if err
      console.error "Could not render stylus file: "+filename
      console.error err
    else
      output(css)

#coffeescript compiler
giles.addCompiler ['.coffee', '.cs'], '.js', (contents, filename, output) ->
  coffee = require 'coffee-script' unless coffee
  output(coffee.compile(contents, {}))

#jade compiler
giles.addCompiler '.jade', '.html',  (contents, filename, output) ->
  jade = require 'jade' unless jade
  output(jade.compile(contents, giles.locals)(giles.locals))

#default ignores, may be overriden
giles.ignore [/node_modules/, /.git/]

#export the giles singleton
module.exports = giles
