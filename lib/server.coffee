# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

'use strict'

restify = require 'restify'
fs = require 'fs'
Path = require 'path'
Url = require 'url'

config = require "../config"

# build server options
server_options =
	name: 'OAuth Daemon'
	version: '1.0.0'

if config.ssl
	server_options.key = fs.readFileSync Path.resolve(config.rootdir, config.ssl.key)
	server_options.certificate = fs.readFileSync Path.resolve(config.rootdir, config.ssl.certificate)
	console.log 'SSL is activated !'

config.base = Path.resolve '/', config.base

# create server
server = restify.createServer server_options

server.use restify.queryParser()
server.use restify.bodyParser()

server.get config.base, (req, res, next) ->
	console.log req
	res.setHeader 'content-type', 'text/plain'
	res.writeHead 200
	res.end "Hello world"
	next()

server.get config.base + '/:provider', (req, res, next) ->
	domain = req.params.d
	if req.headers['referer'] || req.headers['origin']
		domain = Url.parse(req.headers['referer'] || req.headers['origin']).host
	res.setHeader 'content-type', 'text/plain'
	res.writeHead 200
	res.end "Hello world"
	next()

# listen
module.exports =
	listen: (callback) ->
		server.listen config.port, ->
			callback null, server

	close: (callback) -> server.close callback