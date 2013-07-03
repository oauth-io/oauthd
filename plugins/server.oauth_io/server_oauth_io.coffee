
Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	@server.post @config.base + '/contact-us', (req, res, next) =>

		options =
			to:
				email: "team@oauth.io"
			from:
				name: "Contact form"
				email: "team@oauth.io"
			subject: req.body.subject
			body: req.body.body

		mailer = new Mailer options, {}
		mailer.send (err, result) ->
			return next err if err
			res.send result

	callback()