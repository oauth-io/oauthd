module.exports = (app) ->
	app.controller('AppKeysetCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService', 'ProviderService', 'KeysetService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService, ProviderService, KeysetService) ->
			$scope.keyset = {
				parameters: {}
			}
			$scope.keysetEditorControl = {}
			$scope.provider = $stateParams.provider

			$scope.changed = false

			AppService.get $stateParams.key
				.then (app) ->
					$scope.app = app
					$scope.setApp app
					$scope.setProvider $stateParams.provider
					$scope.$apply()
				.fail (e) ->
					console.log e

			# Filling the content
			KeysetService.get $stateParams.key, $scope.provider
				.then (keyset) ->	
					$scope.keyset = keyset
					$scope.original = {}
					for k,v of $scope.keyset.parameters
						$scope.original[k] = v
					$scope.keysetEditorControl.setKeyset $scope.keyset
					return
				.fail (e) ->
					$scope.keysetEditorControl.setKeyset $scope.keyset

			$scope.save = () ->
				keyset = $scope.keysetEditorControl.getKeyset()
				KeysetService.save $scope.app.key, $stateParams.provider, keyset.parameters
					.then (data) ->
						$state.go 'dashboard.apps.show', {
							key: $stateParams.key
						}
					.fail (e) ->
						console.log 'error', e

			$scope.delete = () ->
				if confirm 'Are you sure you want to delete this keyset?'
					KeysetService.del $scope.app.key, $stateParams.provider
						.then (data) ->
							$state.go 'dashboard.apps.show', {
								key: $stateParams.key
							}
						.fail (e) ->
							console.log 'error', e

			ProviderService.getProviderSettings $stateParams.provider
				.then (settings) ->
					$scope.settings = settings
				.fail (e) ->
					consoe.log 'e', e

			$scope.keysetEditorControl.change = () ->
				$scope.changed = not angular.equals($scope.original, $scope.keysetEditorControl.getKeyset().parameters)
				$scope.$apply()

	])	