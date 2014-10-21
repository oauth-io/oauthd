module.exports = (env) ->
	create: require('./create')(env)
	install: require('./install')(env)

	info: require('./info')(env)
	uninstall: require('./uninstall')(env)
	activate: require('./activate')(env)
	deactivate: require('./deactivate')(env)
	git: (plugin_name, fetch) ->
		require('./git')(env, plugin_name, fetch)
	update: require('./update')(env)
	
