"use strict"
define [
	"services/MenuService",
	"services/AppService",
	"services/ProviderService"
	], () ->
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
		return [
			"$scope",
			"MenuService",
			"$routeParams",
			"AppService",
			"ProviderService",
			ProviderSampleCtrl
		]