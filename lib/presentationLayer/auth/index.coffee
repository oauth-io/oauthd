Url = require 'url'
async = require 'async'
UAParser = require 'ua-parser-js'

module.exports = (env) ->
	init: () ->
		return
	registerWs: () ->
		# oauth: refresh token
		env.server.post env.config.base + '/auth/refresh_token/:provider', (req, res, next) ->
			e = new env.engine.check.Error
			e.check req.body, key:check.format.key, secret:check.format.key, token:'string'
			e.check req.params, provider:'string'
			return next e if e.failed()
			env.DAL.db.apps.checkSecret req.body.key, req.body.secret, (e,r) ->
				return next e if e
				return next new env.engine.check.Error "invalid credentials" if not r
				env.DAL.db.apps.getKeyset req.body.key, req.params.provider, (e, keyset) ->
					return next e if e
					if keyset.response_type != "code" and keyset.response_type != "both"
						return next new env.engine.check.Error "refresh token is a server-side feature only"
					env.DAL.db.providers.getExtended req.params.provider, (e, provider) ->
						return next e if e
						if not provider.oauth2?.refresh
							return next new env.engine.check.Error "refresh token not supported for " + req.params.provider
						oa = new @engine.oauth.oauth2(provider, keyset.parameters)
						oa.refresh req.body.token, keyset, send(res,next)

		# iframe injection for IE
		env.server.get env.config.base + '/auth/iframe', (req, res, next) ->
			res.setHeader 'Content-Type', 'text/html'
			res.setHeader 'p3p', 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'
			e = new env.engine.check.Error
			e.check req.params, d:'string'
			origin = env.engine.check.escape req.params.d
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
		env.server.post env.config.base + '/auth/access_token', (req, res, next) ->
			e = new env.engine.check.Error
			e.check req.body, code:check.format.key, key:check.format.key, secret:check.format.key
			return next e if e.failed()
			env.DAL.db.states.get req.body.code, (err, state) ->
				return next err if err
				return next new env.engine.check.Error 'code', 'invalid or expired' if not state || state.step != "1"
				return next new env.engine.check.Error 'code', 'invalid or expired' if state.key != req.body.key
				env.DAL.db.apps.checkSecret state.key, req.body.secret, (e,r) ->
					return next e if e
					return next new env.engine.check.Error "invalid credentials" if not r
					env.DAL.db.states.del req.body.code, (->)
					r = JSON.parse(state.token)
					r.state = state.options.state
					r.provider = state.provider
					res.buildJsend = false
					res.send r

		clientCallback = (data, req, res, next) -> (e, r) -> #data:state,provider,redirect_uri,origin
			if not e and data.redirect_uri
				redirect_infos = Url.parse env.fixUrl(data.redirect_uri), true
				if redirect_infos.hostname == 'oauth.io'
					e = new env.engine.check.Error 'OAuth.redirect url must NOT be "oauth.io"'
			body = env.engine.formatters.build e || r
			body.state = data.state if data.state
			body.provider = data.provider.toLowerCase() if data.provider
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
					view += 'if (opener)\n'
					view += '\topener.postMessage(msg, "' + data.origin + '");\n'
					view += '\twindow.close();\n'
			view += '})();</script></head><body></body></html>'
			res.send view
			next()

		

		# oauth: handle callbacks
		env.server.get env.config.base + '/auth', (req, res, next) ->
			res.setHeader 'Content-Type', 'text/html'
			getState = (callback) ->
				return callback null, req.params.state if req.params.state
				if req.headers.referer
					stateref = req.headers.referer.match /state=([^&$]+)/
					stateid = stateref?[1]
					return callback null, stateid if stateid
				oaio_uid = req.headers.cookie?.match(/oaio_uid=%22(.*?)%22/)?[1]
				if oaio_uid
					env.DAL.db.redis.get 'cli:state:' + oaio_uid, callback
			getState (err, stateid) ->
				return next err if err
				return next new env.engine.check.Error 'state', 'must be present' if not stateid
				env.DAL.db.states.get stateid, (err, state) ->
					return next err if err
					return next new env.engine.check.Error 'state', 'invalid or expired' if not state
					callback = clientCallback state:state.options.state, provider:state.provider, redirect_uri:state.redirect_uri, origin:state.origin, req, res, next
					return callback new env.engine.check.Error 'state', 'code already sent, please use /access_token' if state.step != "0"
					async.parallel [
							(cb) -> env.DAL.db.providers.getExtended state.provider, cb
							(cb) -> env.DAL.db.apps.getKeyset state.key, state.provider, cb
					], (err, r) =>
						return callback err if err
						provider = r[0]
						parameters = r[1].parameters
						response_type = r[1].response_type
						oa = new env.engine.oauth[state.oauthv](provider, parameters)
						oa.access_token state, req, (e, r) ->
							status = if e then 'error' else 'success'
							env.plugins.data.callhook 'connect.auth', req, res, (err) ->
								return callback err if err
								env.events.emit 'connect.callback', req:req, origin:state.origin, key:state.key, provider:state.provider, parameters:state.options?.parameters, status:status
								return callback e if e

								env.plugins.data.callhook 'connect.backend', results:r, key:state.key, provider:state.provider, status:status, (e) ->
									return callback e if e

									if response_type != 'token'
										env.DAL.db.states.set stateid, token:JSON.stringify(r), step:1, (->)
									if response_type != 'code'
										delete r.refresh_token
									if response_type == 'code'
										r = {}
									if response_type != 'token'
										r.code = stateid
									if response_type == 'token'
										env.DAL.db.states.del stateid, (->)
									callback null, r

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
					return next new env.engine.check.Error 'Options must be an object' if typeof options != 'object'
				catch e
					return next new env.engine.check.Error 'Error in request parameters'

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
				(cb) -> env.DAL.db.apps.checkDomain key, ref, cb
				(valid, cb) ->
					return cb new env.engine.check.Error 'Origin "' + ref + '" does not match any registered domain/url on ' + env.config.url.host if not valid
					if req.params.redirect_uri
						env.DAL.db.apps.checkDomain key, req.params.redirect_uri, cb
					else
						cb null, true
				(valid, cb) ->
					return cb new env.engine.check.Error 'Redirect "' + req.params.redirect_uri + '" does not match any registered domain on ' + env.config.url.host if not valid

					env.DAL.db.providers.getExtended req.params.provider, cb
				(provider, cb) ->
					if oauthv and not provider[oauthv]
						return cb new env.engine.check.Error "oauthv", "Unsupported oauth version: " + oauthv
					provider_conf = provider
					oauthv ?= 'oauth2' if provider.oauth2
					oauthv ?= 'oauth1' if provider.oauth1
					env.DAL.db.apps.getKeyset key, req.params.provider, (e,r) -> cb e,r,provider
				(keyset, provider, cb) ->
					return cb new env.engine.check.Error 'This app is not configured for ' + provider.provider if not keyset
					{parameters, response_type} = keyset
					if response_type != 'token' and (not options.state or options.state_type)
						return cb new env.engine.check.Error 'You must provide a state when server-side auth'
					env.plugins.data.callhook 'connect.auth', req, res, (err) ->
						return cb err if err
						env.events.emit 'connect.auth', req:req, key:key, provider:provider.provider, parameters:parameters
						options.response_type = response_type
						options.parameters = parameters
						opts = oauthv:oauthv, key:key, origin:origin, redirect_uri:req.params.redirect_uri, options:options
						oa = new env.engine.oauth[oauthv](provider, parameters)
						oa.authorize opts, cb
				(authorize, cb) ->
						return cb null, authorize.url if not req.oaio_uid
						env.DAL.db.redis.set 'cli:state:' + req.oaio_uid, authorize.state, (err) ->
							return cb err if err
							env.DAL.db.redis.expire 'cli:state:' + req.oaio_uid, 1200
							cb null, authorize.url
			], (err, url) ->
				return callback err if err

				#Fitbit needs this for mobile
				if provider_conf.mobile?.params? and req.params.mobile == 'true'
					for k,v of provider_conf.mobile.params
						if url.indexOf('?') == -1
							url += '?'
						else
							url += '&'
						url += k + '=' + v
				
				res.setHeader 'Location', url
				res.send 302
				next()
