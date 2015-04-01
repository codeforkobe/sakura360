fs = require 'fs'
path = require 'path'

getFiles = (dir) ->
  files = fs.readdirSync dir
  paths = (path.join(dir, f) for f in files when not f.match(/^_/))
  paths.reduce (result, p) ->
    result.concat(if fs.statSync(p).isDirectory() then getFiles(p) else [p])
  , []

module.exports = getFiles
