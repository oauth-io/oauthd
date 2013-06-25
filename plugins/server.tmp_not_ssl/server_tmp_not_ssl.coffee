# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

Url = require 'url'
Path = require 'path'
fs = require 'fs'
restify = require 'restify'

formatters = require '../../lib/formatters'

exports.setup = (callback) ->

	console.log 'Warning: http mode enabled !'

	# build server options
	server_options =
		name: 'OAuth Daemon'
		formatters: formatters.formatters
		version: '1.0.0'

	# create server
	httpserver = restify.createServer server_options
	httpserver.use restify.queryParser()
	httpserver.use restify.bodyParser mapParams:false

	# get a provider config
	httpserver.get @config.base + '/api/providers/:provider/logo', ((req, res, next) =>
			fs.exists Path.normalize(@config.rootdir + '/providers/' + req.params.provider + '.png'), (exists) =>
				if not exists
					req.params.provider = 'default'
				req.url = '/' + req.params.provider + '.png'
				req._url = Url.parse req.url
				req._path = req._url._path
				next()
		), restify.serveStatic
			directory: @config.rootdir + '/providers'
			maxAge: 120

	httpserver.post @config.base + '/api/users/lostpassword', (req, res, next) ->
		next new restify.NotAuthorizedError 'Disabled feature until beta!'

	httpserver.post @config.base + '/token', (req, res, next) ->
		next new restify.NotAuthorizedError 'Disabled feature until beta!'

	# register an account
	httpserver.post @config.base + '/api/users', (req, res, next) =>
		@db.users.register req.body, @server.send(res,next)

	# listen
	httpserver.listen @config.port + 1, (err) =>
		if err
			console.error err
			return
		console.log "Http server listening on port " + (@config.port + 1)

	callback()