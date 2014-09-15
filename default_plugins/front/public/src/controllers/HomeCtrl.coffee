async = require 'async'

module.exports = (app) ->
	app.controller 'HomeCtrl', ['$scope', '$state', '$rootScope', '$location', 'UserService', 'AppService', 'PluginService',
		($scope, $state, $rootScope, $location, UserService, AppService, PluginService) ->
			$scope.providers = {}
			$scope.loadingApps = true

			$scope.count = (object) ->
				count = 0
				for k,v of object
					count++
				return count

			AppService.all()
				.then (apps) ->
					$scope.apps = apps
					async.eachSeries apps, (app, next) ->
						AppService.get app.key
							.then (app_data) ->
								for j of app_data
									app[j] = app_data[j]
									
								for k,v of app_data.keysets
									$scope.providers[v] = true
								next()
							.fail (e) ->
								console.log e
								next()
					, (err) ->
						$scope.$apply()
				.fail (e) ->
					console.log e
				.finally () ->
					$scope.loadingApps = false
					$scope.$apply()

			PluginService.getAll()
				.then (plugins) ->
					$scope.plugins = []
					for name in plugins
						plugin = {}
						plugin.name = name
						plugin.url = "/oauthd/plugins/" + name
						$scope.plugins.push plugin
				.fail (e) ->
					console.log e
				.finally () ->
					$scope.$apply()

	]