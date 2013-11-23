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

	gruntConf.nodemon.server.options.ignoredFiles.push(__dirname + "/app");

	gruntConf.less = gruntConf.less || {};
	gruntConf.less['front-compile'] = { files: {} };
	gruntConf.less['front-compile'].files[__dirname + "/app/css/main.css"] = __dirname + "/app/less/main.less"

	return function() {
		this.loadNpmTasks('grunt-contrib-less');

		gruntConf.taskDefault.unshift('less');
	}
}