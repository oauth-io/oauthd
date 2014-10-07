easy_cli = require 'easy-cli'
fs = require 'fs'
ncp = require 'ncp'
prompt = require 'prompt'
jf = require 'jsonfile'
installPlugin = require('./install')
colors = require 'colors'
exec = require('child_process').exec
Q = require('q')
module.exports = (cli) ->
	main_defer = Q.defer()

	cli.argv._.shift()

	if cli.argv._[0] is 'list'
		cli.argv._.shift()
		require('./list')()

	if cli.argv._[0] is 'uninstall' 
		cli.argv._.shift()
		plugin_name = ""
		for elt in cli.argv._
			if plugin_name != ""
				plugin_name += " "
			plugin_name += elt
		require('./uninstall')(plugin_name)

	if cli.argv._[0] is 'install'

		cli.argv._.shift()
		plugin_repo = cli.argv._[0]
		if plugin_repo?
			require('./install')(plugin_repo, process.cwd())
				.done () ->
					console.log 'Running npm install and grunt'.green + ' This may take a few minutes'.yellow
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
							console.log 'Running npm install and grunt'.green + ' This may take a few minutes'.yellow
							exec 'npm install; grunt;', (error, stdout, stderr) ->
								console.log 'Done'
								main_defer.resolve()
						else
							main_defer.resolve()
					.fail (e) ->
						console.log 'ERROR'.red, e.message.yellow
						main_defer.reject()
	
	return main_defer.promise


