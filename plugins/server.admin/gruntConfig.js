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

module.exports = function(gruntConf) {
	gruntConf.watch['front-coffee'] = {
		files: [
			__dirname + '/app/admin/{,*/}*.coffee',
			__dirname + '/app/coffee/{,*/}*.coffee'
		],
		tasks: ['coffee:front-compile', 'coffee:front-compile-adm']
	};
	gruntConf.watch['front-less'] = {
		files: [
			__dirname + '/app/less/{,*/}*.less'
		],
		tasks: ['less:front-compile']
	};

	gruntConf.coffee['front-compile'] = {
		expand: true,
		cwd: __dirname + '/app/coffee',
		src: ['{,*/}*.coffee'],
		dest: __dirname + '/app/js',
		ext: '.js',
		options: {
			bare: true
		},
	};
	gruntConf.coffee['front-compile-adm'] = {
		expand: true,
		cwd: __dirname + '/app/admin',
		src: ['{,*/}*.coffee'],
		dest: __dirname + '/app/admin/js',
		ext: '.js',
		options: {
			bare: true
		},
	};

	if ( ! gruntConf.nodemon.server.options.ignoredFiles)
		gruntConf.nodemon.server.options.ignoredFiles = [];
	gruntConf.nodemon.server.options.ignoredFiles.push(__dirname + "/app");

	gruntConf.less = gruntConf.less || {};
	gruntConf.less['front-compile'] = { files: {} };
	gruntConf.less['front-compile'].files[__dirname + "/app/css/main.css"] = __dirname + "/app/less/main.less"

	return function() {
		this.loadNpmTasks('grunt-contrib-less');

		gruntConf.taskDefault.unshift('less');
	}
}