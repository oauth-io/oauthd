define [], () ->
	PaymentService = ($rootScope, $http) ->
		api = apiRequest $http, $rootScope
		return {
			process: (paymill, success, error) ->
				api 'payment/process', success, error,
					method:'POST'
					data:
						currency: paymill.currency
						amount: paymill.amount
						token: paymill.token
						offer: paymill.offer
			getCurrentSubscription: (success, error) ->
				api 'subscription/get', success, error
		}
	return ["$rootScope", "$http", PaymentService]