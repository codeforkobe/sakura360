{Promise} = require 'es6-promise'
del = require 'del'
exec = require './src/_scripts/exec'
fs = require 'fs'
getSpots = require './src/_scripts/get-spots'
gulp = require 'gulp'
gutil = require 'gulp-util'
Handlebars = require 'handlebars'
mkdirp = require 'mkdirp'
moment = require 'moment'
path = require 'path'

generateSpots = ->
  config =
    email: process.env.SAKURA360_SPOT_SHEET_EMAIL
    key: JSON.parse process.env.SAKURA360_SPOT_SHEET_KEY
    sheetKey: process.env.SAKURA360_SPOT_SHEET_SHEET_KEY
  getSpots config

generateSiteData = ->
  spots = null

  generateSpots()
  .then (s) ->
    spots = s
  .then ->
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

  # render other files
  getFiles = (dir) ->
    files = fs.readdirSync dir
    (path.join(dir, f) for f in files when not f.match(/^_/)).reduce (paths, p) ->
      paths.concat(if fs.statSync(p).isDirectory() then getFiles(p) else [p])
    , []
  new Promise (resolve, reject) ->
    srcDir = './src'
    files = getFiles srcDir
    gulp.src files, base: srcDir
      .pipe gulp.dest './public'
      .on 'end', -> resolve()
      .on 'error', reject

render = (layout, data) ->
  view = fs.readFileSync "./src/_views/#{layout}.html", encoding: 'utf-8'
  template = Handlebars.compile view
  template data

write = (file, data) ->
  filePath = path.resolve file
  dirname = path.dirname filePath
  mkdirp.sync dirname
  fs.writeFileSync filePath, data, encoding: 'utf-8'

gulp.task 'build', ->
  generateSiteData()
  .then generateSite

gulp.task 'clean', (done) ->
  del [
    './public'
  ], done

gulp.task 'deploy', ['clean'], ->
  message = moment().format() # commit message
  url = 'git@github.com:codeforkobe/sakura360.git' # repository url
  dst = 'gh-pages'
  dir = './public'

  exec "git clone --branch #{dst} #{url} #{dir}"
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    generateSiteData()
    .then generateSite
  .then ->
    exec 'git add --all', cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git config --local user.name circleci", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git config --local user.email circleci@example.com", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git commit --message '#{message}'", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git push --force '#{url}' #{dst}:#{dst}", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr

gulp.task 'default', (done) ->
  run = require 'run-sequence'
  run.apply run, [
    'clean'
    'build'
    done
  ]
