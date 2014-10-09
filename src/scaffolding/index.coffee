# options:
# opts.console (true/false)
module.exports = (opts) ->

	opts = opts || {}

	scaffolding_env = {
		debug: () ->
			if (opts.console)
				console.log.apply null, arguments
			else
				return
		
	}

	scaffolding_env.plugins = require('./plugins')(scaffolding_env)
	scaffolding_env.init = require('./init')(scaffolding_env)

	scaffolding_env




	
