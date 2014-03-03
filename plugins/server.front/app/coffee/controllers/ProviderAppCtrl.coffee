"use strict"
define [
	"services/MenuService",
	"services/ProviderService",
	"services/AppService"
	], () ->
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
			
		return [
			"$scope",
			"MenuService",
			"UserService",
			"ProviderService",
			"AppService",
			"$timeout",
			"$routeParams",
			"$location",
			ProviderAppCtrl
		]