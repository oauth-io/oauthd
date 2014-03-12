module.exports = (config) ->
	cookies:
		createCookie: (name, value, expires) ->
			eraseCookie name
			date = new Date()
			date.setTime date.getTime() + (expires or 1200) * 1000 # def: 20 mins
			expires = "; expires=" + date.toGMTString()
			document.cookie = name + "=" + value + expires + "; path=/"
			return

		readCookie: (name) ->
			nameEQ = name + "="
			ca = document.cookie.split(";")
			i = 0

			while i < ca.length
				c = ca[i]
				c = c.substring(1, c.length)  while c.charAt(0) is " "
				return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
				i++
			null

		eraseCookie: (name) ->
			date = new Date()
			date.setTime date.getTime() - 86400000
			document.cookie = name + "=; expires=" + date.toGMTString() + "; path=/"
			return

	cache:
		tryCache: (provider, cache) ->
			if cacheEnabled(cache)
				cache = readCookie("oauthio_provider_" + provider)
				return false  unless cache
				cache = decodeURIComponent(cache)
			if typeof cache is "string"
				try
					cache = JSON.parse(cache)
				catch e
					return false
			if typeof cache is "object"
				res = {}
				for i of cache
  					res[i] = cache[i]  if i isnt "request" and typeof cache[i] isnt "function"
				return exports.OAuth.create(provider, res, cache.request)
			false

		storeCache: (provider, cache) ->
			createCookie "oauthio_provider_" + provider, encodeURIComponent(JSON.stringify(cache)), cache.expires_in - 10 or 3600
			return

		cacheEnabled: (cache) ->
			return config.options.cache  if typeof cache is "undefined"
			cache
