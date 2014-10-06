'use strict';

module.exports = function(gruntConf) {
	gruntConf.coffee['plugin_test'] = {
		expand: true,
		cwd: __dirname,
		src: ['*.coffee'],
		dest: __dirname + '/bin',
		ext: '.js',
		options: {
			bare: true
		}
	};
	
	gruntConf.watch['plugin_test'] = {
		files: [
			__dirname + '/**/*.coffee'
		],
		tasks: ['coffee:plugin_test']
	};

	return function() {

	}
}