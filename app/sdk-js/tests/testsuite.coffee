exports.launch = (casper, provider, global_conf) ->
	casper.test.begin provider.test_suite_name, 5, suite = (test) ->
		casper.start ->
			window.__flag = false
			return
		casper.thenOpen "https://oauth.io", ->
			base = this
			#Testing OAuth
			OAuth = base.evaluate(->
				window.OAuth
			)
			base.test.assert OAuth isnt null, "OAuth is defined"
			version = base.evaluate(->
				window.OAuth.getVersion()
			)
			base.test.assert typeof version is "string", "OAuth.version is defined"

		require('./initializer').initialize casper, global_conf
		require("./popup").tests casper, provider, global_conf
		# require("./requests_me").tests casper, provider, global_conf

		for request in provider.requests
			console.log "about to test ", request.method, request.params
			request.provider = provider.provider_name
			require('./requester').request casper, request
		
		casper.run()
		return


