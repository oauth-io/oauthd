emailer = require 'nodemailer'
fs = require 'fs'
_ = require 'underscore'
config = require './config'

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

	getTransport : ->
		emailer.createTransport "SMTP", config.smtp

	getHtml : (templateName, data) ->
		templateFullPath = "#{@options.templatePath}/#{templateName}.html"
		templateContent = fs.readFileSync(templateFullPath, encoding = "utf8")
		_.template templateContent, data, { interpolate: /\{\{(.+?)\}\}/g}


exports = module.exports = Mailer