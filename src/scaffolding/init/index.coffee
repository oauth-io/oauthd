fs = require 'fs'
prompt = require 'prompt'
colors = require 'colors'
Q = require 'q'
ncp = require 'ncp'
async = require 'async'

module.exports = (env) ->

	installPlugins = (defer, name) ->
		async.series [
			(next) ->
				env.plugins.install("https://github.com/oauth-io/oauthd-admin-auth#0.x.x", process.cwd() + "/" + name)
					.then () ->
						next()
					.fail (e) ->
						next e
			(next) ->
				env.plugins.install("https://github.com/oauth-io/oauthd-slashme#0.x.x", process.cwd() + "/" + name)
					.then () ->
						next()
					.fail (e) ->
						next e
			(next) ->
				env.plugins.install("https://github.com/oauth-io/oauthd-request#0.x.x", process.cwd() + "/" + name)
					.then () ->
						next()
					.fail (e) ->
						next e
			(next) ->
				env.plugins.install("https://github.com/oauth-io/oauthd-front#0.x.x", process.cwd() + "/" + name)
					.then () ->
						next()
					.fail (e) ->
						next e
		], (err) ->
			return defer.reject err if err
			defer.resolve(name)

	doInit = (defer, name) ->
		schema = {
			properties:{}
		}

		schema.properties.install_default_plugin = {
			pattern: /^([Yy]|[nN])$/
			message: "Please answer by 'y' for yes or 'n' for no."
			description: 'Do you want to install default plugins?  (Y|n)'
			default: 'Y'
		}

		prompt.message = "oauthd".white
		prompt.delimiter = "> "
		prompt.start()
		prompt.get schema, (err, res2) ->
			env.debug 'Generating a folder for ' + name
			ncp __dirname + '/../templates/basis_structure', process.cwd() + '/' + name, (err) ->
				return defer.reject err if err
				fs.rename process.cwd() + '/' + name + '/gitignore', process.cwd() + '/' + name + '/.gitignore', (err) ->
					return defer.reject err if err
					if res2.install_default_plugin.match(/[yY]/)
						installPlugins defer, name
					else
						defer.resolve(name)



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
				env.debug 'You must give a folder name using only letters, digits, dash and underscores.'
				return
			exists = fs.existsSync './' + results.name

			if exists && not force
				schema = {
					properties:{}
				}
				schema.properties.overwrite = {
					pattern: /^(y|n)$/
					message: "Please answer by 'y' for yes or 'n' for no."
					description: 'A folder ' + results.name + ' already exists. Do you want to overwrite it? (y|N)'
					default: 'N'
				}

				prompt.message = "oauthd".white
				prompt.delimiter = "> "
				prompt.start()
				
				prompt.get schema, (err, res_overwrite) ->
					if res_overwrite.overwrite.match(/[Yy]/)
						doInit(defer, results.name)
					else
						return defer.reject new Error 'Stopped'
			else
				doInit(defer, results.name)


		defer.promise


