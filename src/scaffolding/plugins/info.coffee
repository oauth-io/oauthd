jf = require 'jsonfile'
Q = require 'q'
fs = require 'fs'
sugar = require 'sugar'
async = require 'async'
exec = require('child_process').exec

module.exports = (env) ->
	info = 
		getActive: () ->
			try
				obj = jf.readFileSync process.cwd() + '/plugins.json'
			catch e 
				env.debug 'ERROR'.red, e.message.yellow
				env.debug 'Error while trying to read \'plugins.json\'. Please make sure it exists and is well structured.'
			plugin_names = []
			plugin_names = Object.keys(obj) if obj?
			plugin_names.remove("")
			return plugin_names
		getActiveAsync: () ->
			defer = Q.defer()
			jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
				plugin_names = []
				plugin_names = Object.keys(obj) if obj?
				plugin_names.remove("")
				defer.resolve plugin_names

			defer.promise
		getInstalled: () ->
			try
				folder_names = fs.readdirSync process.cwd() + '/plugins'
			catch e 
				env.debug 'ERROR'.red, e.message.yellow
				env.debug 'Error while trying to list plugins into \'plugins\' folder. Please make sure it exists and is well structured.'
			installed_plugins = []
			for name in folder_names
				if env.plugins.info.folderExist(name)
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
		getInfo: (plugin_name, callback) ->
			# env.plugins.info.getFolderName plugin_name, (err, folder_name) ->
			# 	return callback err if err
			env.plugins.info.getDetails process.cwd() + "/plugins/" + plugin_name, (err, plugin_data) ->
				return callback err if err
				return callback null, plugin_data

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
			info.getActiveAsync()
				.then (names) ->
					async.each names, (name, next) ->
						info.getDetails process.cwd() + '/plugins/' + name, (err, data) ->
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

