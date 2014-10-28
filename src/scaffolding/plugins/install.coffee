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
			version_mask = install_data.version || 'master'
			
			if not url?
				return env.debug 'Please provide a repository address for the plugin to install'
			tempfolder_nb = (cloned_nb++)
			temp_location = process.cwd() + '/plugins/cloned' + tempfolder_nb
			temp_pluginname = 'cloned' + tempfolder_nb
			gitClone install_data, temp_location, temp_pluginname, version_mask, (err) ->
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

		gitClone = (install_data, temp_location, temp_pluginname, version_mask, callback) ->
			url = install_data.repository
			rimraf temp_location, (err) ->
				return callback err if err
				command = 'cd ' + temp_location + '; git clone ' + url + ' ' + temp_location
				env.debug "Cloning " + url.red
				fs.mkdir temp_location, (err) ->
					return callback err if err
					exec command, (error, stdout, stderr) ->
						return callback error if error
						plugin_git = env.plugins.git temp_pluginname
						if version_mask
							plugin_git.getLatestVersion version_mask
								.then (version) ->
									if version
										command = 'cd ' + temp_location + '; git checkout ' + version
										exec command, (error, stdout, stderr) ->
											return callback error if error
											return callback null
									else
										return callback null
						else
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
			process.chdir cwd
			env.plugins.pluginsList.updateEntry(plugin_name, install_data)
				.then () ->
					env.debug 'Plugin ' + plugin_name.green + ' successfully activated.'
				.fail (e) ->
					callback(e)
		
		launchInstall(url, cwd)

