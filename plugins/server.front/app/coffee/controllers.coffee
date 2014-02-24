
LogoutCtrl = ($location, UserService, MenuService) ->
	UserService.logout()
	document.location.reload()

###########################
# Landing page Controller #
###########################
IndexCtrl = ($scope, $rootScope, $http, $location, UserService, MenuService) ->
	MenuService.changed()
	# if UserService.isLogin()
	# 	$location.path '/key-manager'

	$scope.selectedProvider = 'facebook'
	$scope.userFormTemplate = '/templates/partials/userForm.html'
	$scope.providers = [
		"facebook"
		"twitter"
		"google"
		"github"
		"stackexchange"
		"soundcloud"
		"youtube"
		"tumblr"
		"instagram"
		"linkedin"
		"deezer"
	]

	$scope.demoTwiConnect = () ->
		OAuth.initialize window.demoKey
		OAuth.popup 'twitter', (err, res) ->
			if err
				alert JSON.stringify err
				return
			res.get('/1.1/account/verify_credentials.json').done (data) ->
				alert 'Hello ' + data.name

	$scope.demoFbConnect = () ->
		OAuth.initialize window.demoKey
		OAuth.popup 'facebook', (err, res) ->
			if err
				alert JSON.stringify err
				return
			res.get('/me').done (data) ->
				alert 'Hello ' + data.name

	$scope.providerClick = (provider) ->
		$scope.selectedProvider = provider



#################################
# Validate account email + pass #
#################################
ValidateCtrl = ($rootScope, $timeout, $scope, $routeParams, MenuService, UserService, $location, $cookieStore) ->
	#MenuService.changed()
	#if UserService.isLogin()
	#	$location.path '/key-manager'
	# console.log "start isValidable"
	UserService.isValidable $routeParams.id, $routeParams.key, ((data) ->
		# console.log "check if validable", data
		$location.path '/404' if not data.data.is_validable and not data.data.is_updated

		if UserService.isLogin() and data.data.is_updated
			$rootScope.me.profile.mail = $rootScope.me.profile.mail_changed
			$rootScope.me.profile.mail_changed = null
			$rootScope.me.validated = '1'
			$location.path '/account'
		else if data.data.is_validable
			# $location.path '/signin'
			$scope.user =
				id: $routeParams.id
				key: $routeParams.key
				mail: data.data.mail
			UserService.validate $scope.user.id, $scope.user.key, ((data) ->
				$rootScope.me.profile.validated = "1"
				$timeout (->
					$rootScope.accessToken = $cookieStore.get 'accessToken'
					$location.path '/key-manager'
					$scope.$apply()
				), 5000
			), (error) ->
		else if not data.data.is_validable
			$location.path '/404'
	), (error) ->
		$location.path '/404'

NotificationCtrl = ($scope, NotificationService) ->
	$scope.notifications = NotificationService.list()

UserFormCtrl = ($scope, $rootScope, $timeout, $http, $location, UserService, MenuService, $routeParams) ->
	MenuService.changed()
	if UserService.isLogin()
		$location.path '/key-manager'

	$('#socialConnect img').tooltip()

	if not $scope.info
		if document.location.hash.match /^#err=./
			$scope.info =
				status: 'error'
				message: (document.location.hash.match /^#err=(.+)$/)[1]
		$scope.info =
			status: ''
			message: ''

	if not $scope.signup
		$scope.signup =
			status:''
			message:''

	me =
		'facebook':
			url: '/me'
			name: 'name'
			mail: 'email'
		'twitter':
			url: '/1.1/account/verify_credentials.json'
			name: 'name'
		'google':
			url: '/oauth2/v1/userinfo'
			name: 'name'
			mail: 'email'
		'linkedin':
			url: '/v1/people/~:(id,email-address,first-name,last-name,headline)?format=json'
			name: ['firstName', 'lastName']
			mail: 'emailAddress',
			company: 'headline'
		'github':
			url: '/user'
			name: 'name'
			company: 'company'
			mail: 'email'
		'vk':
			url: '/method/getProfiles'
			name: ['first_name', 'last_name']
			path: 'response/0'
	$scope.hidePopup = -> $('.modal-backdrop').fadeOut 'fast'
	$scope.socialSignin = (provider) ->
		OAuth.initialize window.loginKey
		OAuth.popup provider, cache: true, (err, res) ->
			return false if err
			UserService.loginOAuth {
				access_token: res.access_token
				oauth_token: res.oauth_token
				oauth_token_secret: res.oauth_token_secret
			}, provider, ((path) ->
				$location.path '/key-manager'
			), (error) ->
				$scope.provider = provider
				$('#error-social').modal('show')
				return false

	$scope.connected = false

	$scope.finalize = ->
		$scope.loading = true

		$scope.canSignin = $scope.needEmail = $scope.success = false
		UserService.signupOAuth $scope.user, $scope.social, ((data) ->
			#console.log data.validated, not data.validated
			$scope.notValidated = not data.data.validated
			$scope.success = true
			$scope.loading = $scope.needEmail = false
		), (error) ->
			if error.message == "This email already exists"
				$scope.canSignin = $scope.success = false
				$scope.emailMessage = 2
				$scope.needEmail = true
			else if error.message == "This account is already linked to a user"
				$scope.canSignin = true
				$scope.needEmail = $scope.success = false
			else
				$scope.canSignin = $scope.success = false
				$scope.emailMessage = 1
				$scope.needEmail = true
			$scope.loading = false

	$scope.socialSignup = (provider) ->
		OAuth.initialize window.loginKey
		$scope.provider = provider
		OAuth.popup provider, cache: true, (err, res) ->
			return false if err
			res.get(me[provider].url).done (data)->

				if me[provider].path
					for eltname in me[provider].path.split '/'
						data = data[eltname]
				if Array.isArray me[provider].name
					name = (data[a] for a in me[provider].name).join ' '
					$scope.user.name = name
				else
					$scope.user.name = data[me[provider].name]
				$scope.user.mail = data[me[provider].mail]
				$scope.user.company = data[me[provider].company]

				$scope.social =
					provider: provider
					token: res.access_token
					oauth_token: res.oauth_token
					oauth_token_secret: res.oauth_token_secret
				$scope.$apply()

				$('#signup-modal').modal('show')
				$scope.finalize()
					#check if user exists
						#popup "connect me with {{provider}}"
					#popup "email" if not email verified in data
						#signup
							#popup email if email already taken
							#popup success -> Go to your dashboard (signin)

	if $routeParams.provider and $location.path().substr(0, 7) == '/signup'
		$scope.socialSignup $routeParams.provider
		$('.modal-backdrop').hide()

	if $routeParams.provider and $location.path().substr(0, 7) == '/signin'
		$scope.socialSignin $routeParams.provider
		$('.modal-backdrop').hide()

	$scope.signinSubmit = ->

	$scope.signupSubmit = ->
		#verif field
		UserService.register $scope.user, ((data) ->
			$scope.signupInfo =
				status: 'success'
		), (error) ->
			$scope.signupInfo =
				status: 'error'
				message: error.message

	$scope.userForm =
		template: "/templates/partials/userForm.html"
		mode: "Sign up"
		switchButtonText: "I already have an account !"
		pass:
			hide: false
		submit: ->

			$scope.info =
				status: ''
				message: ''
			$scope.signup =
				status: ''
				message: ''

			if $scope.userForm.mode == "Sign in"

				#signin
				UserService.login {mail:$('#mail').val(), pass:$('#pass').val()}, ((path)->
					$(window).off()
					$(document).off()
					$location.ga_skip = true;
					$location.path path
					# document.location.href = '/#' + path
					# document.location.reload()
				), (error) ->
					$scope.info =
						status: 'error'
						message: error?.message || 'Wrong email or password'

			else if $scope.userForm.mode == "Sign up"
				#signup
				UserService.register $('#mail').val(), ((data) ->
					$scope.signupInfo =
						status: 'success'
				), (error) ->
					$scope.signupInfo =
						status: 'error'
						message: error.message
			else
				#lost password
				UserService.lostPassword $('#mail').val(), ((data) ->
					$scope.info =
						status: 'info'
						message: 'We have sent password reset instructions to your email address'
				), (error) ->
					$scope.info =
						status: 'error'
						message: error.message


	if $location.path() == "/signin"
		$scope.userForm.mode = "Sign in"

	$scope.user =
		mail: ""
		pass: ""

	#change mode in User Form
	$scope.$watch 'userForm.mode', (newValue, oldValue) ->
		if newValue == 'Lost password'
			$scope.userForm.pass.hide = true
			$scope.userForm.switchButtonText = "I already have an account!"
		else if newValue == 'Sign up'
			$scope.userForm.pass.hide = true
			$scope.userForm.switchButtonText = "I already have an account!"
		else if newValue == 'Sign in'
			$scope.userForm.pass.hide = false
			$scope.userForm.switchButtonText = "I don't have an account yet!"


	#click lost password link
	$scope.lostPasswd = ->
		$scope.userForm.mode = "Lost password"
		$scope.info.status = ''

	#click cancel lost password
	$scope.cancelLostPasswd = ->
		$scope.userForm.mode = "Sign in"
		$scope.info.status = ''

	#click switch button (signin / signup)
	$scope.switchButton = ->
		if $scope.userForm.mode == "Sign up"
			$scope.userForm.mode = "Sign in"
		else
			$scope.userForm.mode = "Sign up"
		$scope.info.status = ''
		$scope.signup.status = ''

generalAccountCtrl = ($rootScope, $scope, $timeout, UserService) ->
	connectionCtx = document.getElementById('connectionChart').getContext '2d'
	appsCtx = document.getElementById('appsChart').getContext '2d'
	providersCtx = document.getElementById('providersChart').getContext '2d'

	drawChart = ->
		getColor = (ratio)->
			if ratio > 0.66
				return '#F7464A'
			else if ratio > 0.33
				return '#ffb554'
			else
				return '#3ebebd'

		connectionData = [
			value: $rootScope.me.totalUsers
			color: getColor $rootScope.me.totalUsers / $rootScope.me.plan.nbUsers
		,
			value: $rootScope.me.plan.nbUsers - $rootScope.me.totalUsers
			color: '#EEEEEE'
		]
		connectionData[1].value = 0  if connectionData[1].value < 0
		connectionChart = new Chart(connectionCtx).Doughnut(connectionData)

		if $rootScope.me.plan.nbApp != 'unlimited'
			appsData = [
				value: $rootScope.me.apps.length
				color: getColor $rootScope.me.apps.length / $rootScope.me.plan.nbApp
			,
				value: $rootScope.me.plan.nbApp - $rootScope.me.apps.length
				color: '#EEEEEE'
			]
			appsData[1].value = 0  if appsData[1].value < 0
			appsChart = new Chart(appsCtx).Doughnut(appsData)

		if $rootScope.me.plan.nbProvider != 'unlimited'
			providersData = [
				value: $rootScope.me.keysets.length
				color: getColor $rootScope.me.keysets.length / $rootScope.me.plan.nbProvider
			,
				value: $rootScope.me.plan.nbProvider - $rootScope.me.keysets.length
				color: '#EEEEEE'
			]
			providersData[1].value = 0  if providersData[1].value < 0
			providersChart = new Chart(providersCtx).Doughnut(providersData)

	$rootScope.$watch 'loading', (newval, oldval) -> drawChart() if newval == false

SettingsCtrl = ($scope, UserService) ->

UserProfileCtrl = ($rootScope, $scope, $routeParams, $location, $timeout, MenuService, UserService, AppService) ->
	MenuService.changed()
	if not UserService.isLogin()
	 	$location.path '/'

	$scope.changeTab = (tab) ->
		if tab == 'payment'
			$scope.loading = true
			$scope.subscriptions = null
			UserService.getSubscriptions (success) ->
				$scope.subscriptions = success.data.subscriptions
				$scope.loading = false
			, (error) ->
				$scope.loading = false
				console.log error

		$scope.accountView = '/templates/partials/account/' + tab + '.html'
		$scope.tab = tab

	$scope.changeTab 'general'
	$scope.sync = {}
	$scope.syncProvider = (provider)->
		OAuth.initialize window.loginKey
		OAuth.popup provider, (err, success) =>
			return null if err
			tokens =
				token: success.access_token
				oauth_token: success.oauth_token
				oauth_token_secret: success.oauth_token_secret

			UserService.sync provider, tokens, ->
				$scope.sync[provider] = true

	UserService.getSync (providers) ->
		$scope.sync = {}
		$scope.sync[provider] = true for provider in providers.data
		$scope.user = $rootScope.me.profile

	$scope.changeEmailState = false
	$scope.emailSent = false
	$scope.updateDone = false

	$scope.changeEmail = ->
		$scope.changeEmailState = true
		$('#email-input').removeAttr('disabled')

	$scope.cancelEmailUpdate = ->
		UserService.cancelUpdateEmail ((success) ->
			$rootScope.me.profile.email_changed = null
		), (error) ->

	$scope.changePasswordButton = ->
		$scope.accountView = '/templates/partials/account/update_password.html'

	$scope.cancelChangePasswordButton = ->
		$scope.accountView = '/templates/partials/account/settings.html'

	$scope.updatePassword = (currentPassword, newPassword, newPassword2) ->
		if newPassword is newPassword2
			UserService.updatePassword currentPassword, newPassword, ((success) ->
				$scope.cancelChangePasswordButton()
			), (error) ->
				$scope.errorPassword = error
		else
			$scope.errorPassword =
				status: "fail"

	$rootScope.$watch 'loading', (newval) ->
		if newval == false
			$scope.user = Object.clone $rootScope.me.profile

	$scope.updateEmail = ->
		UserService.updateEmail $scope.user.mail, ((success) ->
			$('#email-input').attr('disabled', 'disabled')
			$scope.changeEmailState = false
			$rootScope.me.profile.mail_changed = $scope.user.mail
			$scope.user.mail = $rootScope.me.profile.mail
		), (error) ->
			if error.message is "Your email has not changed"
				$('#email-input').attr('disabled', 'disabled')
				$scope.changeEmailState = false


	$scope.update = ->
		$scope.updateDone = false
		UserService.update $scope.user, (success) ->
			$rootScope.me.profile.name = success.data.name
			$scope.updateDone = true
			$rootScope.me.profile.location = success.data.location
			$rootScope.me.profile.company = success.data.company
			$rootScope.me.profile.website = success.data.website
		, (error) ->
			$scope.error =
				state : true
				message : error.message

	$scope.onDismiss = ->
		$scope.error =
			state : false


ProviderCtrl = (MenuService, $filter, $scope, $rootScope, ProviderService, $timeout) ->
	MenuService.changed()
	ProviderService.list (json) ->
		$scope.providers = (provider.provider for provider in json.data).sort()
		$rootScope.providers_name = {} if not $rootScope.providers_name
		$rootScope.providers_name[provider.provider] = provider.name for provider in json.data
		$scope.providers_name = $rootScope.providers_name
		$scope.filtered = $filter('filter')($scope.providers, $scope.query)

		top10 = [
			"facebook"
			"twitter"
			"github"
			"linkedin"
			"dropbox"
			"instagram"
			"google"
			"youtube"
			"foursquare"
			"soundcloud"
		]

		for i in top10
			$scope.providers.remove i

		$scope.providers.add top10, 0

		$scope.pagination =
			nbPerPage: 15
			nbItems: $scope.providers.length
			current: 1
			max: 5

		$scope.queryChange = (query)->
			$timeout (->
				$scope.filtered = $filter('filter')($scope.providers, query)
				$scope.pagination.nbItems = $scope.filtered.length
				$scope.pagination.current = 1
			), 0

WishlistCtrl = ($filter, $scope, WishlistService, $timeout, MenuService) ->
	MenuService.changed()

	WishlistService.list (json) ->

		$scope.providers = json.data
		$scope.filtered = $filter('filter')($scope.providers, $scope.query)

		$scope.pagination =
			nbPerPage: 15
			nbItems: $scope.providers.length
			current: 1
			max: 5

		$scope.queryChange = (query)->

			$timeout (->
				$scope.filtered = $filter('filter')($scope.providers, query)
				$scope.pagination.nbItems = $scope.filtered.length
				$scope.pagination.current = 1
			), 0

	$scope.add = (query) ->

		$scope.info =
			state: false

		$scope.error =
			state : false

		providerPattern = /// ^
			([\w]+)
			{2,15}
			$ ///i

		if not query? or query?.name.length < 2 or !query?.name.match providerPattern
			$scope.error =
				state : true
				message: 'Please, enter a valid provider (2 characters minimum)'
			return

		WishlistService.add query.name, (success) ->

			$scope.info =
				state: true
				message: "Thanks for your contribution !"

			if success.data.updated?
				for i of $scope.providers
					if $scope.providers[i].name == success.data.name
						$scope.providers[i].status = success.data.status
						$scope.providers[i].count = success.data.count
						return
			else
				$scope.providers.push(success.data)
				$scope.filtered = $filter('filter')($scope.providers, success.data.name)

		, (error) ->
			$scope.error =
				state: true
				message: error.message

##############################
# API KEY MANAGER CONTROLLER #
##############################
ApiKeyManagerCtrl = ($scope, $routeParams, $timeout, $rootScope, $location, UserService, $http, MenuService, KeysetService, AppService, ProviderService) ->
	MenuService.changed()
	if not UserService.isLogin()
		$location.path '/signin'

	$rootScope.providers_name = {} if not $rootScope.providers_name
	$scope.providers_name = $rootScope.providers_name
	$scope.keySaved = false
	$scope.createKeyProvider = 'facebook'
	$scope.createKeyTemplate = "/templates/partials/create-key.html"
	$scope.createAppTemplate = "/templates/partials/create-app.html"
	$scope.providersTemplate = "/templates/partials/providers.html"
	$scope.createKeyLastStepTemplate = "/templates/partials/create-key-laststep.html"


	$scope.cancelCreateKey = ->
		if $scope.createKeyStep <= 2
			if $scope.isDropped and $scope.createKeyExists
				app = $rootScope.me.apps.find ((n) ->
					return n.key == $scope.createKeyAppKey
				)
				if app?.keysets?.length > 0
					app.keysets.removeAt(app.keysets.length - 1)
			$scope.$broadcast 'btHide'
		else
			$scope.createKeyStep--


	$scope.scopeSelect =
		escapeMarkup: (m) ->
			return m

	$scope.startDrag = (a, b, c, d)->
		$('.col-lg-4 .dashboard-sidenav li').css('z-index', 10000)

	$scope.stopDrag = (a) ->
		$('.col-lg-4 .dashboard-sidenav li').css('z-index', 0)

	$scope.modifyType = (a) ->
		$scope.createKeyType = a

	$scope.createKeySubmit = ->

		provider = $scope.createKeyProvider

		$rootScope.error =
			state : false
			message : ''
			type  : ''
		if $scope.createKeyStep == 3

			# alert $scope.createKeyAppKey
			key = $scope.createKeyAppKey
			conf = $scope.createKeyConf
			response_type = $scope.createKeyType

			data = {}
			for field of conf
				if not conf[field].value && (field != 'scope' && field != 'permissions' && field != 'perms') # pas propre
					$rootScope.error.state = true
					$rootScope.error.type = "CREATE_KEY"
					$rootScope.error.message = "#{field} must be set"
					break;
				data[field] = conf[field].value

			#if not $scope.error
			if not $rootScope.error.state
				KeysetService.add key, provider, data, response_type, ((keysetEntry) ->

					app = $rootScope.me.apps.find (n) ->
						return n.key == $scope.createKeyAppKey

					# console.log $scope.apikeyUpdate
					app.keys = {} if not app.keys
					app.response_type = {} if not app.response_type
					app.showKeys = true
					app.response_type[provider] = response_type
					app.keys[provider] = data
					if not $scope.apikeyUpdate
						app.keysets.add provider
						app.keysets.sort()
					$scope.$broadcast 'btHide'
				), (error) ->
					console.log "error", error
			# add key
		else
			$scope.createKeyStep++

		if not app.keysField?[provider]?
			ProviderService.get provider, ((conf) ->
				if not app.keysField?
					app.keysField = {}
				oauth = "oauth1"
				if Object.has conf.data, "oauth2"
					oauth = "oauth2"
				app.keysField[provider] = conf.data[oauth].parameters || {}
				for k,v of conf.data.parameters
					app.keysField[provider][k] = v
				return
			), (error) ->
				alert "oh"

	$scope.$watch "createKeyStep", (newVal, oldVal) ->

		if newVal == 2 or newVal == 1
			$scope.createKeyButton = "Next"
			$scope.createKeyCancel = "Cancel"
			$scope.createKeyBtnClass = "btn btn-success"
		if newVal == 3
			$scope.createKeyButton = "Finish"
			$scope.createKeyCancel = "Back"
			$scope.createKeyBtnClass = "btn btn-primary"


			$http(
				method: "GET"
				url: '/api/providers/' + $scope.createKeyProvider + '/keys.png'
			).success(->
				$scope.createKeyKeysImg = true
			).error(->
				$scope.createKeyKeysImg = false
			)

			$scope.apikeyUpdate = false
			KeysetService.get $scope.createKeyAppKey, $scope.createKeyProvider, ((json) ->
				if json.data?
					$scope.apikeyUpdate = true
					for field of json.data.parameters
						$scope.createKeyConf[field].value = json.data.parameters[field]
					$scope.createKeyType = json.data.response_type
				else
					for field in $scope.createKeyConf
						field.value = ""
					$scope.createKeyType = "token"
			), (error) ->

	$scope.updateAppKey = (key) ->
		$scope.createKeyAppKey = key

	#open key form
	$scope.keyFormOpen = (droppable, helper)->
		if Object.isString droppable
			name = droppable
			key = $rootScope.me.apps[0].key
			$scope.isDropped = false
		else
			name = $('.provider-text', helper.draggable).attr('data-provider')
			$scope.isDropped = true
			key = $(droppable.target).find('.app-public-key').text().trim()

		ProviderService.get name, ((data) =>
			$scope.$broadcast 'btShow'
			$scope.createKeyProvider = name
			$scope.createKeyAppKey = key
			$scope.createKeyHref = data.data.href
			a = $rootScope.me.apps.find (n) ->
				return n.key == $scope.createKeyAppKey

			$scope.createKeyAppName = a.name
			$scope.createKeyStep = 2
			if Object.has data.data, "oauth2"
				$scope.oauthType = "OAuth 2"
				$scope.createKeyConf = data.data.oauth2.parameters || {}
				oauth = "oauth2"
			else
				$scope.oauthType = "OAuth 1.0a"
				$scope.createKeyConf = data.data.oauth1.parameters || {}
				oauth = "oauth1"

			for k,v of data.data.parameters
				$scope.createKeyConf[k] = v

			$http(
				method: "GET"
				url: '/api/providers/' + $scope.createKeyProvider + '/config.png'
			).success(->
				$scope.createKeyConfigImg = true
			).error(->
				$scope.createKeyConfigImg = false
			)

			if not a.keysField?
				a.keysField = {}
			a.keysField[$scope.createKeyProvider] = data.data[oauth].parameters || {}
			for k,v of data.data.parameters
				a.keysField[$scope.createKeyProvider][k] = v

		), (error) ->


ProviderAppKeyCtrl = ($scope, $http, MenuService, UserService, KeysetService, ProviderService, AppService, $timeout, $routeParams, $location) ->
	if not $routeParams.provider
		$location.path '/providers'
	if not $routeParams.app
		$location.path '/providers/' + $routeParams.provider + '/app'

	MenuService.changed()
	$scope.provider = $routeParams.provider
	$scope.state = 3

	$scope.providerTemplate = '/templates/partials/provider/apikey.html'


	$scope.scopeSelect =
		escapeMarkup: (m) ->
			return m


	AppService.get $routeParams.app, ((app) =>
		delete app.data.secret
		$scope.app = app.data
		$scope.app.keysets.sort()
	), (error) ->
		console.log "error", error

	$scope.modifyType = (type) ->
		$scope.createKeyType = type
		


	# createKey saves given keys for the app and provider.
	$scope.createKey = ->
		data = {}
		conf = $scope.parameters
		for field of conf
			if not conf[field].value && (field != 'scope' && field != 'permissions' && field != 'perms') # pas propre
				$rootScope.error.state = true
				$rootScope.error.type = "CREATE_KEY"
				$rootScope.error.message = "#{field} must be set"
				break;
			data[field] = conf[field].value
		KeysetService.add $routeParams.app, $routeParams.provider, data, $scope.createKeyType || 'both', ((keysetEntry) ->
			$location.path '/provider/' + $routeParams.provider + '/app/' + $routeParams.app + '/samples'
		), (error) ->
			console.log "error", error
	##

	ProviderService.get $routeParams.provider, ((provider) ->
		ProviderService.getSettings $routeParams.provider, ((settings) ->
			$scope.providerConf = provider
			$scope.parameters = provider.data.oauth2?.parameters || provider.data.oauth1?.parameters || {}
			$scope.settings = settings
			$scope.key_image = settings.data.settings.copyingKey.image

			for k,v of provider.data.parameters
				$scope.parameters[k] = v

			$http(
				method: "GET"
				url: '/api/providers/' + $scope.provider + '/keys.png'
			).success(->
				$scope.createKeyKeysImg = true
			).error(->
				$scope.createKeyKeysImg = false
			)

			$scope.apikeyUpdate = false
			KeysetService.get $routeParams.app, $routeParams.provider, ((json) ->
				$scope.createKeyType = json.data?.response_type
				if json.data?
					$scope.apikeyUpdate = true
					for field of json.data.parameters
						if not $scope.parameters[field]?
							$scope.parameters[field] = {}
						$scope.parameters[field].value = json.data.parameters[field]
				else
					for field in $scope.parameters
						field.value = ""
			), (error) ->

		), (error) ->
	), (error) ->

ProviderSampleCtrl = ($scope, MenuService, $routeParams, AppService, ProviderService) ->
	if not $routeParams.provider
		$location.path '/providers'

	MenuService.changed()
	$scope.provider = $routeParams.provider
	$scope.state = 4

	$scope.providerTemplate = '/templates/partials/provider/sample.html'
	$scope.loaded_fiddle = true
	$scope.loadedJsFiddle = ->
		$scope.loaded_fiddle = false
		$scope.$apply()

	if $routeParams.app
		AppService.get $routeParams.app, ((app) =>
			delete app.data.secret
			$scope.app = app.data
			$scope.app.keysets.sort()
		), (error) ->
			console.log "error", error

	ProviderService.get $routeParams.provider, ((provider) ->
		ProviderService.getSettings $routeParams.provider, ((settings) ->
			$scope.providerConf = provider
			$scope.settings = settings
			$scope.sample = settings.data.settings.sample
			$scope.provider_name = settings.data.provider.replace /_/g, ' '
		), (error) ->
	), (error) ->

ProviderAppCtrl = ($scope, MenuService, UserService, ProviderService, AppService, $timeout, $routeParams, $location) ->
	if not $routeParams.provider
		$location.path '/providers'

	MenuService.changed()
	$scope.provider = $routeParams.provider
	$scope.state = 2

	$scope.providerTemplate = '/templates/partials/provider/app.html'
	counter = 0

	ProviderService.get $routeParams.provider, ((provider) ->
		$scope.providerConf = provider
	), (error) ->

	UserService.me (success) ->
		$scope.apps = success.data.apps
		for i of success.data.apps
			do (i) ->
				AppService.get $scope.apps[i], ((app) =>
					#console.log app.data
					delete app.data.secret
					$scope.createKeyAppKey = app.data.key if counter == 1
					$scope.apps[i] = app.data
					$scope.apps[i].keysets.sort()
					$scope.apps[i].keys = {}
					$scope.apps[i].response_type = {}
					$scope.apps[i].showKeys = false
				), (error) ->
					console.log "error", error

ProviderPageCtrl = ($scope, MenuService, UserService, ProviderService, AppService, $timeout, $routeParams, $location) ->
	if not $routeParams.provider
		$location.path '/providers'

	MenuService.changed()
	$scope.provider = $routeParams.provider
	$scope.state = 1

	$scope.providerTemplate = '/templates/partials/provider/configure.html'
	$scope.configuration_text_class = 'col-lg-6'

	ProviderService.get $routeParams.provider, ((provider) ->
		ProviderService.getSettings $routeParams.provider, ((settings) ->
			$scope.conf_image = settings.data.settings.createApp.image
			$scope.providerConf = provider
			$scope.settings = settings
			$scope.provider = $routeParams.provider
			$scope.oauthVersion = 2
			$scope.oauthVersion = 1 if typeof $scope.providerConf.data.oauth1 != 'undefined'
			$scope.cors = false
			$scope.cors = true if $scope.providerConf.data.oauth2?.request?.cors
			$scope.revoke = false
			$scope.revoke = true if $scope.providerConf.data.oauth2?.revoke? or $scope.providerConf.data.oauth1?.revoke?
			$scope.refresh = false
			$scope.refresh = true if $scope.providerConf.data.oauth2?.refresh? or $scope.providerConf.data.oauth1?.refresh?
			$scope.provider_name = settings.data.provider.replace /_/g, ' '
		), (error) ->
	), (error) ->


##################
# App controller #
##################
AppCtrl = ($scope, $rootScope, $routeParams, $location, UserService, $timeout, AppService, ProviderService, KeysetService) ->
	if not UserService.isLogin()
		$location.path '/signin'

	serializeObject = (form) ->
		o = {}
		a = form.serializeArray()
		$.each a, ->
			pname = this.name.replace /\[\]/, ''
			if o[pname]?
				o[pname] = [o[pname]] if not o[this.name].push
				o[pname].push this.value || ''
			else
				o[pname] = this.value || ''
		return o

	createDefaultApp = ->
		a =
			name: "Default app"
			domains: ["localhost"]

		AppService.add a

	$scope.callback = '/key-manager'
	$rootScope.$watch 'loading', (newV, old) ->
		if newV == false && $location.path() == '/key-manager' and (not $rootScope.me.apps or $rootScope.me.apps.length == 0)
			createDefaultApp()
		if newV == false && $location.path().substr(0, 11) == '/app-create'
			$scope.callback = '/provider/' + $routeParams.provider + '/app'

	$scope.editMode = false
	$scope.appCreateTemplate = "/templates/partials/create-app.html"

	$scope.createAppForm =
		name: ""
		input: ""
		domains: [
			"localhost"
		]

	$scope.displaySecret = (app, disp) ->
		if not disp
			return (app.secret = undefined)
		AppService.get app.key, (r) ->
			app.secret = r.data?.secret

	$scope.tryAuth = (provider, key) ->
		ProviderService.auth key, provider, (err, res) ->
			$scope.$apply ->
				app = $rootScope.me.apps.find (n) ->
					return n.key == key

				if app.showKeys != provider
					$scope.keyClick provider, app

				if not app.auth?
					app.auth = {}
				app.auth[provider] =
					error: err
					result: res

	$scope.addDomain = ->
		if $scope.createAppForm.input != "" and $scope.createAppForm.domains.indexOf($scope.createAppForm.input) == -1
			$scope.createAppForm.domains.push $scope.createAppForm.input
			$scope.createAppForm.input = ""


	$scope.removeDomain = (name)->
		$scope.createAppForm.domains.remove name


	$scope.createAppSubmit = ()->

		$rootScope.error =
			state : false
			type : ""
			message : ""

		nb_domain = $scope.createAppForm.domains.length

		if nb_domain == 0
			$rootScope.error.state = true
			$rootScope.error.type = "CREATE_APP"
			$rootScope.error.message = "You must specify a name and at least one domain for your application"
			return

		AppService.add $scope.createAppForm, (->
			callback = "/key-manager"
			callback = "/provider/" + $routeParams.provider + '/app' if $routeParams.provider
			$location.path callback
		), (error)->
			# console.log error
			$rootScope.error.state = true
			$rootScope.error.type = "CREATE_APP"
			if error.status == "fail"
				$rootScope.error.message = "You must specify a name and at least one domain for your application"
			else
				$rootScope.error.message = 'You must upgrade your plan to get more apps. <a href="/pricing">Check the pricing</a>'

	setKeysField = (app, provider)->
		if not app.keysField?[provider]?
			ProviderService.get provider, (conf) ->
				if not app.keysField?
					app.keysField = {}
				oauth = "oauth1"
				if Object.has conf.data, "oauth2"
					oauth = "oauth2"
				app.keysField[provider] = conf.data[oauth].parameters || {}
				for k,v of conf.data.parameters
					app.keysField[provider][k] = v

	$scope.keyClick = (provider, app) ->
		if app.showKeys != provider
			if not app.keys[provider]
				KeysetService.get app.key, provider, (data) ->
					setKeysField app, provider
					app.keys[provider] = data.data.parameters
					app.response_type[provider] = data.data.response_type
					app.showKeys = provider
			else
				app.showKeys = provider
		else
			app.showKeys = false
	#edit app
	$scope.editApp = (key)->
		app = $rootScope.me.apps.find (n) ->
			return n['key'] == key

		# console.log key
		clone = Object.clone(app)
		$scope.editMode = clone.key
		$scope.createAppForm =
			name: clone.name
			input: ""
			domains: Array.create clone.domains

	$scope.editAppCancel = ->
		$scope.editMode = false

	$scope.editAppSubmit = (key)->
		nb_domain = $scope.createAppForm.domains.length

		$scope.addDomain()

		if nb_domain == 0
			$rootScope.error.state = true
			$rootScope.error.type = "CREATE_APP"
			$rootScope.error.message = "You must specify a name and at least one domain for your application"
			return

		AppService.edit key, $scope.createAppForm, (->
			app = $rootScope.me.apps.find (n) ->
				return n['key'] == key
			app.domains = Array.create $scope.createAppForm.domains
			app.name = $scope.createAppForm.name
			$scope.editMode = false

		), (error)->
			$rootScope.error.state = true
			$rootScope.error.type = "CREATE_APP"
			$rootScope.error.message = "You must specify a name and at least one domain for your application"

	#remove app
	$scope.removeApp = (key)->
		if confirm('Are you sure you want to remove this application? All API Keys stored will be lost forever!')
			AppService.remove key, (->
				$rootScope.me.apps.remove (n) ->
					return n['key'] == key
				if $rootScope.me.apps.isEmpty()
					# $location.path "/app-create"
					createDefaultApp()
			), (error) ->


	#reset public key
	$scope.resetKeys = (key)->
		if confirm 'Are you sure you want to reset your keys? You\'ll need to update the keys in your application.'
			AppService.resetKey key, (data)->
				app = $rootScope.me.apps.find (n)->
					n.key == key
				app.key = data.data.key
				app.secret = data.data.secret
	#edit key in app
	$scope.keySaved = false
	$scope.editKeyset = (app, provider) ->

		$rootScope.error =
			state : false
			message : ''
			type : ''

		keys = serializeObject $('#appkey-' + app.key + '-' + provider)
		response_type = keys.response_type
		delete keys.response_type
		selector = $('#appkey-' + app.key + '-' + provider + ' select[ui-select2=scopeSelect]')
		select = false
		if selector.length > 0
			select = selector.val()
			keys[selector.attr('name')] = select

		for i of keys
			if not keys[i] && (i != 'scope' && i != 'permissions' && i != 'perms') # pas propre
				$rootScope.error.state = true
				$rootScope.error.type = "CREATE_KEY"
				$rootScope.error.message = "#{i} must be set"
				break;

		if not $rootScope.error.state
			KeysetService.add app.key, provider, keys, response_type, (data)->
				$scope.keySaved = true
				app.editProvider = {}
				$timeout (->
					$scope.keySaved = false
				), 1000

	$scope.removeKeyset = (app, provider)->
		# console.log app, provider
		if confirm "Are you sure you want to delete this API Key ? If this Key is running in production, it could break your app."
			KeysetService.remove app.key, provider, ((data) ->
				app.keysets.remove provider
				delete app.keys[provider]
			), (error) ->
				alert "error"

ContactUsCtrl = ($scope, $rootScope, OAuthIOService, MenuService) ->
	MenuService.changed()
	$scope.sendMail = ->

		$rootScope.error =
			state : false
			type : ''
			message : ''

		$scope.sent = false

		emailPattern = /// ^
		([\w\+.-]+)
		@
		([\w\+.-]+)
		\.
		([a-zA-Z.]{2,6})
		$ ///i

		name = $scope.mailForm.name.$viewValue
		email = $scope.mailForm.mail.$viewValue
		subject = $scope.mailForm.subject.$viewValue
		message = $scope.mailForm.message.$viewValue

		if not name? or name.length == 0
			$rootScope.error.state = true
			$rootScope.error.type = "SEND_MAIL"
			$rootScope.error.message = "Please, enter a name"
			return

		if not email? or !email.match emailPattern
			$rootScope.error.state = true
			$rootScope.error.type = "SEND_MAIL"
			$rootScope.error.message = "Please, enter a valid email"
			return

		if not subject? or subject.length == 0
			$rootScope.error.state = true
			$rootScope.error.type = "SEND_MAIL"
			$rootScope.error.message = "Please, enter a subject"
			return

		if not message? or message.length == 0
			$rootScope.error.state = true
			$rootScope.error.type = "SEND_MAIL"
			$rootScope.error.message = "Please, enter your message"
			return

		options =
			from:
				name: name
				email: email
			subject: subject
			body: message

		OAuthIOService.sendMail options, ((data) ->
			$scope.sent = true
		), (error) ->
			$rootScope.error.state = true
			$rootScope.error.type = "SEND_MAIL"
			$rootScope.error.message = "Service unavailable"

EditorCtrl = ($scope, MenuService, ProviderService) ->
	MenuService.changed()

	$scope.providersDemo = [
		"facebook"
		"twitter"
		"github"
		"linkedin"
		"dropbox"
		"instagram"
		"google"
		"youtube"
		"foursquare"
		"soundcloud"
	]

	$scope.type = "oauth2"
	$scope.conf =
		"name": ""
		"url": ""
		"oauth2":
			"authorize": {}
			"access_token": {}
			"parameters":
				"client_id": "string"
				"client_secret": "string"
				"scope":
					"values": {
					}
					"cardinality": "*"
					"separator": ","

	$scope.addValue = (key, val) ->
		if not $scope.param.values
			$scope.param.values = {}

		$scope.param.values[key] = val
		delete $scope.value

	$scope.removeValue = (key) ->
		delete $scope.param.values[key]
		n = Object.size $scope.param.values
		if n == 0
			delete $scope.param.values

	$scope.addHref = (key, url) ->
		if not $scope.conf.href
			$scope.conf.href = {}

		$scope.conf.href[key] = url
		$scope.hrefkey = ""
		$scope.hrefurl = ""

	$scope.removeHref = (key) ->
		delete $scope.conf.href[key]
		n = Object.size $scope.conf.href
		if n == 0
			delete $scope.conf.href

	$scope.addParameter = () ->
		name = $scope.param.name
		if $scope.param.type == 'string'
			$scope.conf[$scope.type].parameters[name] = "string"
		else
			$scope.conf[$scope.type].parameters[name] =
				values: $scope.param.values
				cardinality: $scope.param.cardinality
				separator: $scope.param.separator
		$scope.param = {}
		$scope.paramForm = false

	$scope.removeParameter = (name) ->
		delete $scope.conf[$scope.type].parameters[name]

	$scope.loadConf = (provider) ->
		ProviderService.get provider, (data) =>
			$scope.conf = data.data
			if data.data.oauth2?
				$scope.type = "oauth2"
			else
				$scope.type = "oauth1"

	$scope.getParamType = (key) ->
		if $scope.conf[$scope.type].parameters[key] == "string" || $scope.conf[$scope.type].parameters[key].type == "string"
			return "string"
		else
			return "object"


	$scope.removeQuery = (key, type) ->
		delete $scope.conf[$scope.type][type].query[key]
		n = Object.size $scope.conf[$scope.type][type].query
		if n == 0
			delete $scope.conf[$scope.type][type]['query']

	$scope.addQuery = (type) ->
		if type == 'authorize'
			key = $scope.key2
			val = $scope.val2
			$scope.key2 = ''
			$scope.val2 = ''
		else if type == 'request_token'
			key = $scope.key1
			val = $scope.val1
			$scope.key1 = ''
			$scope.val1 = ''
		else if type == 'access_token'
			key = $scope.key3
			val = $scope.val3
			$scope.key3 = ''
			$scope.val3 = ''

		# alert type + ' ' + $scope.type
		if not $scope.conf[$scope.type][type]? or $scope.conf[$scope.type][type] is ""
			$scope.conf[$scope.type][type] = {query:{}}
		if not $scope.conf[$scope.type][type].query?
			$scope.conf[$scope.type][type].query = {}

		$scope.conf[$scope.type][type].query[key] = val

	$scope.oauthType = () ->
		if $scope.type is "oauth1"
			type2 = "oauth2"
		else
			type2 = "oauth1"

		$scope.conf[$scope.type] = $scope.conf[type2]
		delete $scope.conf[type2]
		delete $scope.conf[$scope.type].request_token if $scope.type == 'oauth2'
		$scope.conf[$scope.type].request_token = "" if $scope.type == 'oauth1'

DocsCtrl = ($scope, UserService, MenuService, $routeParams, $location) ->
	MenuService.changed()
	if not $routeParams.page
		$scope.page = 'getting-started'
		$scope.docTemplate = "/templates/partials/docs/getting-started.html"
		return

	pages = ['getting-started','tutorial','api','faq','oauthd','security','oauthio_api', 'mobiles']
	if pages.indexOf($routeParams.page) >= 0
		$scope.page = $routeParams.page
		$scope.docTemplate = "/templates/partials/docs/" + $routeParams.page + ".html"
	else
		$location.path '/404'

FeaturesCtrl = (UserService, MenuService) ->
	MenuService.changed()

ImprintCtrl = (MenuService) ->
	MenuService.changed()

TermsCtrl = (UserService, MenuService) ->
	MenuService.changed()

AboutCtrl = (UserService, MenuService) ->
	MenuService.changed()

HelpCtrl = (UserService, MenuService) ->
	MenuService.changed()

NotFoundCtrl = ($scope, $routeParams, UserService, MenuService) ->
	MenuService.changed()
	$scope.errorGif = '/img/404/' + (Math.floor(Math.random() * 2) + 1) + '.gif'

InspectorCtrl = (UserService, ProviderService, AppService, KeysetService, OAuthIOService) ->
	console.log "------------------------------------------------------|\n
| Hacker side - OAuth.io                              |\n
|                                                     |\n
| Type help() to get the list of command available    |\n
|                                                     |\n
| You can directly try OAuth.io SDK                   |\n
|                                                     |\n
| e.g.                                                |\n
| OAuth.popup('facebook', function)                   |\n
|                                                     |\n
| Thanks for trying us! <3                            |\n
------------------------------------------------------|"

	fctAvailable = [
		"provider.list"
		"user.register"
		"user.isLogin"
		"user.logout"
		"user.login"
		"user.me"
		"app.get"
		"app.create"
		"app.update"
		"app.remove"
		"keyset.get"
		"keyset.add"
		"keyset.remove"
		"contact"
	]

	window.provider =
		list: ->
			ProviderService.list ((data) ->
				console.log data
			), (err) ->
				console.log err

	window.user =
		login: (mail, pass) ->
			UserService.login {mail: mail, pass: pass}, ((data) ->
				console.log data
			), (err) -> console.log err
		register: (mail) ->
			UserService.register mail, ((data) ->
				console.log data
			), (err) ->
				console.log err
		isLogin: -> console.log UserService.isLogin()
		me: -> console.log UserService.me((data)-> console.log data)

	window.app =
		get: (publicKey) ->
			AppService.get publicKey, ((data) ->
				console.log data
			), (err) ->
				console.log err
		edit: (publicKey, name, domains) ->
			AppService.edit publicKey, {
				name: name,
				domains: domains
			}, ((data) ->
				console.log data
			), (err) ->
				console.log err
		remove: (publicKey) ->
			AppService.remove publicKey

	window.keyset =
		get: (publicKey, provider) ->
			KeysetService.get publicKey, provider, ((data) ->
				console.log data
			), (err) ->
				console.log err

		add: (publicKey, provider, keys) ->
			KeysetService.add publicKey, provider, keys ((data) ->
				console.log data
			), (err) ->
				console.log err
		remove: (publicKey, provider) ->
			KeysetService.remove publicKey, provider, ((data) ->
				console.log data
			), (err) ->
				console.log err

	window.contact = (from_email, from_name, subject, body) ->
		OAuthIOService.sendMail {
			from:
				mail: from_email,
				name: from_name,
			subject: subject,
			body: body
		}, ((data) ->
			console.log data
		), (err) ->
			console.log err


	window.help = ()->
		# if not fct or not fctAvailable[fct]
		console.log "Help\n
====\n
\n
SDK\n
---\n
\n
OAuth.initialize(publicKey)                    - Initialize the SDK with your key\n
OAuth.popup(provider, callback)                - Authorize yourself to an OAuth provider in popup mode\n
OAuth.redirect(provider, url)                  - Authorize yourself to an OAuth provider in redirect mode\n
\n
API Functions\n
-------------\n
\n
PROVIDER\n
provider.list()                                - Get the list of providers available\n
\n
USER\n
user.register(mail)                            - Sign up to OAuth.io\n
user.login(mail, pass)                         - Connect to your account\n
logout()                                       - Log out\n
user.me()                                      - Retrieve your user data\n
\n
APP\n
app.get(publicKey)                             - Get your app's information based on your app's public key\n
app.create(name, domains)                      - Create an app\n
app.edit(publicKey, data)                      - Edit your app's information\n
app.remove(publicKey)                          - Remove your app (no joke, it's really deleted!)\n
\n
KEYSET\n
keyset.get(publicKey, provider)                - Get the keyset associated with an app and a provider\n
keyset.add(publicKey, provider, keys)			- Add keys associated with an app and a provider\n
keyset.remove(publicKey, provider)             - Remove a keyset (no joke, it's really deleted!)\n
\n
CONTACT US :)\n
contact(from_email, from_name, object, body)   - Get in touch with our team\n
\n
You want to get this API on your own server? https://github.com/oauth-io/oauthd"
		return "200 OK"


PricingCtrl = ($scope, $location, MenuService, UserService, PricingService, CartService) ->

	MenuService.changed()

	$scope.current_plan = null
	$scope.devShow = window.devShow

	PricingService.list (success) ->
		$scope.current_plan = success.data.current_plan
		$scope.plans = success.data.offers
	, (error) ->
		console.log error

	if $location.path() == '/pricing/unsubscribe'
		CartService.get (success) ->
			$scope.cart = success.data
		, (error) ->
			console.log error

	$scope.unsubscribe_confirm = (plan) ->

		$("#unsubscribe_#{plan.id}").hide()

		$("#loader_#{plan.id}").fadeIn 1000, ->
			CartService.add plan, (success) ->
				$location.path "/pricing/unsubscribe" if success
			, (error) ->
				console.log error

	$scope.unsubscribe = ->

		$('#bt-unsubscribe').hide 0, ->
			$('#waiting-unsubscribe').fadeIn(1000)

		PricingService.unsubscribe (success) ->
			$scope.current_plan = null
			$location.path "/pricing" if success
		, (error) ->
			console.log error

	$scope.subscribe = (plan) ->

		$("#purchase_#{plan.id}").hide()

		$("#loader_#{plan.id}").fadeIn 1000, ->

			CartService.add plan, (success) ->
				$location.path "/payment/customer" if success
			, (error) ->
				console.log error

"use strict"
define ["app"], (app) ->
  TestlapinController = ($scope) ->
    $scope.lapin = "Plop lapin"
    return

  app.register.controller "TestlapinController", [
    "$scope"
    TestlapinController
  ]
  return

