# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.
 

'use strict'

restify = require 'restify'
fs = require 'fs'
__rootdir = __dirname + '/..'

redis = require "redis"
redisClient = redis.createClient()

server = restify.createServer
	name: 'oauthd'
	version: '1.0.0'

server.use(restify.queryParser());
server.use restify.bodyParser()

server.get '/', (req, res, next) ->
	res.setHeader 'content-type', 'text/plain'
	res.writeHead 200
	res.end "Hello world"
	next

server.listen 6284, ->
	console.log '%s listening at %s', server.name, server.url