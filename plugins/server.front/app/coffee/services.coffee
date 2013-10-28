apiRequest = ($http, $rootScope) -> (url, success, error, opts) ->
	opts ?= {}
	opts.url = "/api/" + url
	if opts.data
		opts.data = JSON.stringify opts.data
		opts.method ?= "POST"
	opts.method = opts.method?.toUpperCase() || "GET"
	opts.headers ?= {}
	if $rootScope.accessToken
		opts.headers.Authorization = "Bearer " + $rootScope.accessToken
	if opts.method is "POST" or opts.method is "PUT"
		opts.headers['Content-Type'] = 'application/json'
	req = $http(opts)
	req.success(success) if success
	req.error(error) if error
	return


app.factory 'OAuthIOService', ($http, $rootScope, $cookieStore) ->
	sendMail: (options, success, error) ->
		$http(
			method: 'POST'
			data:
				name_from: options.from.name
				email_from: options.from.email
				subject : options.subject
				body: options.body
			url: 'auth/contact-us'
		).success(success).error(error)


app.factory 'UserService', ($http, $rootScope, $cookieStore) ->
	$rootScope.accessToken = $cookieStore.get 'accessToken'
	api = apiRequest $http, $rootScope
	return $rootScope.UserService = {
		login: (user, success, error) ->
			authorization = (user.mail + ':' + user.pass).encodeBase64()

			$http(
				method: "POST"
				url: "/auth/token"
				data:
					grant_type: "client_credentials"
				headers:
					Authorization: "Basic " + authorization
			).success((data) ->
				$rootScope.accessToken = data.access_token
				$cookieStore.put 'accessToken', data.access_token

				path = $rootScope.authRequired || '/key-manager'
				success path if success
			).error(error)

		isLogin: -> $cookieStore.get('accessToken')?

		register: (mail, success, error) ->
			api 'users', success, error, data:
				mail:mail

		me: (success, error) ->
			api 'me', success, error

		isValidable: (id, key, success, error) ->
			api "users/" + id + "/validate/" + key.replace(/\=/g, '').replace(/\+/g, ''), success, error

		isValidKey: (id, key, success, error) ->
			api "users/" + id + "/keyValidity/" + key.replace(/\=/g, '').replace(/\+/g, ''), success, error

		validate: (id, key, pass, success, error) ->
			api "users/" + id + "/validate/" + key.replace(/\=/g, '').replace(/\+/g, ''), success, error, data:
				pass:pass

		lostPassword: (mail, success, error) ->
			api "users/lostpassword", success, error, data:mail:mail

		resetPassword: (id, key, pass, success, error) ->
			api "users/resetPassword", success, error, data:
				id: id
				key: key
				pass: pass

		logout: (success) ->
			delete $rootScope.accessToken
			$cookieStore.remove 'accessToken'
			if (success)
				success()
	}


app.factory 'MenuService', ($rootScope, $location) ->
	$rootScope.selectedMenu = $location.path()

	return changed: ->
		p = $location.path()
		if p == '/signin' or p == '/signup' or p == '/help' or p == '/feedback' or p == '/faq' or p == '/pricing'
			$('body').css('background-color', "#d8d8d8")
		else
			$('body').css('background-color', '#FFF')

		$('body > .navbar span, #footer').css('color', '#777777')
		$('#wsh-powered').attr('src', '/img/webshell-logo.png')
		$('body > .navbar li a').css('color', '#777777').css('font-weight', 'normal')

		$rootScope.selectedMenu = $location.path()

app.factory 'ProviderService', ($http, $rootScope) ->
	api = apiRequest $http, $rootScope
	return {
		list: (success, error) ->
			api 'providers', success, error

		get: (name, success, error) ->
			api 'providers/' + name + '?extend=true', success, error

		auth: (appKey, provider, success)->
			OAuth.initialize appKey
			OAuth.popup provider, success
	}

app.factory 'WishlistService', ($http, $rootScope) ->
	api = apiRequest $http, $rootScope
	return {
		list: (success, error) ->
			api 'wishlist', success, error

		add: (name, success, error) ->
			if (name?)
				api "wishlist/add", success, error,
					method: "POST"
					data:
						name: name
	}


app.factory 'AppService', ($http, $rootScope) ->
	api = apiRequest $http, $rootScope
	return {
		get: (key, success, error) ->
			api 'apps/' + key, success, error

		add: (app, success, error) ->
			api 'apps', success, error, data:
				name: app.name
				domains: app.domains

		edit: (key, app, success, error) ->
			api 'apps/' + key, success, error, data:
				name: app.name
				domains: app.domains

		remove: (key, success, error) ->
			api 'apps/' + key, success, error, method:'delete'

		resetKey: (key, success, error) ->
			api 'apps/' + key + '/reset', success, error, method:'post'
	}


app.factory 'KeysetService', ($rootScope, $http) ->
	api = apiRequest $http, $rootScope
	return {
		get: (app, provider, success, error) ->
			api 'apps/' + app + '/keysets/' + provider, success, error

		add: (app, provider, keys, response_type, success, error) ->
			api 'apps/' + app + '/keysets/' + provider, success, error, data:
				parameters: keys
				response_type: response_type

		remove: (app, provider, success, error) ->
			api 'apps/' + app + '/keysets/' + provider, success, error, method:'delete'
	}
