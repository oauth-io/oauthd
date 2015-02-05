jf = require 'jsonfile'
Q = require 'q'
fs = require 'fs'
sugar = require 'sugar'
async = require 'async'

module.exports = (env) ->
	exec = env.exec
	info =
		# retrieve plugins.json data
		# opts can contain:
		# - activeOnly: if true, filters plugins that are not marked active: false
		getPluginsJson: (opts) ->
			defer = Q.defer()
			opts ?= {}

			fs.readFile process.cwd() + '/plugins.json', {encoding: 'UTF-8'}, (err, data) ->
				return defer.reject err if err
				try
					obj = JSON.parse data
					plugins_json = []
					plugins_names = Object.keys obj
					async.eachSeries plugins_names, (plugin_name, next) ->
						value = obj[plugin_name]
						include_plugin = true
						value.active ?= true
						if typeof value == 'string'
							str = value.split '#'
							data = {}
							if str[0] != ''
								data.repository = str[0]
								data.version = str[1]
							data.active = true
							value = data
						else if typeof value == 'object'
							if opts.activeOnly && value.active == false
								include_plugin = false
						else
							include_plugin = false

						if include_plugin
							info.getInfo plugin_name
								.then (plugin_info) ->
									if typeof plugin_info == 'object'
										for k, v of plugin_info
											if k != 'version' and k != 'active' and k != 'repository'
												value[k] = v
									if value.repository?
										value.version ?= 'master'
									value.active ?= true
									plugins_json[plugin_name] = value
									next()
								.fail (e) ->

									plugins_json[plugin_name] = {
										name: plugin_name,
										active: true
									}
									if value.repository?
										value.version ?= 'master'
										plugins_json[plugin_name].repository = value.repository
										plugins_json[plugin_name].version = value.version

									next()
						else
							next()
					, () ->
						defer.resolve plugins_json
				catch e
					defer.reject e
			defer.promise

		# retrieve list of active plugin names
		getActive: () ->
			defer = Q.defer()

			info.getPluginsJson { activeOnly: true }
				.then (plugins) ->
					defer.resolve plugins
				.fail (e) ->
					defer.reject e

			defer.promise

		# retrieve list of installed plugins names
		getInstalled: () ->
			defer = Q.defer()

			fs.readdir process.cwd() + '/plugins', (err, folder_names) ->
				installed_plugins = []
				async.eachSeries folder_names, (name, next) ->
					fs.stat process.cwd() + '/plugins/' + name, (err, stat) ->
						defer.reject err if err
						if stat.isDirectory()
							installed_plugins.push name
						next()
				, () ->
					defer.resolve installed_plugins

			defer.promise

		# retrieve list of inactive plugins names
		getInactive: () ->
			defer = Q.defer()

			installed_plugins = undefined
			active_plugins = undefined

			info.getInstalled()
				.then (_installed) ->
					installed_plugins = _installed
					return info.getActive()
				.then (_active) ->
					active_plugins = Object.keys _active
					inactive_plugins = []
					for plugin in installed_plugins
						if plugin not in active_plugins
							inactive_plugins.push plugin

					defer.resolve inactive_plugins
				.fail (e) ->

					defer.reject e
			defer.promise

		# retrieve plugin.json data for given plugin name
		getInfo: (plugin_name, callback) ->
			defer = Q.defer()
			fs.readFile process.cwd() + '/plugins/' + plugin_name + '/plugin.json', {encoding: 'UTF-8'}, (err, data) ->
				if err
					if err.code == 'ENOENT'
						return defer.reject new Error('No plugin.json')
					else
						return defer.reject err
				try
					plugin_data = JSON.parse data
					env.plugins.git plugin_name
						.then (plugin_git) ->
							plugin_git.getCurrentVersion()
								.then (v) ->
									plugin_data.version = v.version
									defer.resolve plugin_data
								.fail () ->
									defer.reject plugin_data
						.fail (err) ->
							defer.reject err
				catch err
					defer.reject err
					
			defer.promise

		getVersion: (url, callback) ->
			version = null
			tmpArray = url.split("#")
			repo_url = tmpArray[0]
			if tmpArray.length > 1
				version = tmpArray[1]
			return callback repo_url, version

		isActive:(name) ->
			obj = jf.readFileSync process.cwd() + '/plugins.json'
			plugin_names = []
			plugin_names = Object.keys(obj) if obj?
			return plugin_names.indexOf(name) > -1

		folderExist:(folder_name) ->
			stat = fs.statSync process.cwd() + '/plugins/' + folder_name
			return stat.isDirectory()

		getTargetVersion: (name) ->
			defer = Q.defer()

			env.plugins.git name
				.then (plugin_git) ->
					plugin_git.getVersionMask()
						.then (mask) ->
							plugin_git.getLatestVersion(mask)
								.then (version) ->
									defer.resolve version
						.fail (e) ->
							defer.reject e
				.fail (err) ->
					defer.reject err

			defer.promise

	info

