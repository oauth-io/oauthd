module.exports = (app) ->
	app.controller('DashboardCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService',
		($state, $scope, $rootScope, $location, UserService) ->
			if not $rootScope.accessToken? || $rootScope.loginData.expires < new Date().getTime()
				$state.go 'login'
	])
