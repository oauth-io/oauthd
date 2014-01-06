# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	require('./adm_statistics').setup.call @
	require('./adm_scopes').setup.call @
	require('./adm_updates').setup.call @

	@userInvite = (iduser, callback) =>
		prefix = 'u:' + iduser + ':'
		@db.redis.mget [
			prefix+'mail',
			prefix+'key',
			prefix+'validated'
		], (err, replies) =>
			return callback err if err
			if replies[2] == '1'
				return callback new check.Error "not validable"
			options =
				templateName:"mail_validation"
				templatePath:"./app/template/"
				to:
					email: replies[0]
				from:
					name: 'OAuth.io'
					email: 'team@oauth.io'
				subject: 'Validate your OAuth.io account'
			data =
				url: 'https://' + @config.url.host + '/validate/' + iduser + '/' + replies[1]
			mailer = new Mailer options, data
			mailer.send (err, result) =>
				console.error 'error while sending validation mail !', err if err
			@db.redis.set prefix+'validated', '2'
			callback()

	@server.post @config.base_api + '/adm/users/:id/invite', @auth.adm, (req, res, next) =>
		@userInvite req.params.id, @server.send(res, next)

	# get users list
	@server.get @config.base_api + '/adm/users', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			for mail,iduser of users
				cmds.push ['get', 'u:' + iduser + ':date_inscr']
				cmds.push ['smembers', 'u:' + iduser + ':apps']
				cmds.push ['get', 'u:' + iduser + ':key']
				cmds.push ['get', 'u:' + iduser + ':validated']
			@db.redis.multi(cmds).exec (err, r) =>
				return next err if err
				i = 0
				for mail,iduser of users
					users[mail] = email:mail, id:iduser, date_inscr:r[i*4], apps:r[i*4+1], key:r[i*4+2], validated:r[i*4+3]
					i++
				res.send users
				next()

	# get app info with ID
	@server.get @config.base_api + '/adm/app/:id', @auth.adm, (req, res, next) =>
		id_app = req.params.id
		prefix = 'a:' + id_app + ':'
		cmds = []
		cmds.push ['mget', prefix + 'name', prefix + 'key']
		cmds.push ['smembers', prefix + 'domains']
		cmds.push ['keys', prefix + 'k:*']

		@db.redis.multi(cmds).exec (err, results) ->
			return next err if err
			app = id:id_app, name:results[0][0], key:results[0][1], domains:results[1], providers:( result.substr(prefix.length + 2) for result in results[2] )
			res.send app
			next()

	# delete a user
	@server.del @config.base_api + '/adm/users/:id', @auth.adm, (req, res, next) =>
		@db.users.remove req.params.id, @server.send(res, next)

	# regenerate all private keys
	@server.get @config.base_api + '/adm/secrets/reset', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'a:keys', (e, apps) =>
			return next e if e
			mset = []
			for k,id of apps
				mset.push 'a:' + id + ':secret'
				mset.push @db.generateUid()
			@db.redis.mset mset, @server.send(res,next)


	# get provider list
	@server.get @config.base_api + '/adm/wishlist', @auth.adm, (req, res, next) =>
		@db.wishlist.getList full:true, @server.send(res, next)

	@server.del @config.base_api + '/adm/wishlist/:provider', @auth.adm, (req, res, next) =>
		@db.wishlist.remove req.params.provider, @server.send(res, next)

	@server.post @config.base_api + '/adm/wishlist/setStatus', @auth.adm, (req, res, next) =>
		@db.wishlist.setStatus req.body.provider, req.body.status , @server.send(res, next)

	# plans
	@server.post @config.base_api + '/adm/plan/create', @auth.adm, (req, res, next) =>
		@db.pricing.createOffer req.body, @server.send(res, next)

	@server.get @config.base_api + '/adm/plan', @auth.adm, (req, res, next) =>
		@db.pricing.getOffersList @server.send(res, next)

	@server.del @config.base_api + '/adm/plan/:name', @auth.adm, (req, res, next) =>
		@db.pricing.removeOffer req.params.name, @server.send(res, next)


	#@server.post @config.base_api + '/adm/plan/update/:amount/:name/:currency/:interval', @auth.adm, (req, res, next) =>
	#	@db.pricing.updateOffer req.params.amount, req.params.name, req.params.currency, req.params.interval, @server.send(res, next)

	@server.post @config.base_api + '/adm/plan/update', @auth.adm, (req, res, next) =>
		@db.pricing.updateStatus req.body.name, req.body.currentStatus, @server.send(res, next)

	callback()