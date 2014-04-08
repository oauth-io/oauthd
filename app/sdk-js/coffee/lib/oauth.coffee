"use strict"
config = require("../config")
cookies = require("../tools/cookies")
cache = require("../tools/cache")
Url = require("../tools/url")
sha1 = require("../tools/sha1")
module.exports = (window, document, jQuery, navigator) ->
	$ = jQuery

	# datastore = datastore(config, document)
	Url = Url(document)
	cookies.init config, document
	cache.init cookies, config

	oauthio = request: {}
	providers_desc = {}
	providers_cb = {}
	providers_api =
		execProvidersCb: (provider, e, r) ->
			if providers_cb[provider]
				cbs = providers_cb[provider]
				delete providers_cb[provider]

				for i of cbs
					cbs[i] e, r
			return

		
		# "fetchDescription": function(provider) is created once jquery loaded
		getDescription: (provider, opts, callback) ->
			opts = opts or {}
			return callback(null, providers_desc[provider])  if typeof providers_desc[provider] is "object"
			providers_api.fetchDescription provider  unless providers_desc[provider]
			return callback(null, {})  unless opts.wait
			providers_cb[provider] = providers_cb[provider] or []
			providers_cb[provider].push callback
			return

	config.oauthd_base = Url.getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0]
	client_states = []
	oauth_result = undefined
	(parse_urlfragment = ->
		results = /[\\#&]oauthio=([^&]*)/.exec(document.location.hash)
		if results
			document.location.hash = document.location.hash.replace(/&?oauthio=[^&]*/, "")
			oauth_result = decodeURIComponent(results[1].replace(/\+/g, " "))
			cookie_state = cookies.readCookie("oauthio_state")
			if cookie_state
				client_states.push cookie_state
				cookies.eraseCookie "oauthio_state"
		return
	)()

	window.location_operations = {
		reload: ->
			document.location.reload()
		getHash: ->
			return document.location.hash
		setHash: (newHash) ->
			document.location.hash = newHash
		changeHref: (newLocation) ->
			document.location.href = newLocation
	}

	return (exports) ->
		
		# create popup
		delayedFunctions = ($) ->
			oauthio.request = require("./oauthio_requests")($, config, client_states, cache)
			providers_api.fetchDescription = (provider) ->
				return  if providers_desc[provider]
				providers_desc[provider] = true
				$.ajax(
					url: config.oauthd_base + config.oauthd_api + "/providers/" + provider
					data:
						extend: true

					dataType: "json"
				).done((data) ->
					providers_desc[provider] = data.data
					providers_api.execProvidersCb provider, null, data.data
					return
				).always ->
					if typeof providers_desc[provider] isnt "object"
						delete providers_desc[provider]

						providers_api.execProvidersCb provider, new Error("Unable to fetch request description")
					return

				return

			return
		unless exports.OAuth?
			exports.OAuth =
				initialize: (public_key, options) ->
					config.key = public_key
					if options
						for i of options
							config.options[i] = options[i]
					return

				setOAuthdURL: (url) ->
					config.oauthd_url = url
					config.oauthd_base = Url.getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0]
					return

				getVersion: ->
					config.version

				create: (provider, tokens, request) ->
					return cache.tryCache(exports.OAuth, provider, true)  unless tokens
					providers_api.fetchDescription provider  if typeof request isnt "object"
					make_res = (method) ->
						oauthio.request.mkHttp provider, tokens, request, method

					make_res_endpoint = (method, url) ->
						oauthio.request.mkHttpEndpoint data.provider, tokens, request, method, url

					res = {}
					for i of tokens
						res[i] = tokens[i]
					res.get = make_res("GET")
					res.post = make_res("POST")
					res.put = make_res("PUT")
					res.patch = make_res("PATCH")
					res.del = make_res("DELETE")
					res.me = (opts) ->
						oauthio.request.mkHttpMe data.provider, tokens, request, "GET"
						return

					res

				popup: (provider, opts, callback) ->
					getMessage = (e) ->
						return  if e.origin isnt config.oauthd_base
						try
							wnd.close()
						opts.data = e.data
						oauthio.request.sendCallback opts, defer
					wnd = undefined
					frm = undefined
					wndTimeout = undefined
					defer = window.jQuery?.Deferred()
					opts = opts or {}
					unless config.key
						defer?.reject new Error("OAuth object must be initialized")
						return callback(new Error("OAuth object must be initialized"))
					if arguments.length is 2
						callback = opts
						opts = {}
					if cache.cacheEnabled(opts.cache)
						res = cache.tryCache(exports.OAuth, provider, opts.cache)
						if res
							defer?.resolve res
							if callback
								return callback(null, res)
							else
								return
					unless opts.state
						opts.state = sha1.create_hash()
						opts.state_type = "client"
					client_states.push opts.state
					url = config.oauthd_url + "/auth/" + provider + "?k=" + config.key
					url += "&d=" + encodeURIComponent(Url.getAbsUrl("/"))
					url += "&opts=" + encodeURIComponent(JSON.stringify(opts))  if opts
					wnd_settings =
						width: Math.floor(window.outerWidth * 0.8)
						height: Math.floor(window.outerHeight * 0.5)

					wnd_settings.height = 350  if wnd_settings.height < 350
					wnd_settings.width = 800  if wnd_settings.width < 800
					wnd_settings.left = window.screenX + (window.outerWidth - wnd_settings.width) / 2
					wnd_settings.top = window.screenY + (window.outerHeight - wnd_settings.height) / 8
					wnd_options = "width=" + wnd_settings.width + ",height=" + wnd_settings.height
					wnd_options += ",toolbar=0,scrollbars=1,status=1,resizable=1,location=1,menuBar=0"
					wnd_options += ",left=" + wnd_settings.left + ",top=" + wnd_settings.top
					opts =
						provider: provider
						cache: opts.cache

					opts.callback = (e, r) ->
						if window.removeEventListener
							window.removeEventListener "message", getMessage, false
						else if window.detachEvent
							window.detachEvent "onmessage", getMessage
						else document.detachEvent "onmessage", getMessage  if document.detachEvent
						opts.callback = ->

						if wndTimeout
							clearTimeout wndTimeout
							wndTimeout = `undefined`
						(if callback then callback(e, r) else `undefined`)

					if window.attachEvent
						window.attachEvent "onmessage", getMessage
					else if document.attachEvent
						document.attachEvent "onmessage", getMessage
					else window.addEventListener "message", getMessage, false  if window.addEventListener
					if typeof chrome isnt "undefined" and chrome.runtime and chrome.runtime.onMessageExternal
						chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) ->
							request.origin = sender.url.match(/^.{2,5}:\/\/[^/]+/)[0]
							defer?.resolve()
							getMessage request

					if not frm and (navigator.userAgent.indexOf("MSIE") isnt -1 or navigator.appVersion.indexOf("Trident/") > 0)
						frm = document.createElement("iframe")
						frm.src = config.oauthd_url + "/auth/iframe?d=" + encodeURIComponent(Url.getAbsUrl("/"))
						frm.width = 0
						frm.height = 0
						frm.frameBorder = 0
						frm.style.visibility = "hidden"
						document.body.appendChild frm
					wndTimeout = setTimeout(->
						defer?.reject new Error("Authorization timed out")
						if opts.callback and typeof opts.callback == "function"
							opts.callback new Error("Authorization timed out")  
						try
							wnd.close()
						return
					, 1200 * 1000)
					wnd = window.open(url, "Authorization", wnd_options)
					if wnd
						wnd.focus()
					else
						defer?.reject new Error("Could not open a popup")
						opts.callback new Error("Could not open a popup")  if opts.callback and typeof opts.callback == "function"
					return defer?.promise()

				redirect: (provider, opts, url) ->
					if arguments.length is 2
						url = opts
						opts = {}
					if cache.cacheEnabled(opts.cache)
						res = cache.tryCache(exports.OAuth, provider, opts.cache)
						if res
							url = Url.getAbsUrl(url) + ((if (url.indexOf("#") is -1) then "#" else "&")) + "oauthio=cache"
							window.location_operations.changeHref url
							window.location_operations.reload()
							return
					unless opts.state
						opts.state = sha1.create_hash()
						opts.state_type = "client"
					cookies.createCookie "oauthio_state", opts.state
					redirect_uri = encodeURIComponent(Url.getAbsUrl(url))
					url = config.oauthd_url + "/auth/" + provider + "?k=" + config.key
					url += "&redirect_uri=" + redirect_uri
					url += "&opts=" + encodeURIComponent(JSON.stringify(opts))  if opts
					window.location_operations.changeHref url
					return

				callback: (provider, opts, callback) ->
					defer = window.jQuery?.Deferred()
					if arguments.length is 1 and typeof provider == "function"
						callback = provider
						provider = `undefined`
						opts = {}
					if arguments.length is 1 and typeof provider == "string"
						opts = {}
					if arguments.length is 2 and typeof opts == "function"
						callback = opts
						opts = {}
					if cache.cacheEnabled(opts.cache) or oauth_result is "cache"
						res = cache.tryCache(exports.OAuth, provider, opts.cache)
						if oauth_result is "cache" and (typeof provider isnt "string" or not provider)
							defer?.reject new Error("You must set a provider when using the cache")
							if callback
								return callback(new Error("You must set a provider when using the cache"))
							else
								return defer?.promise()
						if res
							if callback
								return callback(null, res)  if res
							else
								defer?.resolve res
								return defer?.promise()
					return  unless oauth_result
					oauthio.request.sendCallback {
						data: oauth_result
						provider: provider
						cache: opts.cache
						callback: callback }, defer

					return defer?.promise()

				clearCache: (provider) ->
					cookies.eraseCookie "oauthio_provider_" + provider
					return

				http_me: (opts) ->
					oauthio.request.http_me opts  if oauthio.request.http_me
					return

				http: (opts) ->
					oauthio.request.http opts  if oauthio.request.http
					return

			if typeof window.jQuery is "undefined"
				_preloadcalls = []
				delayfn = undefined
				if typeof chrome isnt "undefined" and chrome.extension
					delayfn = ->
						->
							throw new Error("Please include jQuery before oauth.js")
							return
				else
					e = document.createElement("script")
					e.src = "//code.jquery.com/jquery.min.js"
					e.type = "text/javascript"
					e.onload = ->
						delayedFunctions window.jQuery
						for i of _preloadcalls
							_preloadcalls[i].fn.apply(null, _preloadcalls[i].args)
						return

					document.getElementsByTagName("head")[0].appendChild e
					delayfn = (f) ->
						->
							args_copy = []
							for arg of arguments
								 args_copy[arg] = arguments[arg]
							_preloadcalls.push
								fn: f
								args: args_copy

							return
				oauthio.request.http = delayfn(->
					oauthio.request.http.apply exports.OAuth, arguments
					return
				)
				providers_api.fetchDescription = delayfn(->
					providers_api.fetchDescription.apply providers_api, arguments
					return
				)
				oauthio.request = require("./oauthio_requests")(window.jQuery, config, client_states, cache)
			else
				delayedFunctions window.jQuery
		return
