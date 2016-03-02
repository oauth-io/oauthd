
module.exports = (env) ->
	debug = () ->
		if env.config?.debug
			console.log.apply console, arguments
	debug.display = () ->
		console.log.apply console, arguments
	return debug
