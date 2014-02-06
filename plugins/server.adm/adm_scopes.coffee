fs = require 'fs'

exports.setup = ->
	@on 'connect.auth', (data) =>
		for apiname, apivalue of data.parameters
			if Array.isArray apivalue
				@db.redis.incr "scopes:#{data.provider}:#{apiname}:total:" + apivalue.join " "
		return

	@on 'connect.auth.new_uid', (data) =>
		for apiname, apivalue of data.parameters
			if Array.isArray apivalue
				@db.redis.incr "scopes:#{data.provider}:#{apiname}:u:total:" + apivalue.join " "
		return

	@on 'connect.callback', (data) =>
		for apiname, apivalue of data.parameters
			if Array.isArray apivalue
				@db.redis.incr "scopes:#{data.provider}:#{apiname}:#{data.status}:" + apivalue.join " "
		return

	@on 'connect.callback.new_uid', (data) =>
		for apiname, apivalue of data.parameters
			if Array.isArray apivalue
				@db.redis.incr "scopes:#{data.provider}:#{apiname}:u:#{data.status}:" + apivalue.join " "
		return

	redisScripts =
		scopesUpdate: (provider, callback) =>
			fs.readFile __dirname + '/lua/scopesupdate.lua', 'utf8', (err, script) =>
				@db.redis.eval script, 0, provider || "*", (e, r) ->
					return callback e if e
					return callback null, r

	@server.get @config.base_api + '/adm/scopes/update', @auth.adm, (req, res, next) =>
		redisScripts.scopesUpdate req.params.provider, @server.send(res, next)