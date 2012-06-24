fs = require 'fs'
pathfs = require 'path'
log = require './log'
connect = require 'connect'

class Giles 
  constructor : () ->
    @compilerMap = {}
    @reverseCompilerMap = {}
    @ignored = []
    @locals = {}

  #the connect module for giles, to use it do
  #express.use(giles.connect(assetDirectory))
  connect : (dir) =>
    (req, res, next) =>
      [requestedFile,args] = (dir+req.url).split("?")
      file = @reverseLookup(requestedFile)
      if(file)
        log.log("Compiling: " + file)
        @compileFile file, @locals, (result) ->
          res.end result.content
      else
        next()

  server : (dir, opts) ->
    port = opts['port'] || 2255
    @app = connect().use(@connect(dir)).use(connect.static(dir)).listen(port)
    log.log("Giles is watching on port "+port)

  reverseLookup : (file) ->
    [name, ext] = @parseFileName(file)
    ext = "."+ext
    pwd = pathfs.resolve(".")
    relativeName = pathfs.relative(pwd, name)

    numberFound = 0
    foundFile = null
    if @reverseCompilerMap[ext]
      for extension in @reverseCompilerMap[ext] 
        if(pathfs.existsSync(name+extension))
          foundFile = name+extension
          numberFound += 1
    
    if numberFound > 1
      throw "You can only have one file that can compile into #{file} - you have #{numberFound} - #{@reverseCompilerMap[ext]}"

    return foundFile

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

  #Adds a compiler.  See README.md for usage
  addCompiler : (extensions, target, callback) ->
    compiler = 
      callback : callback,
      extension: target
    
    if typeof extensions is 'object'
      @compilerMap[ext] = compiler for ext in extensions
      @reverseCompilerMap[target] = [] unless @reverseCompilerMap[target]
      @reverseCompilerMap[target].push ext for ext in extensions
    else
      @compilerMap[extensions] = compiler
      @reverseCompilerMap[target] = [] unless @reverseCompilerMap[target]
      @reverseCompilerMap[target].push extensions


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
  compile : (file, locals) ->
    locals = locals || @locals
    result = @compileFile file, locals, (result) =>
      # Convert to relative output for ease of reading
      relInput = pathfs.relative(process.cwd(), file)
      relOutput = pathfs.relative(process.cwd(), result.outputFile)
      if result.exists
        log.notice "up to date #{relOutput} from #{relInput}"
      else
        log.notice "compiled #{relInput} into #{relOutput}"
        log.encourage()
      return unless result
      fs.writeFileSync result.outputFile, result.content, 'utf8'

  #Compiles a file and calls cb() with the result object
  compileFile : (file, locals, cb) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    unless pathfs.existsSync(file)
      console.error "Could not find source file #{file}"
      return
    outputFile = prefix+compiler.extension
    content = fs.readFileSync(file, 'utf8')

    outputContent = null
    if pathfs.existsSync(outputFile)
      outputContent = fs.readFileSync(outputFile, 'utf8')

    cwd = process.cwd()
    try
      compiler.callback content, file, locals, (output) ->
        if output == outputContent
          cb({
            content: outputContent, 
            outputFile : outputFile,
            inputFile : file,
            originalContent : content,
            exists: true
          })
        else
          cb({ 
            outputFile : outputFile,
            content : output,
            inputFile : file,
            originalContent : content
          })
    catch error
      log.error(error)
      log.error("stack trace:")
      log.error(error.stack.replace(cwd, "."))


  # Get the prefix and extension for a filename
  parseFileName : (file) ->
    ext = pathfs.extname(file)
    base = file.substr(0,file.length - ext.length)
    [base, ext]

  # true if name contains an ignored directory
  isIgnored : (name) ->
    for ignore in @ignored
      return true if ignore.test(name) #this matches really greedy
    return false


[stylus, coffee, iced, jade] = []

#create our export singleton to set up default values
giles = new Giles()

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
  output(iced.compile(contents, options))

#jade compiler
giles.addCompiler '.jade', '.html',  (contents, filename, options, output) ->
  jade = require 'jade' unless jade
  compileOpts = {}
  compileOpts.filename = filename
  compileOpts.pretty = true if options.development
  compiled = jade.compile(contents, compileOpts)(options)
  output(compiled)

#default ignores, may be overriden
giles.ignore [/node_modules/, /.git/]

#export the giles singleton
module.exports = giles
