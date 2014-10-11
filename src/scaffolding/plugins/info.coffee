jf = require 'jsonfile'
Q = require 'q'
fs = require 'fs'

module.exports = (env) ->
	getActive: () ->
		obj = jf.readFileSync process.cwd() + '/plugins.json'
		plugin_names = []
		plugin_names = Object.keys(obj) if obj?
		return plugin_names
	getInstalled: () ->
		plugins = fs.readdirSync process.cwd() + '/plugins'
		installed_plugins = []
		for plugin in plugins
			stat = fs.statSync process.cwd() + '/plugins/' + plugin
			if stat.isDirectory()
				installed_plugins.push plugin
		return installed_plugins
	getInactive: () ->
		installed_plugins = @getInstalled()
		active_plugins = @getActive()
		inactive_plugins = []
		for plugin in installed_plugins
			if plugin not in active_plugins
				inactive_plugins.push plugin
		return inactive_plugins
	isActive:(name) ->
		obj = jf.readFileSync process.cwd() + '/plugins.json'
		plugin_names = []
		plugin_names = Object.keys(obj) if obj?
		return plugin_names.indexOf(name) > -1