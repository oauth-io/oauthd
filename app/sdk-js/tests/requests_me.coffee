# To test that part, the variable facebook_res must be set in the window with
# the value returned by a successful popup / callback

exports.tests = (casper, provider, global_conf) ->
	#Testing Me method
	casper.waitFor (->
		@getGlobal("__flag") is true
	), ->
		window.__flag = false
		me_defined = @evaluate(->
			window.__flag = false
			window.me_info = undefined
			try
				window.res.me(["name"])
					.done (data) ->
						window.__flag = true
						window.me_info = data
						return
				return true
			catch e
				return false
			return
		)
		@test.assert me_defined, "Me method : defined and callable"
		return

	casper.waitFor (->
		@getGlobal("__flag") is true
	), ->
		me = @evaluate(->
			window.me_info
		)
		@test.assert me isnt undefined, "Me method : result defined"
		@test.assert me.raw isnt undefined, "Me method : result contains raw"
		return