fs = require 'fs'
Handlebars = require 'handlebars'

module.exports  = (layout, data) ->
  view = fs.readFileSync "./src/_views/#{layout}.html", encoding: 'utf-8'
  template = Handlebars.compile view
  template data
