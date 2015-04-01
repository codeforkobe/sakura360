fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'

module.exports = (file, text) ->
  filePath = path.resolve file
  dirname = path.dirname filePath
  mkdirp.sync dirname
  fs.writeFileSync filePath, text, encoding: 'utf-8'
