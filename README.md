Giles wants you to stop writing HTML, CSS, and JS. 

Giles is a static asset builder for a variety of useful markup languages.  Use Giles to develop with 
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

<!--
###To watch the current directory, recursively 
    giles -w
_Handles new files too.  It will work even if you re-arrange your whole project._

###To watch a specific directory, recursively 
    giles directory -w
_This compiles to the same directory as the asset._
###To build all assets recursively, outputting to a specific directory 
    giles -o build
-->
###To ignore a directory, or multiple(will match recursively) 
    giles --ignore vendor,bin
###To start a webserver on port 2255
    giles -s [-p 2255]

_ignore defaults to node_modules,.git_


#API
These examples are in coffeescript.

### Building with .js and giles (works with Jake or Cake)
    srcDir = PATH_TO_SOURCE
    options = {}
    
    giles = require('giles')
    giles.build(srcDir, options)
<!--
### To watch with giles 
    srcDir = PATH_TO_SOURCE
    options = {}

    giles = require('giles')
    giles.watch(srcDir, options)
-->

### To run the giles server
    giles = require('giles')
    giles.server(dir, {port : 12345})

### To use giles connect/express module
    connect.use(giles.connect(srcDir))
  
_It is imperative that you place this before `connect.static'_

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

#Changelog
### v0.5.0
  *Added -s option which tells giles to start a webserver on port 2255
  *Added -p option to specify port of -s
  *Removed -w option, -s works better and more consistently

###License
  Giles is available under the MIT license.  We hope you find it useful.  Please let us at 255 BITS know if you use it 
  for something cool.

_Into every generation a slayer is born: one girl in all the world, a Chosen One.  One born with the strength and skill
to fight the vampires, to stop the spread of their evil and swell of their numbers._
