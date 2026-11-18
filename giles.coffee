fs = require 'fs'
path = require 'path'
log = require './log'
connect = require 'connect'
serveStatic = require 'serve-static'

within = (root, file) ->
  relative = path.relative(root, file)
  not path.isAbsolute(relative) and relative.split(path.sep)[0] isnt '..'

class Giles 
  constructor : () ->
    @compilerMap = {}
    @reverseCompilerMap = {}
    @ignored = []
    @locals = {}
    @routes = {}


  extendLocals : (dynLocals) ->
    locals = {}
    for key,value of @locals
      locals[key]=value 
    for key, value of dynLocals
      locals[key] = value
    return locals

  #the connect module for giles, to use it do
  #express.use(giles.connect(assetDirectory))
  connect : (dir) =>
    root = fs.realpathSync(dir)
    (req, res, next) =>
      [route] = req.url.split('?')
      locals = @locals
      route = '/index.html' if(route == '/')

      # Check for user defined route first
      if @routes[route]
        file = @routes[route].source
        #Load in any custom locals
        dynLocals = @routes[route].locals
        locals = @extendLocals(dynLocals) if dynLocals
      else
        #Otherwise look for 1-1 file mappings
        try
          fullFilePath = path.resolve(root, '.' + decodeURIComponent(route))
          return next() unless within(root, fullFilePath)
          file = @reverseLookup(fullFilePath)
          return next() if file and not within(root, fs.realpathSync(file))
        catch error
          return next(error)

      if(file)
        @compileFile file, locals, {}, (result) ->
          relInput = path.relative(process.cwd(), file)
          relOutput = path.relative(process.cwd(), result.outputFile)
          if result.exists
            log.notice "up to date #{relOutput} from #{relInput}"
          else
            log.notice "compiled #{relInput} into #{relOutput}"
            log.encourage()
            
          extname = path.extname(relOutput)
          if extname == '.css'
            #Sets MIME type for CSS stylesheets
            res.setHeader "Content-Type", "text/css"
          else if extname == '.html'
            #Sets MIME type for HTML files
            res.setHeader "Content-Type", "text/html"
          else if extname == '.js'
            #Sets MIME type for JavaScript files
            res.setHeader "Content-Type", "application/javascript"

          res.end result.content
      else
        next()

  # Tells giles to not output anything to the console
  quiet : () ->
    log.quiet(true)


  #adds an endpoint to the list of generated files
  get : (endpoint, source, locals) ->
    @routes[endpoint]={source: source, locals:locals}

  server : (dir, opts = {}) ->
    port = Number(opts.port ? 2255)
    @app = connect().use(@connect(path.resolve(dir)))
      .use(serveStatic(dir))
      .listen(port)
    log.notice("Giles is watching on port "+port)
    return @app

  reverseLookup : (file) ->
    [name, ext] = @parseFileName(file)
    pwd = process.cwd()
    relativeName = path.relative(pwd, name)

    numberFound = 0
    foundFile = null
    if @reverseCompilerMap[ext]
      for extension in @reverseCompilerMap[ext] 
        if(fs.existsSync(name+extension))
          foundFile = name+extension
          numberFound += 1
    
    if numberFound > 1
      throw "You can only have one file that can compile into #{file} - you have #{numberFound} - #{@reverseCompilerMap[ext]}"

    return foundFile

  #Crawls a directory recursively
  #calls onDirectory for every directory encountered
  #calls onFile for every file encountered
  crawl : (dir, onFile) ->

    handlePath = (resource) =>
      (err, stats) =>
        if err
          log.error(err)
        else if stats.isFile()
          onFile(resource)
        else if stats.isDirectory()
          @crawl(resource, onFile)
        else
          #wtf are we dealing with.  A device?!
          log.error("Could not determine file "+filename)
          log.error(stats)

    fs.readdir dir, (err, files) =>
      if err
        log.error("cannot read dir")
        log.error(err)
      else
        for file in files
          resource=dir+'/'+file
          fs.stat resource, handlePath(resource)

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


  process : (dir, onFile) ->
    stats = fs.statSync(dir)
    if stats.isDirectory()
      @crawl dir, onFile
    else if stats.isFile()
      onFile(dir)
    else
      log.error(dir + " is not a directory or file")

  # Removes a specific file
  rmFile : (file) ->
    fs.unlink file, (err) -> 
      log.error("Failed to remove: #{file}", err) if(err)

  # Cleans up a directory's generated files.  See README.md for usage
  clean: (dir, opts) ->
    for route, opts of @routes
      source = opts.source
      fullPath = path.resolve(process.cwd() + route)
      log.notice "cleaning #{fullPath}"
      @rmFile(fullPath)

    @process dir, (f) => 
      # Assume: f is a .html file with a jade file.
      # 1) Check if both the .jade file and the .html file exist
      sourceFile = @reverseLookup(f)
      if sourceFile and fs.existsSync(sourceFile)
        log.notice("Cleaning: " + f)
        @rmFile(f) 

  #Builds a directory.  See README.md for usage
  build : (dir, opts) ->
    for route, opts of @routes
      source = opts.source
      locals = @locals
      locals = @extendLocals(opts.locals) if opts.locals
      log.notice "building user-defined route #{route}"
      fullPath = path.resolve(process.cwd() + route)
      @compile source, locals, {outputFile: fullPath}

    @process dir, (f) => @compile(f)

  # Ignore an array of various directory names
  ignore : (types) ->
    @ignored = types


  #  Compiles a file and writes it out to disk
  #  `file` is the absolute path to the input file
  #  `locals` is an object of dynamic variables available
  #    to the view template.
  #  `options` accepts the following
  #   {
  #     outputFile : The destination file to output to
  #   }
  compile : (file, locals, options) ->
    return if @isIgnored(file)
    locals = locals || @locals
    result = @compileFile file, locals, options, (result) =>
      # Convert to relative output for ease of reading
      relInput = path.relative(process.cwd(), file)
      relOutput = path.relative(process.cwd(), result.outputFile)
      if result.exists
        log.notice "up to date #{relOutput} from #{relInput}"
      else
        log.notice "compiled #{relInput} into #{relOutput}"
        log.encourage()
      return unless result
      fs.writeFileSync result.outputFile, result.content, 'utf8'

  #Compiles a file and calls cb() with the result object
  compileFile : (file, locals, options, cb) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    unless fs.existsSync(file)
      console.error "Could not find source file #{file}"
      return
    outputFile = prefix+compiler.extension
    if options?.outputFile
      outputFile = options.outputFile
    content = fs.readFileSync(file, 'utf8')

    outputContent = null
    if fs.existsSync(outputFile)
      outputContent = fs.readFileSync(outputFile, 'utf8')

    cwd = process.cwd()
    try
      complete = (output) ->
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
      if compiler.callback.length is 3
        compiler.callback content, file, complete
      else
        compiler.callback content, file, locals, complete
    catch error
      log.error(error)
      log.error("stack trace:")
      log.error(error.stack.replace(cwd, "."))


  # Get the prefix and extension for a filename
  parseFileName : (file) ->
    ext = path.extname(file)
    base = file.substr(0,file.length - ext.length)
    [base, ext]

  # true if name contains an ignored directory
  isIgnored : (name) ->
    filename = name.split('/')
    filename = filename[filename.length-1]
    return true if /^_/.test(filename) # ignore all files beginning with underscore
    for ignore in @ignored
      return true if ignore.test(name) #this matches really greedy
    return false


[stylus, coffee, iced, pug, marked] = []

#create our export singleton to set up default values
giles = new Giles()

#Stylus compiler.  Nothing fancy
giles.addCompiler [".styl", ".stylus"], '.css', (contents, filename, options, output) ->
  stylus = require 'stylus' unless stylus
  styl = stylus(contents)
  styl.set('filename', filename)
  styl.include(options.cwd) if options.cwd
  for key, val in options
    styl.define(key, val)

  styl.render (err, css) ->
    if err
      log.error "Could not render stylus file: "+filename
      log.error err
    else
      output(css)

#coffeescript compiler
giles.addCompiler ['.coffee', '.cs'], '.js', (contents, filename, options, output) ->
  coffee = require 'coffeescript' unless coffee
  compilerOptions = Object.assign({}, options, header: true, bare: false)
  delete compilerOptions.scope
  output(coffee.compile(contents, compilerOptions))

#iced-coffeescript compiler
giles.addCompiler '.iced', '.js', (contents, filename, options, output) ->
  iced = require 'iced-coffee-script' unless iced
  iced_output = iced.compile(contents, options)
  output(iced_output)

#jade compiler
legacyJade = {
  preLex: (source, options) ->
    return source unless path.extname(options.filename) is '.jade'
    source.replace(/^([ \t]*)!!!(?:[ \t]+5)?[ \t]*$/gm, '$1doctype html')
  postLex: (tokens, options) ->
    if path.extname(options.filename) is '.jade'
      for token in tokens when token.type is 'path' and not path.extname(token.val)
        resolved = path.resolve(path.dirname(options.filename), token.val + '.jade')
        token.val += '.jade' if not path.isAbsolute(token.val) and fs.existsSync(resolved)
    tokens
}

giles.addCompiler ['.jade', '.pug'], '.html', (contents, filename, options, output) ->
  pug = require 'pug' unless pug
  compileOpts = {}
  compileOpts.filename = filename
  compileOpts.pretty = true
  compileOpts.plugins = [legacyJade]

  try
    compiled = pug.compile(contents, compileOpts)(options)
    output(compiled)
  catch e
    output("<h1>Error compiling #{filename}</h1><code><pre>#{e.message}#{e.stack}</pre></code>")
    throw e

giles.addCompiler '.md', '.html', (contents, filename, options, output) ->
  marked = require('marked') unless marked
  output(marked.parse(contents))



#default ignores, may be overriden
giles.ignore [/node_modules/, /.git/]

#export the giles singleton
module.exports = giles
