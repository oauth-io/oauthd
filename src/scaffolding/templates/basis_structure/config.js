// Here you can configure your oauthd instance

var config = {
	host_url: process.env.oauthd_host_url || "http://localhost:6284",						// mounted on this url
	port: process.env.oauthd_port || 6284,												// the port your instance is supposed to run on
	//http_port: 6285,										// http port for redirection if using SLL
	// bind: "127.0.0.1",									// bind to an ip


	staticsalt: 'i m a random string, change me.',			// used in hash generation, change for more security
	publicsalt: 'i m another random string, change me.',	// used in hash generation, change for more security

	redis: {												// your redis configuration
		port: 6379,
		host: '127.0.0.1',
		// password: '...my redis password...',
		// database: ...0~15...
		// options: {...other options...}
	},

	// SSL is disabled by default. You can put your own key and certificate in a 'keys' folder
	//ssl: {
    //    key: __dirname + '/keys/yourkey.key',
    //    certificate: __dirname + '/keys/yourcertificate.crt'
    //},
};

module.exports = config;