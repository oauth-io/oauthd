module.exports = (app) ->
	app.controller('AppCreateCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService) ->
			$scope.app = {
			}
			$scope.domains_control = {}

			$scope.create = () ->
				AppService.create($scope.app)
					.then (app) ->
						$state.go 'dashboard.apps.all'
						return
					.fail (e) ->
						console.log 'failed', e
						return

			
	])