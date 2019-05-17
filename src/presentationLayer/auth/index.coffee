Url = require 'url'
async = require 'async'
UAParser = require 'ua-parser-js'
restify = require 'restify'

module.exports = (env) ->
	init: () ->
		return
	registerWs: () ->
		if not env.middlewares.connectauth
			env.middlewares.connectauth = {}
		if not env.middlewares.connectauth.all
			env.middlewares.connectauth.all = []
		# Chain of middlewares that are applied to each Auth endpoints
		createMiddlewareChain = () ->
			(req, res, next) ->
				chain = []
				i = 0
				for k, middleware of env.middlewares.connectauth.all
					do (middleware) ->
						chain.push (callback) ->
							middleware req, res, callback
				if chain.length == 0
					return next()
				async.waterfall chain, () ->
					next()

		middlewares_connectauth_chain = createMiddlewareChain()

		# oauth: refresh token
		env.server.post env.config.base + '/auth/refresh_token/:provider', middlewares_connectauth_chain, (req, res, next) ->
			e = new env.utilities.check.Error
			e.check req.body, key: env.utilities.check.format.key, secret: env.utilities.check.format.key, token:'string'
			e.check req.params, provider:'string'
			return next e if e.failed()
			env.data.apps.checkSecret req.body.key, req.body.secret, (e,r) ->
				return next e if e
				return next new env.utilities.check.Error "invalid credentials" if not r
				env.data.apps.getKeyset req.body.key, req.params.provider, (e, keyset) ->
					return next e if e
					if keyset.response_type != "code" and keyset.response_type != "both"
						return next new env.utilities.check.Error "refresh token is a server-side feature only"
					env.data.providers.getExtended req.params.provider, (e, provider) ->
						return next e if e
						if not provider.oauth2?.refresh
							return next new env.utilities.check.Error "refresh token not supported for " + req.params.provider
						oa = new env.utilities.oauth.oauth2(provider, keyset.parameters)
						oa.refresh req.body.token, keyset, env.send(res,next)

		# iframe injection for IE
		env.server.get env.config.base + '/auth/iframe', middlewares_connectauth_chain, (req, res, next) ->
			res.setHeader 'Content-Type', 'text/html'
			res.setHeader 'p3p', 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'
			e = new env.utilities.check.Error
			e.check req.params, d:'string'
			origin = env.utilities.check.escape req.params.d
			return next e if e.failed()
			content = '<!DOCTYPE html>\n'
			content += '<html><head><script>(function() {\n'

			content += 'function eraseCookie(name) {\n'
			content += '	var date = new Date();\n'
			content += '	date.setTime(date.getTime() - 86400000);\n'
			content += '	document.cookie = name+"=; expires="+date.toGMTString()+"; path=/";\n'
			content += '}\n'

			content += 'function readCookie(name) {\n'
			content += '	var nameEQ = name + "=";\n'
			content += '	var ca = document.cookie.split(";");\n'
			content += '	for(var i = 0; i < ca.length; i++) {\n'
			content += '		var c = ca[i];\n'
			content += '		while (c.charAt(0) === " ") c = c.substring(1,c.length);\n'
			content += '		if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length,c.length);\n'
			content += '	}\n'
			content += '	return null;\n'
			content += '}\n'

			content += 'var cookieCheckTimer = setInterval(function() {\n'
			content += '	var results = readCookie("oauthio_last");\n'
			content += '	if (!results) return;\n'
			content += '	var msg = decodeURIComponent(results.replace(/\\+/g, " "));\n'
			content += '	parent.postMessage(msg, "' + origin + '");\n'
			content += '	eraseCookie("oauthio_last");\n'
			content += '}, 1000);\n'

			content += '})();</script></head><body></body></html>'
			res.send content
			next()

		# oauth: get access token from server
		env.server.post env.config.base + '/auth/access_token', middlewares_connectauth_chain, (req, res, next) ->
			e = new env.utilities.check.Error
			e.check req.body, code: env.utilities.check.format.key, key: env.utilities.check.format.key, secret: env.utilities.check.format.key

			return next e if e.failed()
			env.data.states.get req.body.code, (err, state) ->
				return next err if err
				return next new env.utilities.check.Error 'code', 'invalid or expired' if not state || state.step != "1"
				return next new env.utilities.check.Error 'code', 'invalid or expired' if state.key != req.body.key
				env.data.apps.checkSecret state.key, req.body.secret, (e,r) ->
					return next e if e
					return next new env.utilities.check.Error "invalid credentials" if not r
					env.data.states.del req.body.code, (->)
					r = JSON.parse(state.token)
					r.state = state.options.state
					r.provider = state.provider
					res.buildJsend = false
					res.send r

		clientCallback = (data, req, res, next) -> (e, r, response_type) -> #data:state,provider,redirect_uri,origin
			if not e and data.redirect_uri
				redirect_infos = Url.parse env.fixUrl(data.redirect_uri), true
				if redirect_infos.hostname == 'oauth.io'
					e = new env.utilities.check.Error 'OAuth.redirect url must NOT be "oauth.io"'
			body = env.utilities.formatters.build e || r
			body.state = data.state if data.state
			body.provider = data.provider.toLowerCase() if data.provider
			if data.redirect_type == 'server'
				res.setHeader 'Location', data.redirect_uri + '?oauthio=' + encodeURIComponent(JSON.stringify(body))
				res.send 302
				return next()
			view = '<!DOCTYPE html>\n'
			view += '<html><head><script>(function() {\n'
			view += '\t"use strict";\n'
			view += '\tvar msg=' + JSON.stringify(JSON.stringify(body)) + ';\n'
			if data.redirect_uri
				if data.redirect_uri.indexOf('#') > 0
					view += '\tdocument.location.href = "' + data.redirect_uri + '&oauthio=" + encodeURIComponent(msg);\n'
				else
					view += '\tdocument.location.href = "' + data.redirect_uri + '#oauthio=" + encodeURIComponent(msg);\n'
			else
				uaparser = new UAParser()
				uaparser.setUA req.headers['user-agent']
				browser = uaparser.getBrowser()
				chromeext = data.origin.match(/chrome-extension:\/\/([^\/]+)/)
				if browser.name?.substr(0,2) == 'IE'
					res.setHeader 'p3p', 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'
					view += 'function createCookie(name, value) {\n'
					view += '	var date = new Date();\n'
					view += '	date.setTime(date.getTime() + 1200 * 1000);\n'
					view += '	var expires = "; expires="+date.toGMTString();\n'
					view += '	document.cookie = name+"="+value+expires+"; path=/";\n'
					view += '}\n'
					view += 'createCookie("oauthio_last",encodeURIComponent(msg));\n'
				else if (chromeext)
					view += '\tchrome.runtime.sendMessage("' + chromeext[1] + '", {data:msg});\n'
					view += '\twindow.close();\n'
				else
					view += 'var opener = window.opener || window.parent.window.opener;\n'
					view += '\n'
					view += 'if (opener)\n'
					view += '\topener.postMessage(msg, "' + data.origin + '");\n'
					view += '\twindow.close();\n'
			view += '})();</script></head><body style="text-align:center">\n'
			view += '<div style="display:inline-block; padding: 4px; border: 1px solid black">Your browser does not support popup. Please open this site with your default browser.<br />'
			view += '<a href="' + data.origin + '">' + data.origin + '</a></div>'
			view += '</body></html>'
			res.send view
			next()

		auth_middleware = (req, res, next) ->
			res.setHeader 'Content-Type', 'text/html'
			getState = (callback) ->
				return callback null, req.params.state if req.params.state
				if req.headers.referer
					stateref = req.headers.referer.match /state=([^&$]+)/
					stateid = stateref?[1]
					return callback null, stateid if stateid
				oaio_uid = req.headers.cookie?.match(/oaio_uid=%22(.*?)%22/)?[1]
				if oaio_uid
					env.data.redis.get 'cli:state:' + oaio_uid, callback
			getState (err, stateid) ->
				return next err if err
				return next new env.utilities.check.Error 'state', 'must be present' if not stateid
				env.data.states.get stateid, (err, state) ->
					return next err if err
					return next new env.utilities.check.Error 'state', 'invalid or expired' if not state
					req.stateid = stateid
					req.state = state
					next()

		# oauth: handle callbacks
		env.server.get env.config.base + '/auth', auth_middleware, middlewares_connectauth_chain, (req, res, next) ->
			stateid = req.stateid
			state = req.state
			delete req.stateid
			delete req.state
			callback = clientCallback state:state.options.state, provider:state.provider, redirect_uri:state.redirect_uri, origin:state.origin, redirect_type:state.redirect_type, req, res, next
			return callback req.error if req.error
			return callback new env.utilities.check.Error 'state', 'code already sent, please use /access_token' if state.step != "0"
			async.parallel [
					(cb) -> env.data.providers.getExtended state.provider, cb
					(cb) -> env.data.apps.getKeyset state.key, state.provider, cb
			], (err, r) =>
				return callback err if err
				provider = r[0]
				parameters = r[1].parameters
				response_type = r[1].response_type
				app_options = r[1].options
				oa = new env.utilities.oauth[state.oauthv](provider, parameters, app_options)
				oa.access_token state, req, (e, r) ->
					status = if e then 'error' else 'success'
					env.callhook 'connect.auth', req, res, (err) ->
						return callback err if err
						env.events.emit 'connect.callback', req:req, origin:state.origin, key:state.key, provider:state.provider, parameters:state.options?.parameters, status:status
						return callback e if e

						env.callhook 'connect.backend', results:r, key:state.key, provider:state.provider, status:status, (e) ->
							return callback e if e

							# If not client side mode, store the tokens
							if state.options.state_type != 'client'
								env.data.states.set stateid, token:JSON.stringify(r), step:1, (->)

							# Delete or keep refresh token from front-end response
							if not app_options.refresh_client
								delete r.refresh_token

							# If server_side only, remove everything and put the code
							if response_type == 'code'
								r = {}

							# If a state was given by client, give him only the code
							if state.options.state_type != 'client'
								r.code = stateid

							# Remove the state from db for client_side mode
							if state.options.state_type == 'client'
								env.data.states.del stateid, (->)

							callback null, r, response_type

		# oauth: popup or redirection to provider's authorization url
		env.server.get env.config.base + '/auth/:provider', (req, res, next) ->
			res.setHeader 'Content-Type', 'text/html'
			domain = null
			origin = null
			ref = env.fixUrl(req.headers['referer'] || req.headers['origin'] || req.params.d || req.params.redirect_uri || "")
			urlinfos = Url.parse ref
			if not urlinfos.hostname
				if ref
					ref_origin = 'redirect_uri' if req.params.redirect_uri
					ref_origin = 'static' if req.params.d
					ref_origin = 'origin' if req.headers['origin']
					ref_origin = 'referer' if req.headers['referer']
					return next new restify.InvalidHeaderError 'Cannot find hostname in %s from %s', ref, ref_origin
				else
					return next new restify.InvalidHeaderError 'Missing origin or referer.'
			origin = urlinfos.protocol + '//' + urlinfos.host

			options = {}
			if req.params.opts
				try
					options = JSON.parse(req.params.opts)
					return next new env.utilities.check.Error 'Options must be an object' if typeof options != 'object'
				catch e
					return next new env.utilities.check.Error 'Error in request parameters'

			callback = clientCallback state:options.state, provider:req.params.provider, origin:origin, redirect_uri:req.params.redirect_uri, req, res, next

			key = req.params.k
			if not key
				return callback new restify.MissingParameterError 'Missing OAuth.io public key.'

			oauthv = req.params.oauthv && {
				"2":"oauth2"
				"1":"oauth1"
			}[req.params.oauthv]
			provider_conf = undefined
			async.waterfall [
				# Checks domain against registered origins
				(cb) -> env.data.apps.checkDomain key, ref, cb
				# Send error if invalid domain
				(valid, cb) ->
					return cb new env.utilities.check.Error 'Origin "' + ref + '" does not match any registered domain/url on ' + env.config.url.host if not valid
					if req.params.redirect_uri
						env.data.apps.checkDomain key, req.params.redirect_uri, cb
					else
						cb null, true
				(valid, cb) ->
					return cb new env.utilities.check.Error 'Redirect "' + req.params.redirect_uri + '" does not match any registered domain on ' + env.config.url.host if not valid

					env.data.providers.getExtended req.params.provider, cb
				# Check type of OAuth, retrieve keyset
				(provider, cb) ->
					if oauthv and not provider[oauthv]
						return cb new env.utilities.check.Error "oauthv", "Unsupported oauth version: " + oauthv
					provider_conf = provider
					oauthv ?= 'oauth2' if provider.oauth2
					oauthv ?= 'oauth1' if provider.oauth1
					env.data.apps.getKeyset key, req.params.provider, (e,r) -> cb e,r,provider
				# Got keyset, error if inexistant,
				(keyset, provider, cb) ->
					return cb new env.utilities.check.Error 'This app is not configured for ' + provider.provider if not keyset
					{parameters, response_type} = keyset
					if response_type == 'code' and (not options.state or options.state_type)
						return cb new env.utilities.check.Error 'You must provide a state when server-side auth'
					env.callhook 'connect.auth', req, res, (err) ->
						return cb err if err
						env.events.emit 'connect.auth', req:req, key:key, provider:provider.provider, parameters:parameters
						options.response_type = response_type
						options.parameters = parameters
						options.state_type = 'client' if req.params.mobile
						opts = oauthv:oauthv, key:key, origin:origin, redirect_uri:req.params.redirect_uri, options:options
						opts.redirect_type = req.params.redirect_type if req.params.redirect_type
						oa = new env.utilities.oauth[oauthv](provider, parameters)
						oa.authorize opts, cb
				(authorize, cb) ->
					return cb null, authorize.url if not req.oaio_uid
					env.data.redis.set 'cli:state:' + req.oaio_uid, authorize.state, (err) ->
						return cb err if err
						env.data.redis.expire 'cli:state:' + req.oaio_uid, 1200
						cb null, authorize.url
			], (err, url) ->
				return callback err if err
				isJson = (value) ->
					try
						JSON.stringify(value)
						return true
					catch e
						return false

				#Fitbit and tripit needs this for mobile
				if provider_conf.mobile?
					if provider_conf.mobile?.params? and req.params.mobile == 'true'
						for k,v of provider_conf.mobile.params
							if url.indexOf('?') == -1
								url += '?'
							else
								url += '&'
							url += k + '=' + v
					if isJson(req.params.opts)
						opts = JSON.parse(req.params.opts)
						if opts.mobile is 'true' and provider_conf.mobile?.url?
							url_split = url.split("/oauth/authorize")
							if url_split.length is 2
								url = provider_conf.mobile.url + '/oauth/authorize/' + url_split[1]

				# For api like socrata, the endpoint change for every Socrata-powered data site
				if provider_conf.redefine_endpoint
					if isJson(req.params.opts)
						opts = JSON.parse(req.params.opts)
						if opts.endpoint
							url_split = url.split("/oauth/")
							if opts.endpoint[opts.endpoint.length - 1] is '/'
								opts.endpoint = opts.endpoint.slice(0, opts.endpoint.length - 1)
							if url_split.length is 2
								url = opts.endpoint + '/oauth/' + url_split[1]
				res.setHeader 'Location', url
				res.send 302
				next()
