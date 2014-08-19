module.exports = (app) ->
	app.controller('AppsIndexCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService) ->
			$scope.clearArianne()
			reloadApps = () ->
				AppService.all()
					.then (apps) ->
						$scope.apps = apps
						$scope.$apply()
					.fail (e) ->
						console.log e
			reloadApps()

			$scope.deleteApp = (key) ->
				if confirm 'Are you sure you want to delete this app?'
					AppService.del({
						key: key
					})
						.then () ->
							reloadApps()
						.fail () ->
							console.log e

			
	])