"use strict"
define ["app"], (app) ->
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
	
  app.register.controller "ProviderPageCtrl", [
    "$scope"
    "MenuService"
    "UserService"
    "ProviderService"
    "AppService"
    "$timeout"
    "$routeParams"
    "$location"
    ProviderPageCtrl
  ]
  return
