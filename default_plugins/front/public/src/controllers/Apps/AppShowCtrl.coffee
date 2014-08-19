module.exports = (app) ->
	app.controller('AppShowCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService) ->
			$scope.domains_control = {}
			$scope.error = undefined
			$scope.setProvider undefined
			AppService.get($stateParams.key)
				.then (app) ->
					$scope.app = app
					$scope.setApp app
					$scope.error = undefined
					$scope.$apply()
					$scope.domains_control.refresh()
				.fail (e) ->
					console.log e
					$scope.error = e.message
			$scope.saveApp = () ->
				AppService.update($scope.app)
					.then () ->
						$scope.success = "Successfully saved changes"
						$scope.error = undefined
						$scope.$apply()

					.fail (e) ->
						console.log 'error', e
						$scope.error = e.message

			$scope.deleteApp = () ->
				if confirm 'Are you sure you want to delete this app?'
					AppService.del $scope.app
						.then () ->
							$state.go 'dashboard.apps.all'
							$scope.error = undefined
						.fail (e) ->
							console.log 'error', e
							$scope.error = e.message
			
			$scope.$watch 'success', () ->
				setTimeout () ->
					$scope.success = undefined
					$scope.$apply()
				, 3000
	])	