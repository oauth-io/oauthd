module.exports = {
	host_url: "https://oauth.local",		// mounted on this url
	base: "/auth",							// add a base url path. e.g: "/auth"
	base_api: "/api",						// api base path
	port: 6284,
	http_port: 6285,

	debug: true,							// add stack trace & infos in errors

	ssl: {
		key: 'keys/server.key',
		certificate: 'keys/server.crt'
	},

	staticsalt: 'i m a random string, change me.',
	publicsalt: 'i m not really important.',

	redis: {
		port: 6379,
		host: '127.0.0.1',
		// password: '...my redis password...',
		// database: ...0~15...
		// options: {...other options...}
	},

	cacheTime: 1,
	demoKey: "ZjsbIbKdkuw5fmEkBHDZfUqEadY",

	smtp: {},

	plugins: [
		/* --- only for oauth.io --- */
		'server.auth',
		'server.users',
		'server.adm',
		'server.oauth_io',
		'server.mailjet',
		'server.wishlist',
		'server.front',
		/* ------------------------- */

		//'server.tests',
		'server.statistics',
		'server.request'
	]
}
if (require('fs').existsSync(__dirname + '/config.local.js')) {
	var override = require('./config.local.js');
	for (var i in override)
		module.exports[i] = override[i];
}
