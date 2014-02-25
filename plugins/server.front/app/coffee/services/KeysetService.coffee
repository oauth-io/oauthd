define [
	"app",
	"services/apiRequest"
	], (app, apiRequest) ->
		app.register.factory 'KeysetService', ($rootScope, $http) ->
			api = apiRequest $http, $rootScope
			return {
				get: (app, provider, success, error) ->
					api 'apps/' + app + '/keysets/' + provider, success, error

				add: (app, provider, keys, response_type, success, error) ->
					api 'apps/' + app + '/keysets/' + provider, success, error, data:
						parameters: keys
						response_type: response_type

				remove: (app, provider, success, error) ->
					api 'apps/' + app + '/keysets/' + provider, success, error, method:'delete'

				# stats: (app, provider, success, error) ->
				# 	api 'apps/' + app + '/keysets/' + provider + '/stats', success, error
			}