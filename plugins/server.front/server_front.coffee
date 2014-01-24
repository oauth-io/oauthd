# oauth
# http://oauth.io/
#
# Copyright (c) 2013 Webshell
# Licensed under the MIT license.

'use strict'

restify = require 'restify'
fs = require 'fs'
Url = require 'url'

{db} = shared = require '../shared'

cache = {}

addExtension = (req, res, next) ->
	ext = '.json'
	ext = '.html' if req.headers.accept?.substr(0,9) == 'text/html'
	req.url += ext
	req._url = Url.parse req.url
	req._path = req._url._path
	next()

checkLogged = (req, res, next) ->
	token = req.headers.cookie?.match /accessToken=%22(.*)%22/
	req.token = token?[1]
	next()

checkAdmin = (req, res, next) -> checkLogged req, res, ->
	return next() if not req.token
	db.redis.hget 'session:' + req.token, 'mail', (err, res) ->
		if not err and res and res.match /^.*@oauth.io$/
			req.admin = true
		next()

needAdmin = (req, res, next) -> checkAdmin req, res, ->
	return next new restify.ResourceNotFoundError '%s does not exist', req.url if not req.admin
	next()

bootTime = new Date
bootPathCache = (opts) ->
	opts ?= {}
	opts.path ?= '/app'
	chain = restify.conditionalRequest()
	chain.unshift (req, res, next) ->
		fs.stat __dirname + opts.path + req.url, (err, stat) ->
			timeinfo = stat?.mtime || bootTime
			res.setHeader 'Last-Modified', timeinfo
			hashdata = req.path() + ':' + timeinfo
			hashdata = req.admin + ':' + req.logged + ':' + hashdata if opts.logged || opts.admin
			res.set 'ETag', db.generateHash hashdata
			next()
	return chain

init = (callback) ->
	fs.readFile __dirname + '/app/index.html', 'utf8', (err, data) =>
		callback err if err
		cache.index = data.toString().replace /\{\{config\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\}\}/g, (m,prop,prop2) => @config[prop]?[prop2]
		cache.index = cache.index.toString().replace /\{\{config\.([a-zA-Z0-9_]+)\}\}/g, (m,prop) => @config[prop]
		callback()

exports.setup = (callback) ->
	init.call @, (e) =>
		console.error 'error', e if e

		sendIndex = (req, res, next) ->
			res.setHeader 'Content-Type', 'text/html'
			res.set 'Last-Modified', bootTime
			data = cache.index
			data = data.replace /\{\{if admin\}\}([\s\S]*?)\{\{endif\}\}/g, if req.admin then '$1' else ''
			sendres = ->
				data = data.replace /\{\{if logged\}\}([\s\S]*?)\{\{endif\}\}/g, if req.token then '$1' else ''
				res.end data
				next()
			if req.token
				db.redis.hgetall 'session:' + req.token, (err, session) ->
					if err or not session
						req.token = null
						return sendres()
					data = data.replace /\{\{user.id\}\}/g, session.id
					data = data.replace /\{\{user.mail\}\}/g, session.mail
					sendres()
			else
				sendres()

		@server.get '/', checkAdmin, bootPathCache(logged:true), sendIndex

		@server.get /^\/(lib|css|js|img|templates)\/.*/, bootPathCache(), restify.serveStatic
			directory: __dirname + '/app'
			maxAge: 1

		@server.get /^\/(robots.txt|sitemap.xml)/, bootPathCache(), restify.serveStatic
			directory: __dirname + '/app'
			maxAge: 1

		@server.get /^\/adm\/.*/, needAdmin, bootPathCache(admin:true), restify.serveStatic
			directory: __dirname + '/app'
			maxAge: 1

		@server.get /^\/50[2-3]/, addExtension, bootPathCache(path:'/errors'), restify.serveStatic
			directory: __dirname + '/errors'
			maxAge: 1 # no cache on errors !

		@server.get /.*/, checkAdmin, bootPathCache(logged:true), sendIndex

		callback()
