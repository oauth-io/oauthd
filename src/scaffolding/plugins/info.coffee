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
									console.log e
									next()
						else
							next()
					, () ->
						defer.resolve plugins_json
				catch e
					defer.reject e
			defer.promise

		getActive: () ->
			defer = Q.defer()

			info.getPluginsJson { activeOnly: true }
				.then (plugins) ->
					defer.resolve Object.keys plugins
				.fail (e) ->
					defer.reject e

			defer.promise

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

		getInactive: () ->
			defer = Q.defer()

			installed_plugins = undefined
			active_plugins = undefined

			info.getInstalled()
				.then (_installed) ->
					installed_plugins = _installed
					return info.getActive()
				.then (_active) ->
					active_plugins = _active

					inactive_plugins = []
					for plugin in installed_plugins
						if plugin not in active_plugins
							inactive_plugins.push plugin

					defer.resolve inactive_plugins
				.fail (e) ->

					defer.reject e
			defer.promise

		getInfo: (plugin_name, callback) ->
			defer = Q.defer()
			fs.readFile process.cwd() + '/plugins/' + plugin_name + '/plugin.json', {encoding: 'UTF-8'}, (err, data) ->
				return defer.reject err if err
				try
					plugin_data = JSON.parse data
					plugin_git = env.plugins.git(plugin_name)
					plugin_git.getCurrentVersion()
						.then (v) ->
							plugin_data.version = v.version
							defer.resolve plugin_data
				catch err
					defer.reject err
			defer.promise


		getInfoAsync: (plugin_name) ->
			defer = Q.defer()
			# env.plugins.info.getFolderName plugin_name, (err, folder_name) ->
			# 	return defer.reject err if err
			env.plugins.info.getDetails process.cwd() + "/plugins/" + plugin_name, (err, plugin_data) ->
				return defer.reject err if err
				defer.resolve plugin_data
			defer.promise
		getAllFullInfo: () ->
			defer = Q.defer()
			plugins = []
			info.getActive()
				.then (names) ->
					async.each names, (name, next) ->
						info.getInfo name, (err, data) ->
							return next err if err
							plugins.push data
							next()
					, (err) ->
						defer.resolve plugins
				.fail (e) ->
					return defer.reject e
			defer.promise
		getDetails: (path, callback) ->
			try
				plugin_data = JSON.parse(fs.readFileSync path + '/plugin.json', { encoding: 'UTF-8' })
			catch e 
				return callback e
			return callback null, plugin_data

		getFullUrl: (plugin_name, callback) ->
			try
				obj = jf.readFileSync process.cwd() + '/plugins.json'
			catch e 
				env.debug 'ERROR'.red, e.message.yellow
				env.debug 'Error while trying to read \'plugins.json\'. Please make sure it exists and is well structured.'
			for name, url of obj
				if name is plugin_name
					return callback null, url
			return callback true

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


	info

