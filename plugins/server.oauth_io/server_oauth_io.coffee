restify = require 'restify'
Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	@server.post @config.base + '/contact-us', (req, res, next) =>

		options = 
			to: 
				email: req.body.email_to
			from:
				email: req.body.email_from
			subject: req.body.subject
			text: req.body.message

		mailer = new Mailer options
		
		mailer.send (err, result) ->
			return next err if err			
			res.send result

	callback()