module.exports = {
	host_url: "https://oauth.local",		// mounted on this url
	base: "/auth",							// add a base url path. e.g: "/auth"
	base_api: "/api",						// api base path
	port: 6284,

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

	paymill:{
		secret_key: '6cc6913adcad3f37f04feda27ee75f56',
		public_key: '235807894705702ff1aac623959c55cb'
	},

	plugins: [
		/* --- only for oauth.io --- */
		'server.auth',
		'server.users',
		'server.adm',
		'server.oauth_io',
		'server.payments',
		'server.mailjet',
		'server.wishlist',
		'server.pricing',
		'server.front',
		/* ------------------------- */

		//'server.tests',
		'server.statistics',
		'server.request'
	]
}
