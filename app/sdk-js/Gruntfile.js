'use strict';

var package_info = require('./package.json');
var config = require('../../config.js');
var local_config = require('../../config.local.js');
var fs = require('fs');

for (var k in local_config) {
    config[k] = local_config[k];
}


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
                    './dist/oauth.js': ['js/main.js']
                },
                options: {
                    transform: [
                        [
                            'envify', {
                                oauthd_url: config.host_url,
                                api_url: config.host_url + config.base_api,
                                sdk_version: "web-" + package_info.version
                            }
                        ]
                    ]
                }
            }
        },
        uglify: {
            my_target: {
                files: {
                    './dist/oauth.min.js': ['../js/oauth.js']
                }
            }
        },

        taskDefault: ['coffee', 'browserify', 'uglify', 'bower']
    };

    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-concurrent');
    grunt.loadNpmTasks('grunt-browserify');
    grunt.loadNpmTasks('grunt-contrib-uglify');

    grunt.registerTask('bower', 'Creates an updated bower.json to the dist folder', function() {
        console.log("READING FILE");
        var done = this.async();
        fs.readFile('./templates/bower.json', 'UTF-8', function(e, text) {
            if (e) {
                console.err('A problem occured while creating bower.json');
                done();
                return;
            }
            text = text.replace('{{sdk_version}}', package_info.version);
            text = text.replace('{{description}}', package_info.description);
            text = text.replace('{{license}}', package_info.license);
            console.log("WRITING FILE");
            fs.writeFile('./dist/bower.json', text, function(e) {
                if (e) {
                    console.err('A problem occured while creating bower.json');
                    done();
                    return;
                }
                console.log("DONE WRITING");
                done();
            });
        });
    });

    // Default task.
    grunt.registerTask('default', gruntConf.taskDefault);

};