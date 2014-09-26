module.exports = ($http, $rootScope) ->
	return (url, success, error, opts) ->
		opts = {} if not opts?
		opts.url = "/api" + url
		
		if opts.data
			opts.data = JSON.stringify opts.data
			if not opts.method?
				opts.method = "POST"

		opts.method = opts.method || "GET"
		opts.headers = {} if not opts.headers?

		if $rootScope.accessToken
			opts.headers.Authorization = "Bearer " + $rootScope.accessToken

		if opts.method == "POST" || opts.method == "PUT"
			opts.headers['Content-Type'] = 'application/json'

		req = $http(opts)
		if success
			req.success(success)
		if error
			req.error(error)

