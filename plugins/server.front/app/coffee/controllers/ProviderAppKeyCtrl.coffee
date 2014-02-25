"use strict"
define [
	"app",
	"services/MenuService",
	"services/KeysetService",
	"services/ProviderService",
	"services/AppService"
	], (app) ->
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
			
		app.register.controller "ProviderAppKeyCtrl", [
			"$scope"
			"$http"
			"MenuService"
			"UserService"
			"KeysetService"
			"ProviderService"
			"AppService"
			"$timeout"
			"$routeParams"
			"$location"
			ProviderAppKeyCtrl
		]
		return
