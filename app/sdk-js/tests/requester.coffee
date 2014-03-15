exports.request = (casper, request) ->
	#standard endpoints
		#GET
	casper.then ->
		get_defined = @evaluate( (request)->
			window.__flag = false
			window.__error = undefined
			window.request_result = undefined
			try
				window.res[request.method].apply(@, request.params)
					.done (data) ->
						window.__flag = true
						window.request_result = data
						return
					.fail (error) ->
						window.__error = e
						return
				return true
			catch e
				window.__flag = true
				window.__error = e
				return false
			return
		, request: request)
		return

	casper.waitFor (->
		@getGlobal("__flag") is true
	), ->
		result = @evaluate(->
			window.request_result
		)
		error = @evaluate(->
			window.__error
		)
		@test.assert request.validate(error, result), "Request : " + request.method + " method : got expected result"
		return

	