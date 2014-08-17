module.exports = (app) ->
	app.controller('AppsCtrl', ['$state', '$scope', '$rootScope', '$location',
		($state, $scope, $rootScope, $location, UserService) ->
			if not $rootScope.accessToken?
				$state.go 'login'
	])
