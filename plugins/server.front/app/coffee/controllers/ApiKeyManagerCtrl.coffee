##############################
# API KEY MANAGER CONTROLLER #
##############################


"use strict"
define [
	"app",
	"services/UserService",
	"services/MenuService",
	"services/KeysetService",
	"services/AppService",
	"services/ProviderService",
	"controllers/AppCtrl"
	], (app) ->
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
					
		app.register.controller "ApiKeyManagerCtrl", [
			"$scope"
			"$routeParams"
			"$timeout"
			"$rootScope"
			"$location"
			"UserService"
			"$http"
			"MenuService"
			"KeysetService"
			"AppService"
			"ProviderService"
			ApiKeyManagerCtrl
		]
		return
