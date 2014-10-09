fs = require 'fs'
prompt = require 'prompt'
colors = require 'colors'
Q = require 'q'
ncp = require 'ncp'

module.exports = (env) ->
	(force) ->
		defer = Q.defer()
		schema = {
			properties:
				name: {
					pattern: /^[a-zA-Z0-9_\-]+$/
					message: 'You must give a folder name using only letters, digits, dash and underscores'
					description: 'What will be the name of your oauthd instance?'
					require: true
					delimiter: ''
				}
		}
		prompt.message = "oauthd".white
		prompt.delimiter = "> "
		prompt.start()
		prompt.get schema, (err, results) ->
			return defer.reject err if err
			if results.name.length == 0
				env.debug 'You must give a folder name using only letters, digits, dash and underscores'
				return
			exists = fs.existsSync './' + results.name
			if exists && not force
				env.debug 'A folder already exists for that name. Use '.red + '--force'.yellow + ' to overwrite it.'.red
			else
				env.debug 'Generating a folder for ' + results.name
				ncp __dirname + '/../templates/basis_structure', process.cwd() + '/' + results.name, (err) ->
					return defer.reject err if err
					schema = {
						properties:
							install_default_plugin: {
								pattern: /^(yes|no)$/
								message: "Please answer by 'yes' or 'no'."
								description: 'Do you want to install default plugins? (recommanded)'
								require: true
							}
					}
					prompt.message = "oauthd".white
					prompt.delimiter = "> "
					prompt.start()
					prompt.get schema, (err, res2) ->
						return defer.reject err if err
						if res2.install_default_plugin is "yes"
							env.plugins.install("https://github.com/william26/oauthd_default_plugin_auth", process.cwd() + "/" + results.name)
							.then () ->
								env.plugins.install("https://github.com/william26/oauthd_default_plugin_me", process.cwd() + "/" + results.name)
							.then () ->
								env.plugins.install("https://github.com/william26/oauthd_default_plugin_request", process.cwd() + "/" + results.name)
							.then () ->
								env.plugins.install("https://github.com/william26/oauthd_default_plugin_front", process.cwd() + "/" + results.name)
							.then () ->
								defer.resolve(results.name)
							.fail (e) ->
								return defer.reject e if e
						else
							defer.resolve(results.name)

		defer.promise


