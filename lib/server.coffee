# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

'use strict'

fs = require 'fs'
Path = require 'path'
Url = require 'url'

async = require 'async'
restify = require 'restify'
UAParser = require 'ua-parser-js'

config = require './config'
db = require './db'
plugins = require './plugins'
exit = require './exit'
check = require './check'
formatters = require './formatters'
sdk_js = require './sdk_js'

oauth =
	oauth1: require './oauth1'
	oauth2: require './oauth2'

auth = plugins.data.auth


# build server options
server_options =
	name: 'OAuth Daemon'
	version: '1.0.0'

if config.ssl
	server_options.key = fs.readFileSync Path.resolve(config.rootdir, config.ssl.key)
	server_options.certificate = fs.readFileSync Path.resolve(config.rootdir, config.ssl.certificate)
	console.log 'SSL is enabled !'

server_options.formatters = formatters.formatters

# create server
server = restify.createServer server_options

server.use restify.authorizationParser()
server.use restify.queryParser()
server.use restify.bodyParser mapParams:false
server.use (req, res, next) ->
	res.setHeader 'Content-Type', 'application/json'
	next()

# add server to shared plugins data and run init
plugins.data.server = server
plugins.runSync 'init'

# little help
server.send = send = (res, next) -> (e, r) ->
	return next(e) if e
	res.send (if r? then r else check.nullv)
	next()

fixUrl = (ref) -> ref.replace /^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2'

# generated js sdk
server.get config.base + '/download/latest/oauth.js', (req, res, next) ->
	sdk_js.get (e, r) ->
		return next e if e
		res.setHeader 'Content-Type', 'application/javascript'
		res.send r
		next()

# generated js sdk minified
server.get config.base + '/download/latest/oauth.min.js', (req, res, next) ->
	sdk_js.getmin (e, r) ->
		return next e if e
		res.setHeader 'Content-Type', 'application/javascript'
		res.send r
		next()

# oauth: refresh token
server.post config.base + '/refresh_token/:provider', (req, res, next) ->
	e = new check.Error
	e.check req.body, key:check.format.key, secret:check.format.key, token:'string'
	e.check req.params, provider:'string'
	return next e if e.failed()
	db.apps.checkSecret req.body.key, req.body.secret, (e,r) ->
		return next e if e
		return next new check.Error "invalid credentials" if not r
		db.apps.getKeyset req.body.key, req.params.provider, (e, keyset) ->
			return next e if e
			if keyset.response_type != "code"
				return next new check.Error "refresh token is a server-side feature only"
			db.providers.getExtended req.params.provider, (e, provider) ->
				return next e if e
				if not provider.oauth2?.refresh
					return next new check.Error "refresh token not supported for " + req.params.provider
				oa = new oauth.oauth2
				oa.refresh keyset, provider, req.body.token, send(res,next)

# iframe injection for IE
server.get config.base + '/iframe', (req, res, next) ->
	res.setHeader 'Content-Type', 'text/html'
	res.setHeader 'p3p', 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'
	e = new check.Error
	e.check req.params, d:'string'
	origin = check.escape req.params.d
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
server.post config.base + '/access_token', (req, res, next) ->
	e = new check.Error
	e.check req.body, code:check.format.key, key:check.format.key, secret:check.format.key
	return next e if e.failed()
	db.states.get req.body.code, (err, state) ->
		return next err if err
		return next new check.Error 'code', 'invalid or expired' if not state || state.step != "1"
		return next new check.Error 'code', 'invalid or expired' if state.key != req.body.key
		db.apps.checkSecret state.key, req.body.secret, (e,r) ->
			return next e if e
			return next new check.Error "invalid credentials" if not r
			db.states.del req.body.code, (->)
			r = JSON.parse(state.token)
			r.state = state.options.state
			r.provider = state.provider
			res.buildJsend = false
			res.send r
			next()

clientCallback = (data, req, res, next) -> (e, r) -> #data:state,provider,redirect_uri,origin
	body = formatters.build e || r
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
		if browser.name.substr(0,2) == 'IE'
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
server.get config.base + '/', (req, res, next) ->
	if Object.keys(req.params).length == 0
		res.setHeader 'Location', config.base + '/admin'
		res.send 302
		return next()
	res.setHeader 'Content-Type', 'text/html'
	getState = (callback) ->
		return callback null, req.params.state if req.params.state
		if req.headers.referer
			stateref = req.headers.referer.match /state=([^&$]+)/
			stateid = stateref?[1]
			return callback null, stateid if stateid
		oad_uid = req.headers.cookie?.match(/oad_uid=%22(.*?)%22/)?[1]
		if oad_uid
			db.redis.get 'cli:state:' + oad_uid, callback
	getState (err, stateid) ->
		return next err if err
		return next new check.Error 'state', 'must be present' if not stateid
		db.states.get stateid, (err, state) ->
			return next err if err
			return next new check.Error 'state', 'invalid or expired' if not state
			callback = clientCallback state:state.options.state, provider:state.provider, redirect_uri:state.redirect_uri, origin:state.origin, req, res, next
			return callback new check.Error 'state', 'code already sent, please use /access_token' if state.step != "0"
			oa = new oauth[state.oauthv]
			oa.access_token state, req, (e, r) ->
				status = if e then 'error' else 'success'

				plugins.data.emit 'connect.callback', key:state.key, provider:state.provider, status:status
				if not e
					if state.options.response_type != 'token'
						db.states.set stateid, token:JSON.stringify(r), step:1, (->) # assume the db is faster than ext http reqs
					if state.options.response_type == 'code'
						r = {}
					if state.options.response_type != 'token'
						r.code = stateid
					if state.options.response_type == 'token'
						db.states.del stateid, (->)
					oad_uid = req.headers.cookie?.match(/oad_uid=%22(.*?)%22/)?[1]
					if not oad_uid
						oad_uid = db.generateUid()
						d = new Date (new Date).getTime() + 30*24*3600*1000
						res.setHeader 'Set-Cookie', 'oad_uid=%22' + oad_uid + '%22; Path=/; Expires=' + d.toGMTString()

				callback e, r

# oauth: popup or redirection to provider's authorization url
server.get config.base + '/auth/:provider', (req, res, next) ->
	res.setHeader 'Content-Type', 'text/html'

	domain = null
	origin = null
	ref = fixUrl(req.headers['referer'] || req.headers['origin'] || req.params.d || req.params.redirect_uri || "")
	urlinfos = Url.parse ref
	if not urlinfos.hostname
		return next new restify.InvalidHeaderError 'Missing origin or referer.'
	origin = urlinfos.protocol + '//' + urlinfos.host

	options = {}
	if req.params.opts
		try
			options = JSON.parse(req.params.opts)
			return cb new check.Error 'Options must be an object' if typeof options != 'object'
		catch e
			return cb new check.Error 'Error in request parameters'

	callback = clientCallback state:options.state, provider:req.params.provider, origin:origin, redirect_uri:req.params.redirect_uri, req, res, next

	key = req.params.k
	if not key
		return callback new restify.MissingParameterError 'Missing OAuthd public key.'

	oauthv = req.params.oauthv && {
		"2":"oauth2"
		"1":"oauth1"
	}[req.params.oauthv]

	async.waterfall [
		(cb) -> db.apps.checkDomain key, ref, cb
		(valid, cb) ->
			return cb new check.Error 'Origin "' + ref + '" does not match any registered domain/url on ' + config.url.host if not valid
			if req.params.redirect_uri
				db.apps.checkDomain key, req.params.redirect_uri, cb
			else
				cb null, true
		(valid, cb) ->
			return cb new check.Error 'Redirect "' + req.params.redirect_uri + '" does not match any registered domain on ' + config.url.host if not valid

			db.providers.getExtended req.params.provider, cb
		(provider, cb) ->
			plugins.data.emit 'connect.auth', key:key, provider:provider.provider
			if oauthv and not provider[oauthv]
				return cb new check.Error "oauthv", "Unsupported oauth version: " + oauthv
			oauthv ?= 'oauth2' if provider.oauth2
			oauthv ?= 'oauth1' if provider.oauth1
			db.apps.getKeyset key, req.params.provider, (e,r) -> cb e,r,provider
		(keyset, provider, cb) ->
			return cb new check.Error 'This app is not configured for ' + provider.provider if not keyset
			{parameters, response_type} = keyset
			plugins.data.emit 'connect.auth', key:key, provider:provider.provider, parameters:parameters
			if response_type != 'token' and (not options.state or options.state_type)
				return cb new check.Error 'You must provide a state when server-side auth'
			options.response_type = response_type
			opts = oauthv:oauthv, key:key, origin:origin, redirect_uri:req.params.redirect_uri, options:options
			oa = new oauth[oauthv]
			oa.authorize provider, parameters, opts, cb
		(authorize, cb) ->
			oad_uid = req.headers.cookie?.match(/oad_uid=%22(.*?)%22/)?[1]
			return cb null, authorize.url if not oad_uid
			db.redis.set 'cli:state:' + oad_uid, authorize.state, (err) ->
				return cb err if err
				db.redis.expire 'cli:state:' + oad_uid, 1200
				cb null, authorize.url
	], (err, url) ->
		return callback err if err
		res.setHeader 'Location', url
		res.send 302
		next()

# create an application
server.post config.base_api + '/apps', auth.needed, (req, res, next) ->
	db.apps.create req.body, (e, r) ->
		return next(e) if e
		plugins.data.emit 'app.create', req, r
		res.send name:r.name, key:r.key, domains:r.domains
		next()

# get infos of an app
server.get config.base_api + '/apps/:key', auth.needed, (req, res, next) ->
	async.parallel [
		(cb) -> db.apps.get req.params.key, cb
		(cb) -> db.apps.getDomains req.params.key, cb
		(cb) -> db.apps.getKeysets req.params.key, cb
	], (e, r) ->
		return next(e) if e
		res.send name:r[0].name, key:r[0].key, secret:r[0].secret, domains:r[1], keysets:r[2]
		next()

# update infos of an app
server.post config.base_api + '/apps/:key', auth.needed, (req, res, next) ->
	db.apps.update req.params.key, req.body, send(res,next)

# remove an app
server.del config.base_api + '/apps/:key', auth.needed, (req, res, next) ->
	db.apps.get req.params.key, (e, app) ->
		return next(e) if e
		db.apps.remove req.params.key, (e, r) ->
			return next(e) if e
			plugins.data.emit 'app.remove', req, app
			res.send check.nullv
			next()

# reset the public key of an app
server.post config.base_api + '/apps/:key/reset', auth.needed, (req, res, next) ->
	db.apps.resetKey req.params.key, send(res,next)

# list valid domains for an app
server.get config.base_api + '/apps/:key/domains', auth.needed, (req, res, next) ->
	db.apps.getDomains req.params.key, send(res,next)

# update valid domains list for an app
server.post config.base_api + '/apps/:key/domains', auth.needed, (req, res, next) ->
	db.apps.updateDomains req.params.key, req.body.domains, send(res,next)

# add a valid domain for an app
server.post config.base_api + '/apps/:key/domains/:domain', auth.needed, (req, res, next) ->
	db.apps.addDomain req.params.key, req.params.domain, send(res,next)

# remove a valid domain for an app
server.del config.base_api + '/apps/:key/domains/:domain', auth.needed, (req, res, next) ->
	db.apps.remDomain req.params.key, req.params.domain, send(res,next)

# list keysets (provider names) for an app
server.get config.base_api + '/apps/:key/keysets', auth.needed, (req, res, next) ->
	db.apps.getKeysets req.params.key, send(res,next)

# get a keyset for an app and a provider
server.get config.base_api + '/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	db.apps.getKeyset req.params.key, req.params.provider, send(res,next)

# add or update a keyset for an app and a provider
server.post config.base_api + '/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	db.apps.addKeyset req.params.key, req.params.provider, req.body, send(res,next)

# remove a keyset for a app and a provider
server.del config.base_api + '/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	db.apps.remKeyset req.params.key, req.params.provider, send(res,next)

# get providers list
server.get config.base_api + '/providers', auth.needed, (req, res, next) ->
	db.providers.getList send(res,next)

# get a provider config
server.get config.base_api + '/providers/:provider', (req, res, next) ->
	res.setHeader 'Access-Control-Allow-Origin', '*'
	res.setHeader 'Access-Control-Allow-Methods', 'GET'
	if req.query.extend
		db.providers.getExtended req.params.provider, send(res,next)
	else
		db.providers.get req.params.provider, send(res,next)

# get a provider config's extras
server.get config.base_api + '/providers/:provider/settings', (req, res, next) ->
		db.providers.getSettings req.params.provider, send(res,next)

# get a provider logo
server.get config.base_api + '/providers/:provider/logo', ((req, res, next) ->
		fs.exists Path.normalize(config.rootdir + '/providers/' + req.params.provider + '/logo.png'), (exists) ->
			if not exists
				req.params.provider = 'default'
			req.url = '/' + req.params.provider + '/logo.png'
			req._url = Url.parse req.url
			req.path()
			req._path = req._url._path
			next()
	), restify.serveStatic
		directory: config.rootdir + '/providers'
		maxAge: 120

# get a provider file
server.get config.base_api + '/providers/:provider/:file', ((req, res, next) ->
		req.url = '/' + req.params.provider + '/' + req.params.file
		req._url = Url.parse req.url
		req._path = req._url._path
		next()
	), restify.serveStatic
		directory: config.rootdir + '/providers'
		maxAge: config.cacheTime

# listen
exports.listen = (callback) ->
	# tell plugins to configure the server if needed
	plugins.run 'setup', ->
		listen_args = [config.port]
		listen_args.push config.bind if config.bind
		listen_args.push (err) ->
			return callback err if err
			#exit.push 'Http(s) server', (cb) -> server.close cb
			#/!\ server.close = timeout if at least one connection /!\ wtf?
			console.log '%s listening at %s for %s', server.name, server.url, config.host_url
			plugins.data.emit 'server', null
			callback null, server

		server.on 'error', (err) -> callback err
		server.listen.apply server, listen_args
