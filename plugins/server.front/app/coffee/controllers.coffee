#IndexCtrl = ($scope, $location, UserService, MenuService)->
	#$location.ga_skip = true;
	# if $location.path() == '/'
		# if UserService.isLogin()
		# 	$location.path('/key-manager').replace()
		# else
			# $location.path('/home').replace()


LogoutCtrl = ($location, UserService, MenuService) ->
	$location.ga_skip = true;
	UserService.logout ->
		$location.path '/home'

###########################
# Landing page Controller #
###########################
IndexCtrl = LandingCtrl = ($scope, $rootScope, $http, $location, UserService, MenuService) ->
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


	$scope.demoFbConnect = () ->
		OAuth.initialize window.demoKey
		OAuth.popup 'facebook', (err, res) ->
			if err
				alert JSON.stringify err
				return
			$('#token').html("Your access token:<br/>" + res.access_token).show();
			$('#get-token').hide()

	$scope.providerClick = (provider) ->
		$scope.selectedProvider = provider

#################################
# Reset password 				#
#################################
ResetPasswordCtrl = ($scope, $routeParams, MenuService, UserService, $location) ->

	MenuService.changed()
	if UserService.isLogin()
		$location.path '/key-manager'

	UserService.isValidKey $routeParams.id, $routeParams.key, ((data) ->
		$location.path '/404' if not data.data.isValidKey
	), (error) ->
		$location.path '/404'

	$scope.validateForm = () ->
		$scope.error =
			status: ''
			message: ""

		if not $scope.user?.pass or not $scope.user?.pass2
			return false

		if $scope.user.pass == $scope.user.pass2

			UserService.resetPassword $routeParams.id, $routeParams.key, $scope.user.pass, ((data) ->

				UserService.login {
					mail: data.data.email
					pass: $scope.user.pass
				}, (data) ->
					$location.path '/'

			), (error) ->
				$scope.error =
					status: 'error'
					message: error
		else
			$scope.error =
				status: 'error'
				message: "Password1 != Password2"

#################################
# Validate account email + pass #
#################################
ValidateCtrl = ($rootScope, $scope, $routeParams, MenuService, UserService, $location) ->
	MenuService.changed()
	if UserService.isLogin()
		$location.path '/key-manager'

	UserService.isValidable $routeParams.id, $routeParams.key, ((data) ->
		$location.path '/404' if not data.data.is_validable

		if data.data.is_updated?

			$rootScope.info =
				status : 'info'
				message : 'Your account is updated !'

			$location.path '/signin'

		else if not data.data.is_updated?

		else
			$scope.user =
				id: $routeParams.id
				key: $routeParams.key
				mail: data.data.mail

	), (error) ->
		$location.path '/404'

	$scope.validateForm = () ->
		$scope.error =
			status: ''
			message: ""

		user = $scope.user

		if not user?.pass or not user?.pass2
			return false

		if user.pass == user.pass2
			UserService.validate user.id, user.key, user.pass, ((data) ->
				UserService.login {
					mail: data.data.mail
					pass: user.pass
				}, (data) ->
					$location.path('/app-create')

			), (error) ->
				$scope.error =
					status: 'error'
					message: error
		else
			$scope.error =
				status: 'error'
				message: "Password1 != Password2"

UserFormCtrl = ($scope, $rootScope, $timeout, $http, $location, UserService, MenuService) ->
	MenuService.changed()
	if UserService.isLogin()
		$location.path '/key-manager'

	if not $scope.info
		$scope.info =
			status: ''
			message: ''

	if not $scope.signup
		$scope.signup =
			status:''
			message:''

	$scope.oauth = (provider) ->
		OAuth.initialize 'ZjsbIbKdkuw5fmEkBHDZfUqEadY'
		OAuth.popup provider, (err, success) ->
			console.log err, success

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
				UserService.login $scope.user, ((path)->
					$(window).off()
					$(document).off()
					$location.ga_skip = true;
					document.location.href = '/#' + path
					document.location.reload()
				), (error) ->
					$scope.info =
						status: 'error'
						message: error?.message || 'Wrong email or password'

			else if $scope.userForm.mode == "Sign up"
				#signup
				UserService.register $scope.user.mail, ((data) ->
					$scope.signupInfo =
						status: 'success'
				), (error) ->
					$scope.signupInfo =
						status: 'error'
						message: error.message
			else
				#lost password
				UserService.lostPassword $scope.user.mail, ((data) ->
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

UserProfileCtrl = ($rootScope, $scope, $routeParams, $location, $timeout, MenuService, UserService, AppService) ->
	MenuService.changed()
	if not UserService.isLogin()
	 	$location.path '/'

	UserService.me (success) ->
		# for modal
		$scope.user =
			id : success.data.profile.id
			name : success.data.profile.name
			email : success.data.profile.mail
			location : success.data.profile.location
			company : success.data.profile.company
			website : success.data.profile.website

		# for label
		$scope.id = success.data.profile.id
		$scope.name = success.data.profile.name
		$scope.email = success.data.profile.mail
		$scope.location = success.data.profile.location
		$scope.company = success.data.profile.company
		$scope.website = success.data.profile.website
		$scope.plan =
			name : success.data.plan[0]
			nb_connection : success.data.plan[1]


		$scope.apps = []
		$scope.totalConnections = 0;

		for i of success.data.apps

			AppService.get success.data.apps[i], ((app) ->

				AppService.getTotal app.data.key, (success) ->
					app.data.totalConnections = parseInt(success.data) || 0
					$scope.totalConnections += parseInt(success.data) || 0
				, (error) ->
					console.log error

				$scope.apps.push(app.data)

			), (error) ->
				console.log error

	, (error) ->
		console.log error

	$scope.update = ->

		UserService.update $scope.user, (success) ->
			$scope.id = success.data.id
			$scope.name = success.data.name
			$scope.email = success.data.mail
			$scope.location = success.data.location
			$scope.company = success.data.company
			$scope.website = success.data.website
			$('#modal_edit_infos').modal('hide');
		, (error) ->
			$scope.error =
				state : true
				message : error.message

	$scope.onDismiss = ->

		$scope.error =
			state : false

ProviderCtrl = ($filter, $scope, $rootScope, ProviderService, $timeout) ->
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
			nbPages: Math.ceil($scope.providers.length / 15)
			current: 1
			max: 5

		$scope.queryChange = (query)->
			$timeout (->
				$scope.filtered = $filter('filter')($scope.providers, query)
				$scope.pagination.nbPages = Math.ceil($scope.filtered.length / $scope.pagination.nbPerPage)
				$scope.pagination.current = 1
			), 0

WishlistCtrl = ($filter, $scope, WishlistService, $timeout, MenuService) ->
	MenuService.changed()

	WishlistService.list (json) ->

		$scope.providers = json.data
		$scope.filtered = $filter('filter')($scope.providers, $scope.query)

		$scope.pagination =
			nbPerPage: 15
			nbPages: Math.ceil($scope.providers.length / 15)
			current: 1
			max: 5

		$scope.queryChange = (query)->

			$timeout (->
				$scope.filtered = $filter('filter')($scope.providers, query)
				$scope.pagination.nbPages = Math.ceil($scope.filtered.length / $scope.pagination.nbPerPage)
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
ApiKeyManagerCtrl = ($scope, $timeout, $rootScope, $location, UserService, $http, MenuService, KeysetService, ProviderService) ->
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
				app = $rootScope.apps.find ((n) ->
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

					app = $rootScope.apps.find (n) ->
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
				url: '/img/providers/' + $scope.createKeyProvider + '-keys.png'
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
			key = $rootScope.apps[0].key
			$scope.isDropped = false
		else
			name = $('.provider-text', helper.draggable).attr('data-provider')
			$scope.isDropped = true
			key = $(droppable.target).find('.app-public-key').text().trim()

		ProviderService.get name, ((data) =>
			# console.log "uh?!"
			#$scope.$apply (->

				$scope.$broadcast 'btShow'
				$scope.createKeyProvider = name
				$scope.createKeyAppKey = key
				$scope.createKeyHref = data.data.href
				a = $rootScope.apps.find (n) ->
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
					url: '/img/providers/' + $scope.createKeyProvider + '-config.png'
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

			#), 100
		), (error) ->

##################
# App controller #
##################
AppCtrl = ($scope, $rootScope, $location, UserService, $timeout, AppService, ProviderService, KeysetService) ->
	if not UserService.isLogin()
		$location.path '/signin'


	$scope.loaderApps = true

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

	loadApps = ->
		n = $rootScope.apps.length
		for i of $rootScope.apps
			do (i, n) ->
				AppService.get $rootScope.apps[i], ((app) =>
					$scope.counter++
					#console.log app.data
					delete app.data.secret
					$rootScope.apps[i] = app.data
					$rootScope.apps[i].keysets.sort()
					$rootScope.apps[i].keys = {}
					$rootScope.apps[i].response_type = {}
					$rootScope.apps[i].showKeys = false
					$timeout (->
						if $scope.counter == n
							$scope.loaderApps = false
					), 0
				), (error) ->
					console.log "error", error

	createDefaultApp = ->
		a =
			name: "Default app"
			domains: ["localhost"]

		AppService.add a, ((data)->
			$rootScope.apps = [data.data.key]
			loadApps()
		), (err) ->
			console.log err

	# alert $location.path()
	UserService.me ((me)->
		$rootScope.apps = me.data.apps
		n = $rootScope.apps.length
		$rootScope.noApp = false
		if n == 0
			if $location.path() == '/key-manager'
				# $location.path "/app-create"
				createDefaultApp()
			else
				$rootScope.noApp = true
		$scope.counter = 0
		loadApps()
	), (error) ->
		console.log "error", error


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
				app = $rootScope.apps.find (n) ->
					return n.key == key

				if app.showKeys != provider
					$scope.keyClick provider, app

				if not app.auth?
					app.auth = {}
				app.auth[provider] =
					error: err
					result: res

	$scope.addDomain = ->
		if $scope.createAppForm.input != "" and not $scope.createAppForm.domains.find $scope.createAppForm.input
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
			$location.path "/key-manager"
		), (error)->
			$rootScope.error.state = true
			$rootScope.error.type = "CREATE_APP"
			$rootScope.error.message = "You must specify a name and at least one domain for your application"


	setKeysField = (app, provider)->
		if not app.keysField?[provider]?
			ProviderService.get provider, (conf) ->
				# console.log "#####conf", conf.data
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
		app = $rootScope.apps.find (n) ->
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

		if nb_domain == 0
			$rootScope.error.state = true
			$rootScope.error.type = "CREATE_APP"
			$rootScope.error.message = "You must specify a name and at least one domain for your application"
			return

		AppService.edit key, $scope.createAppForm, (->
			app = $rootScope.apps.find (n) ->
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
				$rootScope.apps.remove (n) ->
					return n['key'] == key
				if $rootScope.apps.isEmpty()
					# $location.path "/app-create"
					createDefaultApp()
			), (error) ->


	#reset public key
	$scope.resetKeys = (key)->
		if confirm 'Are you sure you want to reset your keys? You\'ll need to update the keys in your application.'
			AppService.resetKey key, (data)->
				app = $rootScope.apps.find (n)->
					n.key == key
				app.key = data.data.key
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

		if not message? or message.length == 0
			$rootScope.error.state = true
			$rootScope.error.type = "SEND_MAIL"
			$rootScope.error.message = "Please, enter your message"
			return

		options =
			from:
				name: name
				email: "#{email}"
			subject: "[Contact Us] Mail from oauth.io - #{email} (#{name})"
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

	pages = ['getting-started','tutorial','api','faq','oauthd','security','oauthio_api']
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

	window.contact = (from_email, from_name, object, body) ->
		OAuthIOService.sendMail {
			from:
				mail: from_email,
				name: from_name,
			object: object,
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
	if UserService.isLogin()
		UserService.me (success) ->
			if success.data.plan?
				$scope.current_plan = success.data.plan[2] if success.data.plan[2]?
				$scope.current_plan = success.data.plan[0] if not success.data.plan[2]?
		, (error) ->
			console.log "error", error

	PricingService.list (success) ->
		$scope.plans = success.data
	, (error) ->
		console.log error


	$scope.unsubscribe = ->
		PricingService.unsubscribe (success) ->
			$scope.current_plan = null
		, (error) ->
			console.log error

	$scope.subscribe = (plan) ->

		CartService.add plan, (success) ->
			$location.path "/payment/customer" if success
		, (error) ->
			console.log error

PaymentCtrl = ($scope, $rootScope, $location, $routeParams, UserService, PaymentService, PricingService, MenuService, CartService) ->
	MenuService.changed()

	if not UserService.isLogin()
		$location.path '/signin'
		return

	$scope.countries = [{code : "US", name : "United States"},
						{code : "AL", name : "Albania"},
						{code : "DZ", name : "Algeria"},
						{code : "AD", name : "Andorra"},
						{code : "AO", name : "Angola"},
						{code : "AI", name : "Anguilla"},
						{code : "AG", name : "Antigua and Barbuda"},
						{code : "AM", name : "Armenia"},
						{code : "AZ", name : "Azerbaijan Republic"},
						{code : "AD", name : "Andorra"},
						{code : "AI", name : "Anguilla"},
						{code : "AR", name : "Argentina"},
						{code : "AW", name : "Aruba"},
						{code : "AU", name : "Australia"},
						{code : "AT", name : "Austria"},
						{code : "BS", name : "Bahamas"},
						{code : "BH", name : "Bahrain"},
						{code : "BB", name : "Barbados"},
						{code : "BE", name : "Belgium"},
						{code : "BZ", name : "Belize"},
						{code : "BJ", name : "Benin"},
						{code : "BM", name : "Bermuda"},
						{code : "BT", name : "Bhutan"},
						{code : "BO", name : "Bolivia"},
						{code : "BA", name : "Bosnia and Herzegovina"},
						{code : "BW", name : "Botswana"},
						{code : "BR", name : "Brazil"},
						{code : "VG", name : "British Virgin Islands"},
						{code : "BN", name : "Brunei"},
						{code : "BG", name : "Bulgaria"},
						{code : "BF", name : "Burkina Faso"},
						{code : "BI", name : "Burundi"},
						{code : "KH", name : "Cambodia"},
						{code : "CA", name : "Canada"},
						{code : "CV", name : "Cape Verde"},
						{code : "KY", name : "Cayman Islands"},
						{code : "TD", name : "Chad"},
						{code : "CL", name : "Chile"},
						{code : "C2", name : "China"},
						{code : "CR", name : "Costa Rica"},
						{code : "CO", name : "Colombia"},
						{code : "KM", name : "Comoros"},
						{code : "CK", name : "Cook Islands"},
						{code : "HR", name : "Croatia"},
						{code : "CY", name : "Cyprus"},
						{code : "CZ", name : "Czech Republic"},
						{code : "DK", name : "Denmark"},
						{code : "CD", name : "Democratic Republic of the Congo"},
						{code : "DJ", name : "Djibouti"},
						{code : "DM", name : "Dominica"},
						{code : "DO", name : "Dominican Republic"},
						{code : "EC", name : "Ecuador"},
						{code : "SV", name : "El Salvador"},
						{code : "ER", name : "Eritrea"},
						{code : "EE", name : "Estonia"},
						{code : "ET", name : "Ethiopia"},
						{code : "FK", name : "Falkland Islands"},
						{code : "FO", name : "Faroe Islands"},
						{code : "FM", name : "Federated States of Micronesia"},
						{code : "FJ", name : "Fiji"},
						{code : "FI", name : "Finland"},
						{code : "FR", name : "France"},
						{code : "GF", name : "French Guiana"},
						{code : "PF", name : "French Polynesia"},
						{code : "GA", name : "Gabon Republic"},
						{code : "GM", name : "Gambia"},
						{code : "DE", name : "Germany"},
						{code : "GI", name : "Gibraltar"},
						{code : "GR", name : "Greece"},
						{code : "GL", name : "Greenland"},
						{code : "GD", name : "Grenada"},
						{code : "GP", name : "Guadeloupe"},
						{code : "GT", name : "Guatemala"},
						{code : "GN", name : "Guinea"},
						{code : "GW", name : "Guinea Bissau"},
						{code : "GY", name : "Guyana"},
						{code : "HN", name : "Honduras"},
						{code : "HK", name : "Hong Kong"},
						{code : "HU", name : "Hungary"},
						{code : "IS", name : "Iceland"},
						{code : "IN", name : "India"},
						{code : "ID", name : "Indonesia"},
						{code : "IE", name : "Ireland"},
						{code : "IL", name : "Israel"},
						{code : "IT", name : "Italy"},
						{code : "JM", name : "Jamaica"},
						{code : "JP", name : "Japan"},
						{code : "JO", name : "Jordan"},
						{code : "KZ", name : "Kazakhstan"},
						{code : "KE", name : "Kenya"},
						{code : "KI", name : "Kiribati"},
						{code : "KW", name : "Kuwait"},
						{code : "KG", name : "Kyrgyzstan"},
						{code : "LA", name : "Laos"},
						{code : "LV", name : "Latvia"},
						{code : "LS", name : "Lesotho"},
						{code : "LI", name : "Liechtenstein"},
						{code : "LT", name : "Lithuania"},
						{code : "LU", name : "Luxembourg"},
						{code : "MG", name : "Madagascar"},
						{code : "MW", name : "Malawi"},
						{code : "MY", name : "Malaysia"},
						{code : "MV", name : "Maldives"},
						{code : "ML", name : "Mali"},
						{code : "MT", name : "Malta"},
						{code : "MH", name : "Marshall Islands"},
						{code : "MQ", name : "Martinique"},
						{code : "MR", name : "Mauritania"},
						{code : "MU", name : "Mauritius"},
						{code : "YT", name : "Mayotte"},
						{code : "MX", name : "Mexico"},
						{code : "MN", name : "Mongolia"},
						{code : "MS", name : "Montserrat"},
						{code : "MA", name : "Moroccoupdate"},
						{code : "MZ", name : "Mozambique"},
						{code : "NA", name : "Namibia"},
						{code : "NR", name : "Nauru"},
						{code : "NP", name : "Nepal"},
						{code : "NL", name : "Netherlands"},
						{code : "AN", name : "Netherlands Antilles"},
						{code : "NC", name : "New Caledonia"},
						{code : "NZ", name : "New Zealand"},
						{code : "NI", name : "Nicaragua"},
						{code : "NE", name : "Niger"},
						{code : "NU", name : "Niue"},
						{code : "NF", name : "Norfolk Island"},
						{code : "NO", name : "Norway"},
						{code : "OM", name : "Oman"},
						{code : "PW", name : "Palau"},
						{code : "PA", name : "Panama"},
						{code : "PG", name : "Papua New Guinea"},
						{code : "PE", name : "Peru"},
						{code : "PH", name : "Philippines"},
						{code : "PN", name : "Pitcairn Islands"},
						{code : "PL", name : "Poland"},
						{code : "PT", name : "Portugal"},
						{code : "QA", name : "Qatar"},
						{code : "CG", name : "Republic of the Congo"},
						{code : "RE", name : "Reunion"},
						{code : "RO", name : "Romania"},
						{code : "RU", name : "Russia"},
						{code : "RW", name : "Rwanda"},
						{code : "VC", name : "Saint Vincent and the Grenadines"},
						{code : "WS", name : "Samoa"},
						{code : "SM", name : "San Marino"},
						{code : "ST", name : "São Tomé and Príncipe"},
						{code : "SA", name : "Saudi Arabia"},
						{code : "SN", name : "Senegal"},
						{code : "SC", name : "Seychelles"},
						{code : "SL", name : "Sierra Leone"},
						{code : "SG", name : "Singapore"},
						{code : "SI", name : "Slovenia"},
						{code : "SB", name : "Solomon Islands"},
						{code : "SO", name : "Somalia"},
						{code : "ZA", name : "South Africa"},
						{code : "KR", name : "South Korea"},
						{code : "ES", name : "Spain"},
						{code : "LK", name : "Sri Lanka"},
						{code : "SH", name : "St. Helena"},
						{code : "KN", name : "St. Kitts and Nevis"},
						{code : "LC", name : "St. Lucia"},
						{code : "PM", name : "St. Pierre and Miquelon"},
						{code : "SR", name : "Suriname"},
						{code : "SJ", name : "Svalbard and Jan Mayen Islands"},
						{code : "SZ", name : "Swaziland"},
						{code : "SE", name : "Sweden"},
						{code : "CH", name : "Switzerland"},
						{code : "TJ", name : "Tajikistan"},
						{code : "TW", name : "Taiwan"},
						{code : "TZ", name : "Tanzania"},
						{code : "TH", name : "Thailand"},
						{code : "TG", name : "Togo"},
						{code : "TO", name : "Tonga"},
						{code : "TT", name : "Trinidad and Tobago"},
						{code : "TN", name : "Tunisia"},
						{code : "TR", name : "Turkey"},
						{code : "TM", name : "Turkmenistan"},
						{code : "TC", name : "Turks and Caicos Islands"},
						{code : "TV", name : "Tuvalu"},
						{code : "UG", name : "Uganda"},
						{code : "UA", name : "Ukraine"},
						{code : "AE", name : "United Arab Emirates"},
						{code : "GB", name : "United Kingdom"},
						{code : "US", name : "United States"},
						{code : "UY", name : "Uruguay"},
						{code : "VU", name : "Vanuatu"},
						{code : "VA", name : "Vatican City State"},
						{code : "VE", name : "Venezuela"},
						{code : "VN", name : "Vietnam"},
						{code : "WF", name : "Wallis and Futuna Islands"},
						{code : "YE", name : "Yemen"},
						{code : "ZM", name : "Zambia"}]

	$("#vatNumber").hide()
	$("#State").hide()
	$("#BillingvatNumber").hide()
	$("#BillingState").hide()


	UserService.me (success) ->
		$scope.profile = success.data.profile
		$scope.billing = success.data.billing
	, (error) ->
		console.log error

	CartService.get (success) ->
		$scope.cart = success.data
	, (error) ->
		console.log error

	PaymentService.getCurrentSubscription (success) ->
		$scope.subscription = success.data

	$scope.updateCountry = ->
		$("#vatNumber").hide()
		$("#State").hide()
		if $scope.profile.country_code is "AT" or
		$scope.profile.country_code is "AD" or
		$scope.profile.country_code is "AL" or
		$scope.profile.country_code is "AM" or
		$scope.profile.country_code is "AZ" or
		$scope.profile.country_code is "BA" or
		$scope.profile.country_code is "BE" or
		$scope.profile.country_code is "BG" or
		$scope.profile.country_code is "DE" or
		$scope.profile.country_code is "CY" or
		$scope.profile.country_code is "HR" or
		$scope.profile.country_code is "CZ" or
		$scope.profile.country_code is "DK" or
		$scope.profile.country_code is "EE" or
		$scope.profile.country_code is "FI" or
		$scope.profile.country_code is "FR" or
		$scope.profile.country_code is "GR" or
		$scope.profile.country_code is "HU" or
		$scope.profile.country_code is "IS" or
		$scope.profile.country_code is "IR" or
		$scope.profile.country_code is "IT" or
		$scope.profile.country_code is "KZ" or
		$scope.profile.country_code is "LV" or
		$scope.profile.country_code is "LI" or
		$scope.profile.country_code is "LT" or
		$scope.profile.country_code is "LU" or
		$scope.profile.country_code is "MT" or
		$scope.profile.country_code is "NL" or
		$scope.profile.country_code is "NO" or
		$scope.profile.country_code is "PL" or
		$scope.profile.country_code is "PT" or
		$scope.profile.country_code is "RO" or
		$scope.profile.country_code is "SI" or
		$scope.profile.country_code is "ES" or
		$scope.profile.country_code is "TR" or
		$scope.profile.country_code is "SE" or
		$scope.profile.country_code is "GB"
			$("#vatNumber").show()

		if $scope.profile.country_code is "US"
			$("#State").show()

	$scope.billingUpdateCountry = ->
		$("#BillingvatNumber").hide()
		$("#BillingState").hide()
		if $scope.billing.country_code is "AT" or
		$scope.billing.country_code is "AD" or
		$scope.billing.country_code is "AL" or
		$scope.billing.country_code is "AM" or
		$scope.billing.country_code is "AZ" or
		$scope.billing.country_code is "BA" or
		$scope.billing.country_code is "BE" or
		$scope.billing.country_code is "BG" or
		$scope.billing.country_code is "DE" or
		$scope.billing.country_code is "CY" or
		$scope.billing.country_code is "HR" or
		$scope.billing.country_code is "CZ" or
		$scope.billing.country_code is "DK" or
		$scope.billing.country_code is "EE" or
		$scope.billing.country_code is "FI" or
		$scope.billing.country_code is "FR" or
		$scope.billing.country_code is "GR" or
		$scope.billing.country_code is "HU" or
		$scope.billing.country_code is "IS" or
		$scope.billing.country_code is "IR" or
		$scope.billing.country_code is "IT" or
		$scope.billing.country_code is "KZ" or
		$scope.billing.country_code is "LV" or
		$scope.billing.country_code is "LI" or
		$scope.billing.country_code is "LT" or
		$scope.billing.country_code is "LU" or
		$scope.billing.country_code is "MT" or
		$scope.billing.country_code is "NL" or
		$scope.billing.country_code is "NO" or
		$scope.billing.country_code is "PL" or
		$scope.billing.country_code is "PT" or
		$scope.billing.country_code is "RO" or
		$scope.billing.country_code is "SI" or
		$scope.billing.country_code is "ES" or
		$scope.billing.country_code is "TR" or
		$scope.billing.country_code is "SE" or
		$scope.billing.country_code is "GB"
			$("#BillingvatNumber").show()

		if $scope.billing.country_code is "US"
			$("#BillingState").show()

	$scope.handleBillingAddress = ->

		if not $scope.profile.use_profile_for_billing
			$scope.billing =
				type: 'individual'
		else
			$scope.billing = $scope.profile
			$scope.billing.use_profile_for_billing = true

	$scope.process_billing = ->

		if $('#profile_company').is(":visible") and $('#profile_company').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error name of the company missing"
			return null
		if $('#profile_vat_number').is(":visible") and $('#profile_vat_number').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error VAT number missing"
			return null
		if $('#profile_name').is(":visible") and $('#profile_name').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error first name and last name missing"
			return null
		if $('#profile_mail').is(":visible") and $('#profile_mail').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error mail missing"
			return null
		if $('#profile_addr_one').is(":visible") and $('#profile_addr_one').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error address missing"
			return null
		if $scope.profile.country_code is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error country missing"
			return null
		if $('#profile_zipcode').is(":visible") and $('#profile_zipcode').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error country missing"
			return null
		if $('#profile_city').is(":visible") and $('#profile_city').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error city missing"
			return null
		if $('#profile_state').is(":visible") and $('#profile_state').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error state missing"
			return null
		if $('#profile_addr_one').is(":visible") and $('#profile_addr_one').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error address missing"
			return null



		if $('#billing_company').is(":visible") and $('#billing_company').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error name of the company missing"
			return null
		if $('#billing_vat_number').is(":visible") and $('#billing_vat_number').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error VAT number missing"
			return null
		if $('#billing_name').is(":visible") and $('#billing_name').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error first name and last name missing"
			return null
		if $('#billing_mail').is(":visible") and $('#billing_mail').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error mail missing"
			return null
		if $('#billing_addr_one').is(":visible") and $('#billing_addr_one').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error address missing"
			return null
		if $scope.billing.country_code is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error country missing"
			return null
		if $('#billing_zipcode').is(":visible") and $('#billing_zipcode').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error country missing"
			return null
		if $('#billing_city').is(":visible") and $('#billing_city').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error city missing"
			return null
		if $('#billing_state').is(":visible") and $('#billing_state').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error state missing"
			return null
		if $('#billing_addr_one').is(":visible") and $('#billing_addr_one').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error address missing"
			return null

		$('#bt-payment').hide 0, ->
			$('#waiting-payment').fadeIn(1000)

		if $scope.profile.use_profile_for_billing
			$scope.billing = $scope.profile

		for country in $scope.countries
			if $scope.billing.country_code == country.code
				$scope.billing.country = country.name
				break # ?

		UserService.createBilling $scope.profile, $scope.billing, (success) ->
			$location.path "/payment/confirm"
		, (error) ->
			$scope.error =
				state : true
				message : error.message

			$('#waiting-payment').hide 0, ->
				$('#bt-payment').show().css('display', 'inline');

	$scope.process_order = ->


		if $('#card-number').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error card number missing"
			return null
		if $('#card-expiry-month').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error expiration date missing (month)"
			return null
		if $('#card-expiry-year').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error expiration date missing (year)"
			return null
		if $('#card-cvc').val() is ""
			console.log "error"
			$scope.error =
				state : true
				message : "error card cvc missing"
			return null

		$('#bt-payment').hide 0, ->
			$('#waiting-payment').fadeIn(1000)

		$scope.error =
				state: false
				message : ''

		# process order
		params_for_token = checkoutParamsForToken()

		paymill_data =
			currency: 'EUR'
			amount: $scope.cart.total * 100
			token: ''
			offer: $scope.cart.plan_id

		offer_name = $scope.cart.plan_name

		if params_for_token?
			paymill.createToken params_for_token, (error, result) ->
				paymill_data.token = result.token
				PaymentService.process paymill_data, (success) ->
					$rootScope.subscription = success.data[2].data.id
					$location.path "/payment/#{offer_name}/success"
				, (error) ->
					$scope.error =
						state: true
						message : error.message

					$('#waiting-payment').hide 0, ->
						$('#bt-payment').show().css('display', 'inline');


	checkoutParamsForToken = ->
		if !paymill.validateCardNumber($('.card-number').val())
			$scope.error =
				state: true
				message : 'Invalid card number'
			return null

		if !paymill.validateExpiry($('.card-expiry-month').val(), $('.card-expiry-year').val())
			$scope.error =
				state: true
				message : 'Invalid card expiry date'

			return null

		if !paymill.validateCvc($('.card-cvc').val(), $('.card-number').val())
			$scope.error =
				state: true
				message : 'Invalid card CVC'

			return null

		# if $('.card-holdername').val() == ''
		# 	$scope.error =
		# 		state: true
		# 		message : 'Invalid card holdername'

		# 	return null

		params =
			currency: $('.currency').val()
			number: $('.card-number').val()
			exp_month: $('.card-expiry-month').val()
			exp_year: $('.card-expiry-year').val()
			cvc: $('.card-cvc').val()
			cardholder: $('.card-holdername').val()

		return params
