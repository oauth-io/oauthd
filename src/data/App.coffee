Q = require 'q'

module.exports = (env) ->
	class Provider extends env.data.Entity
		@prefix: 'a'
		@incr: 'a:i'
		@indexes: {
			'key': 'a:keys'
		}
		@findByKey: (key) ->
			defer = Q.defer()
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

	Provider
