# oauthd
# Copyright (C) 2016 Webshell SAS

Q = require 'q'

Path = require 'path'
async = require "async"
colors = require "colors"

# request FIX
qs = require 'qs'


exports.init = (env) ->
	defer = Q.defer()
	startTime = new Date
	env = env || {}
	# Env is the global environment object. It is usually the 'this' (or @) in other modules

	env.scaffolding = require('./scaffolding')()

	coreModule = require './core'
	dataModule = require './data'

	coreModule(env).initEnv() #inits env
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



	env.pluginsEngine.init process.cwd(), (err) ->
		if not err
			auth_plugin_present = false
			for k, plugin of env.plugins
				if plugin.plugin_config.type == 'auth'
					auth_plugin_present = true

			if not auth_plugin_present
				console.error "No " + "auth".red + " plugin found"
				console.error "You need to install an " + "auth".red + " plugin to run the server"
				defer.reject()
				process.exit()

			# start server
			env.debug.display "oauthd start server"
			exports.server = server = require('./server')(env)
			async.series [
				env.data.providers.getList,
				server.listen
			], (err) ->
				if err
					console.error 'Error while initialisation', err.stack.toString()
					env.pluginsEngine.data.emit 'server', err
					defer.reject err
				else
					env.debug.display 'Server is ready (load time: ' + Math.round(((new Date) - startTime) / 10) / 100 + 's)', (new Date).toGMTString()
					defer.resolve()

			return defer.promise

exports.installPlugins = () ->
	require('../bin/cli/plugins')(['install'],{}).command()

