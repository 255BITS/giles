_Into every generation a project is born.  One project in all the world, a Chosen One.  One born with the strength and skill
to fight the vampires, to stop the spread of their evil and swell of their numbers._

Giles wants you to stop writing HTML, CSS, and JS.  Whether you are working on
a legacy app supporting ie6, a nodejs server, or you are writing the next hottest html5 app, this can help.

Giles is a project watcher and builder for a variety of useful markup languages.  Use Giles to develop with 
nextgen web tools and increase project momentum.

##Giles supports
  * [CoffeeScript](http://coffeescript.org/) - Incredible javascript compiler.  Everything just seems to work better with coffeescript. 
  * [Stylus](https://github.com/LearnBoost/stylus) - Fantastic css compiler.  The variable/mixin support is extremely powerful.
  * [Jade](http://jade-lang.com/) - Cool HAML-like alternative to writing html.
  * Your favorite language.  Add it and issue a pull request.

###Giles is a command line tool and API for:
* Developing.  Watch a directory and build output files when source files change.
* Releasing.  Building static assets for deployment 

The goal of Giles is not to advocate a specific framework, rather to provide developers and designers
functionality in the languages of their choice.

###To install run 
    sudo npm install -g giles
_npm is available by installing [nodejs](http://nodejs.org)_

###To get help 
    giles -h
_If you ever need to run this, file a bug with me._

###To watch the current directory, recursively 
    giles -w
_Handles new files too.  It will work even if you re-arrange your whole project._

###To watch a specific directory, recursively 
    giles directory -w
_This compiles to the same directory as the asset._
<!--
###To build all assets recursively, outputting to a specific directory 
    giles . -o build
_It will mimic your source directory tree structure, if you like trees._
-->
###To ignore a directory, or multiple(will match recursively) 
    giles . --ignore vendor,bin
_ignore defaults to node_modules,.git_


#API
These examples are in coffeescript.

### Building with .js and giles (works with Jake or Cake)
    srcDir = PATH_TO_SOURCE
    options = {}
    
    giles = require('giles')
    giles.build(srcDir, options)

### To watch with giles using local variables
    srcDir = PATH_TO_SOURCE
    options = {}

    giles = require('giles')
    giles.watch(srcDir, options)

### To add a compiler to giles
    coffee = require 'coffee-script'
    giles.addCompiler ['.coffee', '.cs'], '.js', (contents, filename, output) ->
      output(coffee.compile(contents, {}))


#### Or for stylus
    stylus = require 'stylus'
    giles.addCompiler [".styl", ".stylus"], '.css', (contents, filename, output) ->
      stylus.render contents, {filename: filename}, (err, css) ->
        if err
          console.error "Could not render stylus file: "+filename
          console.error err
        else
          output(css)


**Both of these compilers are already in giles and listed here for illustration purposes.**

###License
  Giles is available under the MIT license.  We hope you find it useful.  Please let us at 255 BITS know if you use it 
  for something cool.
