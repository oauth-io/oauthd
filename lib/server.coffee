# OAuth daemon
# Copyright (C) 2014 Webshell SAS
#
# LICENCE HERE

#libs
express = require 'express'
fs = require 'fs'

#project requires
datal = require('./dataLayer')
businessl = require('./businessLayer')
presl = require('./presentationLayer')

plugins = require('./plugins')
formatters = require './formatters'

# engine initialization
oauth =
	oauth1: require './oauth1'
	oauth2: require './oauth2'

auth = plugins.data.auth

config = require '../config'


#server creation, population and launch

server_options =
	name: 'OAuth Daemon'
	version: '1.0.0'

server_options.formatters = formatters.formatters

if config.ssl
	server_options.key = fs.readFileSync Path.resolve(config.rootdir, process.cwd() + '/' + config.ssl.key)
	server_options.certificate = fs.readFileSync Path.resolve(config.rootdir, process.cwd() + '/' +  config.ssl.certificate)
	server_options.ca = fs.readFileSync Path.resolve(config.rootdir, config.ssl.ca) if config.ssl.ca
	console.log 'SSL is enabled !'

server = express(server_options)
plugins.data.server = server
plugins.runSync 'raw'

exports.listen = (callback) ->
	
	plugins.run 'setup', ->
		listen_args = [config.port]
		listen_args.push config.bind if config.bind
		listen_args.push (err) ->
			return callback err if err
			#exit.push 'Http(s) server', (cb) -> server.close cb
			#/!\ server.close = timeout if at least one connection /!\ wtf?
			console.log '%s listening at %s for %s', server.name, server.url, config.host_url
			plugins.data.emit 'server', null
			callback null, server

		server.listen.apply server, listen_args

