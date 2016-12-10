fs = require 'fs'
ncp = require 'ncp'
exec = require('child_process').exec
Q = require('q')
scaffolding = require('../scaffolding')({ console: true })
colors = require 'colors'
sugar = require 'sugar'
async = require 'async'

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
			console.log ''
			console.log 'Options:'
			console.log '    ' + '--verbose'.yellow + '\t' + 'Get more details about update process'
		if command == 'uninstall'
			console.log 'Usage: oauthd plugins ' + 'uninstall <name>'.yellow
			console.log 'Uninstalls a given plugin'
		if command == 'info'
			console.log 'Usage: oauthd plugins ' + 'info [name]'.yellow
			console.log 'If no argument is given, show info of all plugins listed in plugins.json'
			console.log ''
			console.log 'Options:'
			console.log '    ' + '--fetch'.yellow + '\t' + 'Fetch plugins repository, to get updates availability (a bit longer)'

	command: () ->
		main_defer = Q.defer()

		if args[0] == 'list'
			if options.help
				@help('list')
			else
				active = undefined
				inactive = undefined
				installed = undefined
				scaffolding.plugins.info.getActive()
					.then (_active) ->
						active = _active
						return scaffolding.plugins.info.getInactive()
					.then (_inactive) ->
						inactive = _inactive
						return scaffolding.plugins.info.getInstalled()
					.then (_installed) ->
						installed = _installed

						console.log 'This instance has ' + (installed.length + ' installed plugin(s):').white
						console.log ((Object.keys(active)).length + ' active plugin(s)').green
						for name, value of active
							console.log '- ' + name
						console.log (inactive.length + ' inactive plugin(s)').yellow
						for name in inactive
							console.log '- ' + name
			return main_defer.promise

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
			return main_defer.promise

		chainPluginsInstall = (plugins_data) ->
			async.eachSeries plugins_data, (plugin_data, next) ->
				scaffolding.plugins.install(plugin_data, false)
					.then () ->
						next()
					.fail (e) ->
						next()
			, (err) ->
				scaffolding.compile()
					.then () ->
						main_defer.resolve()
					.fail () ->
						main_defer.reject()


		if args[0] is 'install'
			if options.help
				@help('install')
			else
				arg = args[1]
				if arg?
					args = arg.split '#'
					plugin_data = {}
					plugin_data.repository = args[0]
					plugin_data.version = args[1] if args[1]

					scaffolding.plugins.install(plugin_data)
						.then () ->
							scaffolding.compile()
						.then () ->
							console.log 'Done'
						.fail (e) ->
							console.log 'An error occured: '.red + e.message.yellow
				else
					scaffolding.plugins.info.getPluginsJson()
						.then (plugins) ->
							chainPluginsInstall Object.keys(plugins).map (k) -> plugins[k]
						.fail (e) ->
							console.log 'An error occured:', e.message
			return main_defer.promise
			
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

			return main_defer.promise

		if args[0] is 'activate'
			if options.help || args.length != 2
				@help('activate')
			else
				scaffolding.plugins.activate(args[1])
					.then () ->
						console.log 'Successfully activated '.green + args[1].green
					.fail (e) ->
						console.log 'An error occured while activating '.red + args[1].red + ':'.red
						console.log e.message
			return main_defer.promise


		if args[0] is 'deactivate'
			if options.help || args.length != 2
				@help 'deactivate'
			else
				scaffolding.plugins.deactivate(args[1])
					.then () ->
						console.log 'Successfully deactivated '.green + args[1].green
					.fail (e) ->
						console.log 'An error occured while deactivating '.red + args[1].red + ':'.red
						console.log e.message
			return main_defer.promise

		chainPluginsUpdate = (plugins) ->
			plugin_names = Object.keys plugins
			async.eachSeries plugin_names, (name, next) ->
					console.log 'Updating '.white + name.white

					scaffolding.plugins.update(name)
						.then (updated) ->
							if updated
								console.log 'Succesfully updated '.green + name.green
							else
								console.log name + ' already up to date'
							next()
						.fail (e) ->
							console.log 'Error while updating '.red + name.red + ':'.red
							console.log e.message
							next()
							
			, (err) ->
				return main_defer.reject err
				main_defer.resolve()


		if args[0] is 'update'
			if options.help
				@help('update')
			else
				name = args[1]
				if name
					if scaffolding.plugins.info.isActive(name)
						console.log 'Updating '.white + name.white
						plugin_git = scaffolding.plugins.git(name)

						scaffolding.plugins.update(name)
							.then (updated) ->
								if updated
									console.log 'Succesfully updated '.green + name.green + ' to '.green + updated.white
								else
									console.log name + ' already up to date'
								main_defer.resolve()
							.fail (e) ->
								console.log 'Error while updating '.red + name.red + ':'.red
								console.log e.message
								next()
								
					else
						console.log "The plugin you want to update is not present in \'plugins.json\'."
				else
					scaffolding.plugins.info.getPluginsJson()
						.then (plugins) ->
							chainPluginsUpdate plugins
			return main_defer.promise

		doGetInfo = (name, verbose, done, fetch) ->
			scaffolding.plugins.info.getInfo name
				.then (plugin_data) ->
					if not plugin_data?
						return console.log 'No plugin named ' + name + ' was found'
					plugin_data = plugin_data || { name: name } # probably unable to fetch plugin_data
					error  = ''
					if !plugin_data.name?
						return done null, null, true
					title = plugin_data.name?.white + ' '
					scaffolding.plugins.git(plugin_data.name, fetch)
						.then (plugin_git) ->
							text =  plugin_data.description + "\n" if plugin_data.description? && plugin_data.description != ""
							if not text?
								text = 'No description\n'
							plugin_git.getCurrentVersion()
								.then (current_version) ->
									if current_version.type == 'branch'
										plugin_git.getVersionMask()
											.then (mask) ->
												update = ''
												if not current_version.uptodate
													update = ' (' + 'Updates available'.green + ')'

												if mask != current_version.version
													update += ' (plugins.json points \'' + mask + '\')'
												title +=  '(' +current_version.version + ')' + update + ""
												done(title, text)
									else if current_version.type == 'tag_n'
										plugin_git.getVersionMask()
											.then (mask) ->
												plugin_git.getLatestVersion(mask)
													.then (latest_version) ->
														update = ''
														if plugin_git.isNumericalVersion(latest_version)
															if plugin_git.compareVersions(latest_version, current_version.version) > 0
																update = ' (' + latest_version.green + ' is available)'
														else
															update = ' (plugins.json points \'' + latest_version +  '\')'
														title +=  '(' +current_version.version + ')' + update + ""
														done(title, text)
									else if current_version.type == 'tag_a'
										plugin_git.getVersionMask()
											.then (mask) ->
												title +=  '(tag ' + current_version.version + ')'
												if (mask != current_version.version)
													title += ' (plugins.json points \'' + mask +  '\')'
												done(title, text)
									else if current_version.type == 'unversionned'
										title +=  "(unversionned)"
										done(title, text)
								.fail (e) ->
									done(title, text)
						.fail (e) ->
							if verbose
								console.log 'Error with plugin \'' + name.white + '\':', e.message
				.fail (e) ->
					if verbose
						console.log 'Error with plugin \'' + name.white + '\':', e.message
					done(null, null, true)


		if args[0] is 'info'
			if options.help
				@help('info')
			else
				name = args[1]
				
				if name
					doGetInfo name, true, (title, text, e)->
						if title
							console.log title
							console.log text
						if e 
							console.log 'Could not retrieve information for ' + name.white
					, options.fetch
				else
					scaffolding.plugins.info.getActive()
						.then (plugins) ->
							names = Object.keys plugins
							errors_found = false
							async.eachSeries names, (n, next) ->
								doGetInfo n, options.verbose?, (title, text, e) ->
									if e?
										errors_found = errors_found || e
									if title?
										console.log title
										if text?
											console.log text
									if e && options.verbose?
										console.log ''
									next()
								, options.fetch
							, () ->
								if errors_found && not options.verbose?
									console.log 'Could not retrieve all plugins. Use ' + '--verbose'.white + ' for more information.'
								main_defer.resolve()
			return main_defer.promise

		if args[0]?
			console.log 'Unknown command: ' + args[0].yellow
		if not options.help
			@help()
		return main_defer.promise


