'use strict';

module.exports = function(gruntConf) {
	gruntConf.coffee['me'] = {
		expand: true,
		cwd: __dirname,
		src: ['*.coffee'],
		dest: __dirname + '/bin',
		ext: '.js',
		options: {
			bare: true
		}
	};
	gruntConf.watch['me'] = {
		files: [
			__dirname + '/**/*.coffee'
		],
		tasks: ['coffee:me']
	};

	return function() {

	}
}