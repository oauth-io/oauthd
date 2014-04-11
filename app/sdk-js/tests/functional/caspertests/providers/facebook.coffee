exports.config = 
	provider_name: "facebook"
	domain: "facebook.com"
	test_suite_name: "Facebook test suite"
	client_id: "1410548105863201"
	client_secret: "54eba50b82226c1609f59d0c82d7b705"
	account:
		# firstname: "Jean-René"
		# lastname: "Dupont"
		name: "Jean-René Dupont"
		email: "jeanrenedupont86@gmail.com"
		password: "jeanrene"
	form:
		selector: "form#login_form"
		fields: {
			email: 'jeanrenedupont86@gmail.com',
			pass: 'jeanrene'
		},
		validate_button: "#u_0_1"
		permissions_buttons: [
			'#platformDialogForm',
			'#platformDialogForm'
		]
	requests: [
					name: "Basic user info through GET"
					method: "get",
					params: ["/me"],
					validate: (error, data)  ->
						return (error == undefined or error == null) and data.first_name == "Jean-René"
				,
					name: "Posting to user's wall"
					method: "post"
					params: 
						[
						    "/me/feed",{
							    data: {message: "Hello everyone :)"}
						    }
						]
					validate: (error, data)  ->
						return not error? and data and typeof data.id == "string"
					export: (databag, error, data) ->
						if data and data.id
							databag.facebookid = data.id
				,
					name: "Deleting previously posted message"
					method: "del"
					params: (databag) ->
						return ["/" + databag.facebookid]
					validate: (error, data) ->
						return not error? and data == true
				,
					name: "Revoking permissions"
					method: "del"
					params: (databag) ->
						return ["/me/permissions"]
					validate: (error, data) ->
						return not error? and data == true
	]