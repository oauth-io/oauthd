async = require 'async'

module.exports = (app) ->
	app.controller('AppsIndexCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService) ->
			$scope.clearArianne()
			$scope.loadingApps = true
			$scope.apps = []
			reloadApps = () ->
				AppService.all()
					.then (apps) ->
						async.each apps, (app, cb) ->
							AppService.get app.key
								.then (a) ->
									$scope.apps.push a
									cb()
								.fail (e) ->
									console.log 'err', e
						, (err) ->
							$scope.$apply()
					.fail (e) ->
						console.log e
					.finally () ->
						$scope.loadingApps = false
						$scope.$apply()
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