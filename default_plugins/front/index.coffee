restify = require 'restify'
ecstatic = require 'ecstatic'

exports.setup = (callback) ->
	@server.get /^\/.*/, restify.serveStatic
		directory: __dirname + '/public'
		default: 'index.html'

	callback()