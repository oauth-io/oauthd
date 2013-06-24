# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

Url = require 'url'
Path = require 'path'
fs = require 'fs'
restify = require 'restify'

exports.setup = (callback) ->

	console.log 'Warning: http mode enabled !'

	# build server options
	server_options =
		name: 'OAuth Daemon'
		version: '1.0.0'

	# create server
	httpserver = restify.createServer server_options

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

	# listen
	httpserver.listen @config.port + 1, (err) =>
		if err
			console.error err
			return
		console.log "Http server listening on port " + (@config.port + 1)

	callback()