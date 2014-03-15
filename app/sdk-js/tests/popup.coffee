exports.tests = (casper, provider, global_conf) ->
	casper.then ->
		base = this
		
		#Bad provider error catching -- needs to be new test
	# 	base.evaluate ->
	# 		window.__flag = false
	# 		window.__workedflag = false
	# 		window.OAuth.popup().fail((err) ->
	# 			window.__flag = true
	# 			window.caught_error = err
	# 			return
	# 		).done ->
	# 			window.__flag = true
	# 			window.__workedflag = true
	# 			return

	# 		return

	# 	return

	# casper.waitFor (->
	# 	@getGlobal("__flag") is true
	# ), ->
	# 	result = @evaluate(->
	# 		error: window.caught_error
	# 		passed_in_done: window.__workedflag
	# 	)
	# 	@test.assert result.error and result.passed_in_done is false, "Popup method : failure on wrong provider - promise.fail()"
	# 	return

	casper.then ->
		base = @
		
		#Correct provider
		launch_popup = base.evaluate(->
			window.res = undefined
			window.error = undefined
			try
				popupres = window.OAuth.popup("facebook")
				popupres.done (res) ->
					window.__flag = true
					window.res = res
					window.callPhantom finished: true
					return

				popupres.fail ->
					window.__flag = true
					window.error = arguments_
					window.callPhantom finished: true
					return

				return true
			catch e
				return false
			return
		)
		@.test.assert launch_popup, "Popup method : defined and callable"
		return

	casper.waitForPopup /oauth\.io/, (->
		@test.assertEquals @popups.length, 1, "Popup method : call loaded popup"
		return
	), (->
	), 1000
	casper.then ->
		@echo "Waiting 1 second for facebook form to load"
		return

	casper.wait 1000, ->

	casper.withPopup /oauth\.io/, ->
		@echo "Form loaded"
		@fill provider.form.selector, provider.form.fields, false
		@click provider.form.validate_button
		return

	casper.withPopup /oauth\.io/, ->
		console.log "Filled form and clicked ok."
		return

	casper.wait 5000