emailer = require 'nodemailer'
fs = require 'fs'
_ = require 'underscore'

class Mailer

	options : {}
	data : {}
	
	constructor : (@options, @data) ->

	send : (callback) ->

		if @options.templateName? && @options.templatePath
			html = @getHtml(@options.templateName, @data)

		message = 
			to: "#{@options.to.email}"
			from: "#{@options.from.email}"
			subject: @options.subject
			text: @options.body if not html?
			html: html if html?
			generateTextFromHTML: true if html?

		transport = @getTransport()
		transport.sendMail message, callback

	getTransport : () ->
		emailer.createTransport "SMTP",
			service: "Gmail"
			auth:
				user: "mytest042@gmail.com"
				pass: "P@ssword0"

	getHtml : (templateName, data) ->
		templateFullPath = "#{@options.templatePath}/#{templateName}.html"
		templateContent = fs.readFileSync(templateFullPath, encoding = "utf8")
		_.template templateContent, data, { interpolate: /\{\{(.+?)\}\}/g}
	

exports = module.exports = Mailer