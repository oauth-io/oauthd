Q = require 'q'
exec = require('child_process').exec
colors = require 'colors'
sugar = require 'sugar'

module.exports = (env) ->
	(plugin_name) ->
		defer = Q.defer()
		env.plugins.info.getFolderName plugin_name, (err, folder_name) ->
			return defer.reject err if err
			plugin_location = process.cwd() + '/plugins/' + folder_name
			env.plugins.info.getFullUrl plugin_name, (err, full_url) ->
				return defer.reject err if err
				env.plugins.info.getVersion full_url, (repo_url, version) ->
					if not version
						version = "master"
					command = 'cd ' + plugin_location 
					exec command + '; git fetch; git branch', (error, stdout, stderr) ->
						return defer.reject error if error
						branchs_arr = stdout.split('\n')
						branchs_arr.remove("")
						exist = false
						for branch, i in branchs_arr
							if branch.substr(2) is version
								exist = true
						if not exist
							exec command + "; git tag", (error, stdout, stderr) ->
								tags_arr = stdout.split('\n')
								tags_arr.remove("")
								exist = false
								for tag, i in tags_arr
									if tag is version
										exist = true
								if exist
									exec command + "; git checkout " + version + "; git pull origin " + version, (error, stdout, stderr) ->
										return defer.reject error if error
										env.debug 'Plugin ' + plugin_name.green + ': ' + stdout
										defer.resolve()
								else
									# env.debug "The version \'" + version + "\' specified for the plugin \'" + plugin_name.yellow + "\' doesn\'t exist."
									env.debug 'Plugin ' + plugin_name.yellow + ': ' + "Couldn't find remote ref " + version.red + "."
									defer.resolve()
						else
							exec command + "; git checkout " + version + "; git pull origin " + version, (error, stdout, stderr) ->
								return defer.reject error if error
								# env.debug 'Plugin ' + plugin_name.green + ' successfully update with tag \'' + version + '\'.'
								env.debug 'Plugin ' + plugin_name.green + ': ' + stdout
								defer.resolve()
		defer.promise
