# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

crypto = require 'crypto'
restify = require 'restify'
restifyOAuth2 = require 'restify-oauth2-oauthd'
shared = require '../shared'

_config =
	expire: 3600*36

hooks =
	grantClientToken: (clientId, clientSecret, cb) ->
		shared.db.users.login clientId, clientSecret, (err, res) ->
			return cb null, false if err
			token = shared.db.generateUid clientId + ':' + clientSecret
			(shared.db.redis.multi [
				['hmset', 'session:' + token, 'id', res.id, 'mail', res.mail]
				['expire', 'session:' + token, _config.expire]
			]).exec (err, r) ->
				return cb err if err
				shared.emit 'user.login', res
				return cb null, token

	authenticateToken: (token, cb) ->
		shared.db.redis.hgetall 'session:' + token, (err, res) ->
			return cb err if err
			return cb null, false if not res
			return cb null, res

exports.init = ->
	restifyOAuth2.cc @server,
		hooks:hooks, tokenEndpoint:@config.base+'/token',
		tokenExpirationTime: _config.expire

exports.needed = (req, res, next) ->
	if not req.clientId
		return next new restify.UnauthorizedError "You need authentication"
	req.user = req.clientId
	shared.db.redis.expire 'session:' + req.token, _config.expire
	req.body ?= {}
	if not req.params.key?
		return next()
	shared.db.users.hasApp req.user.id, req.params.key, (err, res) ->
		return next err if err
		if not req.user.mail.match /.*@oauth\.io$/
			return next new restify.NotAuthorizedError "You have not access to this app" if not res
		next()

exports.adm = (req, res, next) ->
	exports.needed req, res, (e) ->
		return next e if e
		if not req.user.mail.match /.*@oauth\.io$/
			return next new restify.NotAuthorizedError
		next()

exports.optional = (req, res, next) ->
	req.user = req.clientId
	req.body ?= {}
	next()

exports.setup = (callback) ->
	@server.post '/signin', (req, res, next) =>
		res.setHeader 'Content-Type', 'text/html'
		hooks.grantClientToken req.body.mail, req.body.pass, (e, token) =>
			return next(e) if e
			if token
				expireDate = new Date((new Date - 0) + _config.expire * 1000)
				res.setHeader 'Set-Cookie', 'accessToken=%22' + token + '%22; Path=/; Expires=' + expireDate.toUTCString()
				res.setHeader 'Location', @config.host_url + '/key-manager'
			else
				res.setHeader 'Location', @config.host_url + '/signin#err=Bad%20credentials'
			res.send 302
			next()

	getInfos =
		'twitter': @check oauth_token:'string', oauth_token_secret:'string', (data, callback) -> callback null, id:4242
		'facebook': @check access_token:'string', (data, callback) -> callback null, id:2222, email:'bumpmann@oauth.io'
		'google': @check access_token:'string', (data, callback) ->
		'linkedin': @check oauth_token:'string', oauth_token_secret:'string', (data, callback) ->
		'github': @check access_token:'string', (data, callback) ->
		'vk': @check access_token:'string', (data, callback) ->

	@server.post @config.base_api + '/signup/oauth', (req, res, next) =>
		callback = @server.send res, next

		e = new check.Error
		e.check req.body,
			provider: 'string'
			access_token:['string','none']
			oauth_token:['string','none']
			oauth_token_secret:['string','none']
			email:'string'
			pass:'string'
			name:'string'
			company:'string'
		return callback e if e.failed()

		provider = req.body.provider
		if not getInfos[provider]
			return callback new @check.Error 'Unsupported provider'

		getInfos[provider] req.body, (err, infos) =>
			return callback err if err
			@db.users.register mail:req.body.email, (err, user) =>
				return callback err if err

				@db.redis.hset 'sign:' + provider, infos.id, user.id

				if infos.email != req.body.email
					@userInvite user.id, (err) =>
						return callback err if err
						return callback id:user.id, mail:req.body.email, validated:false
				else
					@db.users.validate {
						key: user.key
						id: user.id
						pass: req.body.pass
					}, (err, r) =>
						return callback err if err
						@db.timelines.addUse target:'u:validate', (->)
						return callback id:user.id, mail:req.body.email, validated:true

	@server.post @config.base_api + '/signin/oauth', (req, res, next) =>
		callback = @server.send res, next

		e.check req.body,
			provider: 'string'
			access_token:['string','none']
			oauth_token:['string','none']
			oauth_token_secret:['string','none']
		return callback e if e.failed()

		provider = req.body.provider
		if not getInfos[provider]
			return callback new @check.Error 'Unsupported provider'

		getInfos[provider] req.body, (err, infos) =>
			return callback err if err
			@db.redis.hget 'sign:' + provider, infos.id, (err, user_id) =>
				return callback err if err
				return callback new @check.Error "this account is not linked to a user"
				@db.user.get user_id, (err, user) =>
					return callback err if err
					token = @db.generateUid clientId + ':' + clientSecret
					(@db.redis.multi [
						['hmset', 'session:' + token, 'id', res.id, 'mail', res.mail]
						['expire', 'session:' + token, _config.expire]
					]).exec (err, r) ->
						return cb err if err
						@emit 'user.login', res
						return cb null, token

	callback()


shared.auth = exports