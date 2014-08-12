'use strict';

module.exports = function(grunt) {

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
                dest: 'bin',
                ext: '.js',
                options: {
                    bare: true
                }
            }
        }
    };

    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');

    // Default task.
    grunt.registerTask('default', ['coffee']);
    grunt.registerTask('test', ['nodeunit']);
};