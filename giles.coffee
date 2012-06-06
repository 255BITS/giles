fs = require 'fs'
pathfs = require 'path'
log = require './log'
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
          log.error(err)
        else if stats.isFile()
          onFile(path)
        else if stats.isDirectory()
          @crawl(path, onDirectory, onFile)
        else
          #wtf are we dealing with.  A device?!
          log.error("Could not determine file "+filename)
          log.error(stats)

    fs.readdir dir, (err, files) =>
      if err
        log.error("cannot read dir")
        log.error(err)
      else
        onDirectory(dir)
        for file in files
          path=dir+'/'+file
          fs.stat path, handlePath(path)

  #Watches a directory recursively
  watch : (dir, opts) ->
    onDirectory = (dir) =>
      return if @isIgnored(dir)
      fs.watch dir, {persistent:true}, (event, file) =>
        path = dir+'/'+file
        fs.stat path, (err, stats) =>
          if err
            log.error(err)
          else if stats.isDirectory()
            onDirectory(path)
          else if stats.isFile()
            @buildFile(path)
          else
            #wtf are we dealing with.  A device?!
            log.error("Could not determine file "+filename)
            log.error(stats)

    #if 'dir' is a file, we watch it
    ifFile = () =>
      fs.watchFile dir, {persistent:true, interval: 50}, () =>
        @compile(dir)

    @process dir, onDirectory, ifFile
    
  #Adds a compiler.  See README.md for usage
  addCompiler : (extensions, target, callback) ->
    compiler = 
      callback : callback,
      extension: target
    
    if typeof extensions is 'object'
      @compilerMap[ext] = compiler for ext in extensions
    else
      @compilerMap[extensions] = compiler


  buildFile : (name) =>
    @compile(name) unless @isIgnored(name)

  process : (dir, onDirectory, ifFile) ->
    stats = fs.statSync(dir)
    if stats.isDirectory()
      @crawl dir, onDirectory, @buildFile
    else if stats.isFile()
      @compile(dir)
      ifFile() if ifFile
    else
      log.error(dir + " is not a directory or file")

  #Builds a directory.  See README.md for usage
  build : (dir, opts) ->
    onDirectory = () ->

    @process dir, onDirectory
    
  #Ignore an array of various directory names
  ignore : (types) ->
    @ignored = types


  #Compiles a file and writes it out to disk
  compile : (file) ->
    result = @compileFile file, (result) ->
      return unless result
      fs.writeFileSync result.outputFile, result.content, 'utf8'
      log.encourage()

  #Compiles a file and calls cb() with the result object
  compileFile : (file, cb) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    return unless pathfs.existsSync(file)
    outputFile = prefix+compiler.extension
    content = fs.readFileSync(file, 'utf8')

    outputContent = null
    if pathfs.existsSync(outputFile)
      outputContent = fs.readFileSync(outputFile, 'utf8')

    cwd = process.cwd()
    try
      compiler.callback content, file, @locals, (output) ->
        if output == outputContent
          return

        #Output the relative file name in respect
        #to the user's current directory
        relFile = file.replace(cwd, ".")
        relOutputFile = file.replace(cwd, ".")
        log.notice('compiled ' +relFile+ ' to ' + relOutputFile)

        cb( 
          outputFile : outputFile,
          content : output,
          inputFile : file,
          originalContent : content
        )
    catch error
      log.error(error)
      log.error("stack trace:")
      log.error(error.stack.replace(cwd, "."))


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


[stylus, coffee, iced, jade] = []

#create our export singleton to set up default values
giles = new Giles()
giles.locals = {}

#Stylus compiler.  Nothing fancy
giles.addCompiler [".styl", ".stylus"], '.css', (contents, filename, options, output) ->
  stylus = require 'stylus' unless stylus
  styl = stylus(contents)
  styl.set('filename', filename)
  styl.include(options.cwd)
  for key, val in options
    styl.define(key, val)

  stylus.render contents, {filename: filename}, (err, css) ->
    if err
      log.error "Could not render stylus file: "+filename
      log.error err
    else
      output(css)

#coffeescript compiler
giles.addCompiler ['.coffee', '.cs'], '.js', (contents, filename, options, output) ->
  coffee = require 'coffee-script' unless coffee
  output(coffee.compile(contents, options))

#iced-coffeescript compiler
giles.addCompiler '.iced', '.js', (contents, filename, output) ->
  iced = require 'iced-coffee-script' unless iced
  output(iced.compile(contents))

#jade compiler
giles.addCompiler '.jade', '.html',  (contents, filename, options, output) ->
  jade = require 'jade' unless jade
  compileOpts = {}
  compileOpts.filename = filename
  compileOpts.debug = true if options.development
  output(jade.compile(contents, compileOpts)(options))

#default ignores, may be overriden
giles.ignore [/node_modules/, /.git/]

#export the giles singleton
module.exports = giles
