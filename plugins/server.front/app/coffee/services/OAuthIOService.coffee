define [], () ->
	OAauthIOService = ($http, $rootScope, $cookieStore) ->
		return sendMail: (options, success, error) ->
			$http(
				method: "POST"
				data:
					name_from: options.from.name
					email_from: options.from.email
					subject: options.subject
					body: options.body
				url: "auth/contact-us"
			).success(success).error error
	return ["$http", "$rootScope", "$cookieStore", OAauthIOService]