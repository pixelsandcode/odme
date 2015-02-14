gulp       = require 'gulp'
coffee     = require 'gulp-coffee'

gulp.task 'build', ->
  
  src = 'src/**'
  dest = 'build'

  gulp.src( src )
    .pipe( coffee() )
    .pipe( gulp.dest dest )

