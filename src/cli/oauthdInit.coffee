fs = require 'fs'
prompt = require 'prompt'
installPlugin = require('./plugins/install')
colors = require 'colors'
Q = require 'q'

module.exports = () ->
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
			console.log 'You must give a folder name using only letters, digits, dash and underscores'
			return
		console.log 'Generating a folder for ' + results.name
		fs.stat './' + results.name, (err, stats) ->
			return defer.reject err if err
			if not stats
				fs.mkdirSync './' + results.name
			ncp __dirname + '/../../scaffolding/templates/basis_structure', process.cwd() + '/' + results.name, (err) ->
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
						installPlugin("https://github.com/william26/oauthd_default_plugin_auth", process.cwd() + "/" + results.name)
						.then () ->
							installPlugin("https://github.com/william26/oauthd_default_plugin_me", process.cwd() + "/" + results.name)
						.then () ->
							installPlugin("https://github.com/william26/oauthd_default_plugin_request", process.cwd() + "/" + results.name)
						.then () ->
							installPlugin("https://github.com/william26/oauthd_default_plugin_front", process.cwd() + "/" + results.name)
						.then () ->
							defer.promise(results.name)
						.fail (e) ->
							return defer.reject e if e
					else
						defer.promise(results.name)

	defer.promise


