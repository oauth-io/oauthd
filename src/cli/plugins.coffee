fs = require 'fs'
ncp = require 'ncp'
exec = require('child_process').exec
Q = require('q')
scaffolding = require('../scaffolding')({ console: true })
colors = require 'colors'
sugar = require 'sugar'

module.exports = (args, options) ->
	help: (command) ->
		if not command?
			console.log 'Usage: oauthd plugins <command> [args]'
			console.log ''
			console.log 'Available commands'
			console.log '    oauthd plugins ' + 'list'.yellow + '\t\t\t\t' + 'Lists installed plugins'
			console.log '    oauthd plugins ' + 'create'.yellow + ' <name>' + '\t\t' + 'Creates a new plugin'
			console.log '    oauthd plugins ' + 'install'.yellow + ' [git-repository]' + '\t' + 'Installs a plugin'
			console.log '    oauthd plugins ' + 'uninstall'.yellow + ' <name>' + '\t\t' + 'Removes a plugin'
			console.log '    oauthd plugins ' + 'activate'.yellow + ' <name>' + '\t\t' + 'Activates a plugin'
			console.log '    oauthd plugins ' + 'deactivate'.yellow + ' <name>' + '\t\t' + 'Deactivates a plugin'
			console.log ''
			console.log 'oauthd plugins <command> ' + '--help'.green + ' for more information about a specific command'
		if command == 'list'
			console.log 'Usage: oauthd plugins ' + 'list'.yellow
			console.log 'Lists all installed plugins'
		if command == 'activate'
			console.log 'Usage: oauthd plugins ' + 'activate <name>'.yellow
			console.log 'Activates a plugin (puts it in the plugins.json file)'
		if command == 'deactivate'
			console.log 'Usage: oauthd plugins ' + 'deactivate <name>'.yellow
			console.log 'Deactivates a plugin (removes it from the plugins.json file)'
		if command == 'create'
			console.log 'Usage: oauthd plugins ' + 'create <name>'.yellow
			console.log 'Creates a new plugin in ./plugins/<name> with a basic architecture'
			console.log ''
			console.log 'Options:'
			console.log '    ' + '--force'.yellow + '\t\t' + 'Creates the plugin even if another one with same name, overriding it'
			console.log '    ' + '--inactive'.yellow + '\t\t' + 'Prevents oauthd from adding the plugin to plugins.json'
		if command == 'install'
			console.log 'Usage: oauthd plugins ' + 'install [git-repository]'.yellow
			console.log 'Installs a plugin using a git repository.'
			console.log 'If no argument is given, installs all plugins listed in plugins.json'
			console.log ''
			console.log 'Options:'
			console.log '    ' + '--force'.yellow + '\t' + 'Installs the plugin even if already present, overriding it'
		if command == 'update'
			console.log 'Usage: oauthd plugins ' + 'update [name]'.yellow
			console.log 'Updates a plugin using its git repository. If no argument is given, updates all plugins listed in plugins.json'
		if command == 'uninstall'
			console.log 'Usage: oauthd plugins ' + 'uninstall <name>'.yellow
			console.log 'Uninstalls a given plugin'


	command: () ->
		main_defer = Q.defer()

		if args[0] == 'list'
			if options.help
				@help('list')
			else
				active = scaffolding.plugins.info.getActive()
				inactive = scaffolding.plugins.info.getInactive()
				installed = scaffolding.plugins.info.getInstalled()
				console.log 'This instance has ' + (installed.length + ' installed plugin(s):').white
				console.log (active.length + ' active plugin(s)').green
				for name in active
					console.log '- ' + name
				console.log (inactive.length + ' inactive plugin(s)').yellow
				for name in inactive
					console.log '- ' + name

		if args[0] == 'uninstall'
			if options.help
				@help('uninstall')
			else
				args.shift()
				plugin_name = ""
				for elt in args
					if plugin_name != ""
						plugin_name += " "
					plugin_name += elt
				scaffolding.plugins.uninstall(plugin_name)

		chainPluginsInstall = (plugin_names) ->
			promise = undefined
			for name in plugin_names
				do (name) ->
					if not promise?
						promise =  scaffolding.plugins.install(name, process.cwd())
					else
						promise = promise.then () ->
							return scaffolding.plugins.install(name, process.cwd())
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

		if args[0] is 'install'
			if options.help
				@help('install')
			else
				plugin_repo = args[1]
				if plugin_repo?
					scaffolding.plugins.install(plugin_repo, process.cwd())
						.then () ->
							scaffolding.compile()
						.then () ->
							console.log 'Done'
				else
					plugin_names = scaffolding.plugins.info.getActive()
					chainPluginsInstall plugin_names
			
		if args[0] is 'create'
			if options.help
				@help('create')
			else
				force = options.force
				save = not options.inactive
				name = args[1]
				if name
					scaffolding.plugins.create(name, force, save)
						.then () ->
							defer.resolve()
						.fail () ->
							defer.reject()
				else
					defer.reject 'Error'.red + ': '

		if args[0] is 'activate'
			if options.help || args.length != 2
				@help('activate')
			else
				scaffolding.plugins.activate(args[1])

		if args[0] is 'deactivate'
			if options.help || args.length != 2
				@help 'deactivate'
			else
				scaffolding.plugins.deactivate(args[1])

		chainPluginsUpdate = (plugin_names) ->
			for name in plugin_names
				scaffolding.plugins.update(name)
					.then () ->
						console.log "THEN name", name
					.fail (e) ->
						console.log 'ERROR'.red, e.message.yellow

		if args[0] is 'update'
			if options.help
				@help('update')
			else
				name = args[1]
				if name
					if scaffolding.plugins.info.isActive(name)
						scaffolding.plugins.update(name)
							.then () ->
								console.log "THEN name", name
								main_defer.resolve()
							.fail (e) ->
								console.log 'ERROR'.red, e.message.yellow
								main_defer.reject()
					else
						console.log "The plugin you want to update is not present in \'plugins.json\'."
				else
					plugin_names = scaffolding.plugins.info.getActive()
					chainPluginsUpdate plugin_names

		return main_defer.promise

