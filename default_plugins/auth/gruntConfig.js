'use strict';

module.exports = function(gruntConf) {
	gruntConf.coffee['auth'] = {
		expand: true,
		cwd: __dirname,
		src: ['index.coffee'],
		dest: __dirname,
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