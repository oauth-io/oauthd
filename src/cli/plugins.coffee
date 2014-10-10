fs = require 'fs'
ncp = require 'ncp'
exec = require('child_process').exec
Q = require('q')
scaffolding = require('../scaffolding')({ console: true })

module.exports = (cli) ->
	
	main_defer = Q.defer()

	cli.argv._.shift()

	if cli.argv._[0] is 'list'
		cli.argv._.shift()
		scaffolding.plugins.list()

	if cli.argv._[0] is 'uninstall' 
		cli.argv._.shift()
		plugin_name = ""
		for elt in cli.argv._
			if plugin_name != ""
				plugin_name += " "
			plugin_name += elt
		scaffolding.plugins.uninstall(plugin_name)

	if cli.argv._[0] is 'install'
		cli.argv._.shift()
		console.log "cli.argv.force", cli.argv.force
		if cli.argv.force
			force = true
		else
			force = false
		plugin_repo = cli.argv._[0]
		if plugin_repo?
			scaffolding.plugins.install(plugin_repo, process.cwd(), force)
				.then () ->
					scaffolding.compile()
				.then () ->
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
								promise =  scaffolding.plugins.install(v, process.cwd(), force)
							else
								promise = promise.then () ->
									return scaffolding.plugins.install(v, process.cwd(), force)
				promise
					.then () ->
						if (cli.__mode != 'prog')
							scaffolding.compile()
								.then () ->
									main_defer.resolve()
								.fail () ->
									main_defer.reject()
						else
							main_defer.resolve()
					.fail (e) ->
						console.log 'ERROR'.red, e.message.yellow
						main_defer.reject()
	
	

	if cli.argv._[0] is 'create'
		cli.argv._.shift()
		force = cli.argv.force == null
		save = cli.argv.inactive != null
		name = cli.argv._[0]
		scaffolding.plugins.create(name, force, save)
			.then () ->
				defer.resolve()
			.fail () ->
				defer.reject()



	return main_defer.promise

