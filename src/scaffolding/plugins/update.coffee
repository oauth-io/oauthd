jf = require 'jsonfile'
Q = require 'q'

module.exports = () ->
	(name, cwd) ->
		launchUpdate = (name, cwd) ->
			defer = Q.defer()
			checkIfFolderExist

			defer.promise

		checkIfFolderExist = (name, cwd) ->
			stat = fs.statSync process.cwd() + '/plugins/' + plugin
				if stat.isDirectory()
			return
		checkIfPullNeeded = () ->
			return
		checkIfDependenciesProblems = () ->
			return
		updateGit = () ->
			return
		updatePluginsList = () ->
			return

		launchUpdate(name, cwd)
