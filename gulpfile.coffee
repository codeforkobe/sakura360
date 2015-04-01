{Promise} = require 'es6-promise'
data = require './src/_scripts/data'
del = require 'del'
exec = require './src/_scripts/exec'
fs = require 'fs'
gulp = require 'gulp'
gutil = require 'gulp-util'
Handlebars = require 'handlebars'
mkdirp = require 'mkdirp'
moment = require 'moment'
path = require 'path'

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
  data()
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
    data()
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
