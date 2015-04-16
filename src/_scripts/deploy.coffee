exec = require './exec'
gutil = require 'gulp-util' # FIXME

module.exports = ({ dst, url, dir, name, email, message, build }) ->
  exec "git clone --branch #{dst} #{url} #{dir}"
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    build()
  .then ->
    exec 'git add --all', cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git config --local user.name #{name}", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git config --local user.email #{email}", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git commit --allow-empty --message '#{message}'", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
    exec "git push --force '#{url}' #{dst}:#{dst}", cwd: dir
  .then ({ stdout, stderr }) ->
    gutil.log stdout
    gutil.log stderr
