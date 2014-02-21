# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

exports.setup = (callback) ->

	@db.users = require './db_users'

	# statistics
	@on 'user.register', =>
		@db.timelines.addUse target:'users', (->)
	@on 'user.remove', =>
		@db.timelines.addUse target:'users', uses:-1, (->)
	@on 'user.login', =>
		@db.timelines.addUse target:'u:login', (->)
	@on 'app.create', =>
		@db.timelines.addUse target:'apps', (->)
	@on 'app.remove', =>
		@db.timelines.addUse target:'apps', uses:-1, (->)
	@on 'app.addkeyset', (data) =>
		@db.timelines.addUse target:'keysets', (->)
		@db.timelines.addUse target:'a:' + data.app + ':keysets', (->)
		@db.timelines.addUse target:'p:' + data.provider + ':keysets', (->)
		@db.ranking_timelines.addScore 'a:k', id:data.id, (->)
		@db.ranking_timelines.addScore 'p:k', id:data.provider, (->)
	@on 'app.remkeyset', (data) =>
		@db.timelines.addUse target:'keysets', uses:-1, (->)
		@db.timelines.addUse target:'a:' + data.app + ':keysets', uses:-1, (->)
		@db.timelines.addUse target:'p:' + data.provider + ':keysets', uses:-1, (->)
		@db.ranking_timelines.addScore 'a:k', id:data.id, val:-1, (->)
		@db.ranking_timelines.addScore 'p:k', id:data.provider, val:-1, (->)

	# reset password
	@server.post @config.base_api + '/users/resetPassword', (req, res, next) =>
		@db.users.resetPassword req.body, @server.send(res, next)

	# lost password
	@server.post @config.base_api + '/users/lostpassword', (req, res, next) =>
		@db.users.lostPassword req.body, @server.send(res, next)

	# key validity
	@server.get @config.base_api + "/users/:id/keyValidity/:key", (req, res, next) =>
		@db.users.isValidKey {
			key: req.params.key
			id: req.params.id
		}, @server.send(res, next)

	# register an account
	@server.post @config.base_api + '/users', (req, res, next) =>
		req.body.mail = req.body.email
		@db.users.register req.body, (e, r) =>
			return next e if e
			@userInvite r.id, (e) =>
				return next e if e
				res.send r
				next()

	# validate a user
	@server.post @config.base_api + "/users/:id/validate/:key", (req, res, next) =>
		@db.users.validate {
			key: req.params.key
			id: req.params.id
		}, (e, r) =>
			return next(e) if e
			@db.timelines.addUse target:'u:validate', (->)
			prefix = 'u:' + req.params.id + ':'
			@db.redis.get prefix + 'mail', (e, mail) =>
				return next e if e
				@auth.generateToken id:req.params.id, mail:mail, (e, token) =>
					return next e if e
					expireDate = new Date((new Date - 0) + @auth.config.expire * 1000)
					res.setHeader 'Set-Cookie', 'accessToken=%22' + token + '%22; Path=/; Expires=' + expireDate.toUTCString()
					res.send r
					next()

	# get true/false if a user is validable
	@server.get @config.base_api + "/users/:id/validate/:key", (req, res, next) =>
		@db.users.isValidable {
			id: req.params.id
			key: req.params.key
		}, @server.send(res, next)

	# get my infos
	@server.get @config.base_api + '/me', @auth.needed, (req, res, next) =>
		@db.users.get req.user.id, (e, user) =>
			return next(e) if e
			@db.users.getApps user.profile.id, (e, appkeys) ->
				return next(e) if e
				user.apps = appkeys
				res.send user
				next()

	@server.put @config.base_api + '/me/password', @auth.needed, (req, res, next) =>
		@db.users.updatePassword req, @server.send(res, next)

	@server.put @config.base_api + '/me/mail', @auth.needed, (req, res, next) =>
		@db.users.updateEmail req, @server.send(res, next)

	@server.del @config.base_api + '/me/mail', @auth.needed, (req, res, next) =>
		@db.users.cancelUpdateEmail req, @server.send(res, next)

	# update information (name, location, company, website)
	@server.put @config.base_api + '/me', @auth.needed, (req, res, next) =>
		@db.users.updateAccount req, @server.send(res, next)

	# get subscriptions
	@server.get @config.base_api + '/me/subscriptions', @auth.needed, (req, res, next) =>
		@db.users.getAllSubscriptions req.clientId.id, @server.send(res, next)

	# delete my account
	@server.del @config.base_api + '/me', @auth.needed, (req, res, next) =>
		@db.users.remove req.user.id, @server.send(res,next)

	# get total connexion of an app
	@server.get @config.base_api + '/users/app/:key', @auth.needed, (req, res, next) =>
		@db.timelines.getTimeline "co:a:#{req.params.key}",
			unit: 'm',
			start: (new Date / 1000),
			end: (new Date / 1000),
			(err, stats) =>
				return next err if err
				keys = Object.keys(stats)
				return next new @check.Error 'unknown' if ! keys[0]
				res.send stats[keys[0]].toString()
				next()

	# get total users of an app
	@server.get @config.base_api + '/users/app/:key/users', @auth.needed, (req, res, next) =>
		@db.timelines.getTimeline "co:mid:a:#{req.params.key}",
			unit: 'm',
			start: (new Date / 1000),
			end: (new Date / 1000),
			(err, stats) =>
				return next err if err
				keys = Object.keys(stats)
				return next new @check.Error 'unknown' if ! keys[0]
				res.send stats[keys[0]].toString()
				next()

	callback()