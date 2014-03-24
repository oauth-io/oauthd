exports.launch = (casper, provider, global_conf, utils) ->
	casper.test.begin provider.test_suite_name, 5, suite = (test) ->
		casper.start ->
			window.__flag = false
			return
		casper.thenOpen global_conf.test_server, ->
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

		require('./initializer').initialize casper, global_conf, utils
		# require("./popup").tests casper, provider, global_conf, utils
		require("./redirect").tests casper, provider, global_conf, utils
		# require("./requests_me").tests casper, provider, global_conf

		databag = {}
		for request in provider.requests
			request.provider = provider.provider_name
			require('./requester').request casper, request, utils, databag
		
		casper.run()
		return


