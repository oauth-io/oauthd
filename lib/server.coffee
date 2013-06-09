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
dbapps = require './db_apps'
dbstates = require './db_states'
dbproviders = require './db_providers'
plugins = require './plugins'
exit = require './exit'
check = require './check'
formatters = require './formatters'
sdk_js = require './sdk_js'

oauth =
	oauth1: null
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
server.get config.base + '/sdk/oauth.js', (req, res, next) ->
	sdk_js.get (e, r) ->
		return next e if e
		res.setHeader 'Content-Type', 'application/javascript'
		res.send r
		next()

# oauth: handle callbacks
server.get config.base + '/', (req, res, next) ->
	if not req.params.state
		# dev test /!\
		view = '<html><head>\n'
		view += '<script src="https://oauth.local/auth/sdk/oauth.js"></script>\n'
		view += '<script>\n'
		view += 'OAuth.initialize("e-X-fosYgGA7P9j6lGBGUTSwu6A");\n'
		view += 'function connect() {\n'
		view += '\tOAuth.popup("soundcloud", function() {console.log(arguments);});\n'
		view += '}\n'
		view += '</script>\n'
		view += '</head><body>\n'
		view += '<a href="#" onclick="connect()">connect</a>\n'
		view += '</body></html>'
		res.setHeader 'Content-Type', 'text/html'
		res.send view
		next()
	dbstates.get req.params.state, (err, state) ->
		return next err if err
		return next new check.Error 'state', 'invalid or expired' if not state
		oauth[state.oauthv].access_token state, req, (e, r) ->
			body = formatters.build e || r
			body.provider = state.provider.toLowerCase()
			view = '<script>var msg=' + JSON.stringify(JSON.stringify(body)) + ';\n'
			view += 'var opener = window.opener || window.parent\n'
			view += 'if (opener)'
			view += '\topener.postMessage(msg, "' + state.origin + '");\n'
			view += 'window.close();\n'
			view += '</script>'
			res.setHeader 'Content-Type', 'text/html'
			res.send view
			next()

# oauth: popup or redirection to provider's authorization url
server.get config.base + '/:provider', (req, res, next) ->
	if not req.params.k
		return next new restify.MissingParameterError 'Missing OAuth.io public key.'

	domain = null
	origin = null
	if req.headers['referer'] || req.headers['origin']
		urlinfos = Url.parse(req.headers['referer'] || req.headers['origin'])
		domain = urlinfos.host
		origin = urlinfos.protocol + '//' + domain
	if not domain
		return next(new restify.InvalidHeaderError('Missing origin or referer.'))

	if req.params.redirect_uri
		return next new restify.InvalidVersionError 'Redirection mode not supported yet'

	oauthv = req.params.oauthv && {
		"2":"oauth2"
		"1":"oauth1"
	}[req.params.oauthv]

	dbproviders.getExtended req.params.provider, (err, provider) ->
		return next err if err
		if oauthv and not provider[oauthv]
			return next new check.Error "oauthv", "Unsupported oauth version: " + oauthv
		oauthv ?= 'oauth2' if provider.oauth2
		oauthv ?= 'oauth1' if provider.oauth1
		dbapps.getKeyset req.params.k, req.params.provider, (err, keyset) ->
			return next err if err
			opts = oauthv:oauthv, key:req.params.k, origin:origin
			oauth[oauthv].authorize provider, keyset, opts, (err, url) ->
				return next err if err
				res.setHeader 'Location', url
				res.send 302
				next()

# create an application
server.post config.base + '/api/apps', auth.needed, (req, res, next) ->
	dbapps.create req.body, (e, r) ->
		return next(e) if e
		plugins.data.emit 'app.create', req, r
		res.send name:r.name, key:r.key, domains:r.domains
		next()

# get infos of an app
server.get config.base + '/api/apps/:key', auth.needed, (req, res, next) ->
	async.parallel [
		(cb) -> dbapps.get req.params.key, cb
		(cb) -> dbapps.getDomains req.params.key, cb
		(cb) -> dbapps.getKeysets req.params.key, cb
	], (e, r) ->
		return next(e) if e
		res.send name:r[0].name, key:r[0].key, domains:r[1], keysets:r[2]
		next()

# update infos of an app
server.post config.base + '/api/apps/:key', auth.needed, (req, res, next) ->
	dbapps.update req.params.key, req.body, send(res,next)

# remove an app
server.del config.base + '/api/apps/:key', auth.needed, (req, res, next) ->
	dbapps.get req.params.key, (e, r) ->
		return next(e) if e
		plugins.data.emit 'app.remove', req, r
		dbapps.remove req.params.key, send(res,next)

# reset the public key of an app
server.post config.base + '/api/apps/:key/reset', auth.needed, (req, res, next) ->
	dbapps.resetKey req.params.key, send(res,next)

# list valid domains for an app
server.get config.base + '/api/apps/:key/domains', auth.needed, (req, res, next) ->
	dbapps.getDomains req.params.key, send(res,next)

# update valid domains list for an app
server.post config.base + '/api/apps/:key/domains', auth.needed, (req, res, next) ->
	dbapps.updateDomains req.params.key, req.body.domains, send(res,next)

# add a valid domain for an app
server.post config.base + '/api/apps/:key/domains/:domain', auth.needed, (req, res, next) ->
	dbapps.addDomain req.params.key, req.params.domain, send(res,next)

# remove a valid domain for an app
server.del config.base + '/api/apps/:key/domains/:domain', auth.needed, (req, res, next) ->
	dbapps.remDomain req.params.key, req.params.domain, send(res,next)

# list keysets (provider names) for an app
server.get config.base + '/api/apps/:key/keysets', auth.needed, (req, res, next) ->
	dbapps.getKeysets req.params.key, send(res,next)

# get a keyset for an app and a provider
server.get config.base + '/api/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	dbapps.getKeyset req.params.key, req.params.provider, send(res,next)

# add or update a keyset for an app and a provider
server.post config.base + '/api/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	dbapps.addKeyset req.params.key, req.params.provider, req.body, send(res,next)

# remove a keyset for an app and a provider
server.del config.base + '/api/apps/:key/keysets/:provider', auth.needed, (req, res, next) ->
	dbapps.remKeyset req.params.key, req.params.provider, send(res,next)

# get providers list
server.get config.base + '/api/providers', (req, res, next) ->
	dbproviders.getList send(res,next)

# get a provider config
server.get config.base + '/api/providers/:provider', (req, res, next) ->
	if req.query.extend
		dbproviders.getExtended req.params.provider, send(res,next)
	else
		dbproviders.get req.params.provider, send(res,next)

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
