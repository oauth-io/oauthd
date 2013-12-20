
Mailer = require '../../lib/mailer'
restify = require 'restify'

exports.setup = (callback) ->

	@server.post @config.base + '/contact-us', (req, res, next) =>

		contact =
			name: req.body.name_from?.toString().replace(/</g,'&lt;').replace(/>/g,'&gt;')
			email: req.body.email_from?.toString().replace(/</g,'&lt;').replace(/>/g,'&gt;')
			subject: req.body.subject?.toString().replace(/</g,'&lt;').replace(/>/g,'&gt;')
			message: req.body.body?.toString().replace(/<'/g,'&lt;').replace(/>/g,'&gt;')

		contact.body = "From: " + contact.name + "\n"
		contact.body += "Email: " + contact.email + "\n"
		contact.body += "Subject: " + contact.subject + "\n\n"
		contact.body += contact.message

		@emit 'user.contact', contact
		res.send @check.nullv
		next()

	if ! @config.http_port
		console.log "Warning: oauth_io plugin is not configured"

	redir = (req, res, next) =>
		res.setHeader 'Location', @config.host_url + req.url
		res.send 301
		next false
	http_server = restify.createServer name: 'OAuth Daemon (http)', version: '1.0.0'
	http_server.get /^.*$/, redir
	http_server.post /^.*$/, redir
	http_server.put /^.*$/, redir
	http_server.patch /^.*$/, redir
	http_server.del /^.*$/, redir
	http_server.head /^.*$/, redir
	http_server.listen (@config.http_port||6285), (err) ->
		return callback err if err
		console.log '%s listening at %s', http_server.name, http_server.url
		callback()