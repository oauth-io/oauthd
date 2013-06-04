# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

restify = require 'restify'

exports.setup = (callback) ->

	# get users list
	@server.get @config.base + '/api/adm/users', @auth.needed, (req, res, next) =>
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
					users[mail] = id:iduser, date_inscr:parseInt(r[i*2]), apps:r[i*2+1]
					i++
				res.send users
				next()

	callback()