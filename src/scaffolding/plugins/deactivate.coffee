jf = require 'jsonfile'
Q = require 'q'


module.exports = (env) ->
	exec = env.exec
	(plugin) ->
		defer = Q.defer()
		jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
			return defer.reject err if err
			if obj? and obj[plugin]?
				delete obj[plugin]
				jf.writeFile process.cwd() + '/plugins.json', obj, (err) ->
					return defer.reject err if err
					env.debug "Successfully removed plugin '" + plugin.yellow + "' from the plugins.json file."
					defer.resolve()
		defer.promise