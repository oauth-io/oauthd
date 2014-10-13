jf = require 'jsonfile'
Q = require 'q'

module.exports = (env) ->
	(name) ->
		launchUpdate = (name) ->
			defer = Q.defer()
			checkIfFolderExist

			defer.promise

		checkIfFolderExist = (name) ->

			return
		checkIfPullNeeded = () ->
			return
		checkIfDependenciesProblems = () ->
			return
		updateGit = () ->
			return
		updatePluginsList = () ->
			return

		launchUpdate(name)
