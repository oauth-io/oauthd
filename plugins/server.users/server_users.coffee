# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

restify = require 'restify'
dbusers = require './db_users'

exports.setup = (callback) ->
	@server.post @config.base + '/api/users', (req, res, next) =>
		if not req.params.mail?.match(@check.format.mail)
			return next new restify.InvalidArgumentError "Invalid user mail"
		else if not req.params.pass?.match(/^.{6,}$/)
			return next new restify.InvalidArgumentError "Invalid user pass"
		dbusers.register mail:req.params.mail, pass:req.params.pass, (e, r) ->
			return next new restify.InvalidArgumentError e.message if e
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify r
			next()

	@server.get @config.base + '/api/me', @auth.needed, (req, res, next) ->
		dbusers.get res.user.id, (err, user) ->
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify user
			next()

	@server.del @config.base + '/api/me', @auth.needed, (req, res, next) ->
		dbusers.delete res.user.id, (err, r) ->
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify r
			next()

	callback()