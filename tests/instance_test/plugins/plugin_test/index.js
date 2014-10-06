module.exports = function(env) {
	var plugin = require('./bin/plugin_test.js')(env);
	return plugin;
}
