async = require 'async'

module.exports = (app) ->
	app.controller('DashboardCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', 'AppService',
		($state, $scope, $rootScope, $location, UserService, AppService) ->
			if not $rootScope.accessToken? || $rootScope.loginData?.expires < new Date().getTime()
				$state.go 'login'
			
			$scope.state = $state
	])
