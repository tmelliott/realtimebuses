var gulp = require('gulp');
var sass = require('gulp-ruby-sass');
var autoprefixer = require('gulp-autoprefixer');
var browserSync = require('browser-sync');
var concat = require('gulp-concat');
var uglify = require('gulp-uglify');
var reload = browserSync.reload;

var jquery = './node_modules/jquery';
var bootstrap = './node_modules/bootstrap-sass';
var fontawesome = './node_modules/font-awesome';
var slick = './assets/slick/slick';

gulp.task('sass', function() {
    gulp.src([bootstrap + '/assets/fonts/bootstrap/*'])
        .pipe(gulp.dest('assets/fonts/bootstrap'));
    gulp.src([fontawesome + '/fonts/*'])
        .pipe(gulp.dest('assets/fonts/font-awesome'));
    return sass('assets/sass/app.sass')
        .pipe(autoprefixer())
        .pipe(gulp.dest('assets/css'))
        .pipe(reload({
            stream: true
        }));
});

gulp.task('scripts', function() {
    gulp.src([jquery + '/dist/jquery.min.js',
              bootstrap + '/assets/javascripts/bootstrap.min.js',
              slick + '/slick.min.js',
              'assets/scripts/*.js'])
        .pipe(concat('app.min.js'))
        .pipe(uglify())
        .pipe(gulp.dest('assets/js'));
    reload();
});

gulp.task('serve', ['sass', 'scripts'], function() {
    browserSync({
        server: {
            baseDir: ''
        },
        open: false
    });

    gulp.watch('assets/sass/**/*.sass', ['sass']);
    gulp.watch('assets/scripts/**/*.js', ['scripts']);
    gulp.watch(['*.html', 'assets/js/app.min.js'], { cwd: ''}, reload);
});
