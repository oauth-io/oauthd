module.exports = (env) ->
	env.plugins = require('./plugins')(env)
	