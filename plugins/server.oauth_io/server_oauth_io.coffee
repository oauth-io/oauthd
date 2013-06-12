restify = require 'restify'
Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	@server.post @config.base + '/contact-us', (req, res, next) =>

		options = 
			to: 				
				email: req.body.email_to			
			from:
				name: req.body.name_from
				email: req.body.email_from
			subject: req.body.subject
			body: req.body.body
			#templatePath: "#{__dirname}/mailer/templates"
			#templateName: 'contact-us'
		
		data =
			name_from: options.from.name
			email_from: options.from.email
			body: options.body.replace(/\n/g, "<br />")

		mailer = new Mailer options, data		
		mailer.send (err, result) ->
			return next err if err			
			res.send result

	callback()