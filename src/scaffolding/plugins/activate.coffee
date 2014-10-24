jf = require 'jsonfile'
Q = require 'q'


module.exports = (env) ->

	writeEntry = (key, value) ->
		defer = Q.defer()
		jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
			return defer.reject err if err
			if obj?
				obj[key] = value
				jf.writeFile process.cwd() + '/plugins.json', obj, (err) ->
					return defer.reject err if err
					env.debug "Successfully added plugin '" + key.green + "' to the plugins.json file."
					defer.resolve()
		defer.promise


	exec = env.exec
	(plugin) ->
		defer = Q.defer()
		regex = /origin\t(.*) \(fetch\)/g;
		exec 'cd ' + process.cwd() + '/plugins/' + plugin + '; git remote -v', (err, stdout, stderr) ->
			return defer.reject err if err
			match = regex.exec(stdout)
			if match[1]
				plugin_git = env.plugins.git(plugin)
				plugin_git.getCurrentVersion()
					.then (v) ->
						if (v.version)
							writeEntry(plugin, match[1] + '#' + v.version)
						else
							writeEntry(plugin, match[1])
					.fail () ->
						writeEntry(plugin, match[1])
			else
				defer.reject()

		defer.promise