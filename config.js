var config = {
	host_url: "http://localhost:6284",		// mounted on this url
	base: "/",								// add a base url path. e.g: "/auth"
	base_api: "/api",						// api base path
	port: 6284,
	// bind: "127.0.0.1",					// bind to an ip

	debug: false,							// add stack trace & infos in errors


	staticsalt: 'i m a random string, change me.',
	publicsalt: 'i m another random string, change me.',

	redis: {
		port: 6379,
		host: '127.0.0.1',
		// password: '...my redis password...',
		// database: ...0~15...
		// options: {...other options...}
	},

	plugins: [

	]
};

try {
	if (__dirname != process.cwd()) {
		var instance_config = require(process.cwd() + '/config.js');
		for (var k in instance_config) {
			config[k] = instance_config[k];
		}
	}
} catch (e) {
	console.log('No config file found, using defaults');
}

try {
	if (__dirname != process.cwd()) {
		var instance_config = require(process.cwd() + '/config.local.js');
		for (var k in instance_config) {
			config[k] = instance_config[k];
		}
	}
} catch (e) {
}

module.exports = config;
