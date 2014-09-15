Q = require('q')

module.exports = (app) ->
	app.factory('PluginService', ['$http', '$rootScope', '$location', 
		($http, $rootScope, $location) ->
			api = require('../utilities/apiCaller') $http, $rootScope
			plugin_service =
				getAll: () ->
					defer = Q.defer()
					api "/plugins", (data) ->
						defer.resolve data.data
					, (e) ->
						defer.reject e
					return defer.promise
				get: (name) ->
					defer = Q.defer()
					api "/plugins/" + name, ((data) ->
						defer.resolve data.data
						return
					), (e) ->
						defer.reject e
						return
					return defer.promise

			plugin_service
	])
