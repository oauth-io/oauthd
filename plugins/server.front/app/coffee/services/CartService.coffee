define [
	"app",
	"services/apiRequest"
	], (app, apiRequest) ->
	app.register.factory 'CartService', ($rootScope, $http) ->
		api = apiRequest $http, $rootScope
		return {
			add: (plan, success, error) ->
				api 'payment/cart/new', success, error,
					method:'POST'
					data:
						plan: plan

			get: (success, error) ->
				api 'payment/cart/get', success, error
		}