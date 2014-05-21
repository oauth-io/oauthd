# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	@db.heroku = require './../server.heroku/db_heroku'
	@db.platforms = require './../server.platforms/db_platforms'
	@db.platforms_admins = require './../server.platforms/db_platforms_admins'

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
			###
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
			###
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
				cmds.push ['get', 'u:' + iduser + ':heroku_id']
				cmds.push ['get', 'u:' + iduser + ':platform']
				cmds.push ['get', 'u:' + iduser + ':platform_admin']
			@db.redis.multi(cmds).exec (err, r) =>
				return next err if err
				i = 0
				for mail,iduser of users
					users[mail] = email:mail, id:iduser, date_inscr:r[i*7], apps:r[i*7+1], key:r[i*7+2], validated:r[i*7+3], heroku_id:r[i*7+4], platform:r[i*7+5], platform_admin:r[i*7+6]
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

	##################### heroku
	# get all heroku apps
	@server.get @config.base_api + '/adm/getAllAppsHeroku', @auth.adm, (req, res, next) =>
		@db.heroku.getAllApps @server.send(res, next)

	# get a heroku app info
	@server.get @config.base_api + '/adm/getAppInfoHeroku/:heroku_id', @auth.adm, (req, res, next) =>
		@db.heroku.getAppInfo req.params.heroku_id, @server.send(res, next)

	##################### platforms
	# get platforms
	@server.get @config.base_api + '/adm/platforms', @auth.adm, (req, res, next) =>
		@db.platforms.getAll @server.send(res, next)

	# add platform
	@server.post @config.base_api + '/adm/platforms/:platform_name', @auth.adm, (req, res, next) =>
		@db.platforms.add req.params.platform_name, @server.send(res, next)

	# remove platform
	@server.del @config.base_api + '/adm/platforms/:idplatform', @auth.adm, (req, res, next) =>
		@db.platforms.remove req.params.idplatform, @server.send(res, next)

	# add admin to platform
	@server.post @config.base_api + '/adm/platforms/:idplatform/addAdmin/:iduser', @auth.adm, (req, res, next) =>
		@db.platforms_admins.add req.params.idplatform, req.params.iduser, @server.send(res, next)

	# get admins of platforms
	@server.get @config.base_api + '/adm/platforms/getAdmins', @auth.adm, (req, res, next) =>
		@db.platforms_admins.getAll @server.send(res, next)

	# remove admin of platforms
	@server.del @config.base_api + '/adm/platforms/removeAdmin/:iduser', @auth.adm, (req, res, next) =>
		@db.platforms_admins.remove req.params.iduser, @server.send(res, next)

	callback()


