giles = require('../giles')
fs = require 'fs'
path = require 'path'

describe 'building', () ->
  it 'should build an individual file', () ->
    giles.compile(__dirname+'/test.test-giles-compiler')
    contents = fs.readFileSync(__dirname+'/test.test-giles-compiler-out', 'utf8')
    contents.length.should.equal(5)

describe 'connect', () ->
  #test that res is not passed on success
  #test error conditions around 500, 404
  #test if url parms hose it up
  #test mime header type

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


