
waitformyselector = (selectors, callback, index) ->
	index = index || 0
	
	@waitForSelector selectors[index], =>
		#Accepting permissions
		@fill selectors[index], {}, true
		if (selectors.length > index + 1)
			@wait 2000, =>
				waitformyselector.call @, selectors, callback, index + 1
		else
			@wait 2000, =>
				callback.apply @

exports.tests = (casper, provider, global_conf, utils) ->
	
	casper.then ->
		@echo "Launching redirect"
		redirect = @evaluate ( (global_conf, provider)->
			try
				window.OAuth.redirect provider.provider_name, global_conf.test_server
				return true
			catch e
				return e
			

			), {
				global_conf: global_conf,
				provider: provider
			}
		@test.assert typeof redirect == "boolean" and redirect == true, "Redirect method present and callable"

	casper.wait 3000, ->
		

	casper.waitForUrl new RegExp(provider.popup_domain), ->
		form_exists = @evaluate ((selector) ->
			__utils__.exists(selector)
		), {
			selector: provider.form.selector
		}
		@test.assert(form_exists, "Provider authentication form present")
		@fill provider.form.selector, provider.form.fields, true

	casper.wait 3000, ->
		@capture("facebookstuff.png")

	casper.then ->
		if (@getCurrentUrl().match(provider.popup_domain))
			waitformyselector.apply @, [provider.form.permissions_buttons, => @echo "Clicked accept permission"]

	casper.waitForUrl  new RegExp(global_conf.urlCallback), ->
		authenticate = @evaluate ( ->
			try 
				window.__callbacked = false
				window.__error = undefined
				window.__result = undefined
				window.OAuth.callback((err, result) ->
					window.__callbacked = true
					if (err)
						window.__error = "HELLO MAN"
					window.__result = result
					window.res = result
				);	
			catch e
				window.__callbacked = true
				window.__error = e
				throw e
			
		)

	casper.waitFor (->
		@getGlobal("__callbacked") is true
	), ->
		authentication_worked = @evaluate ->
			return (window.__error == undefined or window.__error == null) and typeof window.__result == "object"
		error = @evaluate ->
			return window.__error
		if (casper.cli.options.logall)
			utils.dump error
		@test.assert authentication_worked, "Authentication done with callback"
