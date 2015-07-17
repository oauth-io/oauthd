# OAuth daemon
# Copyright (C) 2015 Webshell SAS
#
# LICENCE HERE

module.exports = (env) ->

	#libs
	fs = require 'fs'
	restify = require 'restify'
	bodyParser = require "body-parser"
	cookieParser = require "cookie-parser"
	session = require "express-session"
	https = require 'https'
	Path = require 'path'

	PLModule = require './presentationLayer'

	# Server config and launch
	server_options =
		name: 'oauthd'
		version: '1.0.0'

	if env.config.ssl
		server_options.key = fs.readFileSync env.config.ssl.key
		server_options.certificate = fs.readFileSync env.config.ssl.certificate
		server_options.ca = fs.readFileSync env.config.ssl.ca if env.config.ssl.ca
		env.debug 'SSL is enabled !'
	server_options.formatters = env.utilities.formatters.formatters

	env.server = server = restify.createServer server_options
	env.pluginsEngine.runSync 'raw'

	server.use restify.queryParser()
	server.use restify.bodyParser mapParams:false
	server.use restify.authorizationParser()

	# Adds the 'always' middleware for each request
	for k, middleware of env.middlewares.always
		server.use middleware

	return {
		listen: (callback) =>
			env.pluginsEngine.loadPluginPages(env.server)
				.then () ->
					# runs the plugins' method init if popuplated
					env.pluginsEngine.runSync 'init'

					# init the presentation layer
					PLModule(env) # initializes the api webservices endpoints

					env.pluginsEngine.run 'setup', =>
						listen_args = [env.config.port]
						listen_args.push env.config.bind if env.config.bind
						listen_args.push (err) =>
							return callback err if err
							env.debug '%s listening at %s for %s', server.name, server.url, env.config.host_url
							env.events.emit 'server', null
							callback null, server

						server.listen.apply server, listen_args
	}
