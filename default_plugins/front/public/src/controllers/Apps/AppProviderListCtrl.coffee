module.exports = (app) ->
	app.controller('AppProviderListCtrl', ['$state', '$scope', '$rootScope', '$location', '$timeout', '$filter', 'UserService', '$stateParams', 'AppService', 'ProviderService', 'KeysetService',
		($state, $scope, $rootScope, $location, $timeout, $filter, UserService, $stateParams, AppService, ProviderService, KeysetService) ->
			AppService.get $stateParams.key
				.then (app) ->
					$scope.app = app
					$scope.setApp app
					$scope.setProvider 'Add a provider'
					$scope.$apply()
				.fail (e) ->
					console.log e

			$scope.loadingProviders = true
			ProviderService.getAll()
				.then (providers) ->
					$scope.providers = providers
					$scope.selectedProviders = providers
					$scope.loadingProviders = false
					$scope.$apply()
				.fail (e) ->
					console.log e

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