# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#

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

	@on 'user.contact', (data) ->
		hipchat data.body

	@on 'user.pay', (data) ->
		hipchat data.user.profile.name + ' bought offer ' + data.invoice.plan_name + ' ($' + data.invoice.total + ') *shlingggggggggggg*'

	callback()