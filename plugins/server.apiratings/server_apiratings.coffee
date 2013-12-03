

exports.setup = (callback) ->
	@server.post '/apiratings/signup', (req, res, next) =>
		next new restify.MissingParameterError "Enter an email before to submit. ;)" unless req.body.mail

		mail = req.body.mail
		mailRegexp = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/
		next new restify.InvalidArgumentError "Your email is invalid. Please enter a valid one." unless mail.match(mailRegexp)

		@db.redis.sadd "apiratings:users", mail

		res.send error:false
		next()

	callback()