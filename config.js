module.exports = {
	base: "/",		// base url path. e.g: "/auth"
	port: 6284,

	ssl: {
		key: 'keys/server.key',
		certificate: 'keys/server.crt'
	},

	staticsalt: 'i m a random string, change me.',
	publicsalt: 'i m not really important.'
}