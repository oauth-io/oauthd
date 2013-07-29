# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

'use strict'

fs = require 'fs'
Path = require 'path'
Url = require 'url'

async = require 'async'
restify = require 'restify'

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

# oauth: handle callbacks
server.get config.base + '/', (req, res, next) ->
	res.setHeader 'Content-Type', 'text/html'
	if not req.params.state
		return next new check.Error 'state', 'must be present'
	db.states.get req.params.state, (err, state) ->
		return next err if err
		return next new check.Error 'state', 'invalid or expired' if not state
		oauth[state.oauthv].access_token state, req, (e, r) ->
			status = if e then 'error' else 'success'

			plugins.data.emit 'connect.callback', key:state.key, provider:state.provider, status:status
			body = formatters.build e || r
			body.provider = state.provider.toLowerCase()
			view = '<script>(function() {\n'
			view += '\t"use strict";\n'
			view += '\tvar msg=' + JSON.stringify(JSON.stringify(body)) + ';\n'
			if state.redirect_uri
				redirect_infos = Url.parse state.redirect_uri
				if redirect_infos.hostname == config.url.hostname
					return next new check.Error 'OAuth.redirect url must NOT be "' + config.url.host + '"'
				view += '\tdocument.location.href = "' + state.redirect_uri + '#oauthio=" + encodeURIComponent(msg);\n'
			else
				view += '\tvar opener = window.opener || window.parent.window.opener;\n'
				view += '\tif (opener)\n'
				view += '\t\topener.postMessage(msg, "' + state.origin + '");\n'
				view += '\twindow.close();\n'
			view += '})();</script>'
			res.send view
			next()

# oauth: popup or redirection to provider's authorization url
server.get config.base + '/:provider', (req, res, next) ->
	res.setHeader 'Content-Type', 'text/html'
	key = req.params.k
	if not key
		return next new restify.MissingParameterError 'Missing OAuth.io public key.'

	domain = null
	origin = null
	ref = req.headers['referer'] || req.headers['origin'] || req.params.d || req.params.redirect_uri
	if ref
		urlinfos = Url.parse(ref)
		if not urlinfos.hostname
			return next new restify.InvalidHeaderError 'Missing origin or referer.'
		origin = urlinfos.protocol + '//' + urlinfos.host

	oauthv = req.params.oauthv && {
		"2":"oauth2"
		"1":"oauth1"
	}[req.params.oauthv]

	async.waterfall [
		(cb) -> db.apps.checkDomain key, ref, cb
		(valid, cb) ->
			return cb new check.Error 'Domain name does not match any registered domain on ' + config.url.host if not valid
			if req.params.redirect_uri
				db.apps.checkDomain key, req.params.redirect_uri, cb
			else
				cb null, true
		(valid, cb) ->
			return cb new check.Error 'Redirect domain name does not match any registered domain on ' + config.url.host if not valid

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
			options = {}
			if req.params.opts
				try
					options = JSON.parse(req.params.opts)
				catch e
					cb new check.Error 'Error in request parameters'
			opts = oauthv:oauthv, key:key, origin:origin, redirect_uri:req.params.redirect_uri, options:options
			oauth[oauthv].authorize provider, keyset, opts, cb
	], (err, url) ->
		return next err if err
		res.setHeader 'Location', url
		res.send 302
		next()

# create an application
server.post config.base + '/api/apps', auth.needed, (req, res, next) ->
	db.apps.create req.body, (e, r) ->
		return next(e) if e
		plugins.data.emit 'app.create', req, r
		res.send name:r.name, key:r.key, domains:r.domains
		next()

# get infos of an app
server.get config.base + '/api/apps/:key', auth.needed, (req, res, next) ->
	async.parallel [
		(cb) -> db.apps.get req.params.key, cb
		(cb) -> db.apps.getDomains req.params.key, cb
		(cb) -> db.apps.getKeysets req.params.key, cb
	], (e, r) ->
		return next(e) if e
		res.send name:r[0].name, key:r[0].key, domains:r[1], keysets:r[2]
		next()

# update infos of an app
server.post config.base + '/api/apps/:key', auth.needed, (req, res, next) ->
	db.apps.update req.params.key, req.body, send(res,next)

# remove an app
server.del config.base + '/api/apps/:key', auth.needed, (req, res, next) ->
	db.apps.get req.params.key, (e, app) ->
		return next(e) if e
		db.apps.remove req.params.key, (e, r) ->
			return next(e) if e
			plugins.data.emit 'app.remove', req, app
			res.send check.nullv
			next()

# reset the public key of an app
server.post config.base + '/api/apps/:key/reset', auth.needed, (req, res, next) ->
	db.apps.resetKey req.params.key, send(res,next)

# list valid domains for an app
server.get config.base + '/api/apps/:key/domains', auth.needed, (req, res, next) ->
	db.apps.getDomains req.params.key, send(res,next)

# update valid domains list for an app
server.post config.base + '/api/apps/:key/domains', auth.needed, (req, res, next) ->
	db.apps.updateDomains req.params.key, req.body.domains, send(res,next)

# add a valid domain for an app
server.post config.base + '/api/apps/:key/domains/:domain', auth.needed, (req, res, next) ->
	db.apps.addDomain req.params.key, req.params.domain, send(res,next)

# remove a valid domain for an app
server.del config.base + '/api/apps/:key/domains/:domain', auth.needed, (req, res, next) ->
	db.apps.remDomain req.params.key, req.params.domain, send(res,next)

# list keysets (provider names) for an app
server.get config.base + '/api/apps/:key/keysets', auth.needed, (req, res, next) ->
	db.apps.getKeysets req.params.key, send(res,next)

# get a keyset for an app and a provider
server.get config.base + '/api/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	db.apps.getKeyset req.params.key, req.params.provider, send(res,next)

# add or update a keyset for an app and a provider
server.post config.base + '/api/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	db.apps.addKeyset req.params.key, req.params.provider, req.body, send(res,next)

# remove a keyset for an app and a provider
server.del config.base + '/api/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	db.apps.remKeyset req.params.key, req.params.provider, send(res,next)

# get providers list
server.get config.base + '/api/providers', (req, res, next) ->
	db.providers.getList send(res,next)

# get a provider config
server.get config.base + '/api/providers/:provider', (req, res, next) ->
	if req.query.extend
		db.providers.getExtended req.params.provider, send(res,next)
	else
		db.providers.get req.params.provider, send(res,next)

# get a provider config
server.get config.base + '/api/providers/:provider/logo', ((req, res, next) ->
		fs.exists Path.normalize(config.rootdir + '/providers/' + req.params.provider + '.png'), (exists) ->
			if not exists
				req.params.provider = 'default'
			req.url = '/' + req.params.provider + '.png'
			req._url = Url.parse req.url
			req._path = req._url._path
			next()
	), restify.serveStatic
		directory: config.rootdir + '/providers'
		maxAge: 120

# listen
exports.listen = (callback) ->
	# tell plugins to configure the server if needed
	plugins.run 'setup', ->
		server.listen config.port, (err) ->
			return callback err if err
			#exit.push 'Http(s) server', (cb) -> server.close cb
			#/!\ server.close = timeout if at least one connection /!\ wtf?
			callback null, server
