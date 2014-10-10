fs = require 'fs'
ncp = require 'ncp'
exec = require('child_process').exec
Q = require('q')
scaffolding = require('../scaffolding')({ console: true })
program = require 'commander'
colors = require 'colors'

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
		if command == 'list'
			console.log 'Usage: oauthd plugins list'
			console.log ''
			console.log 'Lists all installed plugins'.yellow
			console.log ''
			console.log ''
		if command == 'create'
			console.log 'Usage: oauthd plugins create <name>'
			console.log ''
			console.log 'Creates a new plugin in ./plugins/<name> with a basic architecture'
			console.log ''
			console.log 'Options:'
			console.log '    ' + '--force' + '\t\t' + 'Creates the plugin even if another one with same name, overriding it'
			console.log '    ' + '--save' + '\t\t' + 'Adds an entry in plugins.json for the plugin'
		if command == 'install'
			console.log 'Usage: oauthd plugins install [git-repository]'
			console.log ''
			console.log 'Installs a plugin using a git repository. If no argument is given, installs all plugins listed in plugins.json'
			console.log ''
			console.log 'Options:'
			console.log '    ' + '--force' + '\t\t' + 'Installs the plugin even if already present, overriding it'
		if command == 'uninstall'
			console.log 'Usage: oauthd plugins uninstall <name>'
			console.log ''
			console.log 'Uninstalls a given plugin'
	command: () ->
		main_defer = Q.defer()

		if args[0] == 'list'
			if options.help
				@help('list')
			else
				scaffolding.plugins.list()
					.then (plugins_name) ->
						if plugins_name.length is 0
							console.log "There is no plugins installed yet."
						else if plugins_name.length is 1
							console.log "There is one plugin installed: "
						else
							console.log "There are " + plugins_name.length + " plugins installed: "
						for name in plugins_name
							console.log "- '" + name + "'"
					.fail (e) ->
						console.log 'ERROR'.red, e.message.yellow

		if args[0] == 'uninstall'
			args.shift()
			plugin_name = ""
			for elt in args
				if plugin_name != ""
					plugin_name += " "
				plugin_name += elt
			scaffolding.plugins.uninstall(plugin_name)

		chainPluginInstall = (plugins_name) ->
			promise = undefined
			if plugins_name?
				for name in plugins_name
					if (name != "")
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
			plugin_repo = args[1]
			if plugin_repo?
				scaffolding.plugins.install(plugin_repo, process.cwd())
					.then () ->
						scaffolding.compile()
					.then () ->
						console.log 'Done'
			else
				scaffolding.plugins.list()
					.then (plugins_name) ->
						chainPluginInstall plugins_name
					.fail (e) ->
						console.log 'ERROR'.red, e.message.yellow
						console.log 'Error while trying to read \'plugins.json\'. Please make sure it exists and is well structured.'

		if args[0] is 'create'
			options = cli.args[cli.args.length - 1]
			force = options.force
			console.log cli
			name = args[1]
			if name
				scaffolding.plugins.create(name, force)
					.then () ->
						defer.resolve()
					.fail () ->
						defer.reject()
			else
				defer.reject 'Error'.red + ': '

		if args[0] is 'update'
			console.log "update plugins!"

		return main_defer.promise

