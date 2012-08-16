clc = require('cli-color')
quiet = false
module.exports = 
  error: (message, more...) ->
    unless quiet
      console.log(clc.red.bold("[ ERROR  ] ", more)+message)
  warn: (message, more...) ->
    unless quiet
      console.log(clc.yellow.bold("[  WARN  ] ", more)+message)
  notice: (message, more...) ->
    unless quiet
      console.log(clc.cyan.bold("[ NOTICE ] ", more)+message)
  info: (message, more...) ->
    unless quiet
      console.log(clc.cyan.bold("[  INFO  ] ", more)+message)
  log: (message, more...) ->
    if more.length > 0 
      console.log(message, more)
    else
      console.log message
  encourage: () ->
    array = ["That's quite good, what you've done.", "Most acceptable.", "You are quite good when you focus.", "Well, I didn't quite expect you to do that well.", "You have saved the world, again.", "They came after me, but I was more than a match for them."]
    goodjob = clc.green.bold("[GOOD JOB] ")
    words = clc.green(array[Math.floor(Math.random() * array.length)])
    unless quiet
      console.log(goodjob+words) 

  quiet: (bool = true) ->
    quiet = bool

