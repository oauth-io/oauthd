request = require 'request'


exports.setup = (callback) ->

	if not @config.mixpanel?.api_key or not @config.mixpanel.token
		console.log 'Warning: mixpanel plugin is not configured'
		return callback()

	callback()