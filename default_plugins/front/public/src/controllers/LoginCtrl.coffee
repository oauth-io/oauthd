module.exports = (app) ->
	app.controller('LoginCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService',
		($state, $scope, $rootScope, $location, UserService) ->
			$scope.error = undefined
			$scope.user = {

			}
			$scope.login = () ->
				UserService.login({
					email: $scope.user.email,
					pass: $scope.user.pass
				})
					.then (user) ->
						$state.go('dashboard')
					.fail (e) ->
						$scope.error = e.message
						return
	])
