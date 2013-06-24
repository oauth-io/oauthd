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
	@on 'app.remkeyset', (data) =>
		@db.timelines.addUse target:'keysets', uses:-1, (->)
		@db.timelines.addUse target:'a:' + data.app + ':keysets', uses:-1, (->)
		@db.timelines.addUse target:'p:' + data.provider + ':keysets', uses:-1, (->)

	# reset password
	@server.post @config.base + '/api/users/resetPassword', (req, res, next) =>			
		@db.users.resetPassword req.body, (callback) =>			
			res.send(callback, next)

	# lost password
	@server.post @config.base + '/api/users/lostpassword', (req, res, next) =>
		console.log 'lost pswd'
		@db.users.lostPassword req.body, (callback) =>			
			res.send(callback, next)
	
	# key validity
	@server.get @config.base + "/api/users/:id/keyValidity/:key", (req, res, next) =>		
		@db.users.isValidKey {
			key: req.params.key
			id: req.params.id
		}, (json) ->
			res.send(json)

	# register an account
	@server.post @config.base + '/api/users', (req, res, next) =>
		@db.users.register req.body, @server.send(res,next)

	# validate a user
	@server.post @config.base + "/api/users/:id/validate/:key", (req, res, next) =>
		console.log "uh?!"
		console.log req.params
		console.log req.body
		@db.users.validate {
			key: req.params.key
			id: req.params.id
			pass: req.body.pass
		}, (e, r) =>
			return next(e) if e
			@db.timelines.addUse target:'u:validate', (->)
			res.send r
			next()

	# get true/false if a user is validable
	@server.get @config.base + "/api/users/:id/validate/:key", (req, res, next) =>
		console.log req.params
		@db.users.isValidable {
			id: req.params.id
			key: req.params.key
		}, @server.send(res, next)

	# get my infos
	@server.get @config.base + '/api/me', @auth.needed, (req, res, next) =>
		@db.users.get req.user.id, (e, user) =>
			return next(e) if e
			@db.users.getApps user.id, (e, appkeys) ->
				return next(e) if e
				user.apps = appkeys
				res.send user
				next()

	# update mail or password
	@server.post @config.base + '/api/me', @auth.needed, (req, res, next) =>
		next new @check.Error "Implemented soon !"

	# delete my account
	@server.del @config.base + '/api/me', @auth.needed, (req, res, next) =>
		@db.users.remove req.user.id, @server.send(res,next)

	callback()