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
        jasmine_node: {

            options: {
                forceExit: true,
                match: '.',
                matchall: false,
                extensions: 'js',
                specNameMatcher: 'spec'
            },
            all: ['tests/unit/spec/']
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
    grunt.loadNpmTasks('grunt-jasmine-node');

    grunt.registerTask('bower', 'Creates an updated bower.json to the dist folder', function() {
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
            fs.writeFile('./dist/bower.json', text, function(e) {
                if (e) {
                    console.err('A problem occured while creating bower.json');
                    done();
                    return;
                }
                console.log("Wrote bower.json file in app/sdk-js/dist/");
                done();
            });
        });
    });

    grunt.registerTask('coverage', 'Creates a tests coverage report', function() {
        var exec = require('child_process').exec;
        var done = this.async();
        exec('npm test', function(error, stdout, stderr) {
            console.log("Coverage report should be generated in ./coverage/lcov-report/index.html");
            done();
        });
    });

    // Default task.
    grunt.registerTask('default', gruntConf.taskDefault);

};