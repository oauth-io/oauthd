# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

hooks.config.push ->

	app.controller 'LogoutCtrl', ($location, $rootScope) ->
		document.location.reload()

	app.controller 'ProviderCtrl', ($filter, $scope, $rootScope, ProviderService, $timeout) ->
		ProviderService.list (json) ->
			$scope.providers = (provider.provider for provider in json.data)
			$rootScope.providers_name = {} if not $rootScope.providers_name
			$rootScope.providers_name[provider.provider] = provider.name for provider in json.data
			$scope.providers_name = $rootScope.providers_name
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


	##############################
	# API KEY MANAGER CONTROLLER #
	##############################
	app.controller 'ApiKeyManagerCtrl', ($scope, $timeout, $rootScope, $location, UserService, $http, MenuService, KeysetService, ProviderService) ->
		MenuService.changed()
		if not UserService.isLogin()
			$location.path '/'

		$rootScope.providers_name = {} if not $rootScope.providers_name
		$scope.providers_name = $rootScope.providers_name
		$scope.keySaved = false
		$scope.authUrl = oauthdconfig.host_url + oauthdconfig.base
		$scope.authDomain = oauthdconfig.host_url
		$scope.oauthdconfig = oauthdconfig;
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

				if not $rootScope.error.state
					KeysetService.add key, provider, data, response_type, ((keysetEntry) ->

						app = $rootScope.apps.find (n) ->
							return n.key == $scope.createKeyAppKey

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
					console.log "error", error

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
					url: $scope.oauthdconfig.base_api + '/providers/' + $scope.createKeyProvider + '/keys.png'
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
					url: $scope.oauthdconfig.base_api + '/providers/' + $scope.createKeyProvider + '/config.png'
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

	##################
	# App controller #
	##################
	app.controller 'AppCtrl', ($scope, $rootScope, $location, AdmService, UserService, $timeout, AppService, ProviderService, KeysetService) ->
		if not UserService.isLogin()
			$location.path '/'

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

		AdmService.me ((me)->
			$rootScope.apps = me.data.apps

			n = $rootScope.apps.length
			$rootScope.noApp = false
			if n == 0
				if $location.path() == '/key-manager'
					$location.path "/app-create"
				else
					$rootScope.noApp = true
			$scope.counter = 0
			for i of $rootScope.apps
				do (i, n) ->
					AppService.get $rootScope.apps[i], ((app) =>
						$scope.counter++
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
			if $scope.createAppForm.input != "" and $scope.createAppForm.domains.indexOf($scope.createAppForm.input) == -1
				$scope.createAppForm.domains.push $scope.createAppForm.input
				$scope.createAppForm.input = ""


		$scope.removeDomain = (name)->
			$scope.createAppForm.domains.remove name


		$scope.createAppSubmit = ->

			$scope.addDomain()

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
						$location.path "/app-create"
				), (error) ->


		#reset public key
		$scope.resetKeys = (key)->
			if confirm 'Are you sure you want to reset your Keys? You\'ll need to update the keys in your application.'
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
			if confirm "Are you sure you want to delete this API Key ? If this Key is running in production, it could break your app."
				KeysetService.remove app.key, provider, ((data) ->
					app.keysets.remove provider
					delete app.keys[provider]
				), (error) ->
					console.log "error"

	app.controller 'LicenseCtrl', (UserService, MenuService) ->
		MenuService.changed()

	app.controller 'AboutCtrl', (UserService, MenuService) ->
		MenuService.changed()

	app.controller 'NotFoundCtrl', ($scope, $routeParams, UserService, MenuService) ->
		MenuService.changed()
		$scope.errorGif = 'img/404/' + (Math.floor(Math.random() * 2) + 1) + '.gif'