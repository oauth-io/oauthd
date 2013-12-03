

exports.setup = (callback) ->
	@server.post '/apiratings/signup', (req, res, next) =>
		next new restify.MissingParameterError "Enter an email before to submit. ;)" unless req.body.mail

		mail = req.body.mail
		mailRegexp = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/
		next new restify.InvalidArgumentError "Your email is invalid. Please enter a valid one." unless mail.match(mailRegexp)

		@db.redis.sadd "apiratings:users", mail

		res.setHeader 'access-control-allow-origin', 'http://apiratings.org'
		res.setHeader 'access-control-allow-methods', 'POST'

		res.send error:false
		next()

	@server.opts '/apiratings/signup', (req, res, next) =>
		res.setHeader 'access-control-allow-origin', 'http://apiratings.org'
		res.setHeader 'access-control-allow-methods', 'POST'
		if req.headers['access-control-request-headers']
			res.setHeader 'access-control-allow-headers', req.headers['access-control-request-headers']
		res.send 200
		next false

	callback()