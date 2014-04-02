'use strict';

module.exports = function(grunt) {
    var config = require('./config');
    var fs = require('fs');

    // Project configuration.
    var gruntConf = {
        watch: {
            options: {
                nospawn: true
            },
            lib: {
                files: ['lib/*.coffee'],
                tasks: ['coffee:lib']
            }
        },
        coffee: {
            lib: {
                expand: true,
                cwd: 'lib',
                src: ['*.coffee'],
                dest: 'lib',
                ext: '.js',
                options: {
                    bare: true
                }
            }
        },
        requirejs: {

        },
        nodemon: {
            server: {
                options: {
                    file: 'lib/oauthd.js',
                    watchedExtensions: ['js'],
                    ignoredFiles: [],
                    legacyWatch: true
                }
            }
        },
        nodeunit: {
            files: ['test/**/*_test.js']
        },
        concurrent: {
            server: {
                options: {
                    logConcurrentOutput: true
                }
            }
        },
        subgrunt: {
            options: {
                // Task-specific options go here.
            },
            default: {
                options: {
                    // Target-specific options
                },
                projects: {
                    'app/sdk-js': 'default'
                }
            },
        },
        taskDefault: ['coffee', 'requirejs', 'subgrunt:default'],
        taskServer: ['watch', 'nodemon:server', 'subgrunt:default']
    };


    var tasks = [];
    for (var i in config.plugins) {
        var plugin = config.plugins[i];
        gruntConf.watch[plugin] = {
            files: ['plugins/' + plugin + '/**/*.coffee'],
            tasks: ['coffee:' + plugin]
        };
        gruntConf.coffee[plugin] = {
            expand: true,
            cwd: 'plugins/' + plugin,
            src: ['{,*/}*.coffee'],
            dest: 'plugins/' + plugin,
            ext: '.js',
            options: {
                bare: true
            }
        };
        if (fs.existsSync(__dirname + '/plugins/' + plugin + '/gruntConfig.js')) {
            var task = require('./plugins/' + plugin + '/gruntConfig').call(this, gruntConf);
            if (task)
                tasks.push(task);
        }
    }

    gruntConf.concurrent.server.tasks = gruntConf.taskServer;
    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-nodeunit');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-concurrent');
    grunt.loadNpmTasks('grunt-nodemon');
    grunt.loadNpmTasks('grunt-subgrunt');

    grunt.loadNpmTasks('grunt-contrib-requirejs');

    for (var i in tasks)
        tasks[i].call(this);

    // Default task.
    grunt.registerTask('default', gruntConf.taskDefault);
    grunt.registerTask('server', ['default', 'concurrent:server']);
    grunt.registerTask('test', ['nodeunit']);
};