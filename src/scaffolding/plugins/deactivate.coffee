jf = require 'jsonfile'
Q = require 'q'


module.exports = (env) ->
	exec = env.exec
	(plugin) ->
		defer = Q.defer()
		env.plugins.modify.updatePluginsJson(plugin, {
			active: false
		})
			.then () ->
				defer.resolve()
			.fail (e) ->
				defer.reject e
		defer.promise