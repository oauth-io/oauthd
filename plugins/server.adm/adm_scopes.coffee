
exports.setup = ->
	@on 'connect.auth', (data) =>
		for apiname, apivalue of data.parameters
			if Array.isArray apivalue
				@db.redis.incr "scopes:#{data.provider}:#{apiname}:total:" + apivalue.join " "
		return

	@on 'connect.callback', (data) =>
		for apiname, apivalue of data.parameters
			if Array.isArray apivalue
				@db.redis.incr "scopes:#{data.provider}:#{apiname}:#{data.status}:" + apivalue.join " "
		return