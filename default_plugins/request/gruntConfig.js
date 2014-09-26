'use strict';

module.exports = function(gruntConf) {
	gruntConf.coffee['request'] = {
		expand: true,
		cwd: __dirname,
		src: ['index.coffee'],
		dest: __dirname,
		ext: '.js',
		options: {
			bare: true
		}
	};
	gruntConf.watch['request'] = {
		files: [
			__dirname + '/**/*.coffee'
		],
		tasks: ['coffee:request']
	};

	return function() {

	}
}