# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

crypto = require 'crypto'
restify = require 'restify'
restifyOAuth2 = require 'restify-oauth2-oauthd'
shared = require '../shared'
request = require 'request'

exports.config = _config =
	expire: 3600*36

hooks =
	grantClientToken: (clientId, clientSecret, cb) ->
		shared.db.users.login clientId, clientSecret, (err, res) ->
			return cb null, false if err
			exports.generateToken id:res.id, mail:res.mail, validated:res.validated, cb
	authenticateToken: (token, cb) ->
		shared.db.redis.hgetall 'session:' + token, (err, res) ->
			return cb err if err
			return cb null, false if not res
			return cb null, res

exports.generateToken = (user, cb) ->
	token = shared.db.generateUid user.id
	(shared.db.redis.multi [
		['hmset', 'session:' + token, 'id', user.id, 'mail', user.mail, 'validated', user.validated]
		['expire', 'session:' + token, _config.expire]
	]).exec (err, r) ->
		return cb err if err
		shared.emit 'user.login', user
		return cb null, token


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
		if not (req.user.mail.match /.*@oauth\.io$/ and req.user.validated)
			return next new restify.NotAuthorizedError "You have not access to this app" if not res
		next()

exports.validPlatformName = (platform_name, callback) ->
	shared.db.redis.hgetall 'p:platforms_name', (err, platforms) =>
		return callback err if err
		for name,idplatform of platforms
			if name is platform_name
				return callback null, true
		return callback null, false

exports.platformAdm = (req, res, next) ->
	if not req.clientId 
		return next new restify.UnauthorizedError "You need authentication"
	req.admin = req.clientId
	if not req.admin.validated
		return next new restify.UnauthorizedError "You need authentication"
	if not req.params.platform?
		return next new restify.InvalidArgumentError "You need to specify a valid platform name."
	exports.validPlatformName req.params.platform, (err, valid) ->
		return next err if err
		if not valid
			return next new restify.InvalidArgumentError "You need to specify a valid platform name."
	
	shared.db.redis.expire 'session:' + req.token, _config.expire
	req.body ?= {}
	shared.db.users.get req.admin.id, (err, user) ->
		return next new restify.UnauthorizedError "Bad id." unless user
		return next err if err
		if not user.profile.platform_admin? or not user.profile.validated?
			return next new restify.NotAuthorizedError "You must be a platform administrator to access this methods." 
		req.admin.platform_admin = user.profile.platform_admin
		if req.params.platform isnt req.admin.platform_admin
			return next new restify.InvalidArgumentError "You need to specify a valid platform name."
		next()
	
exports.platformManageUser = (req, res, next) ->
	if not req.params.mail?
		return next new restify.InvalidArgumentError "You need to specify a valid email."	
	shared.db.redis.hget 'u:mails', req.params.mail, (err, iduser) ->
		return next new restify.InvalidArgumentError "You need to specify a valid email." unless iduser
		return next err if err
		shared.db.users.get iduser, (err, user) ->
			return next new restify.UnauthorizedError "Bad id." unless user
			return next err if err
			
			platform_user = user.profile
			if not platform_user.platform? or platform_user.platform isnt req.admin.platform_admin
				return next new restify.InvalidArgumentError "You need to specify a valid email."
			else
				req.platform_user = platform_user
				next()

exports.checkPlatformUserHasAccessToAppKey = (req, res, next) ->
	if not req.params.key?
		return next new restify.InvalidArgumentError "You need to specify the app's public key."
	shared.db.users.hasApp req.platform_user.id, req.params.key, (err, res) ->
		return next err if err
		return next new restify.InvalidArgumentError "Unknown key" if not res? or not res
		next()

exports.adm = (req, res, next) ->
	exports.needed req, res, (e) ->
		return next e if e
		if not req.user.mail.match(/.*@oauth\.io$/) or not req.user.validated
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
		'twitter': @check oauth_token:'string', oauth_token_secret:'string', (data, callback) =>
			@apiRequest apiUrl: '/1.1/account/verify_credentials.json', "twitter", data, (err, options) =>
				return callback err if err
				options.json = true
				request options, (err, response, body) =>
					return callback err if err
					if response.statusCode != 200 || not body.id_str
						return callback new @check.Error "something gone wrong with the api"
					callback null, id:body.id_str
		'facebook': @check token:'string', (data, callback) =>
			@apiRequest apiUrl: '/me', "facebook", data, (err, options) =>
				return callback err if err
				options.json = true
				request options, (err, response, body) =>
					return callback err if err
					if response.statusCode != 200 || not body.id
						return callback new @check.Error "something gone wrong with the api"
					callback null, id:body.id, email:body.email
		'google': @check token:'string', (data, callback) =>
			@apiRequest apiUrl: '/oauth2/v1/userinfo', "google", data, (err, options) =>
				return callback err if err
				options.json = true
				request options, (err, response, body) =>
					return callback err if err
					if response.statusCode != 200 || not body.id
						return callback new @check.Error "something gone wrong with the api"
					callback null, id:body.id, email:body.verified_email && body.email
		'linkedin': @check oauth_token:'string', oauth_token_secret:'string', (data, callback) =>
			@apiRequest apiUrl: '/v1/people/~:(id,email-address)?format=json', "linkedin", data, (err, options) =>
				return callback err if err
				options.json = true
				request options, (err, response, body) =>
					return callback err if err
					if response.statusCode != 200 || not body.id
						return callback new @check.Error "something gone wrong with the api"
					callback null, id:body.id
		'github': @check token:'string', (data, callback) =>
			@apiRequest apiUrl: '/user', "github", data, (err, options) =>
				return callback err if err
				options.json = true
				options.headers["User-Agent"] = "OAuth-io"
				request options, (err, response, body) =>
					return callback err if err
					if response.statusCode != 200 || not body.id
						return callback new @check.Error "something gone wrong with the api"
					callback null, id:body.id.toString(), email:body.email
		'vk': @check token:'string', (data, callback) =>
			@apiRequest apiUrl: '/method/getProfiles', "vk", data, (err, options) =>
				return callback err if err
				options.json = true
				request options, (err, response, body) =>
					return callback err if err
					if response.statusCode != 200 || not body.response?[0]?.uid
						return callback new @check.Error "something gone wrong with the api"
					callback null, id:body.response[0].uid

	@server.get @config.base_api + '/sync/oauth', exports.needed, (req, res, next) =>
		@db.redis.hkeys "u:#{req.user.id}:sync", @server.send(res, next)

	@server.post @config.base_api + '/sync/oauth', exports.needed, (req, res, next) =>
		callback = @server.send res, next

		e = new @check.Error
		e.check req.body,
			provider: 'string'
			token:['string','none']
			oauth_token:['string','none']
			oauth_token_secret:['string','none']
		return callback e if e.failed()

		provider = req.body.provider
		if not getInfos[provider]
			return callback new @check.Error 'Unsupported provider'

		req.body.k = @config.loginKey
		getInfos[provider] req.body, (err, infos) =>
			return callback err if err
			@db.redis.hget 'sign:' + provider, infos.id, (err, existing_user) =>
				return callback err if err
				if existing_user
					@db.redis.hdel 'sign:' + provider, infos.id
					@db.redis.hdel "u:#{existing_user}:sync", provider
				@db.redis.hset 'sign:' + provider, infos.id, req.user.id
				@db.redis.hset "u:#{req.user.id}:sync", provider, infos.id
				res.send @check.nullv
				next()

	@server.post @config.base_api + '/signup/oauth', (req, res, next) =>
		callback = @server.send res, next

		e = new @check.Error
		e.check req.body,
			provider: 'string'
			token:['string','none']
			oauth_token:['string','none']
			oauth_token_secret:['string','none']
			email:['string','none']
			name:'string'
			company:['string','none']
		return callback e if e.failed()

		provider = req.body.provider
		if not getInfos[provider]
			return callback new @check.Error 'Unsupported provider'

		pass = @db.generateUid().substr 0, 8

		req.body.k = @config.loginKey
		getInfos[provider] req.body, (err, infos) =>
			return callback err if err
			@db.redis.hget 'sign:' + provider, infos.id, (err, existing_user) =>
				return callback err if err
				return callback new @check.Error 'This account is already linked to a user' if existing_user

				@db.users.register mail:req.body.email, pass: pass, name: req.body.name, company: req.body.company, (err, user) =>
					return callback err if err

					@db.redis.hset 'sign:' + provider, infos.id, user.id
					prefix = "u:#{user.id}:"
					@db.redis.hset prefix + 'sync', provider, infos.id
					upd = [prefix + 'name', req.body.name]
					if req.body.company
						upd.push prefix + 'company'
						upd.push req.body.company
					@db.redis.mset upd, (->)

					if infos.email != req.body.email
						@userInvite user.id, (err) =>
							return callback err if err
							return callback null, id:user.id, mail:req.body.email, validated:false
					else
						@db.users.validate {
							key: user.key
							id: user.id
						}, (err, r) =>
							return callback err if err
							@db.timelines.addUse target:'u:validate', (->)
							return callback null, id:user.id, mail:req.body.email, validated:true


	@server.post @config.base_api + '/signin/oauth', (req, res, next) =>
		cb = @server.send res, next

		e = new @check.Error
		e.check req.body,
			provider: 'string'
			token:['string','none']
			oauth_token:['string','none']
			oauth_token_secret:['string','none']
		return cb e if e.failed()

		provider = req.body.provider
		if not getInfos[provider]
			return cb new @check.Error 'Unsupported provider'
		req.body.k = @config.loginKey
		getInfos[provider] req.body, (err, infos) =>
			return cb err if err
			@db.redis.hget 'sign:' + provider, infos.id, (err, user_id) =>
				return cb err if err
				return cb new @check.Error "this account is not linked to a user" if not user_id
				@db.users.get user_id, (err, user) =>
					return cb err if err
					token = @db.generateUid()
					(@db.redis.multi [
						['hmset', 'session:' + token, 'id', user.profile.id, 'mail', user.profile.mail, 'validated', user.profile.validated == "1"]
						['expire', 'session:' + token, _config.expire]
					]).exec (err, r) =>
						return cb err if err
						@emit 'user.login', user.profile
						return cb null, access_token:token, expires_in:_config.expire
	callback()


shared.auth = exports