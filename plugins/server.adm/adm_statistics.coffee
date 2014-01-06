fs = require 'fs'
async = require 'async'

exports.setup = ->
	@on 'connect.callback', (data) =>
		@db.timelines.addUse target:'co:' + data.status, (->)
		@db.ranking_timelines.addScore 'p:co:' + data.status, id:data.provider, (->)
		@db.redis.hget 'a:keys', data.key, (e,app) =>
			@db.ranking_timelines.addScore 'a:co:' + data.status, id:app, (->)

	@on 'connect.auth', (data) =>
		@db.timelines.addUse target:'co', (->)
		@db.ranking_timelines.addScore 'p:co', id:data.provider, (->)
		@db.redis.hget 'a:keys', data.key, (e,app) =>
			@db.ranking_timelines.addScore 'a:co', id:app, (->)

	@on 'request', (data) =>
		@db.timelines.addUse target:'req', (->)
		@db.ranking_timelines.addScore 'p:req', id:data.provider, (->)
		@db.redis.hget 'a:keys', data.key, (e,app) =>
			@db.ranking_timelines.addScore 'a:req', id:app, (->)

	redisScripts =
		appsbynewusers: @check start:'int', end:['int', 'none'], (data, callback) =>
			start = Math.floor(data.start)
			end = Math.floor(data.end || (new Date).getTime() / 1000)
			return callback new @check.Error 'start', 'start must be > 01/06/2013' if start < 1370037600 # 01/06/2013 00:00:00
			return callback new @check.Error 'start must be < end !' if end - start < 0
			return callback new @check.Error 'time interval must be within 3 months' if end - start > 3600*24*93
			fs.readFile __dirname + '/lua/appsbynewusers.lua', 'utf8', (err, script) =>
				@db.redis.eval script, 0, start*1000, end*1000, (e,r) ->
					return callback e if e
					r[1][i] /= 100 for i of r[1]
					return callback null, r

	@server.get @config.base_api + '/adm/scripts/appsbynewusers', @auth.adm, (req, res, next) =>
		redisScripts.appsbynewusers req.params, @server.send(res, next)

	# get any timeline
	@server.get new RegExp('^' + @config.base_api + '/adm/stats/(.+)'), @auth.adm, (req, res, next) =>
		async.parallel [
			(cb) => @db.timelines.getTimeline req.params[0], req.query, cb
			(cb) => @db.timelines.getTotal req.params[0], cb
		], (e, r) ->
			return next e if e
			res.send total:r[1], timeline:r[0]
			next()



	# RANKINGS #

	# refresh rankings
	@server.get @config.base_api + '/adm/rankings/refresh', @auth.adm, (req, res, next) =>
		providers = {}
		@db.redis.hgetall 'a:keys', (e, apps) =>
			return next e if e
			tasks = []
			for k,id of apps
				do (id) => tasks.push (cb) =>
					@db.redis.keys 'a:' + id + ':k:*', (e, keysets) =>
						return cb e if e
						for keyset in keysets
							prov = keyset.match /^a:.+?:k:(.+)$/
							continue if not prov?[1]
							providers[prov[1]] ?= 0
							providers[prov[1]]++
						@db.rankings.setScore 'a:k', id:id, val:keysets.length, cb
			async.parallel tasks, (e) =>
				return next e if e
				for p,keysets of providers
					@db.rankings.setScore 'p:k', id:p, val:keysets, (->)
				res.send @check.nullv
				next()

	# get a ranking
	@server.post @config.base_api + '/adm/ranking', @auth.adm, (req, res, next) =>
		@db.ranking_timelines.getRanking req.body.target, req.body, @server.send(res, next)

	# get a ranking related to apps
	@server.post @config.base_api + '/adm/ranking/apps', @auth.adm, (req, res, next) =>
		@db.ranking_timelines.getRanking req.body.target, req.body, (e, infos) =>
			return next e if e
			cmds = []
			for info in infos
				cmds.push ['get', 'a:' + info.name + ':name']
				cmds.push ['smembers', 'a:' + info.name + ':domains']
				# ... add more ? domains ? owner ?
			@db.redis.multi(cmds).exec (e, r) ->
				infos[i].name = r[i*2] + ' (' + r[i*2+1].join(', ') + ')' for i of infos
				res.send infos
				next()