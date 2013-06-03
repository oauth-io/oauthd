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
plugins = require './plugins'
exit = require './exit'
check = require './check'
formatters = require './formatters'

auth = plugins.data.auth


# build server options
server_options =
	name: 'OAuth Daemon'
	version: '1.0.0'

if config.ssl
	server_options.key = fs.readFileSync Path.resolve(config.rootdir, config.ssl.key)
	server_options.certificate = fs.readFileSync Path.resolve(config.rootdir, config.ssl.certificate)
	console.log 'SSL is enabled !'

server_options.formatters = formatters

# create server
server = restify.createServer server_options

server.use restify.authorizationParser()
server.use restify.queryParser()
server.use restify.bodyParser mapParams:false


# add server to shared plugins data and run init
plugins.data.server = server
plugins.runSync 'init'

# little help
server.send = send = (res, next) -> (e, r) ->
	return next(e) if e
	res.send (if r? then r else check.nullv)
	next()

# dev test /!\
server.get config.base + '/', (req, res, next) ->
	console.log req
	res.send check.nullv
	next()
server.post config.base + '/test/:ttt', (req, res, next) ->
	console.log req
	res.send "Hello world"
	next()

# oauth: popup or redirection to provider's authorization url
server.get config.base + '/:provider', (req, res, next) ->
	if not req.params.k
		return next new restify.MissingParameterError 'Missing OAuth.io public key.'
	### ## really need domain ? ##
	domain = null
	if req.headers['referer'] || req.headers['origin']
		domain = Url.parse(req.headers['referer'] || req.headers['origin']).host
	if not domain
		return next(new restify.InvalidHeaderError('Missing origin or referer.'))
	###

	if req.params.redirect_uri
		return next new restify.InvalidVersionError 'Redirection mode not supported yet'

	#res.setHeader 'content-type', 'text/plain'
	#res.writeHead 200
	#res.end "Hello world"
	res.setHeader 'location', 'http://httpbin.org/get?client_id=akey&redirect_uri=makemycb&state='
	next()

# create an application
server.post config.base + '/api/apps', auth.needed, (req, res, next) ->
	dbapps.create req.body, (e, r) ->
		return next(e) if e
		plugins.data.emit 'app.create', req, r
		res.send name:r.name, key:r.key, domains:r.domains
		next()

# get infos of an app
server.get config.base + '/api/app/:key', auth.needed, (req, res, next) ->
	async.parallel [
		(cb) -> dbapps.get req.params.key, cb
		(cb) -> dbapps.getDomains req.params.key, cb
		(cb) -> dbapps.getKeysets req.params.key, cb
	], (e, r) ->
		return next(e) if e
		res.send name:r[0].name, key:r[0].key, domains:r[1], keysets:r[2]
		next()

# update infos of an app
server.post config.base + '/api/app/:key', auth.needed, (req, res, next) ->
	dbapps.update req.params.key, req.body, send(res,next)

# remove an app
server.del config.base + '/api/app/:key', auth.needed, (req, res, next) ->
	dbapps.get req.params.key, (e, r) ->
		return next(e) if e
		plugins.data.emit 'app.remove', req, r
		dbapps.remove req.params.key, send(res,next)

# reset the public key of an app
server.post config.base + '/api/app/:key/reset', auth.needed, (req, res, next) ->
	dbapps.resetKey req.params.key, send(res,next)

# list valid domains for an app
server.get config.base + '/api/app/:key/domains', auth.needed, (req, res, next) ->
	dbapps.getDomains req.params.key, send(res,next)

# add a valid domain for an app
server.post config.base + '/api/app/:key/domain/:domain', auth.needed, (req, res, next) ->
	dbapps.addDomain req.params.key, req.params.domain, send(res,next)

# remove a valid domain for an app
server.del config.base + '/api/app/:key/domain/:domain', auth.needed, (req, res, next) ->
	dbapps.remDomain req.params.key, req.params.domain, send(res,next)

# list keysets (provider names) for an app
server.get config.base + '/api/app/:key/keysets', auth.needed, (req, res, next) ->
	dbapps.getKeysets req.params.key, send(res,next)

# get a keyset for an app and a provider
server.get config.base + '/api/app/:key/keyset/:provider', auth.needed, (req, res, next) ->
	dbapps.getKeyset req.params.key, req.params.provider, send(res,next)

# add or update a keyset for an app and a provider
server.post config.base + '/api/app/:key/keyset/:provider', auth.needed, (req, res, next) ->
	dbapps.addKeyset req.params.key, req.params.provider, req.body, send(res,next)

# remove a keyset for an app and a provider
server.del config.base + '/api/app/:key/keyset/:provider', auth.needed, (req, res, next) ->
	dbapps.remKeyset req.params.key, req.params.provider, send(res,next)


# listen
exports.listen = (callback) ->
	# tell plugins to configure the server if needed
	plugins.run 'setup', ->
		server.listen config.port, (err) ->
			return callback err if err
			#exit.push 'Http(s) server', (cb) -> server.close cb
			#/!\ server.close = timeout if at least one connection /!\ wtf?
			callback null, server