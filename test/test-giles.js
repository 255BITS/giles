(function() {
  var createFixture, fs, giles, path;

  giles = require('../giles');

  fs = require('fs');

  path = require('path');

  describe('watch', function() {
    return it('should assert', function() {
      return [1, 2, 3].indexOf(5).should.equal(-1);
    });
  });

  describe('giles', function() {
    return it('should get extensions', function() {
      giles.parseFileName('test.test').should.eql(['test', '.test']);
      giles.parseFileName('test').should.eql(['test', '']);
      giles.parseFileName('.test').should.eql(['', '.test']);
      giles.parseFileName('file.min.css').should.eql(['file.min', '.css']);
      return giles.parseFileName('file.really.long-whatever-name.out').should.eql(['file.really.long-whatever-name', '.out']);
    });
  });

  giles.addCompiler('.test-giles-compiler', '.test-giles-compiler-out', function(contents) {
    return contents.substr(0, 5);
  });

  describe('new compiler', function() {
    return it('should compile correctly', function() {
      var result;
      result = giles.compileFile(__dirname + '/test.test-giles-compiler');
      result.content.should.equal(result.originalContent.substr(0, 5));
      result.outputFile.indexOf('test.test-giles-compiler-out').should.not.eql(-1);
      result.inputFile.indexOf('test.test-giles-compiler').should.not.eql(-1);
      giles.addCompiler(['.test-giles-compiler', '.test-giles-compiler2'], '.test-giles-compiler-out', function(contents) {
        return contents.substr(0, 6);
      });
      result = giles.compileFile(__dirname + '/test.test-giles-compiler');
      result.content.should.equal(result.originalContent.substr(0, 6));
      return giles.addCompiler('.test-giles-compiler', '.test-giles-compiler-out', function(contents) {
        return contents.substr(0, 5);
      });
    });
  });

  describe('building', function() {
    return it('should build an individual file', function() {
      var contents;
      giles.compile(__dirname + '/test.test-giles-compiler');
      contents = fs.readFileSync(__dirname + '/test.test-giles-compiler-out', 'utf8');
      return contents.length.should.equal(5);
    });
  });

  createFixture = function(filename, content, done, callback) {
    var file;
    file = __dirname + "/" + filename;
    console.log('creating fixture: ' + file);
    fs.writeFileSync(file, content, 'utf8');
    return setTimeout(function() {
      callback();
      fs.unlinkSync(file);
      return done();
    }, 100);
  };

  giles.watch(__dirname, {});

  describe('watch', function() {
    return it('should work with subdirs', function(done) {
      var origContent;
      origContent = 'this is a tmp file';
      fs.mkdirSync(__dirname + '/tmp');
      return setTimeout(function() {
        return createFixture('tmp/tmp.test-giles-compiler', origContent, done, function() {
          var content, outfile;
          outfile = __dirname + '/tmp/tmp.test-giles-compiler-out';
          content = fs.readFileSync(outfile, 'utf8');
          content.should.equal(origContent.substr(0, 5));
          return setTimeout(function() {
            fs.unlinkSync(outfile);
            return fs.rmdirSync(__dirname + '/tmp');
          }, 0);
        });
      }, 100);
    });
  });

}).call(this);
