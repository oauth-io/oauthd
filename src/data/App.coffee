Q = require 'q'

module.exports = (env) ->
	class App extends env.data.Entity
		@prefix: 'a'
		@incr: 'a:i'
		@indexes: {
			'key': 'a:keys'
		}
		# basic props
		@properties: [
			'name'
			'key'
			'secret'
			'owner'
			'domains'
			'providers' # list of keysets
			'date'
			'stored_keysets' # true if using keysets list
		]
		@findByKey: (key) ->
			defer = Q.defer()
			_start = new Date().getTime()
			@findByIndex 'key', key
				.then (app) ->
					defer.resolve app
				.fail (e) ->
					defer.reject new Error 'App not found'
			defer.promise

		prepareResponse: () ->
			response_body = {
				id: @props.key
			}
			for k,v of @provider.props
				response_body[k] = v
			response_body

	App
