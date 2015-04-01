{Promise} = require 'es6-promise'
buildSite = require './src/_scripts/build-site'
del = require 'del'
exec = require './src/_scripts/exec'
getData = require './src/_scripts/get-data'
getFiles = require './src/_scripts/get-files'
gulp = require 'gulp'
gutil = require 'gulp-util'
moment = require 'moment'

gulp.task 'build', (done) ->
  run = require 'run-sequence'
  run.apply run, [
    'build-site'
    'copy-files'
    done
  ]

gulp.task 'build-site', ->
  getData()
  .then buildSite

gulp.task 'copy-files', ->
  srcDir = './src'
  files = getFiles srcDir
  gulp.src files, base: srcDir
    .pipe gulp.dest './public'

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
    getData()
    .then buildSite
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
