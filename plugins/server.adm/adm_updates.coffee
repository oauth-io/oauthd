fs = require 'fs'
async = require 'async'

exports.setup = ->

	redisScripts =
		dbapps_update_owners: (callback) =>
				fs.readFile __dirname + '/lua/dbapps_update_owners.lua', 'utf8', (err, script) =>
					@db.redis.eval script, 0, (e,r) ->
						return callback e if e
						return callback null, r

	@server.get @config.base_api + '/adm/scripts/appsbynewusers', @auth.adm, (req, res, next) =>
		redisScripts.appsbynewusers req.params, @server.send(res, next)

	@server.get @config.base_api + '/adm/scripts/dbapps_update_owners', @auth.adm, (req, res, next) =>
		redisScripts.dbapps_update_owners @server.send(res, next)

	@server.get @config.base_api + '/adm/updates/dbusers_providers', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			for mail,iduser of users
				do (iduser) =>
					cmds.push (callback) => @db.users.updateProviders iduser, callback
			console.log '[ADMIN] beginning dbusers_providers'
			async.series cmds, (e,r) ->
				return console.log '[ADMIN] error dbusers_providers', e if e
				console.log '[ADMIN] finished dbusers_providers'
			res.send @check.nullv
			next()

	@server.get @config.base_api + '/adm/updates/dbusers_auths', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			now = new Date - 0
			lastmonth = new Date(now - 30 * 24 * 3600 * 1000) - 0
			for mail,iduser of users
				do (iduser) =>
					cmds.push (callback) => @db.users.updateConnections iduser, now, callback
					cmds.push (callback) => @db.users.updateConnections iduser, lastmonth, callback
			console.log '[ADMIN] beginning dbusers_auths'
			async.series cmds, (e,r) ->
				return console.log '[ADMIN] error dbusers_auths', e if e
				console.log '[ADMIN] finished dbusers_auths'
			res.send @check.nullv
			next()

	@server.get @config.base_api + '/adm/updates/cohort_ready', @auth.adm, (req, res, next) =>
		console.log '[ADMIN] beginning cohort_ready'
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			for mail,iduser of users
				pfx = 'u:' + iduser + ':'
				cmds.push ['scard', pfx+'apps']
				cmds.push ['scard', pfx+'providers']
			@db.redis.multi(cmds).exec (err, r) =>
				console.log '[ADMIN] error with big multi', err if err
				return next err if err
				i = 0
				for mail,iduser of users
					do (mail, iduser) =>
						user = mail:mail, id:iduser
						@emit 'user.update_nbapps', user, r[i*2]
						@emit 'user.update_nbproviders', user, r[i*2+1]
					i++
				console.log '[ADMIN] finished cohort_ready (there still may be some events in queue)'

			res.send @check.nullv
			next()
