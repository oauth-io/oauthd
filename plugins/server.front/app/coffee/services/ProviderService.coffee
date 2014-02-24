define ["app"], (app) ->
	app.register.factory 'ProviderService', ($http, $rootScope) ->
		api = apiRequest $http, $rootScope
		return {
			list: (success, error) ->
				api 'providers', success, error
			get: (name, success, error) ->
				api 'providers/' + name + '?extend=true', success, error
			getSettings: (name, success, error) ->
				api 'providers/' + name + '/settings', success, error

			auth: (appKey, provider, success)->
				OAuth.initialize appKey
				OAuth.popup provider, success
		}