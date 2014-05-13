exports.initialize = (casper, config) ->
	casper.then () ->
		#Initialize
		init_worked = @.evaluate((config) ->
			try
				window.OAuth.initialize config.appkey
				return true
			catch e
				return false
			return
		,
			config: config
		)
		return