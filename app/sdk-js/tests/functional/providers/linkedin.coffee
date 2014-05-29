exports.config = 
	provider_name: "linkedin"
	domain: "www.linkedin.com"
	test_suite_name: "Linkedin test suite"
	client_id: "77umzpmoio9djg"
	client_secret: "qtFnZDl5F99iY1a5"
	form:
		selector: "form.grant-access"
		fields: {
			session_key: 'jeanrenedupont86@gmail.com',
			session_password: 'jeanrene'
		}
	requests: [
					method: "me",
					params: [],
					validate: (error, data)  ->
						return (error == undefined or error == null) and data.firstname == "Jean-René"
		]