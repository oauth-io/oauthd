# oauthd
# Copyright (C) 2014 Webshell SAS
#
# NEW LICENSE HERE

Q = require 'q'

events = require('events')
Path = require 'path'
async = require "async"

# request FIX
qs = require 'request/node_modules/qs'

exports.init = () ->
	startTime = new Date

	# Env is the global environment object. It is usually the 'this' (or @) in other modules
	env = {
		events: new events.EventEmitter()
	}

	coreModule = require './engine'
	dataModule = require './dataLayer'
	
	coreModule(env).initConfig() #inits env.config
	coreModule(env).initUtilities() # initializes env, env.utilities, ...
	dataModule(env) # initializes env.data

	coreModule(env).initOAuth() # might be exported in plugin later
	coreModule(env).initPluginsEngine()

	oldstringify = qs.stringify
	qs.stringify = ->
		result = oldstringify.apply(qs, arguments)
		result = result.replace /!/g, '%21'
		result = result.replace /'/g, '%27'
		result = result.replace /\(/g, '%28'
		result = result.replace /\)/g, '%29'
		result = result.replace /\*/g, '%2A'
		return result

	defer = Q.defer()
	env.pluginsEngine.init (res) ->
		# start server
		console.log "oauthd start server"
		exports.server = server = require('./server')(env)
		async.series [
			env.pluginsEngine.data.db.providers.getList,
			server.listen
		], (err) ->
			if err
				console.error 'Error while initialisation', err.stack.toString()
				env.pluginsEngine.data.emit 'server', err
				defer.reject err
			else
				console.log 'Server is ready (load time: ' + Math.round(((new Date) - startTime) / 10) / 100 + 's)', (new Date).toGMTString()
				defer.resolve()

		return defer.promise

	
