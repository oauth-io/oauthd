module.exports = (env) ->
	create: require './create'
	install: require('./install')(env)
	list: require('./list')(env)
	uninstall: require('./uninstall')(env)
	activate: require('./activate')(env)
	deactivate: require('./deactivate')(env)
