Q = require 'q'
exec = require('child_process').exec

module.exports = (env) ->
	(plugin_name) ->
		launchUpdate = (plugin_name) ->
			defer = Q.defer()
			env.plugins.info.getFolderName plugin_name, (err, folder_name) ->
				return defer.reject err if err
				plugin_location = process.cwd() + '/plugins/' + folder_name
				env.plugins.info.getFullUrl plugin_name, (err, full_url) ->
					return defer.reject err if err
					env.plugins.info.getVersion full_url, (repo_url, version) ->
						if not version
							version = "master"
						makeUpdate plugin_location, version, (err) ->
							return defer.reject err if err
							env.debug 'Plugin ' + plugin_name.green + ' successfully update with tag \'' + version + '\'.'
							defer.resolve()
			defer.promise

		makeUpdate = (plugin_location, version, callback) ->
			command = 'cd ' + plugin_location + '; git fetch'
			command += '; git checkout ' + version
			exec command, (error, stdout, stderr) ->
				return callback error if error
				return callback null

		launchUpdate(plugin_name)
