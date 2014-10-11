module.exports = (env) ->
	create: require './create'
	install: require('./install')(env)
	update: require('./update')(env)
	info: require('./info')(env)
	uninstall: require('./uninstall')(env)
	activate: require('./activate')(env)
	deactivate: require('./deactivate')(env)
