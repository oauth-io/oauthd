jf = require 'jsonfile'
Q = require 'q'


module.exports = (env) ->
	exec = env.exec
	(plugin) ->
		defer = Q.defer()
		regex = /origin\t(.*) \(fetch\)/g;
		exec 'cd ' + process.cwd() + '/plugins/' + plugin + '; git remote -v', (err, stdout, stderr) ->
			return defer.reject err if err
			match = regex.exec(stdout)
			if match[1]
				jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
					return defer.reject err if err
					if obj?
						obj[plugin] = match[1]
						jf.writeFile process.cwd() + '/plugins.json', obj, (err) ->
							return defer.reject err if err
							env.debug "Successfully added plugin '" + plugin.green + "' to the plugin.json file."
							defer.resolve()
			else
				defer.reject()

		defer.promise