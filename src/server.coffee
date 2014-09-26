# OAuth daemon
# Copyright (C) 2014 Webshell SAS
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

	
	PLModule = require './presentationLayer'

	# Server config and launch
	server_options =
		name: 'oauthd'
		version: '1.0.0'

	if env.config.ssl
		server_options.key = fs.readFileSync Path.resolve(env.config.rootdir, process.cwd() + '/' + env.config.ssl.key)
		server_options.certificate = fs.readFileSync Path.resolve(env.config.rootdir, process.cwd() + '/' +  env.config.ssl.certificate)
		server_options.ca = fs.readFileSync Path.resolve(env.config.rootdir, env.config.ssl.ca) if env.config.ssl.ca
		console.log 'SSL is enabled !'
	server_options.formatters = env.utilities.formatters.formatters

	env.server = server = restify.createServer server_options
	env.pluginsEngine.runSync 'raw'

	server.use restify.authorizationParser()
	server.use restify.queryParser()
	server.use restify.bodyParser mapParams:false

	# runs the plugins' method init if popuplated
	env.pluginsEngine.runSync 'init'


	if not env.hooks["api_cors_middleware"]
		env.addhook 'api_cors_middleware', (req, res, next) =>
			next()
	if not env.hooks["api_create_app_restriction"]
		env.addhook 'api_create_app_restriction', (req, res, next) =>
			next()

	# init the presentation layer
	PLModule(env) # initializes the api webservices endpoints

	return {
		listen: (callback) =>
			env.pluginsEngine.run 'setup', =>
				listen_args = [env.config.port]
				listen_args.push env.config.bind if env.config.bind
				listen_args.push (err) =>
					return callback err if err
					console.log '%s listening at %s for %s', server.name, server.url, env.config.host_url
					env.events.emit 'server', null
					callback null, server

				server.listen.apply server, listen_args
	}
