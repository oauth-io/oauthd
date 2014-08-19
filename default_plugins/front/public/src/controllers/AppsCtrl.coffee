module.exports = (app) ->
	app.controller('AppsCtrl', ['$state', '$scope', '$rootScope', '$location',
		($state, $scope, $rootScope, $location, UserService) ->
			$scope.setApp = (app) ->
				$scope.app = app


			$scope.getApp = () ->
				return $scope.app

			$scope.setProvider = (provider) ->
				$scope.provider_name = provider

			$scope.clearArianne = () ->
				$scope.app = undefined
				$scope.provider_name = undefined
				$scope.$apply()


			
	])
