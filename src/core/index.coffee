# OAuth daemon
# Copyright (C) 2014 Webshell SAS
#
# LICENCE HERE

# the engine object
# contains raw features
module.exports = (env) ->
	return  {
		initConfig: () ->
			env.config = require('./config')(env)
		initUtilities: () ->
			env.utilities = require('./utilities')(env)
		initOAuth: () ->
			env.utilities.oauth = require('./oauth')(env)
		initPluginsEngine: () ->
			env.pluginsEngine = require('./pluginsEngine')(env)
	}

	
		