define ["app", "services/apiRequest"], (app, apiRequest) ->
    app.register.factory 'WishlistService', ($http, $rootScope) ->
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