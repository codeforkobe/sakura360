moment = require 'moment'
render = require './render'
write = require './write'

module.exports = (site) ->
  # render index html
  write './public/index.html', render 'index', site

  # render spot html
  site.spots.forEach (spot) ->
    d = moment spot.created_at
    pattern = '/:year/:id/'
    params = {}
    params[':year'] = d.year()
    params[':id'] = spot.id
    filePath = './public' + pattern.replace /:([^\/]+)/g, (param) ->
      params[param]
    .replace /\/$/, '/index.html'
    write filePath, render 'single', spot
