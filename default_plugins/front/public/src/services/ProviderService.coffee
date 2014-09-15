Q = require("q")

module.exports = (app) ->
	app.factory "ProviderService", [
		"$rootScope"
		"$http"
		($rootScope, $http) ->
			api = require("../utilities/apiCaller")($http, $rootScope)
			get_provider_conf = (name) ->
				defer = Q.defer()
				api "/providers/" + name + "?extend=true", ((data) ->
					defer.resolve data.data
					return
				), (e) ->
					defer.reject e
					return

				defer.promise

			get_provider_settings = (name) ->
				defer = Q.defer()
				api "/providers/" + name + "/settings", ((data) ->
					defer.resolve data.data.settings
					return
				), (e) ->
					defer.reject e
					return

				defer.promise

			provider_service =
				getAll: () ->
					defer = Q.defer()

					api "/providers", (data) ->
						defer.resolve data.data
					, (e) ->
						defer.reject e

					return defer.promise
				get: (name) ->
					get_provider_conf name

				getSettings: (name) ->
					get_provider_settings name

				getCurrentProvider: ->
					get_provider_conf $rootScope.wd.provider

				getCurrentProviderSettings: ->
					get_provider_settings $rootScope.wd.provider
				getProviderConfig: (name) ->
					get_provider_conf name
				getProviderSettings: (name) ->
					get_provider_settings name


			return provider_service
	]
	return