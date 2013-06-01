# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

restify = require 'restify'
dbusers = require './db_users'

exports.setup = (callback) ->

	# register an account
	@server.post @config.base + '/api/users', (req, res, next) =>
		if not req.body.mail?.match(@check.format.mail)
			return next new restify.InvalidArgumentError "Invalid user mail"
		else if not req.body.pass?.match(/^.{6,}$/)
			return next new restify.InvalidArgumentError "Invalid user pass"
		dbusers.register mail:req.body.mail, pass:req.body.pass, (e, r) ->
			return next new restify.InvalidArgumentError e.message if e
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify r
			next()

	# get my infos
	@server.get @config.base + '/api/me', @auth.needed, (req, res, next) ->
		dbusers.get req.user.id, (e, user) ->
			return next new restify.InvalidArgumentError e.message if e
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify user
			next()

	# update mail or password
	@server.post @config.base + '/api/me', @auth.needed, (req, res, next) ->
		next new restify.InternalError "Implemented soon !"

	# delete my account
	@server.del @config.base + '/api/me', @auth.needed, (req, res, next) ->
		dbusers.remove req.user.id, (e, r) ->
			return next new restify.InvalidArgumentError e.message if e
			res.setHeader 'content-type', 'application/json'
			res.writeHead 200
			res.end JSON.stringify r
			next()

	callback()