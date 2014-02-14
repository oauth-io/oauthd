
exports.setup = (callback) ->

	@hooks['connect.auth'].push (req, res, next) =>
		oaio_uid = req.headers.cookie?.match(/oaio_uid=%22(.*?)%22/)?[1]

		if not oaio_uid
			oaio_uid = @db.generateUid()
			d = new Date (new Date).getTime() + 3*365*24*3600*1000
			res.setHeader 'Set-Cookie', 'oaio_uid=%22' + oaio_uid + '%22; Path=/; Expires=' + d.toGMTString()
			req.new_oaio_uid = true
			@db.redis.set 'oaio_uid:' + oaio_uid + ':new', '1'

		req.oaio_uid = oaio_uid
		next()

	@hooks['connect.callback'].push (req, res, next) =>
		req.oaio_uid = req.headers.cookie?.match(/oaio_uid=%22(.*?)%22/)?[1]
		return next() if not req.oaio_uid
		@db.redis.del 'oaio_uid:' + req.oaio_uid + ':new', (e, r) ->
			return next e if e
			console.log r
			req.new_oaio_uid = true if r == 1
			next()

	callback()