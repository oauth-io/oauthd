# OAuth daemon
# Copyright (C) 2014 Webshell SAS
#
# LICENCE HERE

# the engine object
# contains raw features
module.exports = (env) ->
	env.engine = env.engine || {}

	return  {
		initEngine: () ->
			require('./config')(env) # env.config
			require('./check')(env) # env.engine.check
			require('./logger')(env) # env.engine.logger
			require('./formatters')(env) # env.engine.formatters
			require('./mailer')(env) # env.engine.mailer
			require('./exit')(env) # env.engine.exit
		initOAuth: () ->
			require('./oauth')(env) # env.engine.oauth.oauth1/oauth2
		initPlugins: () ->
			require('./plugins')(env) # env.plugins
	}

	
		