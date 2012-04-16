Into every generation a project is born.  One project in all the world, a Chosen One.  One born with the strength and skill
to fight the vampires, to stop the spread of their evil and swell of their numbers.

Giles wants you to stop writing HTML, CSS, and JS.  Whether you are working on
a legacy app supporting ie6, a nodejs server, or you are writing the next hottest html5 app, giles can help.

Giles is a project watcher and builder for a variety of useful markup languages.  Use Giles to develop with 
nextgen web tools, and increase project momentum.

Giles supports
* Jade[LINK TO JADE] - Great HAML-like alternative to writing html.  Check out the example here[LINK].
* Stylus[LINK TO STYLUS] - Fantastic css compiler.  The variable/mixin support is extremely powerful.
* CoffeeScript[LINK TO CS] - Incredible javascript compiler.  Everything just seems to work better with coffeescript. 
  try it here[LINK]
* Your favorite language.  Add it and issue a pull request.

Giles is a command line tool and API for:
* Developing.  Watch a directory and build output files when source files change.
* Releasing.  Building static assets for deployment to S3 or cloud providers(or for use in mobile frameworks)
* Extremely lightweight client-side development.  Language/library agnostic.

The goal of Giles is not to advocate a specific framework, rather to provide developers and designers
functionality in the languages of their choice.  With Giles' lazy-loading approach, it only forces you to include
functionality that you actually use.

To install run
|  sudo npm install -g giles
npm is available by installing nodejs[LINK]

To get help
|  giles -h
If you ever need to run this, file a bug with me.

To watch the current directory, recursively
|  giles -w
Watchers be watching.  Handles new files too.  It will work even if you re-arrange your whole project.

To watch a specific directory, recursively
|  giles directory -w
This compiles to the same directory as the asset.  Recommended: Start 
by evaluating a .coffee on a vertical piece of functionality.

To build all assets recursively, outputting to a specific directory
|  giles . -o build
It will mimic your source directory tree structure, if you like trees.

To ignore a directory, or multiple(will match recursively)
|  giles . --ignore vendor,bin

Note, giles automatically ignores the following directories:
*node_modules
*.git



=API=
These examples are in coffeescript.

Building with .js and giles (works with Jake)
|  srcDir = PATH_TO_SOURCE
|  options = 
|    #output : __dirname+"/build",#The directory to output to,
|    #locals : {} #variables exposed to all compilers which support variables
|  
|  giles = require('giles')
|  giles.build(srcDir, options)


To watch with giles using local variables
```coffeescript
  giles = require('giles')
  giles.watch(srcDir, options)
```

To add a compiler to giles
For coffeescript
```coffee-script
 coffee = false
 #executed for each .coffee or .cs file
 #if giles.watch is called, we call this function each time a file with the associated extension is changed/added
 #if giles.build is called, we call this function once for each matching file
 giles.compile ['.coffee', '.cs'], '.js', (file) ->
   coffee = require 'coffee-script' unless coffee
   contents = fs.readFileSync(file, 'utf8')
   return coffee.compile(contents, {}) #the processed result, as a utf-8 string
```

Or for jade
| jade = false
| giles.compile '.jade', '.html',  (file) ->
|   jade = require 'jade' unless jade
|   contents = fs.readFileSync(file, 'utf8')
|   return jade.compile(contents, giles.locals)(giles.locals)

**Both of these compilers are already in giles and listed here for illustration purposes.**

