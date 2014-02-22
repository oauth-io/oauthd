refreshSession = ($rootScope) ->
	if $rootScope.accessToken
		date = new Date()
		date.setTime date.getTime() - 86400000
		document.cookie = "accessToken=; expires="+date.toGMTString()+"; path=/"
		date = new Date()
		date.setTime date.getTime() + 3600*36*1000
		expires = "; expires="+date.toGMTString()
		document.cookie = "accessToken=%22"+$rootScope.accessToken+"%22"+expires+"; path=/"
		return

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
	refreshSession $rootScope
	return


app.factory 'OAuthIOService', ($http, $rootScope, $cookieStore) ->
	sendMail: (options, success, error) ->
		$http(
			method: 'POST'
			data:
				name_from: options.from.name
				email_from: options.from.email
				subject: options.subject
				body: options.body
			url: 'auth/contact-us'
		).success(success).error(error)


app.factory 'UserService', ($http, $rootScope, $cookieStore, NotificationService, AppService) ->
	$rootScope.accessToken = $cookieStore.get 'accessToken'
	api = apiRequest $http, $rootScope
	return $rootScope.UserService = {
		logout: ->
			delete $rootScope.accessToken
			$cookieStore.remove 'accessToken'
			OAuth.clearCache(provider) for provider in ['google','facebook','twitter', 'vk', 'linkedin', 'github']
			return false

		initialize: (success, error) ->
			if @isLogin()
				$rootScope.loading = true
				@me ((me) ->
					$rootScope.me =
						plan: me.data.plan
						profile: me.data.profile

					if not $rootScope.me.plan
						$rootScope.me.plan =
							name: "Bootstrap"
							nbUsers: 1000
							nbApp: 2
							nbProvider: 2

					counter = 0
					if me.data.apps.length == 0
						$rootScope.loading = false
						return success() if success
					AppService.loadApps me.data.apps, ->
						if ++counter == me.data.apps.length
							success() if success
				), error


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
				refreshSession $rootScope

				path = $rootScope.authRequired || '/key-manager'
				success path if success
			).error(error)

		loginOAuth: (tokens, provider, success, error) ->
			api 'signin/oauth', ((data) =>
				$rootScope.accessToken = data.data.access_token
				$cookieStore.put 'accessToken', data.data.access_token

				path = $rootScope.authRequired || '/key-manager'
				@initialize()
				success path if success
			), error, data:
				token: tokens.access_token
				oauth_token: tokens.oauth_token
				oauth_token_secret: tokens.oauth_token_secret
				provider: provider

		isLogin: -> $cookieStore.get('accessToken')?

		signupOAuth: (user, social, success, error) ->
			api 'signup/oauth', success, error, data:
				email:user.mail
				name:user.name
				company:user.company
				provider:social.provider
				token:social?.token
				oauth_token:social?.oauth_token
				oauth_token_secret:social?.oauth_token_secret

		register: (user, success, error) ->
			api 'users', success, error, data:
				email:user.mail
				pass:user.pass
				name:user.name
				company:user.company

		me: (success, error) ->
			api 'me', success, error

		getSync: (success, error) ->
			api 'sync/oauth', success, error

		sync: (provider, tokens, success, error) ->
			api 'sync/oauth', success, error, data:
				provider:provider
				token:tokens?.token
				oauth_token:tokens?.oauth_token
				oauth_token_secret:tokens?.oauth_token_secret

		getSubscriptions: (success, error) ->
			api 'me/subscriptions', success, error

		update: (profile, success, error) ->
			api 'me', success, error,
				method: "PUT",
				data:
					profile: profile

		# stats: (success, error) ->
		#	api 'me/stats', success, error

		updateEmail: (email, success, error) ->
			api 'me/mail', success, error,
				method: "PUT",
				data:
					email: email

		cancelUpdateEmail: (success, error) ->
			api 'me/mail', success, error, method: "DELETE"

		updatePassword: (pass, new_pass, success, error) ->
			api 'me/password', success, error,
				method: "PUT",
				data:
					current_password: pass,
					new_password: new_pass


		createBilling: (profile, billing, success, error) ->
			api 'me/billing', success, error,
				method: "POST",
				data:
					profile: profile
					billing: billing

		isValidable: (id, key, success, error) ->
			api "users/" + id + "/validate/" + key.replace(/\=/g, '').replace(/\+/g, ''), success, error

		isValidKey: (id, key, success, error) ->
			api "users/" + id + "/keyValidity/" + key.replace(/\=/g, '').replace(/\+/g, ''), success, error

		validate: (id, key, success, error) ->
			api "users/" + id + "/validate/" + key.replace(/\=/g, '').replace(/\+/g, ''), success, error, method:'POST'

		lostPassword: (mail, success, error) ->
			api "users/lostpassword", success, error, data:mail:mail

		resetPassword: (id, key, pass, success, error) ->
			api "users/resetPassword", success, error, data:
				id: id
				key: key
				pass: pass
	}

app.factory 'NotificationService', ($rootScope) ->
	$rootScope.notifications = []
	return {
		push: (notif) ->
			notif.pop = false
			notif.href = '#' if not notif.href
			$rootScope.notifications.push notif
		list: () ->
			return $rootScope.notifications
		clear: () ->
			$rootScope.notifications = []
		open: () ->
			modalInstance = $modal.open
				templateUrl: '/templates/partials/notifications.html'
				controller: NotificationCtrl
				resolve: {
				}
	}

app.factory 'MenuService', ($rootScope, $location) ->
	$rootScope.selectedMenu = $location.path()

	return changed: ->
		p = $location.path()

		if ['/signin','/signup','/help','/feedback','/faq','/pricing'].indexOf(p) != -1 or p.substr(0, 8) == '/payment'
			$('body').css('background-color', "#FFF")
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

		loadApps: (apps, success, error) ->
			$rootScope.me.apps = []
			$rootScope.me.totalUsers = 0
			$rootScope.me.keysets = []
			for i of apps
				@loadApp apps[i], ((res) ->
					if parseInt(i) + 1 == parseInt(apps.length)
						$rootScope.loading = false
						success() if success
				), error


		loadApp: (key, success, error) ->
			@get key, ((app) =>
				console.log app.data

				app.data.keysets?.sort()
				app.data.keys = {}
				app.data.response_type = {}
				app.data.showKeys = false


				$rootScope.me.keysets = [] if not $rootScope.me.keysets
				$rootScope.me.keysets.add app.data.keysets
				$rootScope.me.keysets = $rootScope.me.keysets.unique()

				@getTotalUsers app.data.key, (res) ->
					app.data.totalUsers = parseInt(res.data) || 0
					$rootScope.me.apps.push app.data
					$rootScope.me.totalUsers += parseInt(res.data) || 0
					success() if success
				, error
			), error

		add: (app, success, error) ->
			api 'apps', ((res) =>
				console.log res.data
				@loadApp res.data.key, success, error
			), error, data:
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

		getTotal: (key, success, error) ->
			api 'users/app/' + key, success, error

		getTotalUsers: (key, success, error) ->
			api 'users/app/' + key + '/users', success, error

		# stats: (key, provider, success, error) ->
		# 	api 'apps/' + key + '/stats', success, error
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

		# stats: (app, provider, success, error) ->
		# 	api 'apps/' + app + '/keysets/' + provider + '/stats', success, error
	}

app.factory 'PaymentService', ($rootScope, $http) ->
	api = apiRequest $http, $rootScope
	return {
		process: (paymill, success, error) ->
			api 'payment/process', success, error,
				method:'POST'
				data:
					currency: paymill.currency
					amount: paymill.amount
					token: paymill.token
					offer: paymill.offer
		getCurrentSubscription: (success, error) ->
			api 'subscription/get', success, error
	}

app.factory 'CartService', ($rootScope, $http) ->
	api = apiRequest $http, $rootScope
	return {
		add: (plan, success, error) ->
			api 'payment/cart/new', success, error,
				method:'POST'
				data:
					plan: plan

		get: (success, error) ->
			api 'payment/cart/get', success, error
	}


app.factory 'PricingService', ($rootScope, $http) ->
	api = apiRequest $http, $rootScope
	return {
		list: (success, error) ->
			api 'plans', success, error

		get: (name, success, error) ->
			api "plans/#{name}", success, error

		unsubscribe: (success, error) ->
			api "plan/unsubscribe", success, error,
				method : 'delete'
	}
