{exec} = require 'child_process'
{Promise} = require 'es6-promise'

module.exports = (command, options) ->
  new Promise (resolve, reject) ->
    exec command, options, (err, stdout, stderr) ->
      return reject(err) if err?
      resolve { stdout, stderr }
