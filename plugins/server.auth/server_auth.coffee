# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

crypto = require 'crypto'
restify = require 'restify'
restifyOAuth2 = require 'restify-oauth2'
shared = require '../shared'

_config =
	expire: 3600*5

hooks =
	grantClientToken: (clientId, clientSecret, cb) ->
		shared.db.users.login clientId, clientSecret, (err, res) ->
			console.log err if err
			return cb null, false if err
			token = shared.db.generateUid clientId + ':' + clientSecret
			(shared.db.redis.multi [
				['hset', 'session:' + token, 'id', res.id]
				['expire', 'session:' + token, _config.expire]
			]).exec (err, r) ->
				return cb err if err
				return cb null, token

	authenticateToken: (token, cb) ->
		shared.db.redis.hgetall 'session:' + token, (err, res) ->
			return cb err if err
			return cb null, false if not res
			return cb null, res

exports.setup = (callback) ->

	restifyOAuth2.cc @server,
		hooks:hooks, tokenEndpoint:@config.base+'/token',
		tokenExpirationTime: _config.expire

	callback()

exports.needed = (req, res, next) ->
	if not req.clientId
		return res.sendUnauthorized()

	req.user = req.clientId
	return next()

shared.auth = exports