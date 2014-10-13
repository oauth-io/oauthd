jf = require 'jsonfile'
Q = require 'q'

module.exports = (env) ->
	(plugin_name) ->
		launchUpdate = (plugin_name) ->
			defer = Q.defer()
			folder_name = env.plugins.info.getFolderName plugin_name
				
			defer.promise

		checkIfPullNeeded = () ->
			return
		checkIfDependenciesProblems = () ->
			return
		updateGit = () ->
			return
		updatePluginsList = () ->
			return

		launchUpdate(plugin_name)
