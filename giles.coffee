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
      console.error(dir + " is not a directory or file")

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

  #Compiles a file and calls cb() with the result object
  compileFile : (file, cb) ->
    [prefix, ext] = @parseFileName(file)
    compiler = @compilerMap[ext]
    return unless compiler

    return unless pathfs.existsSync(file)
    outputFile = prefix+compiler.extension
    console.log('compiling ' +file+ ' to ' + outputFile)
    content = fs.readFileSync(file, 'utf8')

    outputContent = null
    if pathfs.existsSync(outputFile)
      outputContent = fs.readFileSync(outputFile, 'utf8')

    try
      compiler.callback content, file, (output) ->
        if output == outputContent
          console.log "no change in output, not writing " +outputFile
          return

        cb( 
          outputFile : outputFile,
          content : output,
          inputFile : file,
          originalContent : content
        )
    catch error
      console.error(error)
      console.error("stack trace:")
      console.error(error.stack)


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
