# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

'use strict'

fs = require 'fs'
Path = require 'path'
Url = require 'url'

restify = require 'restify'

config = require './config'
dbapps = require './db_apps'
plugins = require './plugins'
exit = require './exit'

auth = plugins.data.auth


# build server options
server_options =
	name: 'OAuth Daemon'
	version: '1.0.0'

if config.ssl
	server_options.key = fs.readFileSync Path.resolve(config.rootdir, config.ssl.key)
	server_options.certificate = fs.readFileSync Path.resolve(config.rootdir, config.ssl.certificate)
	console.log 'SSL is enabled !'


# create server
server = restify.createServer server_options

server.use restify.authorizationParser()
server.use restify.queryParser()
server.use restify.bodyParser mapParams:false

# dev test /!\
server.get config.base + '/', (req, res, next) ->
	console.log req
	res.setHeader 'content-type', 'text/plain'
	res.writeHead 200
	res.end "Hello world"
	next()
server.post config.base + '/test/:ttt', (req, res, next) ->
	console.log req
	res.setHeader 'content-type', 'text/plain'
	res.writeHead 200
	res.end "Hello world"
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
	if not req.params.name?.match(/^.{6,}$/)
		return next new restify.InvalidArgumentError "Invalid app name"
	dbapps.create name:req.params.name, (e, r) ->
		return next new restify.InvalidArgumentError e.message if e
		plugins.emit 'app.create', req, r
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# get infos of an app
server.get config.base + '/api/app/:key', auth.needed, (req, res, next) ->
	dbapps.get req.params.key, (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# update infos of an app
server.post config.base + '/api/app/:key', auth.needed, (req, res, next) ->
	dbapps.update req.params.key, name:req.params.name, (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify r
			next()

# remove an app
server.del config.base + '/api/app/:key', auth.needed, (req, res, next) ->
	dbapps.get req.params.key, (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		plugins.emit 'app.remove', req, r
		dbapps.remove req.params.key, (err, r) ->
			return next new restify.InvalidArgumentError e.message if e
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify r
			next()

# reset the public key of an app
server.post config.base + '/api/app/:key/reset', auth.needed, (req, res, next) ->
	dbapps.resetKey req.params.key, (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# list valid domains for an app
server.get config.base + '/api/app/:key/domains', auth.needed, (req, res, next) ->
	dbapps.getDomains req.params.key (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# add a valid domain for an app
server.post config.base + '/api/app/:key/domain/:domain', auth.needed, (req, res, next) ->
	dbapps.addDomain req.params.key, req.params.domain (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# remove a valid domain for an app
server.del config.base + '/api/app/:key/domain/:domain', auth.needed, (req, res, next) ->
	dbapps.remDomain req.params.key, req.params.domain (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# list keysets (provider names) for an app
server.get config.base + '/api/app/:key/keysets', auth.needed, (req, res, next) ->
	dbapps.getKeysets req.params.key (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# get a keyset for an app and a provider
server.get config.base + '/api/app/:key/keyset/:provider', auth.needed, (req, res, next) ->
	dbapps.remKeyset req.params.key, req.params.domain (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# add or update a keyset for an app and a provider
server.post config.base + '/api/app/:key/keyset/:provider', auth.needed, (req, res, next) ->
	dbapps.addDomain req.params.key, req.params.domain, req.body (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# remove a keyset for an app and a provider
server.del config.base + '/api/app/:key/keyset/:provider', auth.needed, (req, res, next) ->
	dbapps.remKeyset req.params.key, req.params.domain (err, r) ->
		return next new restify.InvalidArgumentError e.message if e
		res.setHeader 'content-type', 'application/json'
		res.writeHead 200
		res.end JSON.stringify r
		next()

# add server to shared plugins data
plugins.data.server = server

# listen
exports.listen = (callback) ->
	# tell plugins to configure the server if needed
	plugins.run 'setup', ->
		server.listen config.port, (err) ->
			return callback err if err
			exit.push 'Http(s) server', (cb) -> server.close cb
			callback null, server