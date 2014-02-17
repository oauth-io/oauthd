module.exports = {
	host_url: "https://oauth.local",		// mounted on this url
	base: "/auth",							// add a base url path. e.g: "/auth"
	base_api: "/api",						// api base path
	port: 6284,
	http_port: 6285,
	// bind: "127.0.0.1",					// bind to an ip

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

	smtp: {
		service: "Gmail",
		auth: {
			user: "mytest042@gmail.com",
			pass: "P@ssword0"
		}
	},

	paymill: {
		secret_key: '923660828109fb1ca53c8e1b6916d94d',
		public_key: '8a8394c340c4033a0140d9f61cfd3145'
	},

	cacheTime: 1,
	demoKey: "ZjsbIbKdkuw5fmEkBHDZfUqEadY",
	loginKey: "ZjsbIbKdkuw5fmEkBHDZfUqEadY",

	hipchat: {
		//token: '...HipChat API token...'
		//room_support: '...ID or name of the support room...'
		//room_activities: '...ID or name of the activities room...'
		//name: '...Name the message will appear be sent from...'
		//crash_monitor: true // will send a crash notif on hipchat
	},

	customer_io: {
		//site_id: '...Site ID...'
		//api_key: '...API key...'
	},

	prerender: {
		//host: '...prerender server host...'
		//port: '...prerender server port...'
	},

	plugins: [
		/* --- only for oauth.io --- */
		'server.auth',
		'server.prerender',
		'server.users',
		'server.clients',
		'server.adm',
		'server.hipchat',
		'server.zendesk',
		'server.oauth_io',
		'server.payments',
		'server.mailjet',
		'server.wishlist',
		'server.pricing',
		'server.customer_io',
		'server.cohort',
		'server.apiratings',
		/* ------------------------- */

		//'server.tests',
		'server.statistics',
		'server.request',

		/* --- only for oauth.io --- */
		'server.front'
		/* ------------------------- */
	]
}
if (require('fs').existsSync(__dirname + '/config.local.js')) {
	var override = require('./config.local.js');
	for (var i in override)
		module.exports[i] = override[i];
}
