module.exports = (app) ->
	app.controller('AppProviderListCtrl', ['$state', '$scope', '$rootScope', '$location', '$timeout', '$filter', 'UserService', '$stateParams', 'AppService', 'ProviderService', 'KeysetService',
		($state, $scope, $rootScope, $location, $timeout, $filter, UserService, $stateParams, AppService, ProviderService, KeysetService) ->
			$scope.loadingProviders = true

			AppService.get $stateParams.key
				.then (app) ->
					$scope.app = app
					$scope.setApp app
					$scope.setProvider 'Add a provider'
					$scope.$apply()
				.fail (e) ->
					console.log e

			ProviderService.getAll()
				.then (providers) ->
					$scope.providers = providers
					$scope.selectedProviders = providers
					$scope.$apply()
				.fail (e) ->
					console.log e
				.finally () ->
					$scope.loadingProviders = false
					$scope.$apply()

			$scope.queryChange = () ->
				$timeout (->
					$scope.loadingProviders = true
					$scope.selectedProviders = $scope.providers
					if $scope.query 
						if $scope.query.name and $scope.query.name isnt ""
							$scope.selectedProviders = $filter('filter')($scope.selectedProviders, {name:$scope.query.name})
					$scope.loadingProviders = false
				), 500	
	])