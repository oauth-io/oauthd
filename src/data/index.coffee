

module.exports = (env) ->
	env.DAL = {}
	
	require('./db') env
	require('./db_apps') env
	require('./db_providers') env
	require('./db_states') env