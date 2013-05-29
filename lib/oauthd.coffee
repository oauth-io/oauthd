# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

'use strict'

restify = require 'restify'
fs = require 'fs'
Path = require 'path'
__rootdir = Path.normalize(__dirname + '/..')

redis = require "redis"
redisClient = redis.createClient()

config = require __rootdir + "/config"

# build server options
server_options =
	name: 'OAuth Daemon'
	version: '1.0.0'

if config.ssl
	server_options.key = fs.readFileSync Path.resolve(__rootdir, config.ssl.key)
	server_options.certificate = fs.readFileSync Path.resolve(__rootdir, config.ssl.certificate)
	console.log 'SSL is activated !'

config.base = Path.resolve '/', config.base

# create server
server = restify.createServer server_options

server.use restify.queryParser()
server.use restify.bodyParser()

server.get config.base, (req, res, next) ->
	res.setHeader 'content-type', 'text/plain'
	res.writeHead 200
	res.end "Hello world"
	next()

# listen
server.listen config.port, ->
	console.log '%s listening at %s', server.name, server.url
