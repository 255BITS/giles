giles = require('../giles')
describe 'watch', () ->
  it 'should assert', () ->
    [1,2,3].indexOf(5).should.equal -1

describe 'giles', () ->
  it 'should get extensions', () ->
    giles.parseFileName('test.test').should.eql(['test','.test'])
    giles.parseFileName('test').should.eql(['test',''])
    giles.parseFileName('.test').should.eql(['','.test'])
    giles.parseFileName('file.min.css').should.eql(['file.min','.css'])
    giles.parseFileName('file.really.long-whatever-name.out').should.eql(['file.really.long-whatever-name', '.out'])

describe 'new compiler', () ->
  it 'should compile correctly', () ->
    giles.addCompiler '.test-giles-compiler', '.test-giles-compiler-out', (contents) ->
      contents.substr(0,5)
    result = giles.compileFile(__dirname+'/test.test-giles-compiler')
    result.content.should.equal result.originalContent.substr(0,5)
    result.outputFile.indexOf('test.test-giles-compiler-out').should.not.eql(-1)
    result.inputFile.indexOf('test.test-giles-compiler').should.not.eql(-1)
  
