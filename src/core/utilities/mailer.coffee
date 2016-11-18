# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

emailer = require 'nodemailer'
fs = require 'fs'
_ = require 'underscore'


module.exports = (env) ->

	config = env.config

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
			template = _.template templateContent, { interpolate: /\{\{(.+?)\}\}/g}
			template data


	Mailer