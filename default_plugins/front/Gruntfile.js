var config = require('../../config');

module.exports = function(grunt) {
	grunt.initConfig({
		coffee: {
			default: {
				expand: true,
				cwd: __dirname,
				src: ['*.coffee'],
				dest: 'bin',
				ext: '.js',
				options: {
					bare: true
				}
			},
			static: {
				expand: true,
				cwd: __dirname,
				src: ['public/**/*.coffee'],
				dest: 'bin/staticjs',
				ext: '.js',
				options: {
					bare: true
				}
			}
		},
		browserify: {
			js: {
				src: 'bin/staticjs/public/src/app.js',
				dest: 'bin/public/src/app.js',
				options: {
                    transform: [
                        [
                            'envify', {
                                host: config.host_url
                            }
                        ]
                    ]
                }
			}
		},
		copy: {
			all: {
				expand: true,
				cwd: './public/',
				src: ['**/*.html', '**/*.map', '**/*.json', '**/*.png', 'libs/**/*.js','libs/**/*.css', 'style/fonts/*'],
				dest: 'bin/public'
			}
		},
		less: {
			production: {
				options: {
					paths: ["assets/css"],
					cleancss: true
				},
				files: {
					"bin/public/style/main.css": "public/style/main.less"
				}
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-browserify');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-less');

	grunt.registerTask('default', ['coffee', 'browserify', 'copy:all', 'less']);
};