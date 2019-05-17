fs = require 'fs'
prompt = require 'prompt'
colors = require 'colors'
Q = require 'q'
ncp = require 'ncp'
async = require 'async'

module.exports = (env) ->

	installPlugins = (defer, name) ->
		old_location = process.cwd()
		process.chdir process.cwd() + '/' + name
		async.series [
			(next) ->
				env.plugins.install({
					repository: "https://github.com/oauth-io/oauthd-admin-auth",
					version: "1.x.x"
				}, process.cwd())
					.then () ->
						next()
					.fail (e) ->
						next e
			(next) ->
				env.plugins.install({
					repository: "https://github.com/oauth-io/oauthd-slashme",
					version: "1.x.x"
				}, process.cwd())
					.then () ->
						next()
					.fail (e) ->
						next e
			(next) ->
				env.plugins.install({
					repository: "https://github.com/oauth-io/oauthd-request",
					version: "1.x.x"
				}, process.cwd())
					.then () ->
						next()
					.fail (e) ->
						next e
			(next) ->
				env.plugins.install({
					repository: "https://github.com/oauth-io/oauthd-front",
					version: "1.x.x"
				}, process.cwd())
					.then () ->
						next()
					.fail (e) ->
						next e
		], (err) ->
			return defer.reject err if err
			process.chdir old_location
			defer.resolve(name)

	doInit = (defer, name, plugins) ->
		if plugins
			copyBasisStructure defer, name, 'n'
			return
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
			copyBasisStructure defer, name, res2.install_default_plugin

	copyBasisStructure = (defer, name, install_default_plugin) ->
		env.debug 'Generating a folder for ' + name
		ncp __dirname + '/../templates/basis_structure', process.cwd() + '/' + name, (err) ->
			return defer.reject err if err
			fs.rename process.cwd() + '/' + name + '/gitignore', process.cwd() + '/' + name + '/.gitignore', (err) ->
				return defer.reject err if err
				if install_default_plugin.match(/[yY]/)
					installPlugins defer, name
				else
					defer.resolve(name)

	(force_default, options) ->
		defer = Q.defer()
		if force_default
			exists = fs.existsSync './default-oauthd-instance'
			if not exists
				plugins = if options.noplugins then "n" else "Y"
				copyBasisStructure defer, "default-oauthd-instance", plugins
			else
				return defer.reject new Error 'Stopped because \'default-oauthd-instance\' folder already exists.'
		else
			if options.name
				exists = fs.existsSync './' + options.name

				if exists
					return defer.reject new Error 'Stopped because \'' + options.name + '\' folder already exists.'
				else
					doInit(defer, options.name, options.noplugins)
			else
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

					if exists
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
								doInit(defer, results.name, options.noplugins)
							else
								return defer.reject new Error 'Stopped'
					else
						doInit(defer, results.name, options.noplugins)


		defer.promise


