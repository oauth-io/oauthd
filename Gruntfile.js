'use strict';

var fs = require('fs');

module.exports = function(grunt) {

    // Project configuration.
    var gruntConf = {
        watch: {
            options: {
                nospawn: true
            },
            lib: {
                files: ['lib/**/*.coffee'],
                tasks: ['coffee:lib']
            },
            cli: {
                files: ['cli/**/*.coffee'],
                tasks: ['coffee:cli']
            },
            static: {
                files: ['lib/**/*.png','lib/**/*.less','lib/**/*.html','lib/**/*.css','lib/**/*.js','lib/**/*.eot','lib/**/*.otf','lib/**/*.svg','lib/**/*.ttf', 'lib/**/*.woff', '**/*.ico'],
                tasks: ['copy']  
            }
        },
        coffee: {
            lib: {
                expand: true,
                cwd: 'lib',
                src: ['**/*.coffee'],
                dest: 'bin',
                ext: '.js',
                options: {
                    bare: true
                }
            },
            cli: {
                expand: true,
                cwd: 'cli',
                src: ['**/*.coffee'],
                dest: 'cli/bin',
                ext: '.js',
                options: {
                    bare: true
                }
            }
        },
        copy: {
            main: {
                files: [
                    {
                        expand: true,
                        src: ['**/*.less', '**/*.html', '**/*.png','**/*.js','**/*.eot','**/*.css','**/*.svg', '**/*.ttf', '**/*.woff', '**/*.otf', '**/*.ico'],
                        dest: 'bin',
                        cwd: 'lib'
                    },
                ]
            }
        },
        subgrunt: {}
    };

    var tasks = [];
    var default_plg = fs.readdirSync(__dirname + '/default_plugins');
    for (var i in default_plg) {
        var plugin = default_plg[i];
        if (fs.existsSync(__dirname + '/default_plugins/' + plugin + '/gruntConfig.js')) {
            var task = require('./default_plugins/' + plugin + '/gruntConfig').call(this, gruntConf);
            if (task)
                tasks.push(task);
        }

        if (fs.existsSync(__dirname + '/default_plugins/' + plugin + '/Gruntfile.js')) {
            gruntConf.subgrunt[plugin] = {
                options: {},
                projects: {}
            };
            gruntConf.subgrunt[plugin].projects['./default_plugins/' + plugin] =  'default';
        }
    }


    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-subgrunt');

    // Default task.
    grunt.registerTask('default', ['coffee', 'copy', 'subgrunt']);
    grunt.registerTask('test', ['nodeunit']);
};