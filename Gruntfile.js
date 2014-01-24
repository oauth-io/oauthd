/*
OAuth daemon
Copyright (C) 2013 Webshell SAS

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
 any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

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
