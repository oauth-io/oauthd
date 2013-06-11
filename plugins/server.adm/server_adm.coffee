# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

restify = require 'restify'

exports.setup = (callback) ->

	# get users list
	@server.get @config.base + '/api/adm/users', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			for mail,iduser of users
				cmds.push ['get', 'u:' + iduser + ':date_inscr']
				cmds.push ['smembers', 'u:' + iduser + ':apps']
			@db.redis.multi(cmds).exec (err, r) =>
				return next err if err
				i = 0
				for mail,iduser of users										
					users[mail] = email:mail, id:iduser, date_inscr:r[i*2], apps:r[i*2+1]
					i++				
				res.send users
				next

	# get app info with ID
	@server.get @config.base + 'api/adm/app/:id', @auth.adm, (req, res, next) =>
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

	callback()