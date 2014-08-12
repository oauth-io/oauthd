var config = {

};

try {
	var local_config = require(process.cwd() + '/config.js');
	for (var k in local_config) {
		config[k] = local_config[k];
	}
} catch (e) {
	console.log('No config file found, using defaults');
}

module.exports = config;