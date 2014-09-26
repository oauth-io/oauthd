'use strict';

module.exports = function(gruntConf) {
	gruntConf.coffee['me'] = {
		expand: true,
		cwd: __dirname,
		src: ['index.coffee'],
		dest: __dirname,
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