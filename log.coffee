clc = require('cli-color')
module.exports = 
  error: (message, more...) ->
    console.log(clc.red.bold("[ERROR ] ", more)+message)
  warn: (message, more...) ->
    console.log(clc.yellow.bold("[WARN  ] ", more)+message)
  notice: (message, more...) ->
    console.log(clc.cyan.bold("[NOTICE] ", more)+message)
  log: (message, more...) ->
    console.log(message, more)
  encourage: () ->
    console.log(clc.blue("  That's quite good, what you've done."))
