define [
	"utilities/apiRequest"
	], (apiRequest) ->
	WishlistService = ($http, $rootScope) ->
		api = apiRequest $http, $rootScope
		return {
			list: (success, error) ->
				api 'wishlist', success, error

			add: (name, success, error) ->
				if (name?)
					api "wishlist/add", success, error,
						method: "POST"
						data:
							name: name
		}
	return ["$http", "$rootScope", WishlistService]
