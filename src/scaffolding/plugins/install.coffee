exec = require('child_process').exec
fs = require 'fs'
ncp = require 'ncp'
rimraf = require 'rimraf'
jf = require 'jsonfile'
Q = require 'q'
colors = require 'colors'

module.exports = (env) ->
	(url, cwd) ->
		launchInstall = (url, cwd) ->
			defer = Q.defer()
			if not url?
				return env.debug 'Please provide a repository address for the plugin to install'
			temp_location = cwd + '/plugins/cloned'
			cloneTheRepository url, temp_location, (err) ->
				return defer.reject err if err
				getPluginDetails temp_location, (err, plugin_data) ->
					return defer.reject err if err
					moveCloneInPluginsFolder plugin_data.name, cwd, (err) ->
						return defer.reject err if err
						addToPluginList plugin_data.name, url, cwd, (err) ->
							return defer.reject err if err
							defer.resolve()
			defer.promise

		getRepositoryTagNameIfExist = (full_url, callback) ->
			tag_name = null
			tmpArray = full_url.split("^")
			repo_url = tmpArray[0]
			if tmpArray.length > 1
				tag_name = tmpArray[1]
			return callback repo_url, tag_name

		cloneTheRepository = (url, temp_location, callback) ->
			rimraf temp_location, (err) ->
				return callback err if err
				getRepositoryTagNameIfExist url, (repo_url, tag_name) ->
					command = 'cd ' + temp_location + '; git clone ' + repo_url + ' ' + temp_location
					if tag_name 
						command += '; git checkout tags/' + tag_name
					fs.mkdirSync temp_location
					env.debug "Cloning " + url.red + "."
					exec command, (error, stdout, stderr) ->
						return callback error if error
						return callback null
		
		getPluginDetails = (temp_location, callback) ->
			env.debug "Loading plugin information"
			try
				plugin_data = JSON.parse(fs.readFileSync temp_location + '/plugin.json', { encoding: 'UTF-8' })
			catch e 
				return callback e
			return callback null, plugin_data

		moveCloneInPluginsFolder = (plugin_name, cwd, callback) ->
			folder_name = cwd + "/plugins/" + plugin_name
			rimraf folder_name, (err) ->
				return callback err if err
				fs.rename cwd + '/plugins/cloned', cwd + '/plugins/' + plugin_name, (err) ->
					return callback err if err
					env.debug 'Plugin "' + plugin_name + '" successfully installed in "'+ folder_name + '".'
					return callback null

		addToPluginList = (plugin_name, url, cwd, callback) ->
			file =  cwd + '/plugins.json'
			jf.spaces = 4
			jf.readFile file, (err, obj) ->
				return callback err if err
				if not obj?
					obj = {}
				if (not obj[plugin_name]?) # only add entry to plugins.json if not already there
					obj[plugin_name] = url
					jf.writeFile file, obj, (err) ->
						return callback err if err
						env.debug 'Plugin "' + plugin_name + '" successfully added to the plugins list.'
						return callback null
				else
					return callback null
		
		launchInstall(url, cwd)

