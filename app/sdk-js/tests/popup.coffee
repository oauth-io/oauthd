popup_gone = false

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
		base = this

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
					window.__flag = tr ue
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

	casper.waitForPopup /facebook\.com/, (->
		@test.assertEquals @popups.length, 1, "Popup method : popup showing"

		

		return
	), (->
	), 1000

	casper.wait 5000, ->
		return

	casper.withPopup /facebook\.com/, ->
		@echo "Form loaded"
		#Logging into service
		@fill provider.form.selector, provider.form.fields, true
		@echo "Filled login form and clicked login button, now waiting 5"
		@wait 5000, ->
			if popup_gone
				@echo "Permissions already validated"
			else
				@echo "Going through permissions validation"
				waitformyselector.apply @, [provider.form.permissions_buttons, => @echo "Clicked accept permission"]

	casper.on 'popup.closed', ->
		popup_gone = true

	casper.waitFor (->
		return popup_gone
		), (->
		), (-> return), 20000
