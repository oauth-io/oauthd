popup_gone = false

waitformyselector = (selectors, callback, index) ->
	index = index || 0
	
	@waitForSelector selectors[index], =>
		#Accepting permissions
		@echo "in waitForSelector"
		@fill selectors[index], {}, true
		if (selectors.length > index + 1)
			@wait 5000, =>
				@echo "recursive call"
				waitformyselector.apply @, [selectors, callback, index + 1]
		else
			@wait 5000, =>
				@echo "end callback"
				callback.apply @

exports.tests = (casper, provider, global_conf, utils) ->

	casper.on 'popup.closed', ->
		popup_gone = true

	casper.then ->
		base = this

	casper.then ->
		base = @
		
		#Correct provider
		launch_popup = base.evaluate((provider)->
			window.res = undefined
			window.error = undefined
			try
				popupres = window.OAuth.popup(provider.provider_name)
				popupres.done (res) ->
					window.__flag = true
					window.res = res
					window.callPhantom finished: true
					return true
				popupres.fail ->
					window.__flag = true
					window.error = arguments_
					window.callPhantom finished: true
					return
				return true
			catch e
				window.error = e
				return false
			return
		, {
			provider: provider
		})

		error = base.evaluate (->
				return window.error
			)
		response = base.evaluate (->
				return window.res
			)

		if (casper.cli.options.logall)
			if error
				utils.dump error
			if response
				utils.dump response
		@.test.assert launch_popup, "Popup method : defined and callable"
		return

	casper.waitForPopup new RegExp(provider.domain_regexp), (->
		@test.assertEquals @popups.length, 1, "Popup method : popup showing"

		

		return
	), (->
	), 1000

	casper.wait 5000, ->
		return

	casper.withPopup new RegExp(provider.domain_regexp), ->
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

	

	casper.waitFor (->
			return popup_gone
	), (->
		error = @evaluate (->
				return window.error
			)
		response = @evaluate (->
				return window.res
			)
		if (casper.cli.options.logall)
			if error
				utils.dump error
			if response
				utils.dump response
			@test.assert typeof response == "object" and !error, "Popup response available"
	), (-> return), 20000
