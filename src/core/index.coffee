# OAuth daemon
# Copyright (C) 2014 Webshell SAS
#
# LICENCE HERE

# the engine object
# contains raw features
events = require('events')

module.exports = (env) ->
	return  {
		initEnv: () ->
			env.events = new events.EventEmitter()
			env.middlewares =  {
				always: []
			}
		initConfig: () ->
			env.config = require('./config')(env)
		initUtilities: () ->
			env.utilities = require('./utilities')(env)
		initOAuth: () ->
			env.utilities.oauth = require('./oauth')(env)
		initPluginsEngine: () ->
			env.pluginsEngine = require('./pluginsEngine')(env)
	}

	
		