
##################
# App controller #
##################

"use strict"
define [], () ->
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
				if $routeParams.provider?
					$scope.callback = '/provider/' + $routeParams.provider + '/app'
				else
					$scope.callback = '/key-manager/'

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
			mixpanel.track "key manager try auth", provider: provider
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
				console.log "AppCtrl error", error
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
					mixpanel.track "reset key"
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
					mixpanel.track "key manager apikeys update"
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

	return [
		'$scope', 
		'$rootScope', 
		'$routeParams', 
		'$location', 
		'UserService', 
		'$timeout', 
		'AppService', 
		'ProviderService', 
		'KeysetService',
		AppCtrl
	]