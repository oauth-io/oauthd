define [
	'utilities/apiRequest'
	], (apiRequest) ->
	PaymentService = ($rootScope, $http) ->
		api = apiRequest $http, $rootScope
		return {
			subscribe: (data, success, error) ->
				api 'payment/subscribe', success, error, data: data

			unsubscribe: (success, error) ->
				api "payment/unsubscribe", success, error,
					method:'DELETE'

			coupon: (data, success, error) ->
				api "payment/coupon", success, error, data:data

			list: (success, error) ->
				api 'plans', success, error
		}
	return ["$rootScope", "$http", PaymentService]