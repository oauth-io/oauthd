jf = require 'jsonfile'
Q = require 'q'
fs = require 'fs'
sugar = require 'sugar'
module.exports = (env) ->
	getActive: () ->
		obj = jf.readFileSync process.cwd() + '/plugins.json'
		plugin_names = []
		plugin_names = Object.keys(obj) if obj?
		plugin_names.remove("")
		return plugin_names
	getInstalled: () ->
		plugins = fs.readdirSync process.cwd() + '/plugins'
		installed_plugins = []
		for name in plugins
			if env.plugins.info.isInstalled(name)
				path = process.cwd() + '/plugins/' + name
				env.plugins.info.getDetails path, (err, plugin_data) ->
					if plugin_data? and plugin_data.name?
						installed_plugins.push plugin_data.name
		return installed_plugins
	getInactive: () ->
		installed_plugins = @getInstalled()
		active_plugins = @getActive()
		inactive_plugins = []
		for plugin in installed_plugins
			if plugin not in active_plugins
				inactive_plugins.push plugin
		return inactive_plugins
	getDetails: (path, callback) ->
		try
			plugin_data = JSON.parse(fs.readFileSync path + '/plugin.json', { encoding: 'UTF-8' })
		catch e 
			return callback e
		return callback null, plugin_data
	isActive:(name) ->
		obj = jf.readFileSync process.cwd() + '/plugins.json'
		plugin_names = []
		plugin_names = Object.keys(obj) if obj?
		return plugin_names.indexOf(name) > -1
	isInstalled:(name) ->
		stat = fs.statSync process.cwd() + '/plugins/' + name
		return stat.isDirectory()