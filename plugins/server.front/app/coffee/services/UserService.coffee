define [
	"app",
	'services/apiRequest',
	'services/NotificationService',
	'services/AppService'
	], (app, apiRequest) ->
		app.register.factory 'UserService', ['$http', '$rootScope', '$cookieStore', 'NotificationService', 'AppService', ($http, $rootScope, $cookieStore, NotificationService, AppService) ->
			$rootScope.accessToken = $cookieStore.get 'accessToken'
			api = apiRequest $http, $rootScope
			return $rootScope.UserService =
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
									$rootScope.loading = false
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
					).success((data) =>
						$rootScope.accessToken = data.access_token
						$cookieStore.put 'accessToken', data.access_token
						refreshSession $rootScope

						path = $rootScope.authRequired || '/key-manager'
						@initialize()
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
						email: user.mail
						name: user.name
						company: user.company
						provider: social.provider
						token: social?.token
						oauth_token: social?.oauth_token
						oauth_token_secret: social?.oauth_token_secret
				register: (user, success, error) ->
					api 'users', success, error, data:
						email: user.mail
						pass: user.pass
						name: user.name
						company: user.company

				me: (success, error) ->
					api 'me', success, error

				getSync: (success, error) ->
					api 'sync/oauth', success, error

				sync: (provider, tokens, success, error) ->
					api 'sync/oauth', success, error, data:
						provider: provider
						token: tokens?.token
						oauth_token: tokens?.oauth_token
						oauth_token_secret: tokens?.oauth_token_secret

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
					api "users/lostpassword", success, error, data: mail: mail

				resetPassword: (id, key, pass, success, error) ->
					api "users/resetPassword", success, error, data:
						id: id
						key: key
						pass: pass
			]
