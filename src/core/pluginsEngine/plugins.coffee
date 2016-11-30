async = require 'async'
jf = require 'jsonfile'
fs = require 'fs'
colors = require 'colors'
Q = require 'q'
restify = require 'restify'
Url = require 'url'

module.exports = (env) ->
	env.debug 'Initializing plugins engine'
	pluginsEngine = {
		plugin: {}
	}
	pluginsEngine.cwd = process.cwd()
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


	global_interface = undefined
	pluginsEngine.load = (plugin_name) ->
		try
			plugin_data = require(env.pluginsEngine.cwd + '/plugins/' + plugin_name + '/plugin.json')
		catch e
			# env.debug 'Error loading plugin.json (' + plugin_name + ')'
			# env.debug e.message.yellow
			plugin_data = {
				name: plugin_name
			}

		if plugin_data.main?
			if plugin_data.main[0] isnt '/'
				plugin_data.main = '/' + plugin_data.main
		else
			plugin_data.main = '/index'

		if not plugin_data.name? or plugin_data.name isnt plugin_name
			plugin_data.name = plugin_name



		if plugin_data.type isnt 'global-interface'
			loadPlugin(plugin_data)
		else
			global_interface = plugin_data

	loadPlugin = (plugin_data) ->
		if not fs.existsSync(env.pluginsEngine.cwd + '/plugins/' + plugin_data.name)
			env.debug "Cannot find addon " + plugin_data.name
			return
		env.debug "Loading " + plugin_data.name.blue
		try
			plugin = require(env.pluginsEngine.cwd + '/plugins/' + plugin_data.name + plugin_data.main)(env)
			if plugin_data.type?
				pluginsEngine.plugin[plugin_data.type] = plugin
				pluginsEngine.plugin[plugin_data.type]?.plugin_config = plugin_data
			else
				pluginsEngine.plugin[plugin_data.name] = plugin
				pluginsEngine.plugin[plugin_data.name]?.plugin_config = plugin_data
		catch e
			env.debug "Error while loading plugin " + plugin_data.name
			env.debug e.stack.yellow # + ' at line ' + e.lineNumber?.red

	pluginsEngine.init = (cwd, callback) ->
		env.pluginsEngine.cwd = cwd

		env.scaffolding.plugins.info.getPluginsJson({ activeOnly: true })
			.then (obj) ->
				if not obj?
					obj = {}
				for pluginname, data of obj
					stat = fs.statSync cwd + '/plugins/' + pluginname
					if stat.isDirectory()
						pluginsEngine.load pluginname
				if global_interface?
					loadPlugin(global_interface)
				return callback null
			.fail (e) ->
				return callback e

	pluginsEngine.list = (callback) ->
		list = []
		env.scaffolding.plugins.info.getPluginsJson({ activeOnly: true })
			.then (obj) ->
				if obj?
					for key, value of obj
						list.push key
				return callback null, list
			.fail (err) ->
				env.debug 'An error occured: ' + err
				return callback err




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

	pluginsEngine.loadPluginPages = (server) ->
		defer = Q.defer()
		env.scaffolding.plugins.info.getPluginsJson()
			.then (plugins) ->
				for plugin_name, plugin of plugins
					if plugin.interface_enabled
						do (plugin) ->
							server.get new RegExp("^/plugins/" + plugin.name + "/(.*)"), (req, res, next) ->
								req.params[0] ?= ""
								req.url = req.params[0]
								req._url = Url.parse req.url
								req._path = req._url.pathname

								fs.stat process.cwd() + '/plugins/' + plugin.name + '/public/' + req.params[0], (err, stat) ->

									if stat?.isFile() && req.params[0] != 'index.html'
										next()
										return
									else
										fs.readFile process.cwd() + '/plugins/' + plugin.name + '/public/index.html', {encoding: 'UTF-8'}, (err, data) ->
											if err
												res.send 404
												return
											res.setHeader 'Content-Type', 'text/html'
											data2 = data.replace(/\{\{ plugin_name \}\}/g, plugin.name)
											res.send 200, data2
											return
							, restify.serveStatic
								directory: process.cwd() + '/plugins/' + plugin.name + '/public'
				defer.resolve()
		defer.promise

	extended_endpoints = []

	pluginsEngine.describeAPIEndpoint = (endpoint_description) ->
		extended_endpoints.push endpoint_description


	pluginsEngine.getExtendedEndpoints = () ->
		extended_endpoints



	pluginsEngine