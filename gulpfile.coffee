del = require 'del'
fs = require 'fs'
gulp = require 'gulp'
Handlebars = require 'handlebars'
mkdirp = require 'mkdirp'
moment = require 'moment'
path = require 'path'

generateSiteData = ->
  spots = [
    id: 'syukugawa'
    name: '夙川公園'
    photos: []
  ,
    id: 'ojizoo'
    name: '王子動物園'
    photos: []
  ]

  photos = [
    spot_id: 'ojizoo'
    type: 'theta'
    author: 'bouzuya'
    created_at: new Date(moment().valueOf())
    url: 'http://example.com/ozizoo.jpg'
  ]

  # merge photos to spots.photos
  photos.forEach (photo) ->
    spot = spots.filter((spot) -> spot.id is photo.spot_id)[0]
    return unless spot?
    spot.photos.push photo

  # sort spots.photos
  spots.forEach (spot) ->
    spot.photos.sort (a, b) ->
      ad = moment a.created_at
      bd = moment b.created_at
      if ad.isBefore bd
        -1
      else if ad.isAfter bd
        1
      else
        0

  # build site data
  site = { spots }

generateSite = (site) ->
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
    write filePath, render 'spot', spot

render = (layout, data) ->
  view = fs.readFileSync "./src/views/#{layout}.html", encoding: 'utf-8'
  template = Handlebars.compile view
  template data

write = (file, data) ->
  filePath = path.resolve file
  dirname = path.dirname filePath
  mkdirp.sync dirname
  fs.writeFileSync filePath, data, encoding: 'utf-8'

gulp.task 'build', ->
  generateSite generateSiteData()

gulp.task 'clean', (done) ->
  del [
    './public'
  ], done

gulp.task 'default', ['build']
