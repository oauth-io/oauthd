
Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	@server.post @config.base + '/contact-us', (req, res, next) =>

		body = "From: " + req.body.name_from?.toString().replace('<','&lt;').replace('>','&gt;') + "\n"
		body += "Email: " + req.body.email_from?.toString().replace('<','&lt;').replace('>','&gt;') + "\n\n"
		body += req.body.body?.toString().replace('<','&lt;').replace('>','&gt;')

		options =
			to:
				email: "team@oauth.io"
			from:
				name: "Contact form"
				email: "team@oauth.io"
			subject: "[Contact Us] Mail from oauth.io"
			body: body

		mailer = new Mailer options, {}
		mailer.send (err, result) ->
			return next err if err
			res.send result

	callback()