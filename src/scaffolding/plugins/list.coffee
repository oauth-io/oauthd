jf = require 'jsonfile'
Q = require 'q'
fs = require 'fs'

module.exports = (env) ->

	getActive: () ->

		obj = jf.readFileSync process.cwd() + '/plugins.json'
		plugins = []
		if obj?
			plugins = Object.keys(obj)
		plugins
	getInstalled: () ->
		installed_plugins = fs.readdirSync process.cwd() + '/plugins'
		i = []
		for v in installed_plugins
			stat = fs.statSync process.cwd() + '/plugins/' + v
			if stat.isDirectory()
				i.push v
		i
	getInactive: () ->
		installed_plugins = @getInstalled()
		active = @getActive()
		unactivated_plugins = []

		for v in installed_plugins
			if v not in active
				unactivated_plugins.push v
		unactivated_plugins
		