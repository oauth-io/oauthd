define ["app"], (app) ->
    window.apiRequest = ($http, $rootScope) ->
        (url, success, error, opts) ->
            opts ?= {}
            opts.url = "/api/" + url
            if opts.data
                opts.data = JSON.stringify opts.data
                opts.method ?= "POST"
            opts.method = opts.method?.toUpperCase() || "GET"
            opts.headers ?= {}
            if $rootScope.accessToken
                opts.headers.Authorization = "Bearer " + $rootScope.accessToken
            if opts.method is "POST" or opts.method is "PUT"
                opts.headers['Content-Type'] = 'application/json'
            req = $http(opts)
            req.success(success) if success
            req.error(error) if error
            refreshSession $rootScope
            return