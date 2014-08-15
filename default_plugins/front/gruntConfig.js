'use strict';

module.exports = function(gruntConf) {

	gruntConf.watch['front'] = {
		files: [
			__dirname + '/**/*.coffee',
			__dirname + '/public/**/*'
		],
		tasks: ['subgrunt:front']
	};

	return function() {

	}
}