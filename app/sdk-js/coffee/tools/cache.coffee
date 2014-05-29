module.exports =
	init: (cookies_module, config) ->
		@config = config
		@cookies = cookies_module
	tryCache: (OAuth, provider, cache) ->
			if @cacheEnabled(cache)
				cache = @cookies.readCookie("oauthio_provider_" + provider)
				return false  unless cache
				cache = decodeURIComponent(cache)
			if typeof cache is "string"
				try cache = JSON.parse(cache)
				catch e
					return false
			if typeof cache is "object"
				res = {}
				for i of cache
  					res[i] = cache[i]  if i isnt "request" and typeof cache[i] isnt "function"
				return OAuth.create(provider, res, cache.request)
			false

	storeCache: (provider, cache) ->
		@cookies.createCookie "oauthio_provider_" + provider, encodeURIComponent(JSON.stringify(cache)), cache.expires_in - 10 or 3600
		return

	cacheEnabled: (cache) ->
		return @config.options.cache  if typeof cache is "undefined"
		cache