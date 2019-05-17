'use strict';

var fs = require('fs');

module.exports = function(grunt) {

    // Project configuration.
    var gruntConf = {
        watch: {
            options: {
                nospawn: true
            },
            src: {
                files: ['src/**/*.coffee'],
                tasks: ['coffee:src']
            },
            static: {
                files: ['src/**/*.png', 'src/**/*.less', 'src/**/*.html', 'src/**/*.css', 'src/**/*.js', 'src/**/*.eot', 'src/**/*.otf', 'src/**/*.svg', 'src/**/*.ttf', 'src/**/*.woff', '**/*.ico'],
                tasks: ['copy']
            }
        },
        coffee: {
            src: {
                expand: true,
                cwd: 'src',
                src: ['**/*.coffee'],
                dest: 'bin',
                ext: '.js',
                options: {
                    bare: true
                }
            }
        },
        copy: {
            main: {
                files: [{
                    expand: true,
                    src: ['**', '!**/*.coffee'],
                    dest: 'bin',
                    cwd: 'src'
                }, ]
            }
        },
        subgrunt: {},
        jasmine_node: {
            options: {
                forceExit: true,
                match: '.',
                matchall: false,
                extensions: 'js',
                specNameMatcher: 'spec'
            },
            all: ['./tests/spec/']
        }
    };

    var tasks = [];
    // var default_plg = fs.readdirSync(__dirname + '/default_plugins');
    // for (var i in default_plg) {
    //     var plugin = default_plg[i];
    //     if (fs.existsSync(__dirname + '/default_plugins/' + plugin + '/gruntConfig.js')) {
    //         var task = require('./default_plugins/' + plugin + '/gruntConfig').call(this, gruntConf);
    //         if (task)
    //             tasks.push(task);
    //     }

    //     if (fs.existsSync(__dirname + '/default_plugins/' + plugin + '/Gruntfile.js')) {
    //         gruntConf.subgrunt[plugin] = {
    //             options: {},
    //             projects: {}
    //         };
    //         gruntConf.subgrunt[plugin].projects['./default_plugins/' + plugin] =  'default';
    //     }
    // }

    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-subgrunt');

    // Default task.
    grunt.registerTask('default', ['coffee', 'copy']);
    grunt.registerTask('test', ['jasmine_node:all']);
};