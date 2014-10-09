fs = require 'fs'
ncp = require 'ncp'
installPlugin = require('./install')
exec = require('child_process').exec
Q = require('q')

module.exports = (cli) ->
	scaffolding_folder_path = "../scaffolding"
	main_defer = Q.defer()

	cli.argv._.shift()

	if cli.argv._[0] is 'list'
		cli.argv._.shift()
		require(scaffolding_folder_path + '/list')()

	if cli.argv._[0] is 'uninstall' 
		cli.argv._.shift()
		plugin_name = ""
		for elt in cli.argv._
			if plugin_name != ""
				plugin_name += " "
			plugin_name += elt
		require(scaffolding_folder_path + '/uninstall')(plugin_name)

	if cli.argv._[0] is 'install'

		cli.argv._.shift()
		plugin_repo = cli.argv._[0]
		if plugin_repo?
			save = cli.argv.save == null
			require(scaffolding_folder_path + '/install')(plugin_repo, process.cwd(), save)
				.done () ->
					console.log 'Running npm install and grunt..'.green + ' This may take a few minutes'.yellow
					exec 'npm install; grunt;', (error, stdout, stderr) ->
						console.log 'Done'
		else
			try
				plugins = JSON.parse(fs.readFileSync process.cwd() + '/plugins.json', { encoding: 'UTF-8' })
			catch e
				console.log e.message.red
				console.log 'Error while trying to read \'plugins.json\'. Please make sure it exists and is well structured.'
			promise = undefined
			if plugins?
				for k,v of plugins
					if (v != "")
						do (v) ->
							if not promise?
								promise =  installPlugin(v, process.cwd())
							else
								promise = promise.then () ->
									return installPlugin(v, process.cwd())
				promise
					.then () ->
						if (cli.__mode != 'prog')
							console.log 'Running npm install and grunt.. '.green + 'This might take a few minutes'.yellow
							exec 'npm install; grunt;', (error, stdout, stderr) ->
								console.log 'Done'
								main_defer.resolve()
						else
							main_defer.resolve()
					.fail (e) ->
						console.log 'ERROR'.red, e.message.yellow
						main_defer.reject()
	
	

	if cli.argv._[0] is 'create'
		cli.argv._.shift()
		force = cli.argv.force == null
		save = cli.argv.save == null
		name = cli.argv._[0]
		require(scaffolding_folder_path + '/create')(name, force, save)
			.then () ->
				defer.resolve()
			.fail () ->
				defer.reject()



	return main_defer.promise

