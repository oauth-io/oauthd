# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#

request = require 'request'

exports.setup = (callback) ->

	if not @config.zendesk?.token
		console.log 'Warning: zendesk plugin is not configured'

	@on 'user.contact', (contact) =>
		return if not @config.zendesk?.token or not @config.zendesk.user
		request {
			url: 'https://oauthio.zendesk.com/api/v2/tickets.json'
			method: 'POST'
			auth:
				user: @config.zendesk.user + '/token'
				pass: @config.zendesk.token
			json:
				ticket:
					requester:
						name: contact.name
						email: contact.email
					subject: contact.subject
					comment:
						body: contact.message
		}, (e, r, body) ->
			console.error "Error while sending contact-us to zendesk", e, body, contact.body if e

	callback()