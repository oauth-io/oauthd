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
		nodemon: {
			server: {
				options: {
					file: 'lib/oauthd.js',
					watchedExtensions: ['js'],
					ignoredFiles: ['Gruntfile.js']
				}
			}
		},
		nodeunit: {
			files: ['test/**/*_test.js']
		},
		concurrent: {
			server: {
				options: { logConcurrentOutput: true }
			}
		},
		taskDefault: ['coffee'],
		taskServer: ['watch', 'nodemon:server']
	};

	var tasks = [];
	for (var i in config.plugins) {
		var plugin = config.plugins[i];
		gruntConf.watch[plugin] = {
			files: ['plugins/' + plugin + '/*.coffee'],
			tasks: ['coffee:' + plugin]
		};
		gruntConf.coffee[plugin] = {
			expand: true,
			cwd: 'plugins/' + plugin,
			src: ['*.coffee'],
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

	for (var i in tasks)
		tasks[i].call(this);

	// Default task.
	grunt.registerTask('default', gruntConf.taskDefault);
	grunt.registerTask('server', ['default', 'concurrent:server']);
	grunt.registerTask('test', ['nodeunit']);
};
