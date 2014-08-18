Q = require('q')

module.exports = (app) ->
	app.factory('AppService', ['$rootScope', '$http',
		($rootScope, $http) ->
			api = require('../utilities/apiCaller')($http, $rootScope)
			return {
				get: (key) ->
					defer = Q.defer()
					api '/apps/' + key, (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject(e)
					return defer.promise
				create: (app) ->
					defer = Q.defer()

					api '/apps',  (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject e
					, {
						method: 'POST',
						data: app
					}

					return defer.promise
				update: (app) ->
					defer = Q.defer()

					api '/apps/' + app.key,  (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject e
					, {
						method: 'POST',
						data: app
					}
					return defer.promise
				del: (app) ->
					defer = Q.defer()
					key = app.key if typeof app == 'object'
					key = app if typeof app == 'string'
					api '/apps/' + key,  (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject e
					, {
						method: 'DELETE'
					}
					return defer.promise
			}
	])
