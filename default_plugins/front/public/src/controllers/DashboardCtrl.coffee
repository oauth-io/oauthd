module.exports = (app) ->
	app.controller('DashboardCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService',
		($state, $scope, $rootScope, $location, UserService) ->
			
			$scope.lol = 'hello'
	])
