module.exports = (app) ->
	app.controller('AppProviderListCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService', 'ProviderService', 'KeysetService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService, ProviderService, KeysetService) ->
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
					$scope.$apply()
				.fail (e) ->
					console.log e


			
	])