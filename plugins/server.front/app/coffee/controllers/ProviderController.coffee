"use strict"
define ["app"], (app) ->
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
	return
	
  app.register.controller "ProviderCtrl", [
    "$scope"
    ProviderCtrl
  ]
  return
