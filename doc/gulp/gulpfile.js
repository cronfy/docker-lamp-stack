"use strict"

/**
 * Простой конфиг gulp с начальным набором плагинов postcss + livereload.
 * 
 * Установка пакетов:
 * 
 * # от root
 * $ yarn global add gulp@3.9.1
 * 
 * # от пользователя в корне проекта
 * $ yarn install
 */


/**
 * Конфиг. прописать тут путь(-и) до scss.
 */

const config = {
    bundles: {
        mobile: {
            cssFiles: [
                'www/bitrix/templates/eshop_bootstrap_green_copy/css/custom.scss',
            ],
            watchFiles: [
                'www/bitrix/templates/eshop_bootstrap_green_copy/css/*.scss'
            ]
        }
    }
}



const gulp = require('gulp')

const postcss = require('gulp-postcss')
const autoprefixer = require('autoprefixer')
const scss = require('postcss-scss')
const livereload = require('gulp-livereload')
const sourcemaps = require('gulp-sourcemaps')
const rename = require('gulp-rename')
const filter = require('gulp-filter')
const expect = require('gulp-expect-file')
const precss = require('precss')
const stripInlineComments = require('postcss-strip-inline-comments')

let browserslistConf = require('./browserslist.js');


gulp.task('css', function() {

    const processors = [
        precss({import: {extension: 'scss'}}),
        stripInlineComments,
        autoprefixer({browsers: browserslistConf}),
    ]

    const files = config.bundles.mobile.cssFiles

    return gulp.src(files, {base: "./"})
        .pipe(expect(files))
        .pipe(sourcemaps.init())
        .pipe(postcss(processors, {syntax: scss}))
        .pipe(rename({extname: '.css'}))
        .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest('./'))
        .pipe(filter("**/*.css"))
        .pipe(livereload())

})


gulp.task('this-js', function() {
    return

    // not implemented, code from some other project for example:

    const babel = require('gulp-babel')
    const expect = require('gulp-expect-file')
    const rename = require('gulp-rename')
    const sourcemaps = require('gulp-sourcemaps')

    const files = [
        'ui/this/**/*.es6',
    ];

    return gulp.src(files, {base: "./"})
        .pipe(expect(files))
        .pipe(babel(
            {
                "comments": false,
                "presets": [
                    ["env", {
                        "targets": {
                            "browsers": browserslistConf,
                        }
                    }]
                ]
            }
        ))
        .pipe(sourcemaps.init())
        // .pipe(postcss(processors, {syntax: scss}))
        .pipe(rename({extname: '.js'}))
        .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest('./web/'))
    // .pipe(filter("**/*.css"))
    // .pipe(livereload())
});

gulp.task('watch', ['css'], function() {
    const livereload = require('gulp-livereload');
    livereload.listen();

    gulp.watch(config.bundles.mobile.watchFiles, ['css']);
});

gulp.task('default', ['watch'])

