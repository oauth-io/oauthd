
module.exports = (env) ->
	debug = () ->
		if env.config?.debug
			console.log.apply this, arguments
	return debug
