module.exports = (app) ->
	app.controller('AppShowCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService) ->
			$scope.domains_control = {}
			$scope.error = undefined
			$scope.setProvider undefined

			$scope.backend = {}

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

			AppService.getBackend $stateParams.key
				.then (backend) ->
					$scope.backend.name = backend?.name
					if not $scope.backend?.name
						$scope.backend.name = 'none'
					$scope.$apply()
				.fail (e) ->

			$scope.saveApp = () ->
				AppService.update($scope.app)
					.then () ->
						$scope.success = "Successfully saved changes"
						$scope.error = undefined
						$scope.$apply()

					.fail (e) ->
						console.log 'error', e
						$scope.error = e.message


			$scope.setBackend = () ->
				AppService.setBackend $stateParams.key, $scope.backend?.name
					.then () ->
						$scope.success = "Successfully changed backend to " + $scope.backend.name
						$scope.$apply()
					.fail (e) ->
						$scope.error = "A problem occured while changing the backend"
						console.log 'error', e

			$scope.deleteApp = () ->
				if confirm 'Are you sure you want to delete this app?'
					AppService.del $scope.app
						.then () ->
							$state.go 'dashboard.apps.all'
							$scope.error = undefined
						.fail (e) ->
							console.log 'error', e
							$scope.error = e.message
			timeout = undefined
			$scope.$watch 'success', () ->
				clearTimeout timeout
				if $scope.success != undefined
					timeout = setTimeout () ->
						$scope.success = undefined
						$scope.$apply()
					, 3000

			timeoute = undefined
			$scope.$watch 'error', () ->
				clearTimeout timeoute
				if $scope.error != undefined
					timeoute = setTimeout () ->
						$scope.error = undefined
						$scope.$apply()
					, 3000

	])	