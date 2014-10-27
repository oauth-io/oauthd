fs = require 'fs'
rimraf = require 'rimraf'
jf = require 'jsonfile'
Q = require 'q'
colors = require 'colors'

cloned_nb = 0

module.exports = (env) ->
	exec = env.exec
	(url, cwd) ->
		launchInstall = (install_data, cwd) ->
			defer = Q.defer()

			url = install_data.repository
			version_mask = install_data.version
			
			if not url?
				return env.debug 'Please provide a repository address for the plugin to install'
			tempfolder_nb = (cloned_nb++)
			temp_location = process.cwd() + '/plugins/cloned' + tempfolder_nb
			temp_pluginname = 'cloned' + tempfolder_nb
			gitClone install_data, temp_location, (err) ->
				return defer.reject err if err
				env.plugins.info.getInfo temp_pluginname
					.then (plugin_data) ->
						moveClonedToPlugins plugin_data.name, temp_location, cwd, (err) ->
							return defer.reject err if err
							updatePluginsList plugin_data.name, install_data, cwd, (err) ->
								return defer.reject err if err
								if version_mask?
									plugin_git = env.plugins.git(plugin_data.name, false, cwd)
									plugin_git.getLatestVersion(version_mask)
										.then (lv) ->
											plugin_git.checkout lv
												.then () ->
													defer.resolve()
												.fail (e) ->
													defer.reject(e)
								else	
									defer.resolve()
					.fail (e) ->
						defer.reject e

			defer.promise

		gitClone = (install_data, temp_location, callback) ->
			url = install_data.repository
			rimraf temp_location, (err) ->
				return callback err if err
				env.plugins.info.getTargetVersion install_data.name
					.then (version) ->
						command = 'cd ' + temp_location + '; git clone ' + url + ' ' + temp_location
						if version 
							command += '; git checkout ' + version
						fs.mkdirSync temp_location
						env.debug "Cloning " + url.red + "."
						exec command, (error, stdout, stderr) ->
							return callback error if error
							return callback null

		moveClonedToPlugins = (plugin_name, temp_location, cwd, callback) ->
			folder_name = cwd + "/plugins/" + plugin_name
			rimraf folder_name, (err) ->
				return callback err if err
				fs.rename temp_location, cwd + '/plugins/' + plugin_name, (err) ->
					return callback err if err
					env.debug 'Plugin ' + plugin_name.green + ' successfully installed in "'+ folder_name + '".'
					return callback null

		updatePluginsList = (plugin_name, install_data, cwd, callback) ->
			file =  cwd + '/plugins.json'
			jf.spaces = 4
			jf.readFile file, (err, obj) ->
				return callback err if err
				if not obj?
					obj = {}
				if (not obj[plugin_name]?) # only add entry to plugins.json if not already there
					obj[plugin_name] = install_data
					jf.writeFile file, obj, (err) ->
						return callback err if err
						env.debug 'Plugin ' + plugin_name.green + ' successfully activated.'
						return callback null
				else
					return callback null
		
		launchInstall(url, cwd)

