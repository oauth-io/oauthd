colors = require 'colors'
Q = require 'q'

module.exports = (env) ->
	(name, force, save) ->
		# testable packages
		exec = env.exec
		ncp = env.ncp
		jf = env.jsonfile
		fs = env.fs

		# implementation
		defer = Q.defer()

		path = process.cwd() + '/plugins/' + name
		exists = fs.existsSync process.cwd() + '/plugins/' + name

		if not exists or force

			ncp __dirname + '/../templates/plugin', path, (err) ->
				if err
					return defer.reject err
				else
					jf.readFile path + '/plugin.json', (err, obj) ->
						return defer.reject(err) if err
						if not obj?
							obj = {}
						obj.name = name
						jf.writeFile path + '/plugin.json', obj, (err) ->
							return defer.reject err if err
							exec 'cd ' + path + '&& git init', (error, stdout, stderr) ->
								if save
									env.plugins.pluginsList.updateEntry name, {active: true}
										.then () ->
											env.debug 'The plugin ' + name.green + ' was successfully created in ./plugins/' + name
											defer.resolve()
										.fail (e) ->
											env.debug 'An error occured while initializing the plugin git repo: '.red
											console.log e.message
											defer.reject e
								else
									if not error
										env.debug 'The plugin ' + name.green + ' was successfully created in ./plugins/' + name
										defer.resolve()
									else
										env.debug 'An error occured while initializing the plugin git repo'.red
										defer.reject error
		else
			env.debug 'The plugin ' + name.yellow + ' already exists. To override, use ' + '--force'.green
			defer.reject({message: 'Folder already exists'})

		defer.promise