clc = require('cli-color')
module.exports = 
  error: (message, more...) ->
    console.log(clc.red.bold("[ERROR ] ", more)+message)
  warn: (message, more...) ->
    console.log(clc.yellow.bold("[WARN  ] ", more)+message)
  notice: (message, more...) ->
    console.log(clc.cyan.bold("[NOTICE] ", more)+message)
  info: (message, more...) ->
    console.log(clc.cyan.bold("[INFO  ] ", more)+message)
  log: (message, more...) ->
    if more.length > 0 
      console.log(message, more)
    else
      console.log message
  encourage: () ->
    console.log(clc.blue("  That's quite good, what you've done."))

