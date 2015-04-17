browserSync = require 'browser-sync'
buildSite = require './src/_scripts/build-site'
del = require 'del'
deploy = require './src/_scripts/deploy'
getData = require './src/_scripts/get-data'
getFiles = require './src/_scripts/get-files'
gulp = require 'gulp'
gutil = require 'gulp-util'
moment = require 'moment'

gulp.task 'build', (done) ->
  run = require 'run-sequence'
  run.apply run, [
    'clean'
    'build-data'
    'build-site'
    'copy-files'
    done
  ]

gulp.task 'build-data', ->
  getData()
  .then (site) ->
    fs = require 'fs'
    dir = './.tmp/'
    file = dir + 'site.json'
    data = JSON.stringify(site)
    fs.mkdirSync(dir) unless fs.existsSync dir
    fs.writeFileSync file, data, encoding: 'utf-8'

gulp.task 'build-site', ->
  site = require './.tmp/site.json'
  buildSite site

gulp.task 'clean', (done) ->
  del [
    './.tmp'
    './public'
  ], done

gulp.task 'copy-files', ->
  srcDir = './src'
  files = getFiles srcDir
  gulp.src files, base: srcDir
    .pipe gulp.dest './public'

gulp.task 'default', (done) ->
  run = require 'run-sequence'
  run.apply run, [
    'clean'
    'build'
    done
  ]

gulp.task 'deploy', ['clean'], ->
  message = moment().format() # commit message
  url = 'git@github.com:codeforkobe/sakura360.git' # repository url
  dst = 'gh-pages'
  dir = './public'
  name = 'circleci'
  email = 'circleci@example.com'
  build = ->
    {Promise} = require 'es6-promise'
    new Promise (resolve) ->
      run = require 'run-sequence'
      run.apply run, [
        'clean'
        'build-data'
        'build-site'
        'copy-files'
        resolve
      ]
  deploy { message, url, dst, dir, name, email, build }

gulp.task 'watch', ['build'], ->
  browserSync
    server:
      baseDir: './public/'

  gulp.watch './src/**/*', ['build-site', browserSync.reload]
