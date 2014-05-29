'use strict';

module.exports = function(grunt) {
    // Project configuration.
    var gruntConf = {
        watch: {
            options: {
                nospawn: true
            },
            default: {
                files: ['./**/*.coffee'],
                tasks: ['coffee', 'browserify']
            }
        },
        coffee: {
            default: {
                expand: true,
                cwd: 'coffee',
                src: ['**/*.coffee'],
                dest: 'js',
                ext: '.js',
                options: {
                    bare: true
                }
            }
        },
        concurrent: {
            server: {
                options: {
                    logConcurrentOutput: true
                }
            }
        },
        browserify: {
            dist: {
                files: {
                    '../js/oauth.js': ['js/main.js']
                }
            }
        },
        uglify: {
            my_target: {
                files: {
                    '../js/oauth.min.js': ['../js/oauth.js']
                }
            }
        },

        taskDefault: ['coffee', 'browserify'],
    };

    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-concurrent');
    grunt.loadNpmTasks('grunt-browserify');
    grunt.loadNpmTasks('grunt-contrib-uglify');

    // grunt.registerMultiTask('shimcreate', '', function() {
    //     var fs = require('fs');
    //     var Path = require('path');

    //     fs.readFile(path.join('..', 'js', 'oauth.js'), 'UTF-8', function(e, r) {
    //         if (e) return e;
    //         grunt.log.writeln(r);
    //     });
    // });
    // Default task.
    grunt.registerTask('default', gruntConf.taskDefault);


};