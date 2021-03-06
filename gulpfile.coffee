gulp         = require 'gulp'
notify       = require 'gulp-notify'
coffee       = require 'gulp-coffee'
fs           = require 'fs'
concat       = require 'gulp-concat'

gulp.task 'coffee', ->
  gulp.src('./source/coffee/*.coffee')
    .pipe(coffee(bare: true)
      .on('error', notify.onError((error) ->
        title: "Coffee error"
        message: error.message + "\r\n" + error.filename + ':' + error.location.first_line
        sound: 'Pop'
      )))
    .pipe(concat('index.js'))
    .pipe(gulp.dest('./source/javascript'))

watch = ->
  gulp.watch ['./source/coffee/*.coffee'], ['coffee']

gulp.task 'watch', watch
gulp.task 'default', ['coffee']
