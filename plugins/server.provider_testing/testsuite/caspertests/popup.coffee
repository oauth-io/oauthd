popup_gone = false
popup = undefined
local_data = {
	loaded: false,
	url: ""
	page: undefined
}
waitformyselector = (selectors, callback, index) ->
	index = index || 0
	
	selector = {

	}
	if (typeof selectors[index] is 'object')
		selector = selectors[index]
	if (typeof selectors[index] is 'string')
		selector.selector = selectors[index]
		selector.type = 'form'

	@waitForSelector selector.selector, (=>
		#Accepting permissions
		if (@cli.options.screenshots)
			@capture './pictures/' + local_data.provider.provider_name + '_form' + (new Date().getTime()) + '.png'
		if selector.type == 'click'
			@click selector.selector
		if selector.type == 'form'
			@fill selectors[index].selector, {}, true
		if (@cli.options.verbose)
			@echo "validated step " + (index + 1) + " of scope "
		casper.__clearPopup()

		casper.wait 5000, (->
			if (selectors.length > index + 1)
				if (not popup_gone)
					waitformyselector.apply @, [selectors, callback, index + 1]
			else
				if (casper.cli.options.verbose)
					@echo "All saved permission steps done."
					@echo "If next tests don't work, ensure that the test config matches provider instance in oauthd."
				callback.apply @
		), (-> @echo "Timeout on permissions steps (10 seconds)"), 10000
		
	), (-> @echo "Timeout loading permission form"), 5000


exports.tests = (casper, provider, global_conf, utils) ->

	clearPopup = ->
		popup.loaded = false
		popup.page = undefined
		popup.url = ""
	casper.__clearPopup = clearPopup
	local_data.provider = provider
	casper.on 'popup.closed', ->
		popup_gone = true
	casper.on "popup.loaded", (page) ->
		popup = {
			loaded: "true",
			url: page.url,
			page: page
		}

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
				popupres.fail (e) ->
					window.__flag = true
					window.error = e
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

		if (casper.cli.options.verbose)
			if error
				utils.dump error
			if response
				utils.dump response
		
		return

	casper.waitForPopup new RegExp(provider.domain_regexp), (->
		# @test.assertEquals @popups.length, 1, "Popup method : popup showing"
		return
	), (->
	), 1000

	casper.wait 5000, ->
		return

	casper.withPopup new RegExp(provider.domain_regexp), ->
		if (casper.cli.options.verbose)
			@echo "Form loaded"
		#Logging into service
		if (casper.cli.options.screenshots)
			@capture './pictures/' + provider.provider_name + '_form' + (new Date().getTime()) + '.png'
		@fill provider.form.selector, provider.form.fields, true
		if (provider.form.validate_button and @exists(provider.form.validate_button))
			@click provider.form.validate_button
		if (casper.cli.options.verbose)
			@echo "Filled login form and clicked login button, now waiting 5"
		clearPopup()
		casper.waitFor (->
			popup.loaded or popup_gone
		), (->
			if popup_gone
				if (casper.cli.options.verbose)
					@echo "Permissions already validated"
			else
				if (casper.cli.options.verbose)
					@echo "Going through permissions validation"
				if (casper.cli.options.screenshots)
					@capture './pictures/' + provider.provider_name + '_popup_after_form' + (new Date().getTime()) + '.png'
				waitformyselector.apply @, [provider.form.permissions_buttons, => 
					if (casper.cli.options.verbose)
						@echo "Clicked accept permission"
				]
		), (-> @echo "Timeout on authentication form validation (10 seconds)"), 10000

	casper.waitFor (->
			return popup_gone
	), (->
		error = @evaluate (->
				return window.error
			)
		response = @evaluate (->
				return window.res
			)
		if (casper.cli.options.verbose)
			if error?
				@echo "An error occured while getting post OAuth response object"
				utils.dump error
			if response?
				@echo "Received post OAuth response object"
				utils.dump response

		# @test.assert typeof response == "object" and response != null and !error, "Popup response available"
		if (provider.auth?.validate?)
			@test.assert provider.auth.validate(error, response), provider.auth.message || "OAuth response retrieved"
	), (-> 
		@test.assert false, 'Failed OAuth step (timeout)' 
		return
	), 20000
