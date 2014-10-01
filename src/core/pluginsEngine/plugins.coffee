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

async = require 'async'
jf = require 'jsonfile'


module.exports = (env) ->
	console.log 'Initializing plugins engine'

	check = env.utilities.check
	exit = env.utilities.exit

	shared = env


	pluginsEngine = {
		plugin: {}
	}
	env.plugins = pluginsEngine.plugin
	env.hooks = {
		'connect.auth': []
		'connect.callback': []
		'connect.backend': []
	}
	env.callhook = -> # (name, ..., callback)
		name = Array.prototype.slice.call(arguments)
		args = name.splice(1)
		name = name[0]
		callback = args.splice(-1)
		callback = callback[0]
		return callback() if not env.hooks[name]
		cmds = []
		args[args.length] = null
		for hook in env.hooks[name]
			do (hook) ->
				cmds.push (cb) ->
					args[args.length - 1] = cb
					hook.apply pluginsEngine.data, args
		async.series cmds, callback

	env.addhook = (name, fn) ->
		env.hooks[name] ?= []
		env.hooks[name].push fn

	pluginsEngine.load = (plugin_name) ->
		console.log "Loading '" + plugin_name + "'."
		env.config.plugins.push plugin_name
		try 
			plugin_data = require(process.cwd() + '/plugins/' + plugin_name + '/plugin.json')
		catch
			console.log 'absent plugin.json for plugin \'' + plugin_name + '\''
			plugin_data = {}
		if plugin_data.main?
			entry_point = '/' + plugin_data.main
		else
			entry_point = '/index'
		plugin = require(process.cwd() + '/plugins/' + plugin_name + entry_point)(env)
		pluginsEngine.plugin[plugin_name] = plugin
		return

	pluginsEngine.init = (callback) ->
		try
			jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
				throw err if err
				if not obj?
					obj = {}

				for pluginname, pluginversion of obj
					pluginsEngine.load pluginname

				callback true
		catch e
			console.log 'An error occured: ' + e.message
			callback true

	pluginsEngine.list = (callback) ->
		list = []
		jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
			return callback err if err
			if obj?
				for key, value of obj
					list.push key
			return callback null, list

	pluginsEngine.run = (name, args, callback) ->
		if typeof args == 'function'
			callback = args
			args = []
		args.push null
		calls = []
		for k,plugin of pluginsEngine.plugin
			if typeof plugin[name] == 'function'
				do (plugin) ->
					calls.push (cb) ->
						args[args.length-1] = cb
						plugin[name].apply env, args
		async.series calls, ->
			args.pop()
			callback.apply null,arguments
			return
		return

	pluginsEngine.runSync = (name, args) ->
		for k,plugin of pluginsEngine.plugin
			if typeof plugin[name] == 'function'
				plugin[name].apply env, args
		return

	pluginsEngine