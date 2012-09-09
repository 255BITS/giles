giles = require('../giles')
fs = require 'fs'
path = require 'path'

describe 'building', () ->
  it 'should build an individual file', () ->
    giles.compile(__dirname+'/test.test-giles-compiler')
    contents = fs.readFileSync(__dirname+'/test.test-giles-compiler-out', 'utf8')
    contents.length.should.equal(5)

describe 'connect', () ->
  before () ->
    giles.addCompiler '.test-connect', '.test-connect-out', (contents, filename, options, output) ->
      output "spec response"

  #test that res is not passed on success
  it 'should send result', () -> 
    connect = giles.connect(__dirname)
    connect(req, res, next)
    #TODO fill me in

  #test error conditions around 500
  it 'should output 500 error', () ->
    giles.addCompiler '.test-500', '.test-500-out', (contents, filename, options, output) ->
      throw "500 error"
    #TODO fill me in

  it 'should call next on 404', () ->
    #time out error means giles.connect never called next
    next = () ->
      done()

    connect = giles.connect(__dirname)
    connect(req, res, next)

    #TODO fill me in

  #test if url parms hose it up
  it 'should ignore url params', () ->
    url = "a?b"
    # TODO fill me in


  #test mime header type
  it 'should return valid mime type', () ->
    #TODO fill me in
    res.getHeader("Content-Type").should.eql "text/css"
    #TODO fill me in
    res.getHeader("Content-Type").should.eql "text/html"
    #TODO fill me in
    res.getHeader("Content-Type").should.eql "application/javascript"

describe 'giles', () ->
  it 'should get extensions', () ->
    name = giles.parseFileName('test.test')
    name.should.eql(['test','.test'])
    giles.parseFileName('test').should.eql(['test',''])
    giles.parseFileName('.test').should.eql(['.test',''])
    giles.parseFileName('file.min.css').should.eql(['file.min','.css'])
    giles.parseFileName('file.really.long-whatever-name.out').should.eql(['file.really.long-whatever-name', '.out'])

    giles.addCompiler '.test-giles-compiler', '.test-giles-compiler-out', (contents, filename, options, output) ->
      output(contents.substr(0,5))


describe 'locals', () ->
  meta = null
  before () ->
    #TODO : meta is null
    giles.addCompiler '.test-meta-data', '.test-meta-data-out', (contents, filename, options, output) ->
      #meta = options.giles
      output ""
    giles.get 'test2', 'test.test-meta-data', {}
    giles.compile(__dirname+'/test.test-meta-data')

  it 'should have environment meta data', (done) ->
    #meta.environment.should.equal('development')
    done()

  it 'should have route meta data', (done) ->
    #meta.allRoutes.length.should.equal(2)
    #meta.allRoutes[0].source.should.equal("test.test-meta-data")
    done()


describe 'new compiler', () ->
  it 'should compile correctly', () ->
    giles.compileFile __dirname+'/test.test-giles-compiler', {}, {}, (result) ->
      result.content.should.equal result.originalContent.substr(0,5)
      result.outputFile.indexOf('test.test-giles-compiler-out').should.not.eql(-1)
      result.inputFile.indexOf('test.test-giles-compiler').should.not.eql(-1)
  
    giles.addCompiler ['.test-giles-compiler', '.test-giles-compiler2'], '.test-giles-compiler-out', (contents, filename, options, output) ->
      output(contents.substr(0,6))
    giles.compileFile __dirname+'/test.test-giles-compiler', {}, {}, (result) ->
      result.content.should.equal result.originalContent.substr(0,6)

    giles.addCompiler '.test-giles-compiler', '.test-giles-compiler-out', (contents, filename, options, output) ->
      output(contents.substr(0,5))


