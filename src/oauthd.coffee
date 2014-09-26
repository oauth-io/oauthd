# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

Q = require 'q'

defer = Q.defer()
events = require('events')
# Env is the global environment object. It is usually the 'this' (or @) in other modules
env = {}

exports.init = () ->
	startTime = new Date
	env.events = new events.EventEmitter()

	Path = require 'path'
	async = require "async"

	#project requires
	engineModule = require './engine'
	DALModule = require './dataLayer'
	BLModule = require './businessLayer'
	

	engineModule(env).initEngine() # initializes env.engine
	DALModule(env) # initializes env.DAL

	engineModule(env).initOAuth()


	engineModule(env).initPlugins()
	BLModule(env) # inits env.BL, the module containing all business methods. Part of that must be opened to plugins
	
	exports.mailer = env.engine.mailer
	exports.exit = env.engine.exit
	exports.oauth1 = env.engine.oauth.oauth1
	exports.oauth2 = env.engine.oauth.oauth2
	exports.plugin_env = env.plugins.data

	# request FIX
	qs = require 'request/node_modules/qs'
	oldstringify = qs.stringify
	qs.stringify = ->
		result = oldstringify.apply(qs, arguments)
		result = result.replace /!/g, '%21'
		result = result.replace /'/g, '%27'
		result = result.replace /\(/g, '%28'
		result = result.replace /\)/g, '%29'
		result = result.replace /\*/g, '%2A'
		return result
	# --

	# initialize plugins
	console.log "oauthd initialize plugins"
	exports.plugins = plugins = env.plugins
	plugins.init (res) ->
		# start server
		console.log "oauthd start server"
		exports.server = server = require('./server')(env)
		async.series [
			plugins.data.db.providers.getList,
			server.listen
		], (err) ->
			if err
				console.error 'Error while initialisation', err.stack.toString()
				plugins.data.emit 'server', err
				defer.reject err
			else
				console.log 'Server is ready (load time: ' + Math.round(((new Date) - startTime) / 10) / 100 + 's)', (new Date).toGMTString()
				defer.resolve()

		return defer.promise

	
