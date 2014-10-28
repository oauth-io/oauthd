jf = require 'jsonfile'
Q = require 'q'


module.exports = (env) ->

	exec = env.exec
	(plugin) ->
		defer = Q.defer()
		
		env.plugins.pluginsList.updateEntry(plugin, {
			active: true
		})
			.then () ->
				defer.resolve()
			.fail (e) ->
				defer.reject e

		defer.promise