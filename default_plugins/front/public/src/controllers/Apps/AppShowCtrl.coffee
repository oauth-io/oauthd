module.exports = (app) ->
	app.controller('AppShowCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams',
		($state, $scope, $rootScope, $location, UserService, $stateParams) ->
			$scope.hello = 'hi'
			$scope.app = {
				id: $stateParams.id
			}
			
	])