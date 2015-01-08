module.exports = (env) ->
	env.data = require('./db') env
	env.data.Entity = require('./base-entity') env
	env.data.apps = require('./db_apps') env
	env.data.App = require('./App') env
	env.data.providers = require('./db_providers') env
	env.data.states = require('./db_states') env



