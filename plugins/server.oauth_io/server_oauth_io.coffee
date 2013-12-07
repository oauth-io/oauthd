
Mailer = require '../../lib/mailer'
restify = require 'restify'
request = require 'request'

exports.setup = (callback) ->

	hipchat = (txt) =>
		return if not @config.hipchat?.token
		request {
			url: 'https://api.hipchat.com/v1/rooms/message'
			method: 'POST'
			qs:
				auth_token: @config.hipchat.token
			form:
				room_id: @config.hipchat.room
				from: @config.hipchat.name
				message: txt.replace(/\n/g,'<br/>')
				message_format: 'html'
				notify: '1'
		}, (e, r, body) ->

	@server.post @config.base + '/contact-us', (req, res, next) =>

		body = "From: " + req.body.name_from?.toString().replace(/</g,'&lt;').replace(/>/g,'&gt;') + "\n"
		body += "Email: " + req.body.email_from?.toString().replace(/</g,'&lt;').replace(/>/g,'&gt;') + "\n\n"
		body += req.body.body?.toString().replace(/<'/g,'&lt;').replace(/>/g,'&gt;')

		options =
			to:
				email: "team@oauth.io"
			from:
				name: "Contact form"
				email: "team@oauth.io"
			subject: "[Contact Us] Mail from oauth.io"
			body: body

		hipchat options.body
		mailer = new Mailer options, {}
		mailer.send (err, result) ->
			return next err if err
			res.send result

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