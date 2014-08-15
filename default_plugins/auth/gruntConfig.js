'use strict';

module.exports = function(gruntConf) {
	gruntConf.coffee['auth'] = {
		expand: true,
		cwd: __dirname,
		src: ['*.coffee'],
		dest: __dirname + '/bin',
		ext: '.js',
		options: {
			bare: true
		}
	};
	gruntConf.watch['auth'] = {
		files: [
			__dirname + '/**/*.coffee'
		],
		tasks: ['coffee:auth']
	};

	return function() {

	}
}