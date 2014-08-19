Q = require('q')

module.exports = (app) ->
	app.factory('KeysetService', ['$rootScope', '$http',
		($rootScope, $http) ->
			api = require('../utilities/apiCaller')($http, $rootScope)
			keyset_service = {
				get: (app_key, provider) ->
					defer = Q.defer()

					api('/apps/' + app_key + '/keysets/' + provider, (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject(e)
					)
					return defer.promise
				,
				save: (app_key, provider, keyset) ->
					defer = Q.defer()
					api('/apps/' + app_key + '/keysets/' + provider, (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject(e)
					, data:
						parameters: keyset,
						response_type: 'token'
					)
					return defer.promise
				,
				del: (app_key, provider) ->
					defer = Q.defer()
					api('/apps/' + app_key + '/keysets/' + provider, (data) ->
						defer.resolve(data.data)
					, (e) ->
						defer.reject(e)
					, {
						method: 'DELETE'
					})
					return defer.promise
			}

			return keyset_service

	])
