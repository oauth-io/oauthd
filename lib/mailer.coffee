emailer = require('nodemailer')
fs = require('fs')

class Mailer

	options : {}
	data : {}

	constructor : (@options, @data) ->

	send : (callback) ->

		if @options.template?
			html = @getHtml(@options.template, @data)

		message = 
			to: "#{@options.to.email}"
			from: "#{@options.from.email}"
			subject: @options.subject
			text: @options.text			

		transport = @getTransport()
		transport.sendMail message, callback

	getTransport : () ->
		emailer.createTransport "SMTP",
			service: "Gmail"
			auth:
				user: "mytest042@gmail.com"
				pass: "P@ssword0"
	

exports = module.exports = Mailer