restify = require 'restify'

exports.setup = (callback) ->
	@server.post '/apiratings/signup', (req, res, next) =>
		next new restify.MissingParameterError "Enter an email before to submit. ;)" unless req.body.mail

		mail = req.body.mail
		mailRegexp = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/
		next new restify.InvalidArgumentError "Your email is invalid. Please enter a valid one." unless mail.match(mailRegexp)

		@db.redis.sadd "apiratings:users", mail

		res.setHeader 'Access-Control-Allow-Origin', 'http://apiratings.org'
		res.setHeader 'Access-Control-Allow-Methods', 'POST'

		res.send error:false
		next()

	@server.get '/apiratings/adm/tralalatsointsoin', (req, res, next) =>
		@db.redis.smembers "apiratings:users", @server.send(res, next)

	@server.opts '/apiratings/signup', (req, res, next) =>
		res.setHeader 'Access-Control-Allow-Origin', 'http://apiratings.org'
		res.setHeader 'Access-Control-Allow-Methods', 'POST'
		if req.headers['access-control-request-headers']
			res.setHeader 'Access-Control-Allow-Headers', req.headers['access-control-request-headers']
		res.send 200
		next false

	callback()