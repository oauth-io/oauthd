# oauth
# http://oauth.io/
#
# Copyright (c) 2013 Webshell
# Licensed under the MIT license.

'use strict'

restify = require 'restify'
fs = require 'fs'
Url = require 'url'
proxy = require './proxy/js'
contentify = require 'contentify'
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
	token = req.headers.cookie?.match /accessToken=%22(.*?)%22/
	req.token = token?[1]
	next()

checkHeroku = (req, res, next) ->
	herokuNavData = req.headers.cookie?.match /heroku-nav-data=(.*?);/
	req.herokuNavData = herokuNavData?[1]
	herokuBodyApp = req.headers.cookie?.match /heroku-body-app=%22(.*?)%22/
	req.herokuBodyApp = herokuBodyApp?[1]
	next()

checkAdmin = (req, res, next) -> checkLogged req, res, ->
	return next() if not req.token
	db.redis.hgetall 'session:' + req.token, (err, res) ->
		if not err and res?['mail'].match(/^.*@oauth.io$/) and res['validated']
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
			if req.headers.host == 'www.oauth.io'
				res.setHeader 'Location', 'https://oauth.io'
				res.send 301
				return next()
			res.setHeader 'Content-Type', 'text/html'
			res.set 'Last-Modified', bootTime
			data = cache.index
			data = data.replace /\{\{if admin\}\}([\s\S]*?)\{\{endif\}\}/g, if req.admin then '$1' else ''
			sendres = ->
				data = data.replace /\{\{if logged\}\}([\s\S]*?)\{\{endif\}\}/g, if req.token then '$1' else ''
				res.end data
				next()

			data = data.replace /\{\{if herokuNavData\}\}([\s\S]*?)\{\{endif\}\}/g, if req.herokuNavData then '$1' else ''
			data = data.replace /\{\{if herokuUser\}\}([\s\S]*?)\{\{endif\}\}/g, if req.herokuNavData then '' else '$1'
			data = data.replace /\{\{heroku_app\}\}/g, req.herokuBodyApp

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

		@server.get '/', checkAdmin, checkHeroku, bootPathCache(logged:true), sendIndex

		@server.get '/proxy', (req, res, next) ->
			proxy(req, res, next);

		@server.get '/logout', (req, res, next) =>
			cookies = [
				'accessToken=; Path=/; Expires=' + (new Date(0)).toUTCString()
				'heroku-nav-data=; Path=/; Expires=' + (new Date(0)).toUTCString()
				'heroku-body-app=; Path=/; Expires=' + (new Date(0)).toUTCString()
				]
			res.setHeader 'Set-Cookie', cookies
			res.setHeader 'Location', '/'
			res.send 302
			next()

		@server.get '/home', (req, res, next) ->
			res.setHeader 'Location', '/'
			res.send 301
			next()

		@server.get /^\/templates\/.*\.html/, contentify.serve
			owner: 'oauth-io'
			repo: 'content'
			mode: 'draft'
			user: @config.github_login
			password: @config.github_pass
			directory: __dirname + '/app'

		@server.get /^\/(lib|data|css|js|img|fonts)\/.*/, bootPathCache(), restify.serveStatic
			directory: __dirname + '/app'
			maxAge: 1

		@server.get /^\/(robots.txt|sitemap.xml|loaderio-66375ef31c0db14063ea59a1240b59be\.txt)/, bootPathCache(), restify.serveStatic
			directory: __dirname + '/app'
			maxAge: 1

		@server.get /^\/adm\/.*/, needAdmin, bootPathCache(admin:true), restify.serveStatic
			directory: __dirname + '/app'
			maxAge: 1

		@server.get /^\/50[2-3]/, addExtension, bootPathCache(path:'/errors'), restify.serveStatic
			directory: __dirname + '/errors'
			maxAge: 1 # no cache on errors !

		@server.get /.*/, checkAdmin, checkHeroku, bootPathCache(logged:true), sendIndex

		callback()
