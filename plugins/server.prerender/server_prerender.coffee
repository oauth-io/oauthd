prerender = require 'prerender-node'

exports.init = ->

	if not @config.prerender?.host || not @config.prerender.port
		console.log 'Warning: prerender plugin is not configured'
		return

	prerender.set 'prerenderServiceUrl', 'http://' + @config.prerender.host + ':' + @config.prerender.port

	prerender.crawlerUserAgents = [
		'googlebot',
		'yahoo',
		'bingbot',
		'baiduspider',
		'facebookexternalhit',
		'twitterbot'
	]

	prerender.set 'beforeRender', (req, done) =>
		@db.redis.get 'prerender:' + req.url, done

	prerender.set 'afterRender', (req, prerender_res) =>
		@db.redis.set 'prerender:' + req.url, prerender_res.body, =>
			@db.redis.expire 'prerender:' + req.url, 3600*48

	@server.use (req, res, next) =>
		req.protocol = 'https'
		req.get = (k) -> req.headers[k.toLowerCase()]
		next()

	@server.use prerender


exports.setup = (callback) ->

	@server.get @config.base_api + '/adm/prerender/flush', @auth.adm, (req, res, next) =>
		@db.redis.eval 'return redis.call("del", unpack(redis.call("keys", "prerender:*")))', 0, @server.send(res, next)

	callback()