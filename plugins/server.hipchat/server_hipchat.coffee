# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#

request = require 'request'

exports.setup = (callback) ->

	if not @config.hipchat?.token
		console.log 'Warning: hipchat plugin is not configured'
		return callback()

	hipchat = (data) =>
		request {
			url: 'https://api.hipchat.com/v1/rooms/message'
			method: 'POST'
			qs:
				auth_token: @config.hipchat.token
			form:
				room_id: data.room
				from: @config.hipchat.name
				message: data.message.replace(/\n/g,'<br/>')
				message_format: 'html'
				notify: '1'
		}, (e, r, body) ->

	@on 'user.contact', (data) =>
		hipchat room:@config.hipchat.room_support, message:data.body

	@on 'user.pay', (data) =>
		hipchat room:@config.hipchat.room_activities, message:data.user.profile.name + ' bought offer ' + data.invoice.plan_name + ' ($' + data.invoice.total + ') *shlingggggggggggg*'

	callback()