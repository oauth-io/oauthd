fs = require 'fs'
rimraf = require 'rimraf'
jf = require 'jsonfile'
Q = require 'q'

module.exports = (env) ->
	(plugin_name) ->
		defer = Q.defer()
		if plugin_name is ""
			env.debug 'Please provide a plugin name to uninstall.'
			defer.reject()
			return defer.promise
		try
			folder_name = process.cwd() + "/plugins/" + plugin_name
			fs.exists folder_name, (exists) ->
				if exists
					rimraf folder_name, (err) ->
						return defer.reject err if err
						env.debug "Successfully removed plugin '" + plugin_name.yellow + "' folder."
				env.plugins.pluginsList.removeEntry plugin_name
					.then () ->
						env.debug "Successfully removed plugin '" + plugin_name.yellow + "' from the plugins list."
						defer.resolve()
					.fail (e) ->
						defer.reject e
		catch e
			env.debug 'An error occured: ' + e.message
		defer.promise